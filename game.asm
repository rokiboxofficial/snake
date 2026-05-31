section .text

; -> set_snake_tile([yx]), unset_snake_tile([yx]),
; -> set_apple_tile([yx])
; -> direction_ptr, game_state_ptr
; -> direction_back_ptr
game_setup:
	push	bp
	mov	bp, sp
	push	di

	call	game_zero_bitboard	
	mov	word [game_snake_len], 0
	mov	ax, word [bp + 4]
	mov 	word [game_set_snake_tile], ax
	mov	ax, word [bp + 6]
	mov	word [game_unset_snake_tile], ax
	mov	ax, word [bp + 8]
	mov	word [game_set_apple_tile], ax
	mov	ax, word [bp + 10]
	mov	word [game_direction_ptr], ax
	mov	ax, word [bp + 12]
	mov	word [game_state_ptr], ax
	mov	ax, word [bp + 14]
	mov	word [game_direction_back_ptr], ax

	mov	ah, game_board_height >> 1
	mov	al, 0; game_board_width >> 1 
	mov	cx, 4
	mov	dx, cx

game_setup_loop:
	mov	bx, dx
	sub	bx, cx
	shl	bx, 1
	mov	di, game_board
	mov	[di + bx], ax
	push	dx
	push	cx
	push	ax
	call	game_enter_tile
	pop	ax
	pop	cx
	pop	dx

	inc	word [game_snake_len]	
	inc	al
	loop	game_setup_loop

	pop	di
	mov	sp, bp
	pop	bp
	ret

game_snake_move:
	push	bp
	mov	bp, sp
	sub	sp, 2

	mov	bx, word [game_direction_ptr]
	xor	ax, ax
	mov	al, byte [bx]
	mov	word [bp - 2], ax

	mov	cx, word [game_snake_len]
	dec	cx

	mov	bx, cx
	shl	bx, 1
	add	bx, game_board	

	push	cx
	push	bx
	push	word [bp -2]
	push	word [bx]
	call	game_get_next
	add	sp, 4
	pop	bx
	pop	cx

	cmp	ax, [game_apple_yx]
	jne	game_snake_move_default
	inc	word [game_snake_len]
	mov	bx, cx
	inc	bx
	shl	bx, 1
	add	bx, game_board	
	jmp	game_snake_move_grow

game_snake_move_default:
	push	cx
	push	word [game_board]
	call	game_leave_tile
	add	sp, 2
	pop	cx

	mov	dx, cx
game_snake_move_loop:
	mov	bx, dx
	sub	bx, cx
	shl	bx, 1
	mov	ax, [game_board + 2 + bx]	
	mov	[game_board + bx], ax
	loop	game_snake_move_loop
	shl	dx, 1
	mov	bx, dx

	push	bx
	add	bx, game_board
	push	word [bp - 2]
	push	word [bx]
	call	game_get_next
	add	sp, 4
	pop	bx
	add	bx, game_board
game_snake_move_grow:
	mov	word [bx], ax
	
	push	ax
	call	game_snake_check_win
	pop	ax

	push	ax
	call	game_snake_check_collisions
	pop	ax

	mov	bx, word [game_state_ptr]
	cmp	byte [bx], 0
	jne	game_snake_move_end

	push	ax
	call	game_enter_tile
	pop	ax

	mov	ax, [bp - 2]
	xor	al, 0b00000010
	and	al, 0b00000011
	mov	bx, word [game_direction_back_ptr]
	mov	byte [bx], al
	mov	bx, word [game_direction_ptr]
	mov	ax, [bp - 2]
	mov	byte [bx], al

game_snake_move_end:
	mov	sp, bp
	pop	bp
	ret

game_snake_check_win:
	push	bp
	mov	bp, sp

	cmp	word [game_snake_len], game_board_width * game_board_height
	jne	game_snake_check_win_end
	mov	bx, word [game_state_ptr]
	mov	byte [bx], 1

game_snake_check_win_end:
	mov	sp, bp
	pop	bp
	ret

game_snake_check_collisions:
	push	bp
	mov	bp, sp

	mov	bx, [game_snake_len]
	dec	bx
	mov	cx, bx
	shl	bx, 1
	
	mov	ax, [game_board + bx] 
	cmp	al, 0
	jl	game_snake_check_collisions_violation
	cmp	al, game_board_width
	jge	game_snake_check_collisions_violation

	cmp	ah, 0
	jl	game_snake_check_collisions_violation
	cmp	ah, game_board_height
	jge	game_snake_check_collisions_violation

	mov	dx, cx
game_snake_check_collisions_with_snake_loop:
	mov	bx, dx
	sub	bx, cx
	shl	bx, 1
	push	dx
	mov	dx, word [game_board + bx]
	cmp	ax, dx
	pop	dx
	je	game_snake_check_collisions_violation
	loop	game_snake_check_collisions_with_snake_loop

	jmp	game_snake_check_collisions_end
game_snake_check_collisions_violation:
	mov	bx, word [game_state_ptr]
	mov	byte [bx], 2
