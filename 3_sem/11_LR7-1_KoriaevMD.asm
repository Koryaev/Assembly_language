use16
org 0x100

read_master_boot_record:
	mov ah, 02h ; функция чтения физ.диска
	mov al, 01h ; число читаемых секторов
	mov ch, 0x0 ; цилиндр
	mov cl, 0x1 ; начальный сектор
	mov dh, 0x0 ; головка
	mov dl, 80h ; жесткий диск
	mov bx, buffer
	int 13h
	jc exit ;в случае ошибки

prepare_before_write:
	mov si, buffer
	mov di, asci_buffer

call rewrite_buffer

create_file:
	mov ah, 0x3C
	mov cx, 0x0
	mov dx, fname
	int 21h
	; в ax логический номер файла

write_in_file:
	mov bx, ax
	mov ah, 0x40
	mov dx, asci_buffer
	mov cx, 1600
	int 21h

close_file:
	mov ah, 0x3E
	int 21h

int 16h
int 20h


rewrite_buffer:
	pusha
	mov cx, 0x20
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
	mov dl, [si]
	inc si

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
	mov byte [di], dl
	inc di
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
	mov byte [di], 0x20
	inc di

	dec cx
	cmp cx, 0x0
	ja read_mem
	pop cx
	dec cx

	mov byte [di], 0xD
	inc di
	mov byte [di], 0xA
	inc di

	jmp read_lines

exit:
	mov ah, 09h
	mov dx, error_msg
	int 21h
	int 16h
	int 20h

error_msg db 'error MBR', 0xD, 0xA, '$'
next_stroka_msg db 0xD, 0xA, '$'
fname db 'lab7_1.txt',0
buffer db 512 dup (?)
asci_buffer db 1600 dup (?)
