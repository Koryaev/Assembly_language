;
; kbd_count_dxe.asm
; DXE driver in assembly
; Enable PCSpeaker by any key

; Symbols and structures

; The UEFI favorite data type: Unsigned Integer Native width
; (32-bit width in 32-bit systems, 64-bit in 64-bit systems)
; I use 64-bit width because my EFI is 64-bit (rq)
; Data alignment must be same as width
; (all UEFI data stuff must be native aligned)
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
; Etc (more error codes in EFI spec)


; Our program on entry gets two pointers as arguments:
; ImageHandle and SystemTable (see below at the beginning of code)
; ImageHandle is just like an ID of our running app
; SystemTable is just a table somewhere in memory
; which contains pointers to all functionality of UEFI
; (without it our program is blind and can't contact with UEFI
; functions just because it doesn't know where they are)

; SystemTable structure
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



; Simple Text Output is a Protocol (like just a set of functions).
; The ConOut pointer in SystemTable (above) points to the memory address
; where the table described just below is located.
; The table itself contains memory addresses to 'call'
; if we want to use a specific UIFI function

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

; Some initial format settings for the linker regarding
; the executable file format used by UEFI
format pe64 efiboot
entry main
section '.text' code executable readable

; Program entry point

main:
;The registers Rax, Rcx Rdx R8, R9, R10, R11, and XMM0-XMM5 are volatile and are, therefore, destroyed
;on function calls.
;The registers RBX, RBP, RDI, RSI, R12, R13, R14, R15, and XMM6-XMM15 are considered nonvolatile and
;must be saved and restored by a function that uses them.

        push    rbx
        push    r15
        mov     [ImageHandle], RCX
        mov     [SystemTable], RDX
        mov     rbx, [rdx + EFI_SYSTEM_TABLE.BootServices]
        mov     [BootServices], rbx


        ; Call OutputString function of SIMPLE_TEXT_OUTPUT protocol
        ; Function OutputString when entered, looks for two args in the stack:
        ; 1. The address of the zero-ended UCS2 string to print
        ; 2. The address of the Simple Text Output interface (aka *This in C language)
        ; so we 'push' them before calling the function and then
        ; restore the stack pointer (add esp,8 ) when the function returns
        ; 8 is the total size of our two args of type UINTN
        ; More info is in UEFI spec, page 474 (UEFI Specification Version 2.6)
        ; http://www.uefi.org/specifications
        ; Pay attention to the reversed order of the arguments pushed on stack

;2.3.4.2 Detailed Calling Conventions
;The caller passes the first four integer arguments in registers. The integer values are passed from left to
;right in Rcx, Rdx, R8, and R9 registers. The caller passes arguments five and above onto the stack. All
;arguments must be right-justified in the register in which they are passed. This ensures the callee can
;process only the bits in the register that are required. 

;In the Microsoft x64 calling convention,
;it is the caller's responsibility to allocate 32 bytes of "shadow space"
;on the stack right before calling the function (regardless of the actual number of parameters used), 
;and to pop the stack after the call. 
;The shadow space is used to spill RCX, RDX, R8, and R9,[19] but must be made available to all functions,
;even those with fewer than four parameters.

        mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
        lea     rdx, [Text]                             ; Arg 2 :
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
        add     rsp, 4*8                                ; Восстанавливаем указатель на вершинту стека



    ;         // Locate all SimpleTextInEx protocols
    ; Status = gBS->LocateHandleBuffer(ByProtocol, &gEfiSimpleTextInputExProtocolGuid, NULL, &HandleCount, &HandleBuffer);
    ; if (EFI_ERROR (Status)) {

        mov     rcx, 2                                  ; Arg 1 - IN :2 (ByProtocol)
        lea     rdx, [EFI_SIMPLE_TEXTINPUTEX_PROTOCOL_GUID]; Arg 2 - IN :GUID
        mov     r8, 0                                   ; Arg 3 - IN :NULL
        lea     r9, [HandleCount]                       ; Arg 4 - OUT :
        lea     rbx, [HandleBufferAddr]
        push    rbx                                     ; Arg 5 - OUT 
        mov     rbx, [BootServices]
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rbx + EFI_BOOT_SERVICES_TABLE.LocateHandleBuffer]
        add     rsp,5*8                                 ; Восстанавливаем указатель на вершинту стека

        cmp     rax, 0
        jne     Exit_Err
        mov     rdx, [SystemTable]
        mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
        lea     rdx, [_OK]                              ; Arg 2 :
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
        add     rsp, 4*8                                ; Восстанавливаем указатель на вершинту стека


        ; // Get protocol handle
        ; Status = gBS->HandleProtocol (HandleBuffer[i], &gEfiSimpleTextInputExProtocolGuid, (VOID **) &SimpleTextInEx);
        ; if (EFI_ERROR (Status)) {
 

        mov     r15, [HandleCount]

cycle:
        dec     r15    
        mov     rax, r15
        shl     rax, 3
    
        mov     rcx, [HandleBufferAddr]
        add     rcx, rax
        mov     rcx, [rcx]                                  ; Arg 1 - IN :
        lea     rdx, [EFI_SIMPLE_TEXTINPUTEX_PROTOCOL_GUID] ; Arg 2 - IN :GUID
        lea     r8, [SimpleTextInEx]                        ; Arg 3 - OUT :
        lea r9, [ImageHandle]                               ; Arg 4

        xor rbx, rbx
        mov rbx, 0x00000001
        push rbx                                            ; EFI_OPEN_PROTOCOL_BY_HANDLE_PROTOCOL

        mov     rax, r15
        shl     rax, 3
    
        mov     rcx, [HandleBufferAddr]
        add     rcx, rax
        mov     rcx, [rcx]
        push rcx                                            ; Arg 6 
        

        mov     rbx,[BootServices]
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rbx + EFI_BOOT_SERVICES_TABLE.OpenProtocol]; OpenProtocol!
        add     rsp, 6*8

        cmp     rax, 0
        jne     Exit_Err
        mov     rdx, [SystemTable]
        mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
        lea     rdx, [_PROTOCOL_LOADED_OK]              ; Arg 2 :
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
        add     rsp, 4*8

    ;             // Register key notification function
    ;     Status = SimpleTextInEx->RegisterKeyNotify(


; ----------- adding scan codes -----------------------------

    push rax
    push r14
    push rdx

    xor rax, rax
    xor r14, r14
    xor rdx, rdx

    mov rax, 0x4 ; amount of scan codes
    mov r14, 0x0 ; 2xi (i=current index in scan_codes)

add_scan_code:
    xor rdx, rdx
    mov word dx, [scan_codes + r14]
    mov [Key], dx
    xor rdx, rdx

    mov     rcx, [SimpleTextInEx]   ; Arg 1 - IN :                             
    lea     rdx, [KeyData]          ; Arg 2 - IN :
    lea     r8, [test_func]         ; Arg 3 - OUT :
    lea     r9, [Handle]            ; Arg 4 - OUT :
    mov     rbx,[SimpleTextInEx]
    sub     rsp, 4*8                ; "shadow space" for Rcx, Rdx, R8, R9

    push rax
    push r14
    push rdx
    call    qword [rbx + SIMPLE_TEXT_INPUT_EX.RegisterKeyNotify]
    pop rdx
    pop r14
    pop rax

    add     rsp, 4*8

    add r14, 0x2
    dec rax

    cmp rax, 0x0
    jne add_scan_code

    pop rdx
    pop r14
    pop rax
 
        
    cmp     rax, 0
    jne     Exit_Err
    mov     rdx, [SystemTable]
    mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
    lea     rdx, [_SCAN_CODES_OK]                   ; Arg 2 :
    sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
    add     rsp, 4*8

    cmp     r15, 0
    jne     cycle

Exit:
        mov     rdx, [SystemTable]
        mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
        lea     rdx, [_Exit]                            ; Arg 2 :
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
        add     rsp, 4*8
        pop     r15
        pop     rbx
        ret
Exit_Err:
        mov     rdx, [SystemTable]
        mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
        lea     rdx, [_ERR]                             ; Arg 2 :
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
        add     rsp, 4*8
        pop     r15
        pop     rbx
        mov     RAX, EFI_SUCCESS
        ret

test_func:
        push rax
        push rbx
        push rcx
        push rdx

        ; call beep
        ; call delay
        ; call turn_off_beep
        call test_

        mov     rdx, [SystemTable]
        mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
        lea     rdx, [_TEST_FUNC]                       ; Arg 2 :
        sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
        call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
        add     rsp, 4*8


        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret

test_:
    push rax
    push rbx
    push rcx
    push rdx

    mov     rdx, [SystemTable]
    mov     rcx, [rdx + EFI_SYSTEM_TABLE.ConOut]    ; Arg 1 :
    lea     rdx, [_TEST_FUNC]                       ; Arg 2 :
    sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rcx + SIMPLE_TEXT_OUTPUT.OutputString]
    add     rsp, 4*8

    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret


beep:
    xor rax, rax
    mov ax, 3000 ;(1190000/395) ; Устанавливаем высоту тона 395 Гц -
    out 0x42, al
    mov al, ah
    out 0x42, al

    in al, 0x61
    or al, 00000011b
    out 0x61, al
    ret

turn_off_beep:
    in al, 0x61
    and al, 11111100b
    out 0x61, al
    ret

delay:
    mov rcx, 3000000;
    mov     rbx, [BootServices]
    sub     rsp, 4*8                                ; "shadow space" for Rcx, Rdx, R8, R9
    call    qword [rbx + EFI_BOOT_SERVICES_TABLE.Stall];
    add     rsp, 4*8
    ret

section '.data' data readable writeable
    align 8
ImageHandle     dq              ?
SystemTable     dq              ?
BootServices    dq              ?
Text            du              'Hello DXE',13,10,0    ; 13 and 10 are Line Feed and Form Feed characters
_OK             du              'OK',13,10,0
_ERR            du              'ERROR',13,10,0
_Exit               du '- exit            successful',13,10,0
_TEST_FUNC du 'test_func',13,10,0
_SCAN_CODES_OK      du '- scan codes      successful',13,10,0
_PROTOCOL_LOADED_OK du '- protocol loaded successful',13,10,0
    align  16

;gEfiSimpleTextInputExProtocolGuid = 
;{0xdd9e7534, 0x7762, 0x4698, { 0x8c, 0x14, 0xf5, 0x85, 0x17, 0xa6, 0x25, 0xaa } }
EFI_SIMPLE_TEXTINPUTEX_PROTOCOL_GUID:
        db   0x34,0x75,0x9E,0xDD,0x62,0x77,0x98,0x46
        db   0x8C,0x14,0xF5,0x85,0x17,0xA6,0x25,0xAA
HandleCount:
        dq  0
HandleBufferAddr:
        dq  0
SimpleTextInEx:
        dq  ?
Handle:
        dq  0
KeyData:
    Key:
        .ScanCode       dw  0
        .UnicodeChar    dw  0
    KeyState:
        .KeyShiftState  dd  0
        .KeyToggleState db  0

scan_codes dw 0x1, 0x2, 0x3, 0x4


section '.reloc' fixups data discardable
    