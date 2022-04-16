use16
org 0x100

check_TF:
	push ss
    pop ss
    pushf
    pop bx 

    and bh, 00000001b
    cmp bh, 0x0
    jz start

	mov dx, debuger_msg
	mov ah, 09h
	int 21h

	mov ah, 01h
	int 21h

	int 20h

start:
	mov ah, 09h
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

	int 16h
	int 20h


password db '20U048'
correct_msg db 'password correct', 0xD, 0xA, '$'
incorrect_msg db 'password incorrect', 0xD, 0xA, '$'
msg db 'Enter your password', 0xD, 0xA, '$'
debuger_msg db ' YOU CANT WORK WITH DEBUGER!', 0xD, 0xA, '$'

Lang_pass_max db 254 ; Максимольная длина пароля
Lang_pass_cur db 0 ; Длина введенной строки
Pass_pressed db 254 dup (0) ; Текст строки