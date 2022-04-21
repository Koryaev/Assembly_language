format pe64 efi
entry main

section '.text' code executable readable
main:
    mov [uefi_system_table_adr], rdx
    sub rsp, 8 + (4 * 8)

    call set_screen_attribute
    call clear_screen

    call set_cursor_position
    call set_attribute
    call write_str

    add rsp, (4 * 8) + 8
    ret

load_table:
    mov rdx, [uefi_system_table_adr]
    mov rcx, [rdx + 64]
    ret

clear_screen:
    call load_table
    call qword [rcx + 48]
    ret

write_str:
    call load_table
    mov rdx, str_data
    call qword [rcx + 8]
    ret

set_cursor_position:
    call load_table
    mov rdx, 0 ; ряд
    mov r8d, 10 ; строка
    call qword [rcx + 56]
    ret

set_attribute:
    call load_table
    mov rdx, 0x24
    call qword [rcx + 40]
    ret

set_screen_attribute:
    call load_table
    mov rdx, 0x30
    call qword [rcx + 40]
    ret

section '.data' data readable writeable
str_data du 'Koriaev Mikhail Dmitrievich :)', 13, 10, 0
uefi_system_table_adr dq ?
