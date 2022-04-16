use16
org 0x100

start_func:
	mov ah, 09h
	mov dx, msg_a
	int 21h
	mov dx, 0
	mov ax, 0xBA12
	mov bx, 0xDE34
	mov cx, 4

main_function:
	cmp cx, 3
	ja first_letter
	cmp cx, 2
	ja second_letter
	cmp cx, 1
	ja third_letter
	cmp cx, 0
	jnz fourth_letter

	cmp bx, 0
	jnz prepare_bx
	mov ax, 0
	int 16h
	int 20h

print:
	mov si, ax
	mov ah, 02h
	int 21h
	mov ax, si
	sub cx, 1
	jmp main_function
	

before_print:
	add dl, 0x30
	jmp print

adding_for_letter:
	add dl, 0x7
	jmp before_print


first_letter:
	mov dx, ax
	and dh, 11110000b
	and dl, 00000000b
	or dl, dh
	mov dh, 0
	shr dl, 4
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

second_letter:
	mov dx, ax
	and dh, 00001111b
	and dl, 00000000b
	or dl, dh
	mov dh, 0
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

third_letter:
	mov dx, ax
	and dh, 00000000b
	and dl, 11110000b
	shr dl, 4
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

fourth_letter:
	mov dx, ax
	mov dh, 0
	and dl, 00001111b
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

prepare_bx:
	mov ah, 09h
	mov dx, special_msg
	int 21h

	mov ah, 09h
	mov dx, msg_b
	int 21h

	mov ax, bx
	mov bx, 0
	mov cx, 4
	jmp main_function

msg_b db 'BX=0x$'
msg_a db 'AX=0x$'
special_msg db 0xD, 0xA, '$'