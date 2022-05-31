struc UINTN {
  align 8
  . rq 1
}

struc int32 {
  align 4
  . rd 1
}

struc int64 {
  align 8
  . rq 1
}

struc dptr {
  align 8
  . rq 1
}

; Error codes

EFI_SUCCESS                     = 0
EFIERR                          = 0x80000000
EFI_LOAD_ERROR                  = EFIERR or 1
EFI_INVALID_PARAMETER           = EFIERR or 2
EFI_UNSUPPORTED                 = EFIERR or 3

virtual at 0
EFI_SYSTEM_TABLE:
 ; Table header
 .Signature                     int64   ; Offset: 0
 .Revision                      int32   ; Offset: 8
 .HeaderSize                    int32   ; Offset: 12
 .CRC32                         int32   ; Offset: 16
 .Reserved                      int32   ; Offset: 20
 
 ; Rest of the table
 .FirmwareVendor                int64   ; Offset: 24
 .FirmwareRevision              int32   ; Offset: 32
 .ConsoleInHandle               int64   ; Offset: 40 (align 8)
 .ConIn                         int64   ; Offset: 48
 .ConsoleOutHandle              int64   ; Offset: 56
 .ConOut                        int64   ; Offset: 64 - We need this one to handle screen output
 .StandardErrorHandle           int64   ; Offset: 72
 .StdErr                        int64   ; Offset: 80
 .RuntimeServices               int64   ; Offset: 88
 .BootServices                  int64   ; Offset: 96
 .NumberOfTableEntries          int64   ; Offset: 104
 .ConfigurationTable            int64   ; Offset: 112
end virtual

virtual at 0
EFI_BOOT_SERVICES_TABLE:
 ; Table header
 .Signature                     int64   ; Offset: 0
 .Revision                      int32   ; Offset: 8
 .HeaderSize                    int32   ; Offset: 12
 .CRC32                         int32   ; Offset: 16
 .Reserved                      int32   ; Offset: 20

 .RaisePriority     dptr
 .RestorePriority   dptr
 .AllocatePages     dptr
 .FreePages     dptr
 .GetMemoryMap      dptr
 .AllocatePool      dptr
 .FreePool      dptr
 .CreateEvent       dptr
 .SetTimer      dptr
 .WaitForEvent      dptr
 .SignalEvent       dptr
 .CloseEvent        dptr
 .CheckEvent        dptr
 .InstallProtocolInterface dptr
 .ReInstallProtocolInterface dptr
 .UnInstallProtocolInterface dptr
 .HandleProtocol    dptr
 .Void          dptr
 .RegisterProtocolNotify dptr
 .LocateHandle      dptr
 .LocateDevicePath  dptr
 .InstallConfigurationTable dptr
 .ImageLoad     dptr
 .ImageStart        dptr
 .Exit          dptr
 .ImageUnLoad       dptr
 .ExitBootServices  dptr
 .GetNextMonotonicCount dptr
 .Stall         dptr
 .SetWatchdogTimer  dptr
 .ConnectController dptr
 .DisConnectController  dptr
 .OpenProtocol      dptr
 .CloseProtocol     dptr
 .OpenProtocolInformation dptr
 .ProtocolsPerHandle    dptr
 .LocateHandleBuffer    dptr
 .LocateProtocol    dptr
 .InstallMultipleProtocolInterfaces dptr
 .UnInstallMultipleProtocolInterfaces dptr
 .CalculateCrc32    dptr
 .CopyMem       dptr
 .SetMem        dptr
end virtual

virtual at 0
SIMPLE_TEXT_OUTPUT:
 .Reset                         int64   
 .OutputString                  int64   ; Offset: 8, Calling this address will run this function
 .TestString                    int64
 .QueryMode                     int64
 .SetMode                       int64
 .SetAttribute                  int64
 .ClearScreen                   int64
 .SetCursorPosition             int64
 .EnableCursor                  int64
 .Mode                          int64
end virtual

virtual at 0
SIMPLE_TEXT_INPUT_EX:
 .Reset                         int64   
 .ReadKeyStrokeEx               int64   ; Offset: 8, Calling this address will run this function
 .WaitForKeyEx                  int64
 .SetState                      int64
 .RegisterKeyNotify             int64
 .UnregisterKeyNotify           int64
end virtual

format pe64 efiboot
entry main
section '.text' code executable readable


main:
    push    rbx
    push    r15
    mov     [ImageHandle], rcx
    mov     [SystemTable], rdx
    mov     rbx, [rdx + EFI_SYSTEM_TABLE.BootServices]
    mov     [BootServices], rbx


    mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
    lea     rdx, [Text]                             ; Arg 2 :
    sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
    add     rsp, 4*8                                ; Восстанавливаем указатель на вершинту стека

reserve_memory:
    mov rcx, 0 ; AllocateAnyPages
    mov rdx, 6 ; EfiRuntimeServicesData
    mov r8, 0x6400 ; 100mb = 25600*4kb = 4kb*0x6400
    mov r9, [Memory]

    mov     rbx, [BootServices]
    sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rbx + EFI_BOOT_SERVICES_TABLE.AllocatePages];
    add     rsp, 4*8
    
    cmp     rax, 0
    jne     Exit_Err
    jmp success
 
Exit:
    mov rdx, [SystemTable]
    mov rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
    lea rdx, [_Exit]                            ; Arg 2 :
    sub rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
    add rsp, 4*8
    pop r15
    pop rbx
    ret

Exit_Err:
    mov     rdx, [SystemTable]
    mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
    
    cmp rax, 0x2
    je er2
    cmp rax, 0x1
    je er1
    cmp rax, 0x3
    je er3
    cmp rax, 0x4
    je er4
    cmp rax, 0x5
    je er5
    cmp rax, 0x6
    je er6

er1:
    lea     rdx, [_error1]
    jmp exit_er
er2:
    lea     rdx, [_error2]
    jmp exit_er
er3:
    lea     rdx, [_error3]
    jmp exit_er
er4:
    lea     rdx, [_error4]
    jmp exit_er
er5:
    lea     rdx, [_error5]
    jmp exit_er
er6:
    lea     rdx, [_error6]
    jmp exit_er

exit_er:
    sub     rsp, 4*8     ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
    add     rsp, 4*8
    pop     r15
    pop     rbx
    mov     RAX, EFI_SUCCESS
    ret

success:
    mov     rdx, [SystemTable]
    mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
    lea     rdx, [_PROTOCOL_LOADED_OK]              ; Arg 2 :
    sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
    add     rsp, 4*8    
    jmp Exit


section '.data' data readable writeable
    align 8
ImageHandle     dq              ?
SystemTable     dq              ?
BootServices    dq              ?
Text            du              'DXE Memory resever',13,10,0    ; 13 and 10 are Line Feed and Form Feed characters
_OK             du              'OK',13,10,0
_ERR            du              'ERROR',13,10,0
_Exit               du '- exit            successful',13,10,0
_PROTOCOL_LOADED_OK du '- protocol loaded successful',13,10,0

_error1 du 'The pages could not be allocated',13,10,0
_error2 du 'Type is not AllocateAnyPages or AllocateMaxAddress or AllocateAddress.',13,10,0
_error3 du 'MemoryType is in the range EfiMaxMemoryType..0x6FFFFFFF.',13,10,0
_error4 du 'MemoryType is EfiPersistentMemory.',13,10,0
_error5 du 'Memory is NULL.',13,10,0
_error6 du 'The requested pages could not be found.',13,10,0

align  16

Memory:
        dq 0x170000

section '.reloc' fixups data discardable
    