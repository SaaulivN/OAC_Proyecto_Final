.386
.model flat, c

DIRECTION_UP    equ 0
DIRECTION_DOWN  equ 1
DIRECTION_LEFT  equ 2
DIRECTION_RIGHT equ 3

.code

game_init PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    mov esi, [ebp + 8]
    xor edi, edi
    mov eax, [ebp + 12]
    mov ebx, [ebp + 16]
    
    mov [esi + 0], eax
    mov [esi + 4], ebx
    ; -----------------------------------------------------------------------
    mov dword ptr [esi + 8], 100  ; Puntuacion
    ; -----------------------------------------------------------------------
    mov dword ptr [esi + 12], 0
    
    shr eax, 1
    shr ebx, 1
    mov [esi + 16], eax
    mov [esi + 20], ebx
    
    mov dword ptr [esi + 24], 2
    mov dword ptr [esi + 28], 2
    ; -----------------------------------------------------------------------
    mov dword ptr [esi + 32], 0 ; Longitud_Inicial
    ; -----------------------------------------------------------------------
    mov dword ptr [esi + 36], DIRECTION_RIGHT
    mov dword ptr [esi + 40], DIRECTION_RIGHT

    mov eax, [esi + 16]
    mov ebx, [esi + 20]

    mov byte ptr [esi + 44], al
    mov byte ptr [esi + 45], bl

    mov al, [esi + 16]
    sub al, 1
    mov byte ptr [esi + 46], al
    mov byte ptr [esi + 47], bl

    mov al, [esi + 16]
    sub al, 2
    mov byte ptr [esi + 48], al
    mov byte ptr [esi + 49], bl
    
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
game_init ENDP

game_tick PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    
    mov esi, [ebp + 8]
    
    cmp dword ptr [esi + 12], 0
    jne tick_done
    
    mov eax, [esi + 40]
    mov [esi + 36], eax
    
    mov eax, [esi + 16]
    mov ebx, [esi + 20]
    
    mov ecx, [esi + 36]
    
    cmp ecx, DIRECTION_UP
    je tick_move_up
    cmp ecx, DIRECTION_DOWN
    je tick_move_down
    cmp ecx, DIRECTION_LEFT
    je tick_move_left
    cmp ecx, DIRECTION_RIGHT
    je tick_move_right
    jmp tick_check_bounds
    
tick_move_up:
    dec dword ptr [esi + 20]
    jmp tick_check_bounds
    
tick_move_down:
    inc dword ptr [esi + 20]
    jmp tick_check_bounds
    
tick_move_left:
    dec dword ptr [esi + 16]
    jmp tick_check_bounds
    
tick_move_right:
    inc dword ptr [esi + 16]
    
tick_check_bounds:
    mov eax, [esi + 16]
    mov ebx, [esi + 20]
    
    cmp eax, 0
    jl tick_game_over
    mov ecx, [esi + 0]
    cmp eax, ecx
    jge tick_game_over
    
    cmp ebx, 0
    jl tick_game_over
    mov ecx, [esi + 4]
    cmp ebx, ecx
    jge tick_game_over
    
    xor edi, edi
    mov eax, [esi + 16]
    mov ebx, [esi + 20]

    cmp eax, [esi + 24]
    jne tick_no_food
    cmp ebx, [esi + 28]
    jne tick_no_food
    
    inc dword ptr [esi + 8]
    mov edi, 1
    
    mov eax, [esi + 24]
    add eax, 3
    mov ecx, [esi + 0]
    xor edx, edx
    cmp eax, ecx
    jl food_x_ok
    mov eax, 2
food_x_ok:
    mov [esi + 24], eax
    
    mov eax, [esi + 28]
    add eax, 3
    mov ecx, [esi + 4]
    cmp eax, ecx
    jl food_y_ok
    mov eax, 2
food_y_ok:
    mov [esi + 28], eax
    
tick_no_food:
    mov eax, [esi + 32]
    cmp eax, 300
    jge tick_body_ok

    cmp eax, 0
    je after_shift

    mov ecx, eax
    dec ecx
    cmp ecx, 0
    jl shift_done
shift_loop:
    mov edx, ecx
    shl edx, 1
    add edx, 44
    mov al, byte ptr [esi + edx]
    mov byte ptr [esi + edx + 2], al
    mov al, byte ptr [esi + edx + 1]
    mov byte ptr [esi + edx + 3], al
    cmp ecx, 0
    je shift_done
    dec ecx
    jmp shift_loop
shift_done:

    mov al, byte ptr [esi + 16]
    mov byte ptr [esi + 44], al
    mov al, byte ptr [esi + 20]
    mov byte ptr [esi + 45], al

after_shift:
    cmp edi, 1
    jne tick_body_ok
    inc dword ptr [esi + 32]

    jmp tick_body_ok
    
tick_body_ok:
    jmp tick_done
    
tick_game_over:
    mov dword ptr [esi + 12], 1
    
tick_done:
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
game_tick ENDP

game_set_input PROC
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 8]
    mov ecx, [ebp + 12]
    
    mov edx, [eax + 36]
    
    mov eax, edx
    xor eax, ecx
    cmp eax, 1
    je input_invalid
    
    mov eax, [ebp + 8]
    mov [eax + 40], ecx
    
input_invalid:
    pop ebp
    ret
game_set_input ENDP

game_get_score PROC
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 8]
    mov eax, [eax + 8]
    
    pop ebp
    ret
game_get_score ENDP

game_is_game_over PROC
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 8]
    mov eax, [eax + 12]
    
    pop ebp
    ret
game_is_game_over ENDP

END