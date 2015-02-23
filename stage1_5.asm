[bits 16]
[org 0]

start:
	mov cx, end_stage_msg - stage_msg 
	mov bp, stage_msg
	call print 
.halt
	jmp .halt
print:
	pusha
	mov al, 1
	mov bh, 0
	mov bl, 02
	mov dl, 0
	mov dh, 1
	push cs
	pop es
	mov ah, 13h
	int 10h
	popa
	ret


db 0xFF
stage_msg: db "Stage 1_5 Loaded...",10,13,0
end_stage_msg:
times 1024-($-$$) db 0
