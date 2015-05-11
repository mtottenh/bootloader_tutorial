/* Stage 1 bootloader */
#.intel_syntax


/* Useful Macros*/
.macro loc
0x1000
.endm

.macro ftable
0x2000
.endm

.macro drive
0x80
.endm

.macro os_sect
2
.endm

.macro ftabsect
2
.endm

.macro sectors
17
.endm

.code16
.file "stage1.s"
.text
.org 0

/*	jmp 0x7c0:_start*/
/* Sets CS to 0x7c0, the default location the BIOS loads the bootloader code to. */

.globl start
jmp start
print:
	pusha
	mov $1, %al
	mov $0, %bh
	mov $2, %bl
	mov $0, %dl
	mov $1, %dh
	push cs
	pop es
	mov 0x13, %ah
	int $0x10
	popa
	ret

/*	; ARGS: hex_to_char(AX) */
hex_to_char:
	pusha
	push ax
	/*; Store ah on the stack, we will print al first
	; Load up conversion table into BX */
	lea (TABLE), %bx

	/*; Exchange ah and al so that al gets written first (little endian) */
	mov %ax,%cx
	xchg %cl,%ch
  /*	;initialize counter = 0 */
	xor %si,%si

swap_char:
    mov %cl,%dl
    and $0xF, %cl
  	shr $4, %dl
    /*	; Translate 0x[dl][cl] */
  	mov %dl,%al
  	xlat
  	mov %al,%dl
  	mov %cl,%al
  	xlat
  	mov %al,%dh
    /*	; store at [STRING+si] */
    push %ax
    lea (STRING), %ax
  	add %ax,%bx
    pop %ax
    add %si,%bx
    mov %dx, (%bx)
  	# %dx,(STRING + %si)
  	lea (TABLE), %bx
    /*	;Loop */
  	inc %si
  	inc %si
  	cmp $4,%si
  	je done_hex_to_char
  	pop %ax
  	mov %ax,%cx
  	jmp swap_char
done_hex_to_char:
    push %ax
    mov $4, %ax
    lea (STRING), %bx
    add %ax,%bx
    pop %ax
  	#lea (STRING+$4),%bx
  	mov 0x48,%ax
  	mov %ax,(%bx)

    popa
  	ret



/* Below works in CHS mode. - Maybe we should write some code to translate
 to LBA and load from LBA addresses? Might be easeier. */
loadsector:
/*	; Load Sector (INT 0x13 - http://www.ctyme.com/intr/rb-0607.htm)
	; AL = Number of Sectors
	; CH = Low 8 Bits of Cylinder number
	; CL =
	;		- Bits 0:5 = Sector number (1-63)
	;		- Bits 6:7 = High two bits of cylinder number
	; DH = Head number
	; DL = Drive number
	; ES:BX = Destination Buffer */
	mov $0,%bx
	mov drive,%dl
	mov $0,%dh
	mov $0,%ch
	mov $2,%ah
	int $0x13
	jc .err
	ret
	.err:
		mov $0x1,%ah
		int $0x13
		mov %ax,%dx
		call hex_to_char
		mov STRINGEND - error,%cx
		mov error, %bp
		call print
		mov $0,%ah
		int $0x16
		int $0x19




start:
  /* Initialize data segment & extra segment = code segment */
  mov %cs,%ax
  mov %ax,%ds
  mov %ax,%es

  /* Initialize Screen
  ; INT 10h = Video Functions (http://www.ctyme.com/intr/rb-0069.htm)
  ; Args (AH,AL,CH,CL,BH,BL,DH,DL)
  ; AH = Function Code
  ; 00h = Set Video Mode
  ;
  ; AL = Video Mode
  ; 03h = 80x25 Screen
  */
  mov $0x03,%al
  mov $0x0,%ah
  int $0x10

	/* Print out welcome message */
	mov  msgend - msg -1,%cx
	mov  msg, %bp
	call print

	/* Grab keypress */
	mov 0,%ah
	int $0x16

	/* Print Loading message */
	mov kernend - kern -1,%cx
	mov kern, %bp
	call print

	/* load kernel */
  mov loc,%ax
  mov %ax,%es
  mov os_sect,%cl
  mov sectors,%al
  call loadsector
  jmp loc


msg:  .asciz "Loaded Bootloader, press any key to continue...\n"
msgend:
kern: .asciz "Loading Kernel...\n"
kernend:
error: .asciz "Error loading kernel, press any key to reboot (ERR): "
errorend:
STRING:
	.org .+6
STRINGEND:
TABLE:
	.asciz "0123456789ABCDEF"

.org 446
#db 0
PART_1:
	.org .+16
PART_2:
	.org .+16
PART_3:
	.org .+16
PART_4:
	.org .+16
/*; MBR Boot Signature */
.word 0xaa55
/*; Note - Little endian 0xaa55 =~ 0x55aa */
