use16
org 0x100

mov ax, 0x1AA1
mov bx, 0xB22B
mov cx, 0x33CC
mov dx, 0x0
call print_registers

mov ax, 0
int 16h
int 20h

print_registers:
	push ax
	call print_ax
	call print_register

	mov ax, bx
	call print_bx
	call print_register

	mov ax, cx
	call print_cx
	call print_register

	mov ax, dx
	call print_dx
	call print_register
	call print_next_stroka

	mov ax, cs
	call print_cs
	call print_register

	mov ax, ss
	call print_ss
	call print_register

	mov ax, ds
	call print_ds
	call print_register

	mov ax, es
	call print_es
	call print_register
	call print_next_stroka

	mov ax, si
	call print_si
	call print_register

	mov ax, di
	call print_di
	call print_register

	mov ax, sp
	call print_sp
	call print_register

	mov ax, bp
	call print_bp
	call print_register
	call print_next_stroka

	pushf
	pop ax
	call print_flags
	call print_register
	
	pop ax
	ret

print_register:
	push cx
	push si
	push dx
	mov cx, 4
	call main_function
	pop dx
	pop si
	pop cx
	ret

main_function:
	cmp cx, 3
	ja first_letter
	cmp cx, 2
	ja second_letter
	cmp cx, 1
	ja third_letter
	cmp cx, 0
	jnz fourth_letter
	call print_special
	ret

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

adding_for_letter:
	add dl, 0x7
	jmp before_print

before_print:
	add dl, 0x30
	jmp print

print:
	mov si, ax
	mov ah, 02h
	int 21h
	mov ax, si
	sub cx, 1
	jmp main_function

print_special:
	push ax
	push dx
	mov ah, 09h
	mov dx, special_msg
	int 21h
	pop dx 
	pop ax 
	ret

print_next_stroka:
	push ax
	push dx
	mov ah, 09h
	mov dx, next_stroka_msg
	int 21h
	pop dx 
	pop ax 
	ret

print_ax:
	pusha
	mov ah, 09h
	mov dx, msg_ax
	int 21h
	popa
	ret

print_bx:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_bx
	int 21h
	pop dx 
	pop ax
	ret

print_cx:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_cx
	int 21h
	pop dx 
	pop ax
	ret

print_dx:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_dx
	int 21h
	pop dx 
	pop ax
	ret

print_cs:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_cs
	int 21h
	pop dx 
	pop ax
	ret

print_ds:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_ds
	int 21h
	pop dx 
	pop ax
	ret

print_es:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_es
	int 21h
	pop dx 
	pop ax
	ret

print_ss:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_ss
	int 21h
	pop dx 
	pop ax
	ret

print_si:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_si
	int 21h
	pop dx 
	pop ax
	ret

print_di:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_di
	int 21h
	pop dx 
	pop ax
	ret

print_sp:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_sp
	int 21h
	pop dx 
	pop ax
	ret

print_bp:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_bp
	int 21h
	pop dx 
	pop ax
	ret

print_flags:
	push ax
	push dx
	mov ah, 09h
	mov dx, msg_flags
	int 21h
	pop dx 
	pop ax
	ret


msg_ax db 'AX=0x$'
msg_bx db 'BX=0x$'
msg_cx db 'CX=0x$'
msg_dx db 'DX=0x$'

msg_cs db 'CS=0x$'
msg_ds db 'DS=0x$'
msg_es db 'ES=0x$'
msg_ss db 'SS=0x$'

msg_si db 'SI=0x$'
msg_di db 'DI=0x$'
msg_sp db 'SP=0x$'
msg_bp db 'BP=0x$'

msg_flags db 'FLAGS=0x$'

special_msg db '; $'
next_stroka_msg db 0xD, 0xA, '$'