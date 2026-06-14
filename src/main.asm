        org 0x100

        %include "macros.asm"

        section .text
        push word direction_back
        push word is_play
        push word is_quit
        push word direction
        call keyboard_setup
        add sp, 8
        call video_setup

main_welcome_loop:
        hlt
        cmp byte [is_play], 1
        je main_game
        cmp byte [is_quit], 1
        je main_drop
        jmp main_welcome_loop

main_game:
        mov byte [state], 0
        mov byte [direction], right
        mov byte [direction_back], left
        call video_set_game_frame
        call rand_setup
        push word direction_back
        push word state
        push word direction
        push word video_set_apple_tile
        push word video_unset_snake_tile
        push word video_set_snake_tile
        call game_setup
        add sp, 12
        call game_spawn_apple
main_game_loop_prolog:
        call video_fill_borders
        push game_board
        push word [game_snake_len]
        push word [game_apple_yx]
        call video_draw_snake_and_apple
        add sp, 6
main_game_loop:
; BIOS WAIT - wait CX,DX microseconds
        mov ah, 0x86
        mov cx, 0x07                   ; 0.5 second
        mov dx, 0xA120
        int 0x15

        push word [game_snake_len]
        call game_snake_move
        pop ax
        cmp byte [state], 0

        jne main_end_of_game
        cmp ax, word [game_snake_len]
        je main_game_loop_continue
        call game_spawn_apple

main_game_loop_continue:
        mov al, byte [is_quit]
        test al, 0x1
        jz main_game_loop
        jmp main_are_you_sure

main_are_you_sure:
        call video_set_are_you_sure_frame
        mov byte [is_quit], 0
        mov byte [is_play], 0
main_are_you_sure_loop:
        hlt
        cmp byte [is_quit], 1
        je main_drop
        cmp byte [is_play], 1
        je main_game_loop_prolog
        jmp main_are_you_sure_loop

main_end_of_game:
        push word [game_snake_len]
        xor ax, ax
        mov al, [state]
        and al, 1
        push ax
        call video_set_game_end_frame
        add sp, 4
        mov byte [is_quit], 0
        mov byte [is_play], 0
main_end_of_game_loop:
        hlt
        mov al, byte [is_quit]
        cmp al, 0x1
        je main_drop
        mov al, byte [is_play]
        cmp al, 0x1
        je main_game
        jmp main_end_of_game_loop

main_drop:
        call keyboard_drop
        call video_drop
        ret

        section .data
        up equ 0
        left equ 1
        down equ 2
        right equ 3
direction:
        db right                       ; up(0); left(1); down(2); right(3)
direction_back:
        db left
is_quit:
        db 0x0
is_play:
        db 0x0
state:
        db 0x0                         ; 0 - running; 1 - win; 2 - lose

        %include "keyboard.asm"
        %include "video.asm"
        %include "game.asm"
