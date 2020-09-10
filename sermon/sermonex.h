//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#ifndef _SERMON_EX_DEFINED_
#define _SERMON_EX_DEFINED_

#ifndef SERMON_DRIVER
#include <winioctl.h>    // if it's not a driver, include it manually
#endif

#define FILE_DEVICE_SERMON    0x00001001

// IOCTL_START_MONITOR initializes port monitoring, obtains a
// handle and returns it to calling application
// Input buffer contains null-terminated string naming serial
// device ("serial1","serial2"...)

// Output buffer will contain MHANDLE value that application 
// should use in all subsequent calls to this driver
#define IOCTL_SERMON_STARTMONITOR    \
    CTL_CODE(FILE_DEVICE_SERMON, 0x0801, METHOD_BUFFERED, \
    FILE_ANY_ACCESS)

// Input buffer contains MHANDLE value application received
// in a call to IOCTL_START_MONITOR
#define IOCTL_SERMON_STOPMONITOR    \
    CTL_CODE(FILE_DEVICE_SERMON, 0x0802, METHOD_BUFFERED, \
    FILE_ANY_ACCESS)

// Input buffer contains MHANDLE value application received
// in a call to IOCTL_START_MONITOR,
// Output buffer will contain the size of the information
#define IOCTL_SERMON_GETINFOSIZE    \
    CTL_CODE(FILE_DEVICE_SERMON, 0x0803, METHOD_BUFFERED, \
    FILE_ANY_ACCESS)

// Input buffer contains MHANDLE value application received 
// in a call to IOCTL_START_MONITOR,
// Output buffer will contain the information copied
#define IOCTL_SERMON_GETINFO        \
    CTL_CODE(FILE_DEVICE_SERMON, 0x0804, METHOD_BUFFERED, \
    FILE_ANY_ACCESS)

typedef ULONG MHANDLE;

// Request types
enum
{
    REQ_OPEN,
    REQ_READ,
    REQ_WRITE,
    REQ_CLOSE,
    REQ_FLUSH,
    REQ_SETBAUDRATE,
    REQ_SETLINECONTROL,
};

struct IOReq
{
#ifdef SERMON_DRIVER
    LIST_ENTRY entry;
    PVOID pData;
#else    // SERMON_DRIVER
    DWORD Reserved1;
    DWORD Reserved2;
    DWORD Reserved3;
#endif    // SERMON_DRIVER
    ULONG SizeRequested,SizeCopied;
    CHAR type;
#ifdef SERMON_DRIVER
    IOReq(CHAR rq,ULONG sr=NULL,ULONG sc=NULL,PVOID orig=NULL)
        : type(rq), SizeRequested(sr), SizeCopied(sc)
    {
        if (SizeCopied)
        {
            pData=ExAllocatePool(NonPagedPool,SizeCopied);
            RtlCopyMemory(pData,orig,SizeCopied);
        }
        else
            pData=NULL;
    }
    ~IOReq() { if (pData) ExFreePool(pData); };
#endif    // SERMON_DRIVER
};

#ifndef SERMON_DRIVER
typedef struct _SERIAL_LINE_CONTROL {
    UCHAR StopBits;
    UCHAR Parity;
    UCHAR WordLength;
    } SERIAL_LINE_CONTROL,*PSERIAL_LINE_CONTROL;
#endif    // !SERMON_DRIVER
#endif    // _SERMON_EX_DEFINED_
