section	.text

video_setup:
	push	bp
	mov	bp, sp
	push	es
	push	ds
	push	di
	push	si

	mov	cx, video_buffer_size_w
	mov	ax, video_buffer_segment
	mov	dx, ds
	mov	ds, ax
	xor	si, si
	mov	di, video_saved_buffer
	rep	movsw
	mov	ds, dx
	call	video_set_background
	call	video_set_borders
	call	video_set_welcome_frame

	pop	si
	pop	di
	pop	ds
	pop	es
	mov	sp, bp
	pop	bp
	ret

video_drop:
	push	bp
	mov	bp, sp
	push	es
	push	di
	push	si

	mov	cx, video_buffer_size_w
	mov	ax, video_buffer_segment
	mov	es, ax
	mov	si, video_saved_buffer
	xor	di, di
	rep	movsw

	pop	si
	pop	di
	pop	es
	mov	sp, bp
	pop	bp
	ret

video_set_welcome_frame:
	push	bp
	mov	bp, sp

	push	video_text_help_ptr
	push	video_text_empty_ptr
	push	video_text_welcome_ptr
	call	video_set_info
	add	sp, 6

	mov	sp, bp
	pop	bp
	ret

video_set_game_frame:
	push	bp
	mov	bp, sp

	call	video_fill_borders

	mov	sp, bp
	pop	bp
	ret

video_set_are_you_sure_frame:
	push	bp
	mov	bp, sp

	push	video_text_empty_ptr
	push	video_text_are_you_sure2_ptr
	push	video_text_are_you_sure1_ptr
	call	video_set_info
	add	sp, 6

	mov	sp, bp
	pop	bp
	ret

; -> is_win: word, score: word
video_set_game_end_frame:
	push	bp
	mov	bp, sp
	
	push	word [bp + 6]
	call	video_set_score_text
	add	sp, 2

	push	video_text_help_ptr
	push	video_text_score_ptr
	
	mov	ax, [bp + 4]
	cmp	ax, 1
	je	video_set_game_end_frame_win
	push	video_text_lose_ptr
	jmp	video_set_game_end_frame_set_info
video_set_game_end_frame_win:
	push	video_text_win_ptr
video_set_game_end_frame_set_info:
	call	video_set_info
	add	sp, 6

	mov	sp, bp
	pop	bp
	ret

; -> score: word
video_set_score_text:
	push	bp
	mov	bp, sp
	push	di
	push	si

	mov	cx, video_text_score_format_len
	mov	di, video_text_score_ascii
	mov	si, video_text_score_format_ascii
	rep	movsb

	mov	ax, [bp + 4]
	xor	di, di
video_set_score_text_tostring_loop:
	cmp	ax, 0
	jng	video_set_score_text_tostring_epilog
	mov	bx, 10
	xor	dx, dx
	div	bx
	add	dx, '0'
	push	dx
	inc	di
	jmp	video_set_score_text_tostring_loop
video_set_score_text_tostring_epilog:
	cmp	di, 0
	jne	video_set_score_text_copy_prolog
	push	0
	mov	di, 1
video_set_score_text_copy_prolog:
	mov	cx, di
video_set_score_text_copy_loop:
	mov	bx, di
	sub	bx, cx
	pop	ax
	mov	[video_text_score_format_len + video_text_score_ascii + bx], al
	loop	video_set_score_text_copy_loop

	mov	ax, di
	add	ax, video_text_score_format_len
	mov	byte [video_text_score_ptr], al
	mov	ax, video_text_score_ascii
	mov	word [video_text_score_ptr + 1], ax

	pop	si
	pop	di
	mov	sp, bp
	pop	bp
	ret

; -> text1, text2, text3 :string_ptr
; string_ptr is (length: word, ascii: bytes)
video_set_info:
	push	bp
	mov	bp, sp
	
	call	video_fill_borders

	push	video_text1_padding_top
	push	word [bp+ 4]
	call	video_set_text
	add	sp, 4

	push	video_text2_padding_top
	push	word [bp + 6]
	call	video_set_text
	add	sp, 4

	push	video_text3_padding_top
	push	word [bp + 8]
	call	video_set_text
	add	sp, 4

	mov	sp, bp
	pop	bp
	ret

