//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#include "stdafx.h"

#include "SerMon.h"
#include "drvclass.h"
#include "devext.h"
#include "serial.h"

CSERMONDevice::CSERMONDevice()
{
};

CSERMONDevice::~CSERMONDevice()
{
};

MHANDLE CSERMONDevice::TryConnectToSerialDevice(LPCTSTR Name)
{
    CUString str((PWCHAR) Name);
    PDEVICE_OBJECT pdo;
    NTSTATUS RC=Attach(&str.m_String,FILE_ALL_ACCESS,&pdo);
    if (RC==STATUS_SUCCESS)
        return (MHANDLE) pdo->DeviceExtension;
    else
        return NULL;
}

NTSTATUS CSERMONDevice::IoControl(PIRP Irp)
{
    PIO_STACK_LOCATION curIRPStack;

    curIRPStack = IoGetCurrentIrpStackLocation(Irp);
    switch (curIRPStack->Parameters.DeviceIoControl.IoControlCode)
    {
    case  IOCTL_SERMON_STARTMONITOR:
    {
        MHANDLE mh=TryConnectToSerialDevice(
            (LPCTSTR) Irp->AssociatedIrp.SystemBuffer);
        if (mh)
        {
            *((MHANDLE *) Irp->AssociatedIrp.SystemBuffer)=mh;
            Irp->IoStatus.Information = sizeof(MHANDLE);
            Irp->IoStatus.Status = STATUS_SUCCESS;
        } else
            Irp->IoStatus.Status = STATUS_INVALID_PARAMETER;
        break;
    }
    case IOCTL_SERMON_STOPMONITOR:
    {
        if (curIRPStack->Parameters.DeviceIoControl.InputBufferLength
            ==sizeof(MHANDLE))
        {
            MHANDLE mh=*((MHANDLE *) Irp->AssociatedIrp.SystemBuffer);
            CAttachedDevice *ptr=(CAttachedDevice *) mh;
            if (ptr && ptr->CheckValid())
            {
                Irp->IoStatus.Status = STATUS_SUCCESS;
                delete ptr;
            } else
                Irp->IoStatus.Status = STATUS_INVALID_PARAMETER;
        } else
            Irp->IoStatus.Status = STATUS_INVALID_HANDLE;

        Irp->IoStatus.Information = 0;
        break;
    }
    case IOCTL_SERMON_GETINFOSIZE:
    {
        if (curIRPStack->Parameters.DeviceIoControl.
            InputBufferLength==sizeof(MHANDLE))
        {
            MHANDLE mh=*((MHANDLE *) 
                Irp->AssociatedIrp.SystemBuffer);
            CAttachedDevice *ptr=(CAttachedDevice *) mh;
            if (ptr && ptr->CheckValid() && 
                curIRPStack->Parameters.DeviceIoControl.
                OutputBufferLength==sizeof(ULONG))
            {
                return ptr->GetNextSize(Irp);
            } else
                Irp->IoStatus.Status = STATUS_INVALID_PARAMETER;
        } else
            Irp->IoStatus.Status = STATUS_INVALID_HANDLE;

        Irp->IoStatus.Information = 0;
        break;
    }
    case IOCTL_SERMON_GETINFO:
    {
        if (curIRPStack->Parameters.DeviceIoControl.
            InputBufferLength==sizeof(MHANDLE))
        {
            MHANDLE mh=*((MHANDLE *) Irp->AssociatedIrp.
                SystemBuffer);
            CAttachedDevice *ptr=(CAttachedDevice *) mh;
            if (ptr && ptr->CheckValid())
            {
                return ptr->GetNext(Irp);
            } else
                Irp->IoStatus.Status = STATUS_INVALID_PARAMETER;
        } else
            Irp->IoStatus.Status = STATUS_INVALID_HANDLE;

        Irp->IoStatus.Information = 0;
        break;
    }
    default:
        Irp->IoStatus.Status = STATUS_IO_DEVICE_ERROR;
        Irp->IoStatus.Information = 0;
        break;
    }

    IoCompleteRequest(Irp, IO_NO_INCREMENT);
    return(Irp->IoStatus.Status);
}

