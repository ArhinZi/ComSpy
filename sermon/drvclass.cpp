//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#include "stdafx.h"

#include "drvclass.h"

void * __cdecl operator new(unsigned int nSize, POOL_TYPE iType)
{
    return ExAllocatePool(iType,nSize);
}

void __cdecl operator delete(void* p)
{
    ExFreePool(p);
}

// derived class Unicode string

#define TYPE_SYSTEM_ALLOCATED 0
#define TYPE_DRIVER_ALLOCATED 1

CUString::CUString(int nSize)
{
    m_status = STATUS_INSUFFICIENT_RESOURCES;
    m_bType = TYPE_DRIVER_ALLOCATED;
    RtlInitUnicodeString(&m_String,NULL);
    m_String.MaximumLength = nSize;
    m_String.Buffer = (unsigned short *)
        ExAllocatePool(PagedPool,nSize);
    if (!m_String.Buffer) return;  // leaving status the way it is
    RtlZeroMemory(m_String.Buffer,m_String.MaximumLength);
    m_status = STATUS_SUCCESS;
}

CUString::CUString(PWCHAR uszString)
{
    m_status = STATUS_SUCCESS;
    m_bType = TYPE_SYSTEM_ALLOCATED;
    RtlInitUnicodeString(&m_String,uszString);
}

CUString::CUString(int iVal, int iBase)  
{
    m_status = STATUS_INSUFFICIENT_RESOURCES;
    m_bType = TYPE_DRIVER_ALLOCATED;
    RtlInitUnicodeString(&m_String,NULL);
    int iSize=1;
    int iValCopy=(!iVal)?1:iVal;
    while (iValCopy>=1)
    {
        iValCopy/=iBase;
        iSize++;
    }    // now iSize carries the number of digits

    iSize*=sizeof(WCHAR);

    m_String.MaximumLength = iSize;
    m_String.Buffer = (unsigned short *)
        ExAllocatePool(PagedPool,iSize);
    if (!m_String.Buffer) return;
    RtlZeroMemory(m_String.Buffer,m_String.MaximumLength);
    m_status = RtlIntegerToUnicodeString(iVal, iBase, &m_String);
}

CUString::~CUString()
{
    if ((m_bType == TYPE_DRIVER_ALLOCATED) && m_String.Buffer) 
        ExFreePool(m_String.Buffer);
}

void CUString::Append(UNICODE_STRING *uszString)
{
    m_status = RtlAppendUnicodeStringToString(&m_String,uszString);
}

void CUString::CopyTo(CUString *pTarget)
{
    RtlCopyUnicodeString(&pTarget->m_String,&m_String);
}

BOOL CUString::operator==(CUString cuArg)
{
    return (!RtlCompareUnicodeString(&m_String,
        &cuArg.m_String,FALSE));
}