; word apple_xy, word snake_len, word board_offset
video_draw_snake_and_apple:
	push	bp
	mov	bp, sp
	push	di

	push	word [bp + 4]
	call 	video_set_apple_tile
	add	sp, 2
	mov	cx, word [bp + 6]
	mov	bx, word [bp + 8]
	mov	dx, cx
video_draw_snake_and_apple_loop:
	mov	di, dx
	sub	di, cx
	shl	di, 1
	mov	ax, word [bx + di]
	push	cx
	push	bx
	push	dx	
	push	ax
	call 	video_set_snake_tile
	add	sp, 2
	pop	dx
	pop	bx
	pop	cx
	loop	video_draw_snake_and_apple_loop

	pop	di
	mov	sp, bp
	pop	bp
	ret

; -> [yx]
video_set_snake_tile:
	push	bp
	mov	bp, sp

	push	video_snake_attr
	push	word [bp + 4]
	call	video_set_tile
	add	sp, 4 

	mov	sp, bp
	pop	bp
	ret

; -> [yx]
video_unset_snake_tile:
	push	bp
	mov	bp, sp

	mov	ax, video_border_fill_word
	mov	al, ah
	xor	ah, ah
	push	ax
	push	word [bp + 4]
	call	video_set_tile
	add	sp, 4

	mov	sp, bp
	pop	bp
	ret

; -> [yx]
video_set_apple_tile:
	push	bp
	mov	bp, sp

	push	video_apple_attr
	push	word [bp + 4]
	call	video_set_tile
	add	sp, 4

	mov	sp, bp
	pop	bp
	ret

; -> [yx], video_attr
video_set_tile:
	push	bp
	mov	bp, sp
	push	di
	push	es

	mov	ax, word [bp + 4]
	mov	al, ah
	xor	ah, ah
	mov	di, video_buffer_width * 2
	mul	di
	mov	di, ax
	add	di, video_border_offset + 2 + (video_buffer_width * 2)
	mov	ax, word [bp + 4]
	xor	ah, ah
	shl	al, 1
	add	di, ax
	mov	ax, video_buffer_segment
	mov	es, ax
	mov	ax, [bp + 6]
	mov	byte [es:di + 1], al	

	pop	es
	pop	di
	mov	sp, bp
	pop	bp
	ret

video_fill_borders:
	push	bp
	mov	bp, sp
	push	es
	push	di
	push	si

	mov	ax, video_buffer_segment
	mov	es, ax
	mov	cx, video_border_height - 2
	mov	bx, cx
video_fill_borders_loop:	
	mov	dx, bx
	sub	dx, cx	
	mov	di, video_border_offset + 2 + (video_buffer_width * 2)	
	mov	ax, video_buffer_width * 2
	mul	dx
	add	di, ax
	mov	ax, video_border_fill_word
	mov	si, cx
	mov	cx, video_border_width - 2
	rep	stosw
	mov	cx, si
	loop	video_fill_borders_loop	
	
	pop	si
	pop	di
	pop	es
	mov	sp, bp
	pop	bp
	ret

; -> text: pointer to (length: byte, string: word)
; -> top-border-padding: byte
video_set_text:
	push	bp
	mov	bp, sp
	push	es
	push	di
	push	si

	xor	ax, ax
	mov	al, video_border_width - 2
	mov	bx, word [bp + 4]
	cmp	byte [bx], 0
	je	video_set_text_end
	sub	al, byte [bx]
	and	al, 0b11111110
	mov	di, ax	
	add	di, video_border_offset + 2 + (video_buffer_width * 2)
	mov	ax, video_buffer_width * 2
	mov	dl, [bp + 6]
	xor	dh, dh
	mul	dx
	add	di, ax
	mov	ax, video_buffer_segment
	mov	es, ax
	xor	cx, cx
	mov	si, word [bp + 4]
	mov	cl, byte [si]
	mov	bx, word [si + 1]
video_set_text_loop:
	mov	al, byte [bx]
	mov	[es:di], al
	add	di, 2
	inc	bx	
	loop	video_set_text_loop
	
video_set_text_end:
	pop	si
	pop	di
	pop	es
	mov	sp, bp
	pop	bp
	ret

video_set_background:
	push	bp
	mov	bp, sp
	push	es
	push	di	

	mov	cx, video_buffer_size_w
	mov	ax, video_buffer_segment
	mov	es, ax
	xor	dx, dx
	mov	ax, video_background_word
	xor	di, di
	rep	stosw

	pop	di
	pop	es
	mov	sp, bp
	pop	bp
	ret

