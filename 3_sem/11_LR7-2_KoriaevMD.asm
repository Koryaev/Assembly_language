use16
org 0x100

call write_description
mov ebx, 0x0

read_map: 
	mov di, buffer
	mov ax, 0xE820
	mov edx, 534d4150h 
	mov ecx, 20
	int 15h
	jc exit ;в случае ошибки

	call write_line
	cmp ebx, 0x0
	jnz read_map

int 16h
int 20h

write_line:
	pusha
	call write_start
	mov di, buffer
	add di, 7
	mov cx, 0x1
	call read_lines
	popa
	ret

read_lines:
	cmp cx, 0x0
	ja read_line
	ret

read_line:
	push cx
	mov cx, 20
	jmp read_mem
	
read_mem:
	mov dl, [di]
	dec di

fitst_symbol:
	push dx
	mov ax, 0
	and dl, 11110000b
	shr dl, 4
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

second_symbol:
	pop dx
	mov ax, 0xFFFF
	and dl, 00001111b
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

adding_for_letter:
	add dl, 0x7

before_print:
	add dl, 0x30

print:
	cmp ax, 0xFFFF
	mov ah, 02h
	int 21h
	jz prepare
	jmp second_symbol

prepare:
	cmp cx, 13
	je set_len
	cmp cx, 5
	je set_type

nowrite_probel:
	dec cx
	cmp cx, 0x0
	ja read_mem
	pop cx
	dec cx
	call write_last
	jmp read_lines

set_len:
	call write_set
	add di, 16
	jmp nowrite_probel

set_type:
	call write_set
	add di, 12
	jmp nowrite_probel

write_last:
	mov ah, 09h
	mov dx, last_msg
	int 21h
	ret

write_set:
	mov ah, 09h
	mov dx, set_msg
	int 21h
	ret

write_start:
	mov ah, 09h
	mov dx, start_msg
	int 21h
	ret

write_description:
	mov dx, setting_msg
	mov ah, 09h
	int 21h
	ret

exit:
	mov ah, 09h
	mov dx, error_msg
	int 21h
	int 16h
	int 20h

start_msg db '| $'
set_msg db ' | $'
last_msg db ' |', 0xD, 0xA, '$'
setting_msg db '|       adress     |       len        |   type   |', 0xD, 0xA, '$'
error_msg db 'error MBR', 0xD, 0xA, '$'
buffer db 20 dup (?)