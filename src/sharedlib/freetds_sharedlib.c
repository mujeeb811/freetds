/*
 * FreeTDS shared library entry point
 * This file provides initialization/cleanup for the FreeTDS shared library
 * that combines tds, tdssrv, replacements, and tdsutils libraries.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef _WIN32
#include <windows.h>

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    switch (fdwReason)
    {
    case DLL_PROCESS_ATTACH:
        /* Initialization code when DLL is loaded */
        break;
    case DLL_PROCESS_DETACH:
        /* Cleanup code when DLL is unloaded */
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    }
    return TRUE;
}

#else /* !_WIN32 */

/* Constructor/destructor for shared library initialization on Unix/Linux */
#if defined(__GNUC__)

__attribute__((constructor))
static void freetds_sharedlib_init(void)
{
    /* Initialization code when shared library is loaded */
}

__attribute__((destructor))
static void freetds_sharedlib_fini(void)
{
    /* Cleanup code when shared library is unloaded */
}

#endif /* __GNUC__ */

#endif /* _WIN32 */
