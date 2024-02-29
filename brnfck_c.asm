.model tiny
.data
    tape db 10000 dup(0)  ; Tape of chars
    bfcode db ',+++.' , '$'  ; Some default code

.code
org 100h
start:
    ;mov ax, @data
    ;mov ds, ax

    lea bx, tape  ; Current pos on tape
    lea si, bfcode  ; Current pos in code

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
    jne check_loop_end
    ; loop begin

check_loop_end:
    cmp al, ']'
    jne next_command
    ; loop end

next_command:
    inc si
    jmp short read_code

done:
    mov ax, 4C00h
    int 21h

end start