NTSTATUS Attach(PUNICODE_STRING TargetDeviceName,
                DWORD           DesiredAccess,
                PDEVICE_OBJECT* PtrReturnedDeviceObject)
{
    NTSTATUS         RC                      = STATUS_SUCCESS;
    PDEVICE_OBJECT   PtrNewDeviceObject      = NULL;
    CAttachedDevice* ptr                     = NULL;
    BOOLEAN          InitializedDeviceObject = FALSE;
    BOOLEAN          AcquiredDeviceObject    = FALSE;
    PDEVICE_OBJECT   PtrTargetDeviceObject   = NULL;
    PFILE_OBJECT     PtrTargetFileObject     = NULL;

    ASSERT(PtrReturnedDeviceObject);

    __try 
    {
        if (!NT_SUCCESS(RC=IoGetDeviceObjectPointer(
            TargetDeviceName,
            DesiredAccess,&PtrTargetFileObject,
            &PtrTargetDeviceObject)))
            __leave;

        // Create a new device object.
        if (!NT_SUCCESS(RC = IoCreateDevice(
            DriverObject,
            sizeof(CAttachedDevice *),
            NULL,        // unnamed object
            PtrTargetDeviceObject->DeviceType,
            PtrTargetDeviceObject->Characteristics,
            FALSE,    // Not exclusive.
            &PtrNewDeviceObject))) 
        {
            // failed to create a device object
            __leave;
        }

        PtrNewDeviceObject->Flags &= ~DO_DEVICE_INITIALIZING;

        // Initialize the extension for the device object.
        (PtrNewDeviceObject->DeviceExtension)=ptr=
            new (NonPagedPool) CAttachedDevice;
        ptr->OriginalDevice=PtrTargetDeviceObject;
        ptr->ThisDevice=PtrNewDeviceObject;
    
        ptr->LockExclusive();
        AcquiredDeviceObject=TRUE;
        // attach to the target FSD.
        RC = IoAttachDeviceByPointer(PtrNewDeviceObject, 
            PtrTargetDeviceObject);

        ASSERT(NT_SUCCESS(RC));

        PtrNewDeviceObject->Flags |= DO_BUFFERED_IO;
    } __finally {
        if (AcquiredDeviceObject) 
        {
            ptr->Unlock();
            AcquiredDeviceObject = FALSE;
        }

        if (!NT_SUCCESS(RC) && PtrNewDeviceObject) 
        {
            delete ptr;
        } else 
        {
            *PtrReturnedDeviceObject = PtrNewDeviceObject;
        }
        if (PtrTargetFileObject)
        {
            ObDereferenceObject(PtrTargetFileObject);
            PtrTargetFileObject=NULL;
        }
    }

    return(RC);
}

NTSTATUS DefaultCompletion(IN PDEVICE_OBJECT DeviceObject,
                           IN PIRP Irp,IN PVOID Context)
{
    if (Irp->PendingReturned) {
        IoMarkIrpPending(Irp);
    }

// Nothing to do, simply return success
    return STATUS_SUCCESS;
}

NTSTATUS ReadCompletion(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,
                        IN PVOID Context)
{
    if (Irp->PendingReturned) {
        IoMarkIrpPending(Irp);
    }
    {
        if (Irp->IoStatus.Information)
        {
// There are bytes read, construct IOReq item and append it to the list
            PIO_STACK_LOCATION cur;
            cur = IoGetCurrentIrpStackLocation(Irp);
            IOReq *req=new (NonPagedPool) IOReq(REQ_READ,
                cur->Parameters.Read.Length,
                Irp->IoStatus.Information,
                Irp->AssociatedIrp.SystemBuffer);
            ((CAttachedDevice *) Context)->New(req);
        }
    }

    return STATUS_SUCCESS;
}

