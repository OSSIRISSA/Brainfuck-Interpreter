.model tiny
.data
    tape DW 10000 dup(?)                    ; Tape of chars
    readBuffer DB 10000 dup(?)              ; Buffer for reading BF code
.code
ORG 0100h
start:
    xor si, si                              ; Start after the command length byte
    parse_filename:
        lodsb
        cmp al, 0Dh
        jne try
        mov byte ptr [si-1], 0
    try:   
        mov ah, 3Dh
        mov dx, 82h                         ; DX points to the file name
        int 21h
        jc parse_filename
        push ax
    
        ;init buffers with 0
        mov cx, 30000
        push cx
        lea di, tape
        xor ax, ax
        rep stosb

        ; Read BF code into buffer
        mov ah, 3Fh
        pop cx
        pop bx
        lea dx, readBuffer
        int 21h

        lea si, readBuffer  
        lea di, tape
        ; Close file
        ;mov ah, 3Eh         
        ;int 21h
    read_code:
        mov al, [si]                        ; Load current Command into AL
        ;inc si
        or al, al                           ; Check end of the code
        jnz short check_increment_pointer
        ret

    check_increment_pointer:
        ; dp++
        cmp al, '>'
        jne short check_decrement_pointer
        inc di
        inc di
        jmp short next_command

    check_decrement_pointer:
        ; dp--
        cmp al, '<'
        jne short check_increment_data
        dec di
        dec di
        jmp short next_command

    check_increment_data:
        ; data[dp]++
        cmp al, '+'
        jne short check_decrement_data
        inc word ptr [di]
        jmp short next_command

    check_decrement_data:
        ; data[dp]--
        cmp al, '-'
        jne short check_output
        dec word ptr [di]
        jmp short next_command

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
        je next_command
        mov ah, 02h         
        int 21h          
        jmp short next_command

    check_input:
        ; read char
        cmp al, ','
        jne short check_loop_begin
        mov ah, 3Fh
        xor bx, bx                           ; stdin handle
        mov cx, 1                           ; 1 byte to read
        and word ptr [di], bx
        lea dx, [di]                        ; buffer to read into
        int 21h                             ; read into buffer
        or ax, ax                           ; Check if the number of bytes read is 0 (EOF)
        jnz short next_command              ; If EOF, handle it specifically
        dec word ptr [di]                   ; EOF
        jmp short next_command

    check_loop_begin:
        ; loop begin
        cmp al, '['
        je short start_loop

    check_loop_end:
        ; loop end
        cmp al, ']'
        je short end_loop

    next_command:
        inc si
        jmp short read_code
    
    end_loop:
        pop si

    start_loop:
        push si

        or word ptr [di], 0
        jnz  next_command
        pop si
        mov cx, 1                           ; Level of nesting, starting with 1 for the current loop
        forward_search_loop:
            inc si                          ; Move to the next character
            mov al, [si]                    ; Load it into AL
            cmp al, '['
            je  increase_nesting            ; If we find another '[', increase nesting level
            cmp al, ']'
            je  decrease_nesting            ; If we find a ']', decrease nesting level and check if it's the matching one
            jmp forward_search_loop         ; Continue searching forward

        increase_nesting:
            inc cx                          ; Increase nesting level
            jmp forward_search_loop

        decrease_nesting:
            dec cx                          ; Decrease nesting level
            jnz forward_search_loop         ; If CX != 0, we're still inside nested loops
            jmp next_command                ; Found the matching ']', continue execution
end start