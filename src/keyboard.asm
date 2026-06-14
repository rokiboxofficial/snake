        section .text

; -> direction_pointer; is_quit_pointer; is_play_pointer;
; -> direction_back_pointer
; set direction: up(0); left(1); down(2); right(3) (arrows, no wasd)
; set is_quit when 'q' is pressed
; set custom keyboard vector handler
keyboard_setup:
        push bp
        mov bp, sp

        mov ax, [bp + 4]
        mov word [keyboard_direction_ptr], ax
        mov ax, [bp + 6]
        mov word [keyboard_is_quit_ptr], ax
        mov ax, [bp + 8]
        mov word [keyboard_is_play_ptr], ax
        mov ax, [bp + 10]
        mov word [keyboard_direction_back_ptr], ax

        mov word [keyboard_handler_offset], keyboard_key_press_handler
        mov word [keyboard_handler_segment], cs
        call keyboard_exchange_handlers

        mov sp, bp
        pop bp
        ret

; set default keyboard vector handler
keyboard_drop:
        call keyboard_exchange_handlers
        ret

; exchange cs:offset in keyboard vector
; with keyboard_handler_segmeent:heyboard_handler_offset
keyboard_exchange_handlers:
        push bp
        mov bp, sp
        push di
        push es

        xor ax, ax
        mov es, ax
        mov di, keyboard_ctrl_vector_offset
        mov ax, word [keyboard_handler_offset]
        mov bx, word [keyboard_handler_segment]
        xchg ax, word [es:di]
        xchg bx, word [es:di + 2]
        mov word [keyboard_handler_offset], ax
        mov word [keyboard_handler_segment], bx

        pop es
        pop di
        mov sp, bp
        pop bp

        ret

keyboard_key_press_handler:
        push ax
        push bx
        in al, keyboard_ctrl_out_buf

keyboard_play_check:
        cmp al, keyboard_play_code
        jne keyboard_quit_check
        mov bx, [keyboard_is_play_ptr]
        mov byte [bx], 1
        jmp keyboard_key_press_handler_end

keyboard_quit_check:
        cmp al, keyboard_quit_code
        jne keyboard_extra_check
        mov bx, word [keyboard_is_quit_ptr]
        mov byte [bx], 1
        jmp keyboard_key_press_handler_end

keyboard_extra_check:
        cmp al, keyboard_extra_code
        jne keyboard_key_press_handler_end
keyboard_second_byte_wait:
        in al, keyboard_ctrl_status_reg
        test al, 1
        jz keyboard_second_byte_wait

        mov bx, word [keyboard_direction_back_ptr]
        in al, keyboard_ctrl_out_buf
keyboard_up_check:
        cmp al, 0x48
        jne keyboard_left_check
        cmp byte [bx], keyboard_up
        je keyboard_left_check
        jmp keyboard_set_up

keyboard_left_check:
        cmp al, 0x4B
        jne keyboard_down_check
        cmp byte [bx], keyboard_left
        je keyboard_down_check
        jmp keyboard_set_left

keyboard_down_check:
        cmp al, 0x50
        jne keyboard_right_check
        cmp byte [bx], keyboard_down
        je keyboard_right_check
        jmp keyboard_set_down

keyboard_right_check:
        cmp al, 0x4D
        jne keyboard_key_press_handler_end
        cmp byte [bx], keyboard_right
        je keyboard_key_press_handler_end
        jmp keyboard_set_right

keyboard_set_up:
        mov bx, word [keyboard_direction_ptr]
        mov byte [bx], keyboard_up
        jmp keyboard_key_press_handler_end

keyboard_set_left:
        mov bx, word [keyboard_direction_ptr]
        mov byte [bx], keyboard_left
        jmp keyboard_key_press_handler_end

keyboard_set_down:
        mov bx, word [keyboard_direction_ptr]
        mov byte [bx], keyboard_down
        jmp keyboard_key_press_handler_end

keyboard_set_right:
        mov bx, word [keyboard_direction_ptr]
        mov byte [bx], keyboard_right
        jmp keyboard_key_press_handler_end

keyboard_key_press_handler_end:
; eoi
        mov al, 0x20
        out 0x20, al
        pop bx
        pop ax
        iret

        section .data

        keyboard_ctrl_status_reg equ 0x64
        keyboard_ctrl_out_buf equ 0x60
        keyboard_ctrl_vector equ 9
        keyboard_ctrl_vector_offset equ keyboard_ctrl_vector * 4

        keyboard_up equ 0
        keyboard_left equ 1
        keyboard_down equ 2
        keyboard_right equ 3

        keyboard_extra_code equ 0xE0   ; first byte of complex scan code
        keyboard_quit_code equ 0x90    ; 'q'
        keyboard_play_code equ 0x19    ; 'p'

keyboard_handler_offset:
        dw 0
keyboard_handler_segment:
        dw 0

keyboard_direction_ptr:
        dw 0
keyboard_direction_back_ptr:
        dw 0
keyboard_is_quit_ptr:
        dw 0
keyboard_is_play_ptr:
        dw 0
