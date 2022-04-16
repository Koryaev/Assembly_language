org 100h
use16
STACK equ 200000h

macro DEFINE_GATE _address,_code_selektor, _type
{
	dw _address and 0FFFFh, _code_selektor, _type, _address shr 16
}

start:
	mov [CS_save], cs ; сохраняем ругистр cs

	call clean_screen
	call filling_base_adress
	call GDT_load
	call IDT_load
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
	mov [DATA_descr+2], al
	mov [CODE16_descr+2], al
	
	
	mov [CODE_descr+3], ah
	mov [DATA_descr+3], ah
	mov [CODE16_descr+3], ah

	shr eax, 8
	mov [CODE_descr+4], ah
	mov [DATA_descr+4], ah
	mov [CODE16_descr+4], ah
	ret


GDT_load:
	mov eax, 0x0; вычисляем линейный адрес точки входа в защищенный режим
	mov ax, cs
	shl eax, 4
	add ax, GDT

	mov dword [GDTR+2], eax ; линейный адрес GDT кладем в заранее подготовленную переменную:

	lgdt fword [GDTR] ; загрузка регистра GDTR:
	ret

IDT_load:
	mov eax, 0x0
	mov ax, cs
	shl eax, 4
	add ax, IDT

	mov dword [IDTR+2], eax
	sidt fword[real_IDTR]
	lidt fword[IDTR]
	ret


protect_start:
	use32 ; далее следует 32-битный код
	mov ax, 10h ; загрузим сегментные регистры требуемыми селекторами
	mov bx, ds ; номер сегмента кода режима реальных адресов
	mov ds, ax
	mov ax, 00011000b
	mov es, ax 

	mov esp, STACK

	sti
	int 42
asd:
	inc word [es:500]
	jmp  asd
	cli 

	jmp far fword 20h:pred_real_mode

handler:
	pusha
	mov di, 0x0
	mov word[es:di], 0xD034
	add di, 0x2
	mov word[es:di], 0xD032

	mov al, 0x20 ; отправляем контролеру прерываний
	out 020h, al ; сигнал, что прерывание обработано
	out 0A0h, al
	
	popa
	iretd

gp_handler:
	pop eax
	pusha
	push edx
	mov edx, 400
	inc word [es:edx]
	pop edx

	mov al, 0x20 ; отправляем контролеру прерываний
	out 020h, al ; сигнал, что прерывание обработано
	out 0A0h, al

	popa
	iretd

pred_real_mode:
	use16

	mov eax, cr0
	and al,0FEh
	mov cr0, eax

	jmp far fword [pm]
pm:
	dd real_mode
	CS_save dw ?


real_mode:
	lidt[real_IDTR]

	in	al,70h
	and	al,7Fh
	out	70h,al
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
	GDT_size equ $-GDT-1

label GDTR fword 
	dw GDT_size; 16-битный лимит GDT
	dd ? ; здесь будет 32-битный линейный адрес GDT

align 8
IDT:
	dq 0 									   ; 0
	dq 0 									   ; 1
	dq 0 									   ; 2
	dq 0 									   ; 3
	dq 0 									   ; 4
	dq 0 									   ; 5
	dq 0 									   ; 6
	dq 0 									   ; 7
	dq 0 									   ; 8
	dq 0 									   ; 9
	dq 0 									   ; 10
	dq 0 									   ; 11
	dq 0 									   ; 12
	DEFINE_GATE gp_handler, 8h, 1000111000000000b ; 13 gp
	dq 0 									   ; 14
	dq 0 									   ; 15
	dq 0 									   ; 16
	dq 0 									   ; 17
	dq 0 									   ; 18
	dq 0 									   ; 19
	dq 0 									   ; 20
	dq 0 									   ; 21
	dq 0 									   ; 22
	dq 0 									   ; 23
	dq 0 									   ; 24
	dq 0 									   ; 25
	dq 0 									   ; 26
	dq 0 									   ; 27
	dq 0 									   ; 28
	dq 0 									   ; 29
	dq 0 									   ; 30
	dq 0 									   ; 31
	dq 0 									   ; 32
	dq 0 									   ; 33
	dq 0 									   ; 34
	dq 0 									   ; 35
	dq 0 									   ; 36
	dq 0 									   ; 37
	dq 0 									   ; 38
	dq 0 									   ; 39
	dq 0 									   ; 40
	dq 0 									   ; 41
	DEFINE_GATE handler, 8h, 1000111000000000b ; 42
	IDT_size equ $-IDT-1

label IDTR fword
    dw IDT_size ; 16-bit limit of the interrupt descriptor table
    dd ?

label real_IDTR fword
    dw ? ; 16-bit limit of the interrupt descriptor table
    dd ?
