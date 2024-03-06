.model tiny
.data
    bfcode db '+.' , '$'  ; Some default code
    tape db 10000 dup(?)  ; Tape of chars

.code
ORG 0100h
start:
    mov ax, cs
    mov ds, ax

    lea si, bfcode  ; Current pos in bf code
    lea bx, tape  ; Current pos on tape

read_code:
    mov al, [si]  ; Load current Command into AL
    cmp al, 0  ; Check end of the code
    je done

    ; dp++
    cmp al, '>'
    jne check_decrement_pointer
    inc bx
    jmp short next_command

check_decrement_pointer:
    ; dp--
    cmp al, '<'
    jne check_increment_data
    dec bx
    jmp short next_command

check_increment_data:
    ; data[dp]++
    cmp al, '+'
    jne check_decrement_data
    inc byte ptr [bx]
    jmp short next_command

check_decrement_data:
    ; data[dp]--
    cmp al, '-'
    jne check_output
    dec byte ptr [bx]
    jmp short next_command

check_output:
    ; print char
    cmp al, '.'
    jne check_input
    mov dl, [bx]
    mov ah, 02h  ; Display output
    int 21h
    jmp short next_command

check_input:
    ; read char
    cmp al, ','
    jne check_loop_begin
    mov ah, 01h  ; Read input
    int 21h
    mov [bx], al
    jmp short next_command

check_loop_begin:
    cmp al, '['
    je start_loop
    jne check_loop_end
    ; loop begin

check_loop_end:
    cmp al, ']'
    je end_loop
    jne next_command
    ; loop end

next_command:
    inc si
    jmp short read_code

done:
    mov ax, 4C00h
    int 21h
    
start_loop:
    cmp byte ptr [bx], 0
    jne loop_continue
    mov cx, 1
find_matching_bracket:
    inc si
    mov al, [si]
    cmp al, '['
    je inc_cx
    cmp al, ']'
    je dec_cx
    jnz find_matching_bracket
    jmp read_code

inc_cx:
    inc cx
    jmp find_matching_bracket

dec_cx:
    dec cx
    jnz find_matching_bracket
    jmp read_code

loop_continue:
    jmp next_command

end_loop:
    cmp byte ptr [bx], 0
    je next_command
    mov cx, 1
find_matching_open_bracket:
    dec si
    mov al, [si]
    cmp al, ']'
    je inc_cx_end
    cmp al, '['
    je dec_cx_end
    jnz find_matching_open_bracket
    jmp start_loop

inc_cx_end:
    inc cx
    jmp find_matching_open_bracket

dec_cx_end:
    dec cx
    jnz find_matching_open_bracket
    jmp start_loop
end start