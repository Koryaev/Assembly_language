format MZ
entry code_seg:start
stack 200h
;----------------------------------------------------
segment data_seg
password db '20U048'
correct_msg db 'password correct', 0xD, 0xA, '$'
incorrect_msg db 'password incorrect', 0xD, 0xA, '$'
msg db 'Enter your password', 0xD, 0xA, '$'

Lang_pass_max db 254 ; Максимольная длина пароля
Lang_pass_cur db 0 ; Длина введенной строки
Pass_pressed db 254 dup (0) ; Текст строки
;----------------------------------------------------
segment code_seg

start:
	mov ax, data_seg 
	mov ds, ax
	mov es, ax
	mov di, password

	mov ah, 09h
	mov dx, msg
	int 21h

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
	mov ax, 4c00h
	int 21h
