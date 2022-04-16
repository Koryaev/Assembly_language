use16
org 0x100

start:
	mov al, 0xb6 ;режим работы с динамиком
	out 0x43, al
	mov si, music
	mov di, delay_time
	mov cx, 38

	call play_music

int 16h
int 20h


play_music:
	call set_sound
	call beep
	call between
	loop play_music
	ret

set_sound:
	mov ax, [si]
	add si, 2
	out 0x42, al
	mov al, ah
	out 0x42, al
	ret

beep:
	call turn_on_speaker
	call delay
	add di, 2
	call turn_off_speaker
	ret

turn_on_speaker:
	in al, 0x61
	or al, 00000011b
	out 0x61, al
	ret

between:
	pusha
	mov ah, 0
	int 0x1a
	add dx, 0x1
	inc di
	mov bx, dx
	jmp time

delay:
	pusha
	mov ah, 0
	int 0x1a
	add dx, [di]
	mov bx, dx

time:
	mov ah, 0
	int 0x1a
	cmp bx, dx
	jne time
	popa
	ret

turn_off_speaker:
	in al, 0x61
	and al, 11111100b
	out 0x61, al
	ret

;Имперский марш
music dw 3036, 3036, 3036, 3826, 2556, 3036, 3826, 3826, 2556, 2027, 2027, 2027, 1913, 2553, 3224, 3826, 2553, 3035, 1517, 3035, 3035, 1517, 1610, 1704, 1805, 1913, 1805, 2867, 2148, 2275, 2413, 2553, 1704, 2553, 3826, 3224, 3826, 2553, 3035
delay_time dw 14, 14, 14, 10, 4, 14, 10, 4, 28, 14, 14, 10, 4, 14, 10, 4, 28, 14, 10, 4, 14, 10, 4, 4, 4, 18, 6, 14, 10, 4, 4, 4, 18, 6, 14, 10, 4, 30