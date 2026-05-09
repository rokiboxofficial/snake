org	0x100

%include	"macros.asm"

section	.text
	push	word is_quit
	push	word direction
	call	keyboard_setup
	add	sp, 4
infinite:
	mov	al, byte [is_quit]
	test	al, 0x1
	jz	infinite
	call	keyboard_drop
	ret

section	.data
up	equ	0
left	equ	1
down	equ	2
right	equ	3
direction	db	right	;up(0); left(1); down(2); right(3)
is_quit	db	0x0

%include	"keyboard.asm"