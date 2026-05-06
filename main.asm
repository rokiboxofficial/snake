org	0x100

section	.text
	mov	word [k_hdl_a], key
	mov	word [k_hdl_s], cs
	call	x_hdlr	
infinite:
	mov	al, byte [is_quit]
	test	al, 0x1
	jz	infinite
	jmp	quit

key:
	push	ax
;	xchg	bx, bx
	in	al, 0x60	

quit_check:
	cmp	al, q_code
	jne	xt_check
	mov	byte [is_quit], 0x1
	jmp	key_e

xt_check:
	cmp	al, xt_code
	jne	key_e

key_wait:
	in	al, 0x64
	test	al, 1
	jz	key_wait
	in	al, 0x60
	mov	byte [pressed], al

key_e:
	mov	al, 0x20
	out	0x20, al
	pop	ax
	iret

x_hdlr:
	xchg	bx, bx
	push	bx
	push 	di
	push	es
	push	ax

	xor	ax, ax
	mov	es, ax
	mov	di, k_vec_a
	mov	ax, word [k_hdl_a]
	mov	bx, word [k_hdl_s]
	xchg	ax, word [es:di]
	xchg	bx, word [es:di + 2]
	mov	word [k_hdl_a], ax
	mov	word [k_hdl_s], bx
	
	pop	ax
	pop 	es
	pop 	di
	pop 	bx
	ret

quit:
	call	x_hdlr
	xchg	bx, bx
	ret

section	.data
k_vec	equ	9
k_vec_a	equ	k_vec * 4
up	equ	0
left	equ	1
down	equ	2
right	equ	3
xt_code	equ	0xE0
q_code	equ	0x90

k_hdl_a	dw	0
k_hdl_s	dw	0
pressed	db	right	;up(0); left(1); down(2); right(3)
is_quit	db	0x0