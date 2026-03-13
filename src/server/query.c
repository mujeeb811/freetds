/* FreeTDS - Library of routines accessing Sybase and Microsoft databases
 * Copyright (C) 1998-2004  Brian Bruns
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
#include <config.h>

#include <assert.h>

#if HAVE_STDLIB_H
#include <stdlib.h>
#endif /* HAVE_STDLIB_H */

#include <freetds/tds.h>
#include <freetds/server.h>

static char *query;
static size_t query_buflen = 0;
static size_t query_len = 0;
static TDSHEADERS head;

/**
 * Read a TDS5 tokenized query.
 */
char *
tds_get_query(TDSSOCKET * tds)
{
	int len;

	if (query_buflen == 0) {
		query_buflen = 1024;
		query = tds_new(char, query_buflen);
	}
	tds_get_byte(tds);	/* 33 */
	len = tds_get_int(tds);	/* query size +1 */
	tds_get_byte(tds);	/* has args, ignored TODO */
	assert(len >= 1);	/* TODO handle correctly */
	if (len > query_buflen) {
		query_buflen = len;
		query = (char *) realloc(query, query_buflen);
	}
	--len;
	tds_get_n(tds, query, len);
	query[len] = 0;
	return query;
}

static bool
tds_lastpacket(TDSSOCKET * tds) 
{
	if (!tds || !tds->in_buf || tds->recv_packet->capacity < 2)
		return true;
	
	return tds->in_buf[1] != 0;
}

/**
 * Check if current packet is the last packet (improved version for binary-safe mode).
 * This version properly checks the TDS_STATUS_EOM flag (bit 0) instead of
 * checking if the status byte is non-zero, which is more correct since the
 * status byte can have multiple flags set.
 * \param tds  The socket to check.
 * \return true if this is the last packet, false otherwise.
 */
static bool
tds_lastpacket_bin(TDSSOCKET *tds)
{
	if (!tds || !tds->in_buf)
		return true;

	/* After tds_read_packet(), in_len contains the packet length which is >= 8 */
	if (tds->in_len < 8)
		return true;

	/* Check TDS_STATUS_EOM flag (bit 0) - 0x01 means last packet */
	return (tds->in_buf[1] & 0x01) != 0;
}

/**
 * get query packet of a given type
 * \tds
 * \param head         extra information to put in a TDS7 header
 */
static TDSRET
tds_get_query_head(TDSSOCKET * tds, TDSHEADERS * head)
{
	int qn_len = 0, more;
	char *qn_msgtext = NULL;
	char *qn_options = NULL;
	size_t qn_msgtext_len = 0;
	size_t qn_options_len = 0;

	if (!IS_TDS72_PLUS(tds->conn))
		return TDS_SUCCESS;

	free((void *) head->qn_options);
	head->qn_options = NULL;
	free((void *) head->qn_msgtext);
	head->qn_msgtext = NULL;

	qn_len = tds_get_int(tds) - 4 - 18;  /* total length */
	tds_get_int(tds);  /* length: transaction descriptor, ignored */
	tds_get_smallint(tds);  /* type: transaction descriptor, ignored */
	tds_get_n(tds, tds->conn->tds72_transaction, 8);  /* transaction */
	tds_get_int(tds);  /* request count, ignored */
	if (qn_len != 0) {
		qn_len = tds_get_int(tds);  /* length: query notification */
		tds_get_smallint(tds);  /* type: query notification, ignored */
		qn_msgtext_len = tds_get_smallint(tds);  /* notifyid */
		if (qn_msgtext_len > 0) {
			qn_msgtext = (char *) realloc(qn_msgtext, qn_msgtext_len);
			tds_get_n(tds, qn_msgtext, qn_msgtext_len);
		}

		qn_options_len = tds_get_smallint(tds);  /* ssbdeployment */
		if (qn_options_len > 0) {
			qn_options = (char *) realloc(qn_options, qn_options_len);
			tds_get_n(tds, qn_options, qn_options_len);
		}
		more = tds->in_len - tds->in_pos;
		if (more)
			head->qn_timeout = tds_get_int(tds);  /* timeout */

		head->qn_options = qn_options;
		head->qn_msgtext = qn_msgtext;
	}
	return TDS_SUCCESS;
}

