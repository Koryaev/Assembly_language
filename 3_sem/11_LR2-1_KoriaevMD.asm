use16
org 0x100

mov ax, 0xb800
mov es, ax
mov di, 0
mov cx, 14
mov si, msg

mycycle:
movsw
loop mycycle

mov ax,0
int 16h
int 20h

msg:
dw 0xE14D, 0xE169, 0xE168, 0xE161, 0xE169, 0xE16C, 0xE120, 0xE14B, 0xE16F, 0xE172, 0xE169, 0xE161, 0xE165, 0xE176
