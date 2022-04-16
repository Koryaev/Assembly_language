use16
org 0x100

mov word[es:0x0], 0xA154 ;T
mov word[es:0x2], 0xB145 ;E
mov word[es:0x4], 0xC153 ;S
mov word[es:0x6], 0xD154 ;T
mov word[es:0x8], 0xF121 ;!

mov ax, 0x5 ; lenth of the world 
mov cx, 0xFF ; number of movements
mov si, 0xF ; column number [0x0 - 0x4F]

call start

int 20h

start:
	pusha

	mov di, ax

	push ax
	mov ax, 0x2
	mov bx, si
	mul bl
	mov si, ax ; column number * 2
	mov bx, si
	add bx, 0xF00

	mov ax, 0xb800
	mov ds, ax

	mov ax, 0x2
	mul di
	mov di, ax
	pop ax
	sub di, 0x2 ;last letter adress

	call write_symbols

	popa
	ret

write_symbols:
	push cx

	mov cx, ax
	push bx
	push di
	call print_letter
	pop di
	pop bx

	call delay

	mov cx, ax
	push bx
	call delete_letter
	pop bx

	call check_bx

	pop cx
	dec cx

	cmp cx, 0x0
	jnz write_symbols
	ret

print_letter:
	mov dx, [es:di]
	mov word[ds:bx], dx;
	call check_bx
	sub di, 0x2

	dec cx
	cmp cx, 0x0
	jnz print_letter
	ret

delete_letter:
	mov word[ds:bx], 0x20;
	call check_bx

	dec cx
	cmp cx, 0x0
	jnz delete_letter
	ret

check_bx:
	cmp bx, si
	jz new_bx
	jnz old_bx
	ret 

new_bx:
	mov bx, 0xF00
	add bx, si
	ret

old_bx:
	sub bx, 0xA0
	ret

delay:
	pusha
	mov ah, 0
	int 0x1a
	add dx, 0x10
	mov bx, dx

time:
	mov ah, 0
	int 0x1a
	cmp bx, dx
	jne time
	popa
	ret
