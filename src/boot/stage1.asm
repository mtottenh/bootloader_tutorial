; Stage 1 bootloader
; Last 2 bytes must be 0x55aa 

; Useful Macros
%define loc 0x1000
%define ftable 0x2000 ; Function Table
%define drive 0x80 ; drive
%define os_sect 2
%define ftabsect 2
%define sectors 17

[bits 16] ; Must start in 16 bit real mode
[org 0] ; - Sets assembler location counter to 0 (load the following at 0x0h)
; Enforce cs=0x7c0
jmp 0x7c0:start ; Sets CS to 0x7c0, the default location the BIOS loads the bootloader code to.

start:
	; Initialize data segment & extra segment = code segment
	mov ax,cs
	mov ds,ax
	mov es,ax

	; Initialize Screen 
	; INT 10h = Video Functions (http://www.ctyme.com/intr/rb-0069.htm)
	; Args (AH,AL,CH,CL,BH,BL,DH,DL)
	; AH = Function Code
	; 00h = Set Video Mode
	;
	; AL = Video Mode
	; 03h = 80x25 Screen 
	mov al,03h
	mov ah,0 
	int 10h


	; Print out welcome message
	mov cx, msgend - msg -1 ;get message size
	mov bp, msg
	call print

	; Grap keypress
	mov ah,0
	int 16h

	; Print Loading message
	mov cx,kernend - kern -1 
	mov bp,kern
	call print
	

	mov ax,loc ; Start location of stage 1.5 (Target addr)
	mov es,ax
	mov cl,os_sect  ; Start Read at sector 2
	mov al,sectors ; Number of sectors
	call loadsector
	jmp loc:0000

; Below works in CHS mode. - Maybe we should write some code to translate 
; to LBA and load from LBA addresses? Might be easeier.
loadsector:
	; Load Sector (INT 0x13 - http://www.ctyme.com/intr/rb-0607.htm)
	; AL = Number of Sectors
	; CH = Low 8 Bits of Cylinder number
	; CL = 
	;		- Bits 0:5 = Sector number (1-63)
	;		- Bits 6:7 = High two bits of cylinder number
	; DH = Head number
	; DL = Drive number
	; ES:BX = Destination Buffer
	mov bx,0
	mov dl,drive
	mov dh,0 ; Head
	mov ch,0 ; Cylinder
	mov ah,2 ; (Int 13/AH=02h - DISK - READ SECTOR(S) INTO MEMORY)
	int 0x13 ;
	jc .err
	ret
	.err:
		mov ah,01h
		int 0x13
		mov dx,ax
		call hex_to_char
		mov cx,STRINGEND - error; String length
		mov bp, error
		call print
		mov ah,0
		int 16h	;Grab Keypress
		int 19h	; Reboot

hex_to_char:
	; ARGS: hex_to_char(AX)
	pusha
	push ax  ; Store ah on the stack, we will print al first
	; Load up conversion table into BX
	lea bx, [TABLE]

	; Exchange ah and al so that al gets written first (little endian)
	mov cx,ax
	xchg ch,cl
	;initialize counter = 0
	xor si,si
	
	.swap_char:
		mov dl,cl
		and cl, 0Fh
		shr dl, 4
	; Translate 0x[dl][cl]
		mov al,dl
		xlat
		mov dl,al
		mov al,cl
		xlat 
		mov dh,al
	; store at [STRING+si]
		lea bx,[STRING+si]
		mov [bx],dx
		lea bx,[TABLE]
	;Loop
		inc si
		inc si
		cmp si,4
		je .done_hex_to_char
		pop ax
		mov cx,ax
		jmp .swap_char
	.done_hex_to_char:
		lea bx,[STRING+4]
		mov ax,0x48
		mov [bx],ax
		popa
		ret

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

msg:  db "Loaded Bootloader, press any key to continue...",10,13,0
msgend:
kern: db "Loading Kernel...",10,13,0
kernend:
error: db "Error loading kernel, press any key to reboot (ERR): "
errorend:
STRING:
	times 6 db 0
STRINGEND:
TABLE:
	db "0123456789ABCDEF", 0

times 446-($-$$) db 0
PART_1: 
	times 16 db 0
PART_2:
	times 16 db 0
PART_3:
	times 16 db 0
PART_4:
	times 16 db 0
; MBR Boot Signature
dw 0xaa55 ; Note - Little endian 0xaa55 =~ 0x55aa

