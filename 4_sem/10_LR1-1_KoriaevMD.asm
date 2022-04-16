use16
org 100h

start:
	call clean_screen
	call disable_interrupts
	call open_A20_line
	call filling_base_adress
	call GDT_load

	mov eax, cr0 ; переключение в защищенный режим:
	or al, 1
	mov cr0, eax

	jmp far fword 0x8:protect_start

clean_screen:
	mov	ax, 3
	int	10h
	ret

disable_interrupts:
	cli	; Отключение внешних прерываний 

	in al, 70h ; Отключение немаскируемых прерываний 
	or al, 80h
	out 70h, al
	ret

open_A20_line:
	in al, 92h ; открываем линию А20 (для 32-битной адресации):
	or al, 2
	out 92h, al
	ret

filling_base_adress:
	mov eax, 0x0
	mov ax, cs
	shl eax, 4
	mov [CODE_descr+2], al
	shr eax, 8
	mov [CODE_descr+3], al
	mov [CODE_descr+4], ah
	ret

GDT_load:
	mov eax, 0x0; вычисляем линейный адрес точки входа в защищенный режим
	mov ax, cs
	shl eax, 4
	add ax, GDT

	mov dword [GDTR+2], eax ; линейный адрес GDT кладем в заранее подготовленную переменную:

	lgdt fword [GDTR] ; загрузка регистра GDTR:
	ret

align 8 ;процессор быстрее обращается с выравненной табличкой
GDT:                      ; ГЛОБАЛЬНАЯ ТАБЛИЦА ДЕСКРИПТОРОВ
	NULL_descr db 8 dup(0)
	CODE_descr db 0FFh, 0FFh, 00h, 00h, 00h, 10011010b, 11001111b, 00h  
	DATA_descr db 0FFh, 0FFh, 00h, 00h, 00h, 10010010b, 11001111b, 00h  
	VIDEO_descr db 0FFh, 0FFh, 60h, 84h, 0Bh, 10010010b, 01000000b, 00h ; 10 строка
	GDT_size equ $-GDT

; CODE_descr db 0FFh, 0FFh, 00h, 00h, 00h, 10011010b, 11001111b, 00h
; segment_limit (2 по 8 бит), base_adress(3 по 8 бит),

; 1001 (p=1 => в памяти,
; dpl = 0 descriptor privilege level (2 бита),
; s=1(сегмент системный(=0)или сегмент кода/данных))

; type(4 бита 1010 execute/read), 

; 11001111b (g=1(гранулярность–0,то лимит измеряется в байтах;1,то в 4КБ страницах),
; D/B=1 Default operation size (0 = 16-bit сегмент; 1 = 32-bit сегмент),
; L=0 => не 64-разрядный сегмент,
; AVL=0 Зарезервировано
; segment_limit=1111(продолжение первых 16 битов)

; base_adress(8 бит, продолжение)

GDTR: 
	dw GDT_size; 16-битный лимит GDT
	dd 0x0 ; здесь будет 32-битный линейный адрес GDT


use32 ; далее следует 32-битный код
protect_start:
	mov ax, 00010000b ; загрузим сегментные регистры требуемыми селекторами
	mov bx, ds ; номер сегмента кода режима реальных адресов
	mov ds, ax
	mov ax, 00011000b
	mov es, ax 

	mov esi, 0xFFFFFFF0
	mov cx, 16
	mov ebx, 0x0

point:
	mov edx, 0x0
	mov dl, byte[esi]

fitst_symbol:
	mov eax, 0x0
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
	mov [es:bx], dl
	jz prepare
	jmp second_symbol

second_symbol:
	inc bx
	inc bx
	mov dl, byte[esi]
	
	mov ax, 0xFFFF
	and dl, 00001111b
	cmp dl, 0x9
	ja adding_for_letter
	jmp before_print

prepare:
	inc esi
	inc bx
	inc bx
	mov byte[es:bx], 0x20
	inc bx
	inc bx
	dec cx
	cmp cx, 0x0
	ja point
	jmp $ ; бесконечный цикл

