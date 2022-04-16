use16
org 0x100

mov ax, 0x0 ;Задаем для дампа сегмент
mov bx, 0x0 ;и смещение

start:
	mov si, buffer ;массив в регистр 
	call write_dump_memory_in_buffer ;записываем туда дамп

create_file:
	mov ah, 0x3C
	mov cx, 0x0
	mov dx, fname
	int 21h
	; в ax логический номер файла

write_in_file:
	mov bx, ax
	mov ah, 0x40
	mov dx, buffer
	mov cx, 800
	int 21h

close_file:
	mov ah, 0x3E
	int 21h


int 16h
int 20h

write_dump_memory_in_buffer:
	pusha
	push ax
	pop es
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
	mov byte[si], dl

	inc si ;к следующей ячейки памяти

	cmp ax, 0xFFFF
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
	mov byte[si], 0x20 ;пробел между числами
	inc si

	dec cx
	cmp cx, 0x0
	ja read_mem
	pop cx
	dec cx

	mov byte[si], 0xD ;перевод каретки на начало новой строки
	inc si
	mov byte[si], 0xA
	inc si

	jmp read_lines


buffer db 800 dup (?) ;массив
fname db 'KMD.txt',0