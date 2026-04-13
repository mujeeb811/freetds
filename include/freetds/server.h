/* FreeTDS - Library of routines accessing Sybase and Microsoft databases
 * Copyright (C) 1998-1999  Brian Bruns
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

#ifndef _tdsguard_gt6cowOjOuyOf2Og3Ypj8u_
#define _tdsguard_gt6cowOjOuyOf2Og3Ypj8u_

#include <freetds/export.h>

#ifdef __cplusplus
extern "C"
{
#endif
#if 0
}
#endif

/* login.c */
TDS_EXPORT unsigned char *tds7_decrypt_pass(const unsigned char *crypt_pass, int len, unsigned char *clear_pass);
TDS_EXPORT TDSSOCKET *tds_listen(TDSCONTEXT * ctx, int ip_port);
TDS_EXPORT int tds_read_login(TDSSOCKET * tds, TDSLOGIN * login);
TDS_EXPORT int tds7_read_login(TDSSOCKET * tds, TDSLOGIN * login);
TDS_EXPORT TDSLOGIN *tds_alloc_read_login(TDSSOCKET * tds);

/* query.c */
/** Flag for tds_get_generic_query_ex() to preserve NUL bytes in query data (for binary data) */
#define TDS_GENERIC_QUERY_FLAG_BINARY_SAFE 0x01

TDS_EXPORT char *tds_get_query(TDSSOCKET * tds);
TDS_EXPORT char *tds_get_generic_query(TDSSOCKET * tds);
TDS_EXPORT char *tds_get_generic_query_ex(TDSSOCKET * tds, int flags, size_t *out_len);
TDS_EXPORT size_t tds_get_generic_query_len(void);
TDS_EXPORT void tds_free_query(void);

/* server.c */
TDS_EXPORT void tds_env_change(TDSSOCKET * tds, int type, const char *oldvalue, const char *newvalue);
TDS_EXPORT void tds_send_msg(TDSSOCKET * tds, int msgno, int msgstate, int severity, const char *msgtext, const char *srvname,
		  const char *procname, int line);
TDS_EXPORT void tds_send_login_ack(TDSSOCKET * tds, const char *progname);
TDS_EXPORT void tds_send_eed(TDSSOCKET * tds, int msgno, int msgstate, int severity, const char *msgtext, const char *srvname,
		  const char *procname, int line, const char *sqlstate);
TDS_EXPORT void tds_send_err(TDSSOCKET * tds, int msgno, int msgstate, int severity, const char *msgtext, const char *srvname,
		  const char *procname, int line);
TDS_EXPORT void tds_send_capabilities_token(TDSSOCKET * tds);
/* TODO remove, use tds_send_done */
TDS_EXPORT void tds_send_done_token(TDSSOCKET * tds, TDS_SMALLINT flags, TDS_INT numrows);
TDS_EXPORT void tds_send_done(TDSSOCKET * tds, int token, TDS_SMALLINT flags, TDS_INT numrows);
TDS_EXPORT void tds_send_control_token(TDSSOCKET * tds, TDS_SMALLINT numcols);
TDS_EXPORT TDSRET tds_send_table_header(TDSSOCKET * tds, TDSRESULTINFO * resinfo);
TDS_EXPORT TDSRET tds_send_row(TDSSOCKET * tds, TDSRESULTINFO * resinfo);
TDS_EXPORT void tds71_send_prelogin(TDSSOCKET * tds);

#if 0
{
#endif
#ifdef __cplusplus
}
#endif

#endif /* _tdsguard_gt6cowOjOuyOf2Og3Ypj8u_ */
