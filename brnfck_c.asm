.model tiny
.data
    fileName DB 20 dup(?)
    tape DW 10000 dup(?)                ; Tape of chars
    readBuffer DB 10000 dup(?)          ; Buffer for reading BF code
.code
ORG 0100h
start:
    lea di, fileName                    ; Load effective address of fileName buffer into DI
    mov si, 82h                         ; Start after the command length byte

parse_filename:
    lodsb                               ; Load byte at DS:SI into AL, increment SI
    cmp al, 0Dh
    je short finished_parsing
    stosb                               ; Store AL into ES:DI, increment DI
    jmp short parse_filename

finished_parsing:
    xor al, al                          ; Null terminator
    stosb

    ; Now, attempt to open the file
    mov ah, 3Dh
    lea dx, fileName                    ; DX points to the file name
    int 21h
    push ax

    mov ax, cs
    mov ds, ax
    
    mov cx, 10000
    lea bx, readBuffer
    xor ax, ax
clearTapeLoop:
    mov [bx], ax
    inc bx
    inc bx
    loop clearTapeLoop

    ; Read BF code into buffer
    mov ah, 3Fh
    pop bx
    lea dx, readBuffer
    mov cx, 10000
    int 21h

    lea bx, tape
    xor ax, ax
clearTapeLoop1:
    mov [bx], ax
    inc bx
    inc bx
    loop clearTapeLoop1

    ;link code to si
    lea si, readBuffer  

    ; Close file
    mov ah, 3Eh         
    int 21h

    lea di, tape

read_code:
    mov al, [si]                        ; Load current Command into AL
    cmp al, 0                           ; Check end of the code
    je short done

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
    mov bx, 0                           ; stdin handle
    mov cx, 1                           ; 1 byte to read
    lea dx, [di]                        ; buffer to read into
    int 21h                             ; read into buffer
    or ax, 0                            ; Check if the number of bytes read is 0 (EOF)
    jnz short next_command              ; If EOF, handle it specifically
    mov word ptr [di], 0FFFFh           ; EOF
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

done:
    mov ax, 4C00h
    int 21h
    
start_loop:
    cmp word ptr [di], 0
    jz  find_matching_bracket_forward   ; If zero, we need to find the matching closing bracket
    jmp next_command                    ; Otherwise, just proceed

find_matching_bracket_forward:
    mov cx, 1                           ; Level of nesting, starting with 1 for the current loop
    jmp forward_search_loop

forward_search_loop:
    inc si                              ; Move to the next character
    mov al, [si]                               ; Load it into AL
    cmp al, '['
    je  increase_nesting                ; If we find another '[', increase nesting level
    cmp al, ']'
    je  decrease_nesting                ; If we find a ']', decrease nesting level and check if it's the matching one
    jmp forward_search_loop             ; Continue searching forward

increase_nesting:
    inc cx                              ; Increase nesting level
    jmp forward_search_loop

decrease_nesting:
    dec cx                              ; Decrease nesting level
    jnz forward_search_loop             ; If CX != 0, we're still inside nested loops
    jmp next_command                    ; Found the matching ']', continue execution
end_loop:
    cmp word ptr [di], 0
    jne find_matching_bracket_backward  ; If nonzero, we need to find the matching opening bracket
    jmp next_command                    ; Otherwise, just proceed

find_matching_bracket_backward:
    mov cx, 1                           ; Level of nesting, starting with 1 for the current loop
    jmp backward_search_loop

backward_search_loop:
    dec si                              ; Move to the previous character
    mov al, [si]                              ; Load it into AL
    cmp al, ']'
    je  increase_nesting_backward       ; If we find another ']', increase nesting level
    cmp al, '['
    je  decrease_nesting_backward       ; If we find a '[', decrease nesting level and check if it's the matching one
    jmp backward_search_loop            ; Continue searching backward

increase_nesting_backward:
    inc cx                              ; Increase nesting level
    jmp backward_search_loop

decrease_nesting_backward:
    dec cx                              ; Decrease nesting level
    jnz backward_search_loop            ; If CX != 0, we're still inside nested loops
    jmp next_command                    ; Found the matching '[', continue execution
end start