video_set_borders:
	push	bp
	mov	bp, sp

	push	video_border_offset
	call	video_set_horizontal_border
	add	sp, 2

	call	video_set_vertical_borders	

	push	video_border_offset + (video_buffer_width * 2 * (video_border_height -1))
	call	video_set_horizontal_border
	add	sp, 2

	mov	sp, bp
	pop	bp
	ret

; -> start_offset
video_set_horizontal_border:
	push	bp
	mov	bp, sp
	push	es
	push	di

	mov	di, [bp + 4]
	mov	ax, video_buffer_segment
	mov	es, ax
	mov	ax, video_border_word
	mov	cx, video_border_width
	rep	stosw

	pop	di
	pop	es
	mov	sp, bp
	pop	bp
	ret

video_set_vertical_borders:
	push	bp
	mov	bp, sp
	push	es
	push	di

	mov	ax, video_buffer_segment
	mov	es, ax	
	mov	cx, video_border_height - 2
	mov	bx, cx
video_set_vertical_borders_loop:
	mov	dx, bx
	sub	dx, cx
	mov	di, video_border_offset + (video_buffer_width * 2)
	mov	ax, video_buffer_width * 2
	mul	dx
	add	di, ax
	mov	ax, video_border_word
	mov	word [es:di], ax
	mov	word [es:di + (video_border_width - 1) * 2], ax
	loop	video_set_vertical_borders_loop

	pop	di
	pop	es
	mov	sp, bp
	pop	bp
	ret

section	.data
video_buffer_segment	equ	0xB800
video_buffer_width	equ	80
video_buffer_height	equ	25
video_buffer_size_w	equ	video_buffer_height * video_buffer_width

video_background_word	equ	0
video_border_word	equ	0b0111000000000000
video_border_fill_word	equ	0b0000011100000000
video_snake_attr	equ	0b00100000
video_apple_attr	equ	0b01000000
video_border_width	equ	22
video_border_height	equ	15
video_border_margin_h	equ	(video_buffer_width - video_border_width) / 2
video_border_margin_v	equ	(video_buffer_height - video_border_height) / 2
video_border_offset	equ	(video_buffer_width * 2) * video_border_margin_v + (video_border_margin_h * 2)

video_text1_padding_top	equ	1
video_text2_padding_top	equ	5
video_text3_padding_top	equ	10

video_text_score_format_ascii	db	"SCORE: "
video_text_score_format_len	equ	$ - video_text_score_format_ascii
video_text_score_format_ptr	db	video_text_score_format_len
				dw	video_text_score_format_ascii

video_text_lose_ascii		db	"YOU LOSE!"
video_text_lose_len		equ	$ - video_text_lose_ascii
video_text_lose_ptr		db	video_text_lose_len
				dw	video_text_lose_ascii

video_text_win_ascii		db	"YOU WIN!"
video_text_win_len		equ	$ - video_text_win_ascii
video_text_win_ptr		db	video_text_win_len
				dw	video_text_win_ascii

video_text_help_ascii		db	"(P)lay   (Q)uit"
video_text_help_len		equ	$ - video_text_help_ascii
video_text_help_ptr		db	video_text_help_len
				dw	video_text_help_ascii

video_text_welcome_ascii	db	"Snake Game"
video_text_welcome_len		equ	$ - video_text_welcome_ascii
video_text_welcome_ptr		db	video_text_welcome_len
				dw	video_text_welcome_ascii

video_text_are_you_sure1_ascii	db	"Are you sure?"
video_text_are_you_sure1_len	equ	$ - video_text_are_you_sure1_ascii
video_text_are_you_sure1_ptr	db	video_text_are_you_sure1_len
				dw	video_text_are_you_sure1_ascii

video_text_are_you_sure2_ascii	db	"(P)Continue (Q)uit"
video_text_are_you_sure2_len	equ	$ - video_text_are_you_sure2_ascii
video_text_are_you_sure2_ptr	db	video_text_are_you_sure2_len
				dw	video_text_are_you_sure2_ascii

video_text_empty_ptr		db	0

section	.bss
video_saved_buffer:	resw	video_buffer_size_w
video_text_score_ptr:	resb	3
video_text_score_ascii:	resb	10