game_snake_check_collisions_end:

	mov	sp, bp
	pop	bp
	ret

game_spawn_apple:
	push	bp
	mov	bp, sp
	sub	sp, 2
	push	di
	push	si

	mov	ax, game_board_width * game_board_height
	sub	ax, word [game_snake_len]
	
	push	ax
	call	rand_next
	add	sp, 2

	mov	di, ax
	mov	si, 0

	mov	cx, game_board_height
game_spawn_apple_height_loop:
	push	cx
	
	mov	cx, game_board_width
game_spawn_apple_width_loop:
	mov	bx, game_board_height
	;
	pop	ax
	push	ax	
	sub	bx, ax
	mov	ah, bl

	mov	bx, game_board_width
	sub	bx, cx
	mov	al, bl

	push	cx
	push	ax
	call	game_get_ordinal
	mov	[bp - 2], ax
	pop	ax
	pop	cx

	mov	dx, [game_bitboard + bx]
	test	dx, [bp - 2]	
	jnz	game_spawn_apple_width_loop_continue
	cmp	si, di
	jne	game_spawn_apple_width_loop_continue_inc
	
	mov	[game_apple_yx], ax
	push	ax
	call	[game_set_apple_tile]
	add	sp, 4
	jmp	game_spawn_apple_epilog
	
	
game_spawn_apple_width_loop_continue_inc:
	inc	si
game_spawn_apple_width_loop_continue:
	loop	game_spawn_apple_width_loop

	pop	cx
	loop	game_spawn_apple_height_loop

game_spawn_apple_epilog:
	pop	si
	pop	di
	mov	sp, bp
	pop	bp
	ret

; -> [yx]
game_enter_tile:
	push	bp
	mov	bp, sp

	push	[bp + 4]
	call	[game_set_snake_tile]
	pop	ax
	push	ax
	call	game_xor_bitboard
	add	sp, 2

	mov	sp, bp
	pop	bp
	ret

; -> [yx]
game_leave_tile:
	push	bp
	mov	bp, sp

	push	[bp + 4]
	call	[game_unset_snake_tile]
	pop	ax
	push	ax
	call	game_xor_bitboard
	add	sp, 2

	mov	sp, bp
	pop	bp
	ret
	
; -> [yx]
game_xor_bitboard:
	push	bp
	mov	bp, sp
	
	push	[bp + 4]
	call	game_get_ordinal
	add	sp, 2

	mov	cl, byte [game_bitboard + bx]
	xor	cl, al
	mov	byte [game_bitboard + bx], cl
	
	mov	sp, bp
	pop	bp
	ret

; -> [yx]
; ax = bit; bx = byte;
game_get_ordinal:
	push	bp
	mov	bp, sp

	mov	ax, [bp + 4]
	mov	al, ah
	xor	ah, ah
	mov	bx, game_board_width
	mul	bx
	
	mov	bx, [bp + 4]
	xor	bh, bh
	add	bx, ax
	mov	cx, bx
	shr	bx, 3
	and	cx, 0b00000111
	mov	dx, 1
	shl	dx, cl
	mov	ax, dx
	mov	sp, bp
	pop	bp
	ret

game_zero_bitboard:
	push	bp
	mov	bp, sp

	mov	cx, game_bitboard_len
	mov	dx, cx

game_zero_bitboard_loop:
	mov	bx, dx
	sub	bx, cx
	mov	[game_bitboard + bx], 0
	loop	game_zero_bitboard_loop

	mov	sp, bp
	pop	bp
	ret

; -> [yx], -> game_direction
; <- [yx]
game_get_next:
	push	bp
	mov	bp, sp

	mov	ax, word [bp + 4]
	mov	cx, word [bp + 6]

	cmp	cl, game_up
	je	game_get_next_set_up
	cmp	cl, game_left
	je	game_get_next_set_left
	cmp	cl, game_down
	je	game_get_next_set_down
	jmp	game_get_next_set_right

game_get_next_set_up:
	dec	ah
	jmp	game_get_next_end
game_get_next_set_left:
	dec	al
	jmp	game_get_next_end
game_get_next_set_down:
	inc	ah
	jmp	game_get_next_end
game_get_next_set_right:
	inc	al

game_get_next_end:
	mov	sp, bp
	pop	bp
	ret

section .data
game_up			equ	0
game_left		equ	1
game_down		equ	2
game_right		equ	3
game_board_width	equ	20
game_board_height	equ	13
game_set_snake_tile	dw	0
game_unset_snake_tile	dw	0
game_set_apple_tile	dw	0
game_direction_ptr	dw	0
game_direction_back_ptr	dw	0
game_state_ptr		dw	0 ; 0 - running; 1; win; 2 lose

section .bss
game_apple_yx: 		resw	1
game_snake_len: 	resw	1
game_board:		resw	game_board_width * game_board_height
game_bitboard		resb	((game_board_width * game_board_height) / 8) + 1
game_bitboard_len	resw	$ - game_bitboard

%include	"rand.asm"