unit ctr_uint;

interface

uses
  Windows;

const
  // 设备类型定义
  FILE_DEVICE_SERMON  =  $00001001;
  METHOD_BUFFERED = 0;
  FILE_ANY_ACCESS = 0;
  FILE_READ_ACCESS = $0001;
  FILE_WRITE_ACCESS = $0002;

type
  ULONG = DWORD;
  MHANDLE = ULONG;
  UCHAR = Byte;

  MY_ENUM = (
    REQ_OPEN,
    REQ_READ,
    REQ_WRITE,
    REQ_CLOSE,
    REQ_FLUSH,
    REQ_SETBAUDRATE,
    REQ_SETLINECONTROL
  );

  {$A4+}//强制按C语言默认的4字节对齐方式，所以这里结构体大小是24，不是21
  pIOReq = ^IOReq;
  IOReq = record
    Reserved1: DWORD;
    Reserved2: DWORD;
    Reserved3: DWORD;
    SizeRequested,
    SizeCopied: ULONG;
    _type: Byte;
  end;

  PSERIAL_LINE_CONTROL = ^SERIAL_LINE_CONTROL;
  SERIAL_LINE_CONTROL = packed record
    StopBits: UCHAR;
    Parity: UCHAR;
    WordLength: UCHAR;
  end;

var
  IOCTL_SERMON_STARTMONITOR: Integer = 0;
  IOCTL_SERMON_STOPMONITOR: Integer = 0;
  IOCTL_SERMON_GETINFOSIZE: Integer = 0;
  IOCTL_SERMON_GETINFO: Integer = 0;

implementation

  function Ctl_Code(DeviceType, FuncNo, Method, Access: integer): integer;
  begin
     Result := (DeviceType shl 16) or (Access shl 14) or (FuncNo shl 2) or (Method)
  end;

initialization

  IOCTL_SERMON_STARTMONITOR:= Ctl_Code(FILE_DEVICE_SERMON, $0801, METHOD_BUFFERED, FILE_ANY_ACCESS);
  IOCTL_SERMON_STOPMONITOR:= Ctl_Code(FILE_DEVICE_SERMON, $0802, METHOD_BUFFERED, FILE_ANY_ACCESS);
  IOCTL_SERMON_GETINFOSIZE:= Ctl_Code(FILE_DEVICE_SERMON, $0803, METHOD_BUFFERED, FILE_ANY_ACCESS);
  IOCTL_SERMON_GETINFO:= Ctl_Code(FILE_DEVICE_SERMON, $0804, METHOD_BUFFERED, FILE_ANY_ACCESS);

end. 
