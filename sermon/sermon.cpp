//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#include "stdafx.h"

#include "drvclass.h"
#include "SERMON.h"
#include "devext.h"

extern "C"
{
#ifdef ALLOC_PRAGMA
// all auxiliary routines that are called during 
// initialization should go in here.
#pragma alloc_text(INIT,DriverEntry)
#pragma alloc_text(INIT,CreateDevices)
#endif
}

PDEVICE_OBJECT deviceObject;
PDRIVER_OBJECT DriverObject;
CDBLinkedList<CAttachedDevice> *listAttached;

NTSTATUS DriverEntry(IN PDRIVER_OBJECT DriverObject,
                     IN PUNICODE_STRING RegistryPath)
{
    NTSTATUS status = CreateDevices(DriverObject,RegistryPath);
    if (status==STATUS_SUCCESS)
    {
        ::DriverObject=DriverObject;

        DriverObject->MajorFunction[IRP_MJ_CREATE] = SERMONOpen;
        DriverObject->MajorFunction[IRP_MJ_CLOSE] = SERMONClose;
        DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = SERMONIoControl;
        DriverObject->MajorFunction[IRP_MJ_READ] = SERMONRead;
        DriverObject->MajorFunction[IRP_MJ_WRITE] = SERMONWrite;
        DriverObject->MajorFunction[IRP_MJ_FLUSH_BUFFERS] = 
            SERMONFlush;
        DriverObject->MajorFunction[IRP_MJ_CLEANUP] = 
            SERMONCleanup;
        
        DriverObject->DriverUnload = SERMONUnload;
    
        status = STATUS_SUCCESS;
        listAttached=
            new (NonPagedPool) CDBLinkedList<CAttachedDevice>;
    }
    return(status);
}

NTSTATUS CreateDevices(IN PDRIVER_OBJECT DriverObject,
                       PUNICODE_STRING RegistryPath)
{
    NTSTATUS status;
    CUString *usName;   
    CUString *usLinkName;

    usName = new(PagedPool) CUString(L"\\Device\\SerMon");
    if (!OK_ALLOCATED(usName))
        return STATUS_NO_MEMORY;
    status = IoCreateDevice(DriverObject,sizeof(CSERMONDevice *),
                &usName->m_String,FILE_DEVICE_UNKNOWN,0,
                FALSE,&deviceObject);
    if (!NT_SUCCESS(status))
    {
        delete usName;
        return status;
    }

    deviceObject->Flags |= DO_BUFFERED_IO;
    deviceObject->DeviceExtension=new (NonPagedPool)CSERMONDevice;

    usLinkName= new (PagedPool)CUString(L"\\??\\SerMon");
    if (!OK_ALLOCATED(usLinkName))
    {
        IoDeleteDevice(deviceObject);
        return STATUS_NO_MEMORY;
    }
    status = IoCreateSymbolicLink (&usLinkName->m_String,
        &usName->m_String);
    if (!NT_SUCCESS(status))
    {
        IoDeleteDevice(deviceObject);
        return status;
    }

    delete usLinkName;
    delete usName;

    return status;
}

VOID SERMONUnload(IN PDRIVER_OBJECT DriverObject)
{
    delete (deviceObject->DeviceExtension);
    IoDeleteDevice(deviceObject);
    CUString *usLinkName= new (PagedPool)CUString(L"\\??\\SerMon");
    IoDeleteSymbolicLink(&usLinkName->m_String);
    
    delete usLinkName;
    
    delete listAttached;    // this will kill all attached devices

    return;
}

IMPLEMENT_FUNCTION(Read)
IMPLEMENT_FUNCTION(Write)
IMPLEMENT_FUNCTION(Flush)
IMPLEMENT_FUNCTION(Cleanup)
IMPLEMENT_FUNCTION(Open)
IMPLEMENT_FUNCTION(Close)
IMPLEMENT_FUNCTION(IoControl)
