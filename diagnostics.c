#include "diagnostics.h"
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
#include <windows.h>
static HANDLE logFile = INVALID_HANDLE_VALUE;
#else
#include <sys/stat.h>
#include <unistd.h>
static FILE *logFile;
#endif

void diagnosticLog(const char *format, ...)
{
    char message[2048];
    char line[2200];
    va_list args;
    time_t now = time(NULL);
    va_start(args, format);
    vsnprintf(message, sizeof(message), format, args);
    va_end(args);
    snprintf(line, sizeof(line), "[%lld] %s\n", (long long)now, message);
#ifdef _WIN32
    if (logFile != INVALID_HANDLE_VALUE) {
        DWORD written;
        WriteFile(logFile, line, (DWORD)strlen(line), &written, NULL);
        FlushFileBuffers(logFile);
    }
#else
    if (logFile) {
        fputs(line, logFile);
        fflush(logFile);
    }
#endif
}

#ifdef _WIN32
static LONG WINAPI logUnhandledException(EXCEPTION_POINTERS *exception)
{
    // Best effort only: heap corruption / fail-fast may bypass this handler.
    // Run with Start-Diagnostics.ps1 for an external crash dump in those cases.
    diagnosticLog("UNHANDLED EXCEPTION code=0x%08lx address=%p thread=%lu",
        exception->ExceptionRecord->ExceptionCode,
        exception->ExceptionRecord->ExceptionAddress, GetCurrentThreadId());
    return EXCEPTION_CONTINUE_SEARCH;
}
#endif

static void closeLog(void)
{
    // atexit also runs for exit(error); this does not imply a successful game.
    diagnosticLog("process exit: atexit reached");
#ifdef _WIN32
    if (logFile != INVALID_HANDLE_VALUE) {
        CloseHandle(logFile);
        logFile = INVALID_HANDLE_VALUE;
    }
#else
    if (logFile) fclose(logFile);
    logFile = NULL;
#endif
}

void diagnosticInit(void)
{
    char path[512];
    time_t now = time(NULL);
#ifdef _WIN32
    CreateDirectoryA("logs", NULL);
    snprintf(path, sizeof(path), "logs/session-%lld-%lu.log", (long long)now, GetCurrentProcessId());
    logFile = CreateFileA(path, FILE_APPEND_DATA, FILE_SHARE_READ, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL);
    if (logFile == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "Cannot create diagnostic log (Windows error %lu)\n", GetLastError());
    }
    SetUnhandledExceptionFilter(logUnhandledException);
#else
    mkdir("logs", 0755);
    snprintf(path, sizeof(path), "logs/session-%lld-%ld.log", (long long)now, (long)getpid());
    logFile = fopen(path, "w");
#endif
    atexit(closeLog);
    diagnosticLog("DreeRally session started; build=%s %s; pointerBits=%u", __DATE__, __TIME__, (unsigned int)(sizeof(void *) * 8));
}
