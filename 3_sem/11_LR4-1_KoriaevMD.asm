use16
org 0x100

jmp init

begin:
	sti
	pusha 

	push ax
	pop es

	mov ax, cs
	mov ds, ax
	call print_dump_memory

	popa
	iret

print_dump_memory:
	pusha
	mov cx, 0x10
	call read_lines
	popa
	ret

read_lines:
	cmp cx, 0x0
	ja read_line
	ret

read_line:
	push cx
	mov cx, 0x10
	jmp read_mem
	
read_mem:
	mov dl, [es:bx]
	inc bx

fitst_symbol:
	push dx
	mov ax, 0x0
	and dl, 11110000b
	shr dl, 4
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

adding_for_letter:
	add dl, 0x7
	jmp before_print

before_print:
	add dl, 0x30
	jmp print

print:
	cmp ax, 0xFFFF
	mov ah, 02h
	int 21h
	jz prepare
	jmp second_symbol


second_symbol:
	pop dx
	mov ax, 0xFFFF
	and dl, 00001111b
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

prepare:
	mov dl, 0x20
	int 21h 

	dec cx
	cmp cx, 0x0
	ja read_mem
	pop cx
	dec cx

	mov ah, 09h
	mov dx, next_stroka_msg
	int 21h

	jmp read_lines

next_stroka_msg db 0xD, 0xA, '$'

init:
	pusha

	mov ah, 0x25
	mov al, 0x8B ;128+11=139=0x8B
	mov dx, begin
	int 21h

	mov dx, init
	int 0x27

	popa
	int 0x16
	int 0x20

