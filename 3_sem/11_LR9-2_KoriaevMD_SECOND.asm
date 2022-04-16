use16
org 0x100

jmp init

begin:
	sti
	pusha 
	mov ax, cs ;инициализируем ds и es, так как они изначально
	mov ds, ax ;указывают на программу, вызвавшую обработчик
	mov es, ax

	mov dx, debuger_msg
	mov ah, 09h
	int 21h

	mov ah, 01h

	;int 21h

	int 20h

	popa
	mov dx, 0xFFFF
	iret


init:
	mov ah, 0x35 ; сохраняем оригинальный вектор
	mov al, 0x01 
	int 21h

	mov [orig_0x15], bx
	mov [orig_0x15+2], es

	mov ah, 0x25 ;задаем новый 
	mov al, 0x01
	mov dx, begin
	int 21h

	mov ah, 09h

	cmp dx, 0xFFFF
	jz finish

	mov dx, msg
	int 21h

	mov ax, cs ;Приравниваем сегменты
	mov ds, ax
	mov es, ax
	mov di, password

input:
	mov ah, 0Ah
	mov dx, Lang_pass_max
	int 21h

get_lenth:
	mov si, dx
	inc si
	mov cl, [si]
	inc si

check_lenth:
	mov ah, 09h
	cmp cx, 0x6 ;проверяем длину пароля
	jnz incorrect
	
compare:
	repe cmpsb
	jnz incorrect

correct:
	mov dx, correct_msg
	jmp write

incorrect:
	mov dx, incorrect_msg
	
write:
	int 21h

	mov dx, [orig_0x15] ; возвращаем старый
	mov ds, [orig_0x15+2]
	mov ah, 0x25
	mov al, 0x01 

	int 21h

	int 16h
	int 20h

finish:
mov dx, [orig_0x15] ; возвращаем старый
	mov ds, [orig_0x15+2]
	mov ah, 0x25
	mov al, 0x01 
	int 21h

	mov ah, 09h
	mov dx, debuger_msg
	int 21h

	int 16h
	int 20h

password db '20U048'
correct_msg db 'password correct', 0xD, 0xA, '$'
incorrect_msg db 'password incorrect', 0xD, 0xA, '$'
msg db 'Enter your password', 0xD, 0xA, '$'
debuger_msg db 'YOU CANT WORK WITH DEBUGER!', 0xD, 0xA, '$'

Lang_pass_max db 254 ; Максимольная длина пароля
Lang_pass_cur db 0 ; Длина введенной строки
Pass_pressed db 254 dup (0) ; Текст строки
orig_0x15 dw 0,0