/**
 * Read a query, and return it as an ASCII string with a \0 terminator.  This
 * should work for TDS4, TDS5, and TDS7+ connections.  Also, it converts RPC
 * calls into stored procedure queries, and it skips CANCEL packets.  The query
 * string is returned in a static buffer which is overwritten each time this
 * function is called.
 * \param tds    The socket to read from.
 * \param flags  Flags to control behavior. Use TDS_GENERIC_QUERY_FLAG_BINARY_SAFE
 *               to preserve NUL bytes in the query data (for binary data).
 * \param out_len  Optional pointer to receive the actual query length. This is
 *                 useful when TDS_GENERIC_QUERY_FLAG_BINARY_SAFE is set since
 *                 the query may contain embedded NUL bytes.
 * \return A query string if successful, or NULL if we either can't read from
 * the socket or we read something that we can't handle.
 */
char *
tds_get_generic_query_ex(TDSSOCKET * tds, int flags, size_t *out_len)
{
 	int token, byte;
	int len, more, i, j;
	int binary_safe = (flags & TDS_GENERIC_QUERY_FLAG_BINARY_SAFE) != 0;

	if (out_len)
		*out_len = 0;

	for (;;) {
		/*
		 * Read a new packet.  We must explicitly read it,
		 * instead of letting functions such as tds_get_byte()
		 * to read it for us, so that we can examine the packet
		 * type via tds->in_flag.
		 */
		if (tds_read_packet(tds) < 0)
			return NULL;

		/* Queries can arrive in a couple different formats. */
		switch (tds->in_flag) {
		case TDS_RPC:
			/* TODO */
			return NULL;
		case TDS_NORMAL: /* TDS5 query packet */
			/* get the token */
			token = tds_get_byte(tds);
			switch (token) {
			case TDS_LANGUAGE_TOKEN:
				/* SQL query */
				len = tds_get_int(tds); /* query size +1 */
				assert(len >= 1);	/* TODO handle */
				tds_get_byte(tds);	/* has args, ignored TODO */
				if (len > query_buflen) {
					query_buflen = len;
					query = (char *) realloc(query, query_buflen);
				}
				--len;
				tds_get_n(tds, query, len);
				query[len] = 0;
				query_len = len;
				if (out_len)
					*out_len = len;
				return query;

			case TDS_DBRPC_TOKEN:
				/* RPC call -- make it look like a query */

				/* skip the overall length */
				(void)tds_get_smallint(tds);

				/* get the length of the stored procedure's name */
				len = tds_get_byte(tds) + 1;/* sproc name size +1 */
				if (len > query_buflen) {
					query_buflen = len;
					query = (char *) realloc(query, query_buflen);
				}

				/*
				 * Read the chars of the name.  Skip NUL
				 * bytes, as a cheap way to convert
				 * Unicode to ASCII.  (For TDS7+, the
				 * name is sent in Unicode.)
				 */
				for (i = j  = 0; i < len - 1; i++) {
					byte = tds_get_byte(tds);
					if (byte != '\0')
						query[j++] = byte;
				}
				query[j] = '\0';
				query_len = j;
				if (out_len)
					*out_len = j;

				/* TODO: WE DON'T HANDLE PARAMETERS YET! */

				/* eat the rest of the packet */
				if (binary_safe) {
					while (!tds_lastpacket_bin(tds) && tds_read_packet(tds) > 0) {
					}
				} else {
					while (!tds_lastpacket(tds) && tds_read_packet(tds) > 0) {
					}
				}
				return query;

			default:
				/* unexpected token */

				/* eat the rest of the packet */
				if (binary_safe) {
					while (!tds_lastpacket_bin(tds) && tds_read_packet(tds) > 0) {
					}
				} else {
					while (!tds_lastpacket(tds) && tds_read_packet(tds) > 0) {
					}
				}
				return NULL;
			}
			break;

		case TDS_QUERY:
			/* TDS7+ adds a query head */
			if (IS_TDS72_PLUS(tds->conn) && tds_get_query_head(tds, &head) != TDS_SUCCESS)
				return NULL;

			/* TDS4 and TDS7+ fill the whole packet with a query */
			len = 0;
			for (;;) {
				const char *src;

				/* If buffer needs to grow, then grow */
				more = tds->in_len - tds->in_pos;
				src = (char *) (tds->in_buf + tds->in_pos);
				if ((size_t)(len + more + 1) > query_buflen) {
					query_buflen = len + more + 1024u;
					query_buflen -= query_buflen % 1024u;
					query = (char *) realloc(query, query_buflen);
				}

				/*
				 * Pull new data into the query buffer.
				 * If binary_safe flag is set, preserve all bytes including NUL.
				 * Otherwise, ignore NUL bytes -- this is a cheap way
				 * to convert Unicode to Latin-1/ASCII.
				 */
				if (binary_safe) {
					/* Preserve all bytes including NUL */
					while (--more >= 0) {
						query[len++] = *src++;
					}
				} else {
					/* Skip NUL bytes (original behavior) */
					while (--more >= 0) {
						query[len] = *src++;
						if (query[len] != '\0')
							len++;
					}
				}

				/* if more then read it */
				/* Use improved lastpacket check for binary-safe mode */
				if (binary_safe) {
					if (tds_lastpacket_bin(tds))
						break;
				} else {
					if (tds_lastpacket(tds))
						break;
				}
				if (tds_read_packet(tds) < 0)
					return NULL;
			}

			/* add a NUL to mark the end */
			query[len] = '\0';
			query_len = len;
			if (out_len)
				*out_len = len;
			return query;

		case TDS_CANCEL:
			/*
			 * ignore cancel requests -- if we're waiting
			 * for the next query then it's obviously too
			 * late to cancel the previous query.
			 */
			/* TODO it's not too late -- freddy77 */
			return NULL;

		default:
			/* not a query packet */
			return NULL;
		}
	}
}

