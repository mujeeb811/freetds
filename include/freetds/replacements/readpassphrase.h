/* OPENBSD ORIGINAL: include/readpassphrase.h */

/*	$OpenBSD: readpassphrase.h,v 1.3 2002/06/28 12:32:22 millert Exp $	*/

/*
 * Copyright (c) 2000 Todd C. Miller <Todd.Miller@courtesan.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _tdsguard_bkwzvYqnksBiqA9Zb1TtWU_
#define _tdsguard_bkwzvYqnksBiqA9Zb1TtWU_

#ifndef _freetds_config_h_
#error should include config.h before
#endif

#include <freetds/export.h>

#ifdef HAVE_READPASSPHRASE
# include <readpassphrase.h>
#endif

#include <freetds/pushvis.h>

/* RPP flags - always define these */
#ifndef RPP_ECHO_OFF
#define RPP_ECHO_OFF    0x00		/* Turn off echo (default). */
#endif
#ifndef RPP_ECHO_ON
#define RPP_ECHO_ON     0x01		/* Leave echo on. */
#endif
#ifndef RPP_REQUIRE_TTY
#define RPP_REQUIRE_TTY 0x02		/* Fail if there is no tty. */
#endif
#ifndef RPP_FORCELOWER
#define RPP_FORCELOWER  0x04		/* Force input to lower case. */
#endif
#ifndef RPP_FORCEUPPER
#define RPP_FORCEUPPER  0x08		/* Force input to upper case. */
#endif
#ifndef RPP_SEVENBIT
#define RPP_SEVENBIT    0x10		/* Strip the high bit from input. */
#endif
#ifndef RPP_STDIN
#define RPP_STDIN       0x20		/* Read from stdin, not /dev/tty */
#endif

/* tds_readpassphrase is always available */
TDS_EXPORT char * tds_readpassphrase(const char *, char *, size_t, int);

#ifndef HAVE_READPASSPHRASE
#undef readpassphrase
#define readpassphrase tds_readpassphrase
#endif

#include <freetds/popvis.h>

#endif /* !_tdsguard_bkwzvYqnksBiqA9Zb1TtWU_ */
