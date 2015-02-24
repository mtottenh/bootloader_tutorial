[bits 16]
[org 0]

start:
	mov cx, end_stage_msg - stage_msg 
	mov bp, stage_msg
	call print 
	; Setup a stack
	mov sp,0x7000
		
	;Query Lower memory
	; Query Upper Memory
	; Read kernel sectors into lower memory - (Try with a basic fs?)
	; Enable the A20 Gate
	call check_a20
	cmp ax,0
	je a20_enabled
	mov cx,end_a20_msg - a20_msg
	mov bp, a20_msg
	call print
	call enable_a20

a20_enabled:
	

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

enable_a20:
	; Try a fast a20
	push ax
	in al,0x92
	or al,2
	out 0x92,al
	pop ax
	ret
check_a20:
	; Check to see if the memory wraps around at 1MB
	;  i.e. if addresses 0:0 and FFFF:10  are equal 
	; (Note real free memory starts at 0000:0500, as 0000-0500 is bios reserved memory)
	; 
	pushf
	push ds
	push es
	push di
	push si

	; Clear IF
	cli

	xor ax,ax ; ax=0
	mov es,ax

	not ax ; ax = 0xFFFF
	mov ds,ax
	mov di, 0x500
	mov si, 0x510
	
	; save what was there already so we don't break anyhting
	mov al, byte [es:di]
	push ax
	mov al, byte [ds:si]
	push ax
	
	mov byte [es:di], 0x00 	; store 00 at 0000:0500
	mov byte [ds:si], 0xFF	; store FF at FFFF:0510

	; ( (FFFF << 4) + 0510 = 100500 eq 0000:0500 if memory wraps)
	

	; Do the comparison
	cmp byte [es:di], 0xFF
	
	; Restore state to what it was
	pop ax
	mov byte [ds:si], al
	pop ax
	mov byte [es:di], al

	; set AX pending result of comparison
	mov ax,0
	je .exit_a20_test
	mov ax,1
.exit_a20_test
	pop si
	pop di
	pop es
	pop ds
	popf
	ret

db 0xFF
stage_msg: db "Stage 1_5 Loaded...",10,13,0
end_stage_msg:
a20_msg: db "Enabling a20 gate.",10,13,0
end_a20_msg:
times 8704-($-$$) db 0
