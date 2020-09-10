//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#include "SERMONEx.h"

struct ExIRP
{
    PIRP Irp;
    LIST_ENTRY entry;
};

class CDevice
{
protected:
    NTSTATUS DoDefault(PIRP Irp)
    {
        IoCompleteRequest(Irp,IO_NO_INCREMENT);
        Irp->IoStatus.Status = STATUS_SUCCESS;
        Irp->IoStatus.Information = 0;
        return STATUS_IO_DEVICE_ERROR;
    };

public:
    virtual NTSTATUS IoControl(PIRP Irp) { return DoDefault(Irp);};
    virtual NTSTATUS Read(PIRP Irp) { return DoDefault(Irp); };
    virtual NTSTATUS Write(PIRP Irp) { return DoDefault(Irp); };
    virtual NTSTATUS Open(PIRP Irp) { return DoDefault(Irp); };
    virtual NTSTATUS Close(PIRP Irp) { return DoDefault(Irp); };
    virtual NTSTATUS Cleanup(PIRP Irp) { return DoDefault(Irp); };
    virtual NTSTATUS Flush(PIRP Irp) { return DoDefault(Irp); };
};

class CSERMONDevice: public CDevice
{
public:
    CSERMONDevice();
    ~CSERMONDevice();

    virtual NTSTATUS IoControl(PIRP Irp);
    MHANDLE TryConnectToSerialDevice(LPCTSTR BufferName);
};

class CAttachedDevice;
extern CDBLinkedList<CAttachedDevice> *listAttached;

NTSTATUS ReadCompletion(IN PDEVICE_OBJECT DeviceObject,
                        IN PIRP Irp,IN PVOID Context);
NTSTATUS WriteCompletion(IN PDEVICE_OBJECT DeviceObject,
                         IN PIRP Irp,IN PVOID Context);
NTSTATUS CloseCompletion(IN PDEVICE_OBJECT DeviceObject,
                         IN PIRP Irp,IN PVOID Context);
NTSTATUS OpenCompletion(IN PDEVICE_OBJECT DeviceObject,
                        IN PIRP Irp,IN PVOID Context);
NTSTATUS IOCompletion(IN PDEVICE_OBJECT DeviceObject,
                      IN PIRP Irp,IN PVOID Context);

class CAttachedDevice : public CDevice
{
protected:
    WCHAR Signature[3];
    ERESOURCE eres;
    CDBLinkedList<IOReq> io;        // request queue
    CDBLinkedList<ExIRP> pending;    // event queue

public:
    KEVENT event;
    LONG Num;
    BOOLEAN bFirstTime;
    PDEVICE_OBJECT OriginalDevice;
    PDEVICE_OBJECT ThisDevice;        // device represented by
                                      // this object
    LIST_ENTRY entry;

public:
    BOOLEAN CheckValid(void)
    {
        return (MmIsAddressValid(this) &&
            Signature[0]==L'B' && Signature[1]==L'A' 
            && Signature[2]==L'V');
    };

    CAttachedDevice()
    {
        Signature[0]=L'B';
        Signature[1]=L'A';
        Signature[2]=L'V';
        ExInitializeResourceLite(&eres);
        KeInitializeEvent(&event,NotificationEvent,TRUE);
        Num=0;
        bFirstTime=TRUE;

        listAttached->New(this);
    };

    ~CAttachedDevice()
    {
        Signature[0]++;
        Signature[1]++;
// The target device MUST be closed so much times it was opened
// so we don't return until this is met
        KeWaitForSingleObject(&event,Executive,KernelMode,
            FALSE,NULL);
        IoDetachDevice(OriginalDevice);
        IoDeleteDevice(ThisDevice);
        ExDeleteResourceLite(&eres);
        ExIRP *p;
        while (p=pending.RemoveHead())
        {
            p->Irp->IoStatus.Status=STATUS_CANCELLED;
            p->Irp->IoStatus.Information=0;
            IoCompleteRequest(p->Irp, IO_NO_INCREMENT);
            delete p;
        }

        listAttached->Remove(this);
    };

    void LockExclusive(void)
    {
        ExAcquireResourceExclusiveLite(&eres, TRUE);
    };

    void LockShared(void)
    {
        ExAcquireResourceSharedLite(&eres, TRUE);
    };

    void Unlock(void)
    {
        ExReleaseResourceForThreadLite(&eres,
            ExGetCurrentResourceThread());
    };

    NTSTATUS Standard(PIRP Irp,
        PIO_COMPLETION_ROUTINE Routine=NULL);

    void New(IOReq *req);
    NTSTATUS GetNext(PIRP Irp);
    NTSTATUS GetNextSize(PIRP Irp);
    NTSTATUS ProcessSize(PIRP Irp,IOReq *);
    NTSTATUS ProcessNext(PIRP Irp,IOReq *);

// Virtual functions from CDevice
    virtual NTSTATUS IoControl(PIRP Irp) 
        { return Standard(Irp,IOCompletion); };
    virtual NTSTATUS Read(PIRP Irp) 
        { return Standard(Irp,ReadCompletion); };
    virtual NTSTATUS Write(PIRP Irp) 
        { return Standard(Irp,WriteCompletion); };
    virtual NTSTATUS Open(PIRP Irp) 
        { return Standard(Irp,OpenCompletion); };
    virtual NTSTATUS Close(PIRP Irp) 
        { return Standard(Irp,CloseCompletion); };
    virtual NTSTATUS Cleanup(PIRP Irp) 
        { return Standard(Irp); };
    virtual NTSTATUS Flush(PIRP Irp) 
        { return Standard(Irp); };
    virtual NTSTATUS Cancel(PIRP Irp) 
        { return Standard(Irp); };
};

extern PDRIVER_OBJECT DriverObject;

NTSTATUS Attach(PUNICODE_STRING TargetDeviceName,DWORD DesiredAccess,
                PDEVICE_OBJECT    *PtrReturnedDeviceObject);