NTSTATUS WriteCompletion(IN PDEVICE_OBJECT DeviceObject,
                         IN PIRP Irp,IN PVOID Context)
{
    if (Irp->PendingReturned) {
        IoMarkIrpPending(Irp);
    }
    {
        if (Irp->IoStatus.Status==STATUS_SUCCESS && 
            Irp->IoStatus.Information)
        {
            PIO_STACK_LOCATION cur;
            cur = IoGetCurrentIrpStackLocation(Irp);
            IOReq *req=new (NonPagedPool) IOReq(REQ_WRITE,
                cur->Parameters.Read.Length,
                Irp->IoStatus.Information,
                Irp->AssociatedIrp.SystemBuffer);
            ((CAttachedDevice *) Context)->New(req);
        }
    }

    return STATUS_SUCCESS;
}

NTSTATUS OpenCompletion(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,
                        IN PVOID Context)
{
    if (Irp->PendingReturned) {
        IoMarkIrpPending(Irp);
    }
    {
        if (Irp->IoStatus.Status==STATUS_SUCCESS)
        {
            CAttachedDevice *p=(CAttachedDevice *) Context;
// Increase usage count
            if (InterlockedIncrement(&p->Num))
                KeResetEvent(&p->event);
            PIO_STACK_LOCATION cur;
            cur = IoGetCurrentIrpStackLocation(Irp);
            IOReq *req=new (NonPagedPool) IOReq(REQ_OPEN);
            ((CAttachedDevice *) Context)->New(req);
        }
    }

    return STATUS_SUCCESS;
}

NTSTATUS CloseCompletion(IN PDEVICE_OBJECT DeviceObject,
                         IN PIRP Irp,IN PVOID Context)
{
    if (Irp->PendingReturned) {
        IoMarkIrpPending(Irp);
    }
    {
        if (Irp->IoStatus.Status==STATUS_SUCCESS)
        {
            CAttachedDevice *p=(CAttachedDevice *) Context;
            if (!p->bFirstTime)
            {
// Decrease usage count and signal the event if it falls to zero
                if (!InterlockedDecrement(&p->Num))
                    KeSetEvent(&p->event,0,FALSE);
                PIO_STACK_LOCATION cur;
                cur = IoGetCurrentIrpStackLocation(Irp);
                IOReq *req=new (NonPagedPool) IOReq(REQ_CLOSE);
                ((CAttachedDevice *) Context)->New(req);
            } else p->bFirstTime=FALSE;

        }
    }

    return STATUS_SUCCESS;
}

NTSTATUS IOCompletion(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp,
                      IN PVOID Context)
{
    if (Irp->PendingReturned) {
        IoMarkIrpPending(Irp);
    }
    {
        if (Irp->IoStatus.Status==STATUS_SUCCESS)
        {
// We process only IOCTL_SERIAL_SET_BAUD_RATE and 
// IOCTL_SERIAL_SET_LINE_CONTROL requests 
// (serial.h file from serial driver
// sample from DDK is used)
            IOReq *req;
            CAttachedDevice *p=(CAttachedDevice *) Context;
            PIO_STACK_LOCATION cur;
            cur = IoGetCurrentIrpStackLocation(Irp);
            switch(cur->Parameters.DeviceIoControl.IoControlCode)
            {
            case IOCTL_SERIAL_SET_BAUD_RATE:
                req=new (NonPagedPool) IOReq(REQ_SETBAUDRATE,
                    sizeof(ULONG),sizeof(ULONG),
                    Irp->AssociatedIrp.SystemBuffer);
                ((CAttachedDevice *) Context)->New(req);
                break;
            case IOCTL_SERIAL_SET_LINE_CONTROL:
                req=new (NonPagedPool) IOReq(REQ_SETLINECONTROL,
                    sizeof(SERIAL_LINE_CONTROL),
                    sizeof(SERIAL_LINE_CONTROL),
                    Irp->AssociatedIrp.SystemBuffer);
                ((CAttachedDevice *) Context)->New(req);
                break;
            }
        }
    }

    return STATUS_SUCCESS;
}

//////////////////////////////
// CAttachedDevice
NTSTATUS CAttachedDevice::Standard(PIRP Irp,
                                   PIO_COMPLETION_ROUTINE Routine)
{
// This function forwards the request
    PIO_STACK_LOCATION curIRPStack,nextIRPStack;
    curIRPStack = IoGetCurrentIrpStackLocation(Irp);
    nextIRPStack=IoGetNextIrpStackLocation(Irp);
    *nextIRPStack=*curIRPStack;
    IoSetCompletionRoutine(Irp, 
        (Routine)?Routine:DefaultCompletion, 
        this, TRUE, TRUE, TRUE);

    return IoCallDriver(OriginalDevice,Irp);
}

