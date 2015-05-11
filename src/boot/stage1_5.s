.code16
.org 0
.text
start:
	mov end_stage_msg - stage_msg, %cx 
	mov stage_msg, %bp
	call print 
	/* Setup a stack */
	mov 0x7000, %sp
		
	/*Query Lower memory
	  Query Upper Memory
	  Read kernel sectors into lower memory - (Try with a basic fs?)
	  Enable the A20 Gate */
	call check_a20
	cmp 0,%ax
	je a20_enabled
	mov end_a20_msg - a20_msg, %cx
	mov a20_msg, %bp
	call print
	call enable_a20

a20_enabled:
	

.halt:
	jmp .halt
print:
	pusha
	mov  $1 ,%al
	mov  $0 ,%bh
	mov  $2,%bl
	mov  $0 ,%dl
	mov  $1 ,%dh
	push %cs
	pop %es
	mov $0x13, %ah
	int $0x10
	popa
	ret

enable_a20:
	/* Try a fast a20  */
	push ax
	in $0x92,%al
	or $2,%al
	out %al,$0x92
	pop ax
	ret
check_a20:
	/* Check to see if the memory wraps around at 1MB
	   i.e. if addresses 0:0 and FFFF:10  are equal 
	  (Note real free memory starts at 0000:0500, as 0000-0500 is bios reserved memory)
	*/
	pushf
	push ds
	push es
	push di
	push si

	/* Clear IF */
	cli

	xor %ax,%ax 
	mov %ax,%bp

	not %ax
	mov %ax,%bx
	mov $0x500, %di
	mov $0x510, %si
	
	/* save what was there already so we don't break anyhting */
	mov (%bp,%di), %al
	push ax
	mov (%bx,%si), %al
	push ax
	
	movb $0x00, (%bp,%di) /*; store 00 at 0000:0500 */
	movb $0xFF, (%bx,%si) /*; store FF at FFFF:0510 */

	/* ( (FFFF << 4) + 0510 = 100500 eq 0000:0500 if memory wraps) */
	

	/* Do the comparison */
	cmpb  $0xFF,(%bp,%di)
	
	/* Restore state to what it was */
	pop ax
	movb %al, (%bx,%si)
	pop ax
	movb %al, (%bp,%di)

	/* set AX pending result of comparison */
	mov $0,%ax
	je .exit_a20_test
	mov $1,%ax
.exit_a20_test:
	pop si
	pop di
	pop es
	pop ds
	popf
	ret

.byte 0xFF
stage_msg: .asciz "Stage 1_5 Loaded...\n"
end_stage_msg:
a20_msg: .asciz "Enabling a20 gate.\n"
end_a20_msg:
.org 8704
