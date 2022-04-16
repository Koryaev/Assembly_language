use16
org 0x100

mov ax, 0xb800
mov ds, ax


mov di, 0x2 ;stroka
mov si, 0x1 ;stolb
mov dh, 0xE1 ;atributs
mov dl, 0x54 ;ASCI
call write_symbol

mov di, 0x3
mov si, 0x2
mov dh, 0xF1
mov dl, 0x45
call write_symbol

mov di, 0x4
mov si, 0x3
mov dh, 0xD1
mov dl, 0x53
call write_symbol

mov di, 0x5
mov si, 0x4
mov dh, 0xC1
mov dl, 0x54
call write_symbol

mov ax,0
int 16h
int 20h

write_symbol:
	pusha
	mov bx, di
	mov al, 0xA0
	mul bl
	mov bx, ax

	mov al, 0x2
	mov cx, si
	mul cl
	add bx, ax
	mov word[ds:bx], dx;
	popa
	ret
