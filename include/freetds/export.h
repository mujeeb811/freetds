/* FreeTDS - Library of routines accessing Sybase and Microsoft databases
 * Copyright (C) 2024  FreeTDS contributors
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

#ifndef _tdsguard_FREETDS_EXPORT_H_
#define _tdsguard_FREETDS_EXPORT_H_

/**
 * @file export.h
 * Symbol export macros for shared library builds.
 *
 * Use TDS_EXPORT to mark functions that should be exported from the
 * shared library (libfreetds.so / freetds.dll).
 *
 * On GCC 4+, symbols are hidden by default with visibility("hidden").
 * Functions marked with TDS_EXPORT will have visibility("default")
 * and will be accessible to external applications.
 *
 * On Windows, we use WINDOWS_EXPORT_ALL_SYMBOLS in CMake which
 * automatically exports all symbols, so TDS_EXPORT is not needed
 * and expands to nothing. If manual export control is needed in
 * the future, define FREETDS_DLL_EXPORT when building the DLL
 * and FREETDS_DLL_IMPORT when using it.
 */

#if defined(_WIN32) || defined(__CYGWIN__)
  /* Windows: use WINDOWS_EXPORT_ALL_SYMBOLS, TDS_EXPORT is a no-op */
  #define TDS_EXPORT
#elif defined(__GNUC__) && __GNUC__ >= 4
  /* GCC 4+ visibility attribute */
  #define TDS_EXPORT __attribute__((visibility("default")))
#else
  /* No export mechanism available */
  #define TDS_EXPORT
#endif

#endif /* _tdsguard_FREETDS_EXPORT_H_ */
