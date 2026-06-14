section .text

rand_setup:
	push	bp
	mov	bp, sp
	push	es

;	0040:006C - @TIMER_LOW (BIOS)
	mov	ax, 0x40
	mov	es, ax
	
	mov	ax, word [es:0x6c]
	mov	word [rand_prev], ax

	pop	es
	mov	sp, bp
	pop	bp

	ret

; -> upper_bound (exclusive)
; ax <- [0;upper_bound)
rand_next:
	push	bp
	mov	bp, sp

	mov	ax, word [rand_prev]
	mov	bx, rand_lcg_a
	mul	bx
	add	ax, rand_lcg_c
	xor	dx, dx
	mov	bx, rand_lcg_m	
	div	bx
	mov	word [rand_prev], dx		
	mov	ax, dx	
	xor	dx, dx	
	div	word [bp+4]
	mov	ax, dx

	mov	sp, bp
	pop	bp
	ret


section .data
rand_lcg_m	equ	256
rand_lcg_a	equ	157
rand_lcg_c	equ	3

rand_prev	dw	0