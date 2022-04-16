use16
org 0x100



mov cl, 0100b
mov al, 0xed
out 0x60, al
mov al, cl
out 0x60, al

call delay

int 16h
int 20h

delay:
	pusha
	mov ah, 0
	int 0x1a
	add dx, 0x30
	mov bx, dx

time:
	mov ah, 0
	int 0x1a
	cmp bx, dx
	jne time
	popa
	ret



