/**
 * Read a query, and return it as an ASCII string with a \0 terminator.  This
 * should work for TDS4, TDS5, and TDS7+ connections.  Also, it converts RPC
 * calls into stored procedure queries, and it skips CANCEL packets.  The query
 * string is returned in a static buffer which is overwritten each time this
 * function is called.
 * \param tds  The socket to read from.
 * \return A query string if successful, or NULL if we either can't read from
 * the socket or we read something that we can't handle.
 * \note This function skips NUL bytes which may corrupt binary data. Use
 *       tds_get_generic_query_ex() with TDS_GENERIC_QUERY_FLAG_BINARY_SAFE
 *       flag for binary data.
 */
char *
tds_get_generic_query(TDSSOCKET * tds)
{
	return tds_get_generic_query_ex(tds, 0, NULL);
}

/**
 * Get the length of the last query returned by tds_get_generic_query_ex().
 * This is useful when TDS_GENERIC_QUERY_FLAG_BINARY_SAFE is used since
 * the query may contain embedded NUL bytes.
 * \return The length of the last query, or 0 if no query has been read.
 */
size_t
tds_get_generic_query_len(void)
{
	return query_len;
}

/**
 * Free query buffer returned by tds_get_generic_query.
 */
void
tds_free_query(void)
{
	TDS_ZERO_FREE(query);
	query_buflen = 0;
	query_len = 0;

	free((void *) head.qn_options);
	head.qn_options = NULL;
	free((void *) head.qn_msgtext);
	head.qn_msgtext = NULL;
}
