use16
org 0x100

call print_dump_memory

mov ax,0
int 16h
int 20h

print_dump_memory:
	pusha
	mov cx, 0x10
	mov bx, 0x0
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
	push word 0
	pop es
	;mov dl, [0x6E+bx] ;11*10=110=6E
	mov [es:bx]
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
