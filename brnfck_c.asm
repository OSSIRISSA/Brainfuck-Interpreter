.model tiny
.data
    tape DW 10000 dup(?)                            ; Tape of chars
    codeBuffer DB 10000 dup(?)                      ; Buffer for reading BF code
.code
ORG 0100h
start:
    ;init
    xor bx, bx
    or bl, ds:[80h]
    add bl, 81h
    and byte ptr [bx], bh
    xor bl, bl

    mov ah, 3Dh
    mov dx, 82h                                     ; DX points to the file name
    int 21h
    xchg bx, ax
    
    ;init buffers with 0
    mov cx, 30000
    push cx
    lea di, tape
    push di
    rep stosb

    pop di                                          ;set char tape buffer

    ; Read BF code into buffer
    mov ah, 3Fh
    pop cx
    lea dx, codeBuffer
    push dx
    int 21h

    pop si                                          ;set brainfuck code buffer
    xor bx, bx                                      ; stdin handle

    read_code:
            mov cx, 1 
            lodsb                                   ; Load current Command into AL
            or al, al                               ; Check end of the code
            jnz short check_increment_pointer
            ret

    check_increment_pointer:
            ; dp++
            cmp al, '>'
            jne short check_decrement_pointer
            inc di
            inc di

    check_decrement_pointer:
            ; dp--
            cmp al, '<'
            jne short check_loop_begin
            dec di
            dec di

    check_loop_begin:
            ; loop begin
            cmp al, '['
            je short start_loop

    check_loop_end:
            ; loop end
            cmp al, ']'
            je short end_loop

    check_increment_data:
            ; data[dp]++
            sub al, '+'
            jnz short check_input
            inc word ptr [di]

    check_input:
            ; read char
            dec al
            jnz short check_decrement_data
            mov ah, 3Fh
            and word ptr [di], bx                   ; set cell to 0 (bx is allways 0)
            lea dx, [di]                            ; buffer to read into
            int 21h                                 ; read into buffer
            xor ax, cx                              ; if 0 bytes read -> xor 0, 1 -> next label decrements pointer to FFFFh

    check_decrement_data:
            ; data[dp]--
            dec al
            jnz short check_output
            dec word ptr [di]

    check_output:
            ;print char
            dec al
            jnz short read_code
            mov dx, [di]
            mov ah, 02h
            cmp dx, 0Ah
            jne short print
            push dx
            mov dx, 0Dh
            int 21h
            pop dx
        print:
            cmp dx, 0Dh
            je short read_code       
            int 21h          
            jmp short read_code

    end_loop:
            pop si

    start_loop:
            push si

            or word ptr [di], bx
            jnz short read_code
            pop si
            forward_search_loop:
                lodsb                               ; Load it into AL
                cmp al, '['
                je short increase_nesting           ; If we find another '[', increase nesting level
                cmp al, ']'
                jne short forward_search_loop           ; If we find a ']', decrease nesting level and check if it's the matching one
                loop short forward_search_loop     ; If CX != 0, we're still inside nested loops
                jmp short read_code

            increase_nesting:
                inc cx                              ; Increase nesting level
                jmp short forward_search_loop   
end start