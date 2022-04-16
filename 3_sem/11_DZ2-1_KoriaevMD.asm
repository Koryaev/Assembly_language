use16
org 0x100

jmp init

begin:
	sti
	pusha 
	mov ax, cs ;инициализируем ds и es, так как они изначально
	mov ds, ax ;указывают на программу, вызвавшую обработчик
	mov es, ax

	in al, 0x60 ;значение скана нажатия

	mov si, keys ;сканы специальных клавиш
	mov cx, 14 
	jmp check

finish:
	popa
	iret

check:
	mov byte bl, [si]
	cmp bl, al
	jz work

	inc si
	loop check

	jmp finish

work:
	call beep
	popa
	iret

beep:
	mov ax, 3000 ;(1190000/395) ; Устанавливаем высоту тона 395 Гц -
	out 0x42, al
	mov al, ah
	out 0x42, al

	in al, 0x61
	or al, 00000011b
	out 0x61, al

	call delay

	in al, 0x61
	and al, 11111100b
	out 0x61, al
	ret

delay:
	pusha
	mov ah, 0
	int 0x1a
	add dx, 0x2
	mov bx, dx

time:
	mov ah, 0
	int 0x1a
	cmp bx, dx
	jne time
	popa
	ret

init:
	mov ah, 09h
	mov dx, msg
	int 21h
	
	mov al, 0xB6 ; устанавливаем режим управления
	out 0x43, al ; динамиком

	mov ah, 0x35 ; сохраняем оригинальный вектор
	mov al, 0x15 
	int 21h

	mov [orig_0x15], bx
	mov [orig_0x15+2], es

	mov ah, 0x25 ;задаем новый 
	mov al, 0x15 
	mov dx, begin
	
	int 21h


	call delay2
 	
	mov dx, [orig_0x15] ; возвращаем старый
	mov ds, [orig_0x15+2]
	mov ah, 0x25
	mov al, 0x15 

	int 21h

	int 16h
	int 20h

delay2:
	pusha
	mov ah, 0
	int 0x1a
	add dx, 0xA0
	mov bx, dx

time2:
	mov ah, 0
	int 0x1a
	cmp bx, dx
	jne time2
	popa
	ret

msg db "This program will finish in 10 seconds", 0xD, 0xA, "$"
orig_0x15 dw 0,0
keys db 0x01, 0x0F, 0xBA, 0x2A, 0x1D, 0x38, 0x0E, 0x1C, 0x36, 0x2A, 0x46, 0xE1, 0x52, 0x53