void CAttachedDevice::New(IOReq *req)
{
    LockExclusive();
    io.New(req);
// check for pending requests
    ExIRP *trp=pending.RemoveHead();
// If we have a pending request, waiting for smth to receive,
// so simply handle it
    if (trp)
    {
        IRP *Irp=trp->Irp;
        req=io.RemoveHead();
        Unlock();    // we don't need to lock anymore
        PIO_STACK_LOCATION curIRPStack;
        curIRPStack = IoGetCurrentIrpStackLocation(Irp);
// process the request
        switch(curIRPStack->Parameters.DeviceIoControl.
            IoControlCode)
        {
        case IOCTL_SERMON_GETINFOSIZE:
            ProcessSize(Irp,req);
            break;
        case IOCTL_SERMON_GETINFO:
            ProcessNext(Irp,req);
            break;
        }
        delete trp;
    } else
        Unlock();
}

NTSTATUS CAttachedDevice::ProcessSize(PIRP Irp,IOReq *q)
{
    Irp->IoStatus.Information=sizeof(ULONG);
    Irp->IoStatus.Status=STATUS_SUCCESS;
    LockExclusive();
    *((ULONG *) Irp->AssociatedIrp.SystemBuffer)=sizeof(IOReq)+
        q->SizeCopied;
    io.InsertHead(q);
    Unlock();
    IoCompleteRequest(Irp, IO_NO_INCREMENT);
    return STATUS_SUCCESS;
}

NTSTATUS CAttachedDevice::ProcessNext(PIRP Irp,IOReq *q)
{
    PIO_STACK_LOCATION curIRPStack;
    curIRPStack = IoGetCurrentIrpStackLocation(Irp);
    if (curIRPStack->Parameters.DeviceIoControl.OutputBufferLength
        <sizeof(IOReq)+q->SizeCopied)
    {
        delete q;
        Irp->IoStatus.Information=0;
        Irp->IoStatus.Status=STATUS_BUFFER_TOO_SMALL;
        IoCompleteRequest(Irp,IO_NO_INCREMENT);
        return STATUS_BUFFER_TOO_SMALL;
    }
    Irp->IoStatus.Information=sizeof(IOReq)+q->SizeCopied;
    Irp->IoStatus.Status=STATUS_SUCCESS;
    RtlCopyMemory(Irp->AssociatedIrp.SystemBuffer,q,sizeof(IOReq));
    if (q->pData)
        RtlCopyMemory((PCHAR) Irp->AssociatedIrp.SystemBuffer
        +sizeof(IOReq),q->pData,q->SizeCopied);
    delete q;
    IoCompleteRequest(Irp, IO_NO_INCREMENT);
    return STATUS_SUCCESS;
}

NTSTATUS CAttachedDevice::GetNextSize(PIRP Irp)
{
    if (!io.IsEmpty())
    {
        LockExclusive();
        IOReq *q=io.RemoveHead();
        NTSTATUS ret=ProcessSize(Irp,q);
        Unlock();
        return ret;
    } else
    {
        ExIRP *irp=new (NonPagedPool) ExIRP;
        irp->Irp=Irp;
        pending.New(irp);

        Irp->IoStatus.Information=0;
        Irp->IoStatus.Status=STATUS_PENDING;
        IoMarkIrpPending(Irp);
        return STATUS_PENDING;
    }
}

NTSTATUS CAttachedDevice::GetNext(PIRP Irp)
{
    LockExclusive();
    if (!io.IsEmpty())
    {
        IOReq *q=io.RemoveHead();
        Unlock();
        return ProcessNext(Irp,q);
    } else
    {
        ExIRP *irp=new (NonPagedPool) ExIRP;
        irp->Irp=Irp;
        pending.New(irp);

        Irp->IoStatus.Information=0;
        Irp->IoStatus.Status=STATUS_PENDING;
        IoMarkIrpPending(Irp);
        Unlock();
        return STATUS_PENDING;
    }
}
