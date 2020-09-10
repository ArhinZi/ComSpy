//////////////////////////////////////////////
// This file is a part of the Serial Monitor 
// device driver source code
// Written by Alex Bessonov, June 1998

#define DECLARE_FUNCTION(x) extern "C" NTSTATUS \
    SERMON##x(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp);
#define IMPLEMENT_FUNCTION(x) NTSTATUS \
    SERMON##x(IN PDEVICE_OBJECT DeviceObject,IN PIRP Irp) \
    { \
        return ((CDevice *) \
        (DeviceObject->DeviceExtension))->x(Irp); \
    }

extern "C"
{
NTSTATUS DriverEntry(IN PDRIVER_OBJECT DriverObject,
                     IN PUNICODE_STRING RegistryPath);

NTSTATUS CreateDevices(IN PDRIVER_OBJECT DriverObject,
                       IN PUNICODE_STRING RegistryPath);
}    // extern "C"

DECLARE_FUNCTION(Open)
DECLARE_FUNCTION(Read)
DECLARE_FUNCTION(Write)
DECLARE_FUNCTION(Flush)
DECLARE_FUNCTION(Cleanup)
DECLARE_FUNCTION(Close)
DECLARE_FUNCTION(IoControl)

VOID SERMONUnload(IN PDRIVER_OBJECT DriverObject);
