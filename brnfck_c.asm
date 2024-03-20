.model tiny
.data
    tape DW 10000 dup(?)                        ; Tape of chars
    codeBuffer DB 10000 dup(?)                  ; Buffer for reading BF code
.code
ORG 0100h
start:
    ;init
    xor bx, bx
    xor cx, cx

    or cl, ds:[80h]
    mov si, 81h
    add si, cx
    and [si], bl

    mov ah, 3Dh
    mov dx, 82h                                 ; DX points to the file name
    int 21h
    xchg bx, ax
    
    ;init buffers with 0
    mov cx, 30000
    push cx
    lea di, tape
    push di
    rep stosb

    pop di                                      ;set char tape buffer

    ; Read BF code into buffer
    mov ah, 3Fh
    pop cx
    lea dx, codeBuffer
    push dx
    int 21h

    pop si                                      ;set brainfuck code buffer
        
    read_code:
            lodsb                               ; Load current Command into AL
            or al, al                           ; Check end of the code
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
            jne short check_increment_data
            dec di
            dec di

    check_increment_data:
            ; data[dp]++
            cmp al, '+'
            jne short check_decrement_data
            inc word ptr [di]

    check_decrement_data:
            ; data[dp]--
            cmp al, '-'
            jne short check_output
            dec word ptr [di]

    check_output:
            ;print char
            cmp al, '.'
            jne short check_input
            mov dx, [di]
            cmp dx, 0Ah
            jne short print
            push dx
            mov dx, 0Dh
            mov ah, 02h 
            int 21h
            pop dx
        print:
            cmp dx, 0Dh
            je short read_code
            mov ah, 02h         
            int 21h          
            jmp short read_code

    check_input:
        ; read char
        cmp al, ','
        jne short check_loop_begin
        mov ah, 3Fh
        xor bx, bx                              ; stdin handle
        mov cx, 1                               ; 1 byte to read
        and word ptr [di], bx
        lea dx, [di]                            ; buffer to read into
        int 21h                                 ; read into buffer
        or ax, ax                               ; Check if the number of bytes read is 0 (EOF)
        jnz short read_code                     ; If EOF, handle it specifically
        dec word ptr [di]                       ; EOF

    check_loop_begin:
        ; loop begin
        cmp al, '['
        je short start_loop

    check_loop_end:
        ; loop end
        cmp al, ']'
        je short end_loop
        jmp read_code

    end_loop:
        pop si

    start_loop:
        push si

        or word ptr [di], 0
        jnz short read_code
        pop si
        mov cx, 1                               ; Level of nesting, starting with 1 for the current loop
        forward_search_loop:
            lodsb                               ; Load it into AL
            cmp al, '['
            je short increase_nesting           ; If we find another '[', increase nesting level
            cmp al, ']'
            je short decrease_nesting           ; If we find a ']', decrease nesting level and check if it's the matching one
            jmp short forward_search_loop       ; Continue searching forward

        increase_nesting:
            inc cx                              ; Increase nesting level
            jmp short forward_search_loop

        decrease_nesting:
            loop short forward_search_loop      ; If CX != 0, we're still inside nested loops
            jmp short read_code
end start