org 100h
use16

start:
	call clean_screen
	call filling_base_adress
	call GDT_load
	call open_A20_line
	call disable_interrupts
	
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
	mov [CODE16_descr+2], al
	mov [LONG_descr+2], al
	
	mov [CODE_descr+3], ah
	mov [CODE16_descr+3], ah
	mov [LONG_descr+3], ah

	shr eax, 8
	mov [CODE_descr+4], ah
	mov [CODE16_descr+4], ah
	mov [LONG_descr+4], ah
	ret

GDT_load:
	mov eax, 0x0; вычисляем линейный адрес точки входа в защищенный режим
	mov ax, cs
	shl eax, 4
	add ax, GDT

	mov dword [GDTR+2], eax ; линейный адрес GDT кладем в заранее подготовленную переменную:

	lgdt fword [GDTR] ; загрузка регистра GDTR:
	ret

protect_start:
	use32

	mov bx, ds
    mov word[pm + 2], bx

	; загрузим сегментные регистры требуемыми селекторами
	mov ax, 10h ; 10 000(в двоичной)

	mov	ds, ax ; перенесем во все регистры
	mov	es, ax
	
	mov eax, cr4 ; enable physical-address extensions
    or  eax,1 shl 5 ; Включить расширение PAE (бит 5 регистра CR4)
    mov cr4, eax   

    mov eax, 0x170000 ; адрес взят из примера из лекции
    mov cr3, eax ; Загружаем базовый адрес всей цепочки таблиц 

    mov edi, 0x170000 ; заполняем 1 запись PDPT
    mov dword[edi], 171007h ; выставляются биты U/S, R/W, P
    mov dword[edi + 4], 0
    
    ; далее заполняем каталог страниц адресами таблиц страниц
    mov edi, 171000h 
    mov dword[edi], 172007h ; 1 таблица
    mov dword[edi + 4], 0

    add edi, 8
    mov dword[edi], 173007h ; 2 таблица
    mov dword[edi + 4], 0 

    add edi, 8
    mov dword[edi], 174007h ; 3 таблица
    mov dword[edi + 4], 0 

    add edi, 8
    mov dword[edi], 175007h ; 4 таблица
    mov dword[edi + 4], 0


    ; заполнение инофрмации в таблицах страниц
    mov edi, 0x172000   ; адрес первой таблицы страниц 
    mov ecx, 512*4      ; число элементов на все 4 таблицы страниц
    mov eax, 0 + 0x87   ; 0 - адрес нулевой страницы, 0x87 - атрибуты
    					; = 10000111 (7, 2, 1, 0) биты (PS, U/S, R/W, P)



gen_page:				; делаем страницы
	stosd
	mov dword[edi + 4], 0
	add edi, 4
	add eax, 0x200000   ; т.к. 2мб
	loop gen_page

; STOSD сохраняет EAX в ячейке памяти по адресу ES:DI.
; После EDI увеличивается на 4, если флаг DF = 0, или уменьшается на 4, если DF = 1.


	mov eax, 0x170000
    mov cr3, eax ;Загружаем базовый адрес всей цепочки таблиц 


; Включить режим Longmode (бит 8 в регистре EFER MSR 0xc0000080)
   	mov ecx, 0C0000080h      ; EFER MSR
    rdmsr
    or  eax, 1 shl 8     ; enable long mode
    wrmsr

; Включить табличную трансляцию (бит 31 регистра CR0)
	mov eax, cr0
    or  eax, 1 shl 31
    mov cr0, eax 

	mov ax, 0x38 ; 111 000 в гдт
    mov es, ax
    xor eax, eax
    mov ax , bx ; в bx лежит ds в момент входа в 32 разрядный
    shl eax, 4
    add eax, long_start
    mov dword[es:long_start_ptr], eax
    jmp fword[es:long_start_ptr]

long_start_ptr:
	dd 0x0
	dw 0x28 ; 101 000 в гдт

long_start:
	use64
	mov ax, 0x30 ;110 000 в гдт 
	mov ds, ax
	mov es, ax

	mov rdi, 0x0B8640 		  ; 10*160 в десятичной
	mov word[rdi], 	   0xA154 ;T
	mov word[rdi + 2], 0xB145 ;E
	mov word[rdi + 4], 0xC153 ;S
	mov word[rdi + 6], 0xD154 ;T
	mov word[rdi + 8], 0xF121 ;!

	xor rdi, rdi

	jmp tbyte[protect_mode_again_ptr] ; tbyte = tenByte

protect_mode_again_ptr:
	dq protect_mode_again
	dw 0x8

protect_mode_again:
	use32
	mov eax, cr0 ; выключаем табличную трансляцию
	btr eax, 31
	mov cr0, eax

	mov ecx, 0x0C0000080 ; выключаем LongMode
	rdmsr
	btr eax, 8 
	wrmsr

	mov eax, cr4 ; Выключаем расширение PAE
	btr eax, 5 
	mov cr4, eax

	jmp  0x20:pred_real_mode

pred_real_mode:
	use16
	mov eax ,cr0
	and al, 0FEh
	mov cr0, eax

	jmp dword [cs:pm]

pm:
	dw real_mode  
	dw 0


real_mode:
	use16
	sti

	in	al, 70h
	and	al, 7Fh
	out	70h, al
	sti
	
	in	al, 92h
	and	al, 0FDh
	out	92h, al
	
	mov ah, 0
	int 16h
	int 20h

align 8 ;процессор быстрее обращается с выравненной табличкой
GDT:                      ; ГЛОБАЛЬНАЯ ТАБЛИЦА ДЕСКРИПТОРОВ
	NULL_descr    db 8 dup(0)
	CODE_descr    db 0FFh, 0FFh, 00h, 00h, 00h, 10011010b, 11001111b, 00h  
	DATA_descr    db 0FFh, 0FFh, 00h, 00h, 00h, 10010010b, 11001111b, 00h  
	VIDEO_descr   db 0FFh, 0FFh, 60h, 84h, 0Bh, 10010010b, 01000000b, 00h ; 10 строка
	CODE16_descr  db 0FFh, 0FFh, 00h, 00h, 00h, 10011010b, 10001111b, 00h  

	CODE64_descr  db 000h, 000h, 00h, 00h, 00h, 10011010b, 00100000b, 00h
	DATA64_descr  db 000h, 000h, 00h, 00h, 00h, 10010010b, 00100000b, 00h
	LONG_descr    db 0FFh, 0FFh, 00h, 00h, 00h, 10010010b, 11001111b, 00h

	GDT_size equ $-GDT-1

label GDTR fword 
	dw GDT_size; 16-битный лимит GDT
	dd ? ; здесь будет 32-битный линейный адрес GDT

align 8
