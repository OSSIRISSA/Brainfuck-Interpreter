.model tiny
.code
ORG 0100h
start:
        mov bx, ds:[80h]                                ;--------init-------
        xor bh, bh
        and [bx+81h], bh
        xor bl, bl

        mov ah, 3Dh                                     ;-----open-file-----
        mov dx, 82h                                     ; DX points to the file name
        int 21h
        xchg bx, ax

        mov cx, 25000                                   ;----init-with-0----
        push cx
        mov di, 1000
        push di
        rep stosb

        pop di                                          ;set char tape buffer

        mov ah, 3Fh                                     ;------read-bf------
        pop cx
        mov dx, cx
        mov si, dx                                     ; set brainfuck code buffer
        int 21h
                                        
        xor bx, bx                                      ; BX must be 0 for ands, ors and stdin handle. Immutable

        read_code:
                mov cx, 1                               ; CX must have 1 in it every iteration, used in input and loops
                lodsb                                   ; Load command into AL
                or al, al                               ; End of the code
                jz short end

                cmp al, '>'                             ;------(dp++)-------
                jne short check_decrement_pointer
                inc di
                inc di

        check_decrement_pointer:                        ;------(dp--)-------
                cmp al, '<'
                jne short check_loop_begin
                dec di
                dec di

        check_loop_begin:                               ;----loop-begin-----
                cmp al, '['
                je short start_loop

        check_loop_end:                                 ;-----loop-end------
                cmp al, ']'
                je short end_loop

        check_increment_data:                           ;---(data[dp]++)----
                sub al, '+'
                jnz short check_input
                inc word ptr [di]

        check_input:                                    ;-----read-char-----
                dec al
                jnz short check_decrement_data
                mov ah, 3Fh
                and [di], bx                            ; set cell to 0 (bx is allways 0)
                lea dx, [di]                            
                int 21h                                 
                xor al, cl                              ; if 0 bytes read -> xor 0, 1 -> next label decrements pointer to FFFFh, else xor 1,1 -> 0 -> next label doesn't trigger

        check_decrement_data:                           ;---(data[dp]--)----
                dec al
                jnz short check_output
                dec word ptr [di]

        check_output:                                   ;----print-char-----
                dec al
                jnz short read_code
                cmp byte ptr [di], 0Dh
                jz short read_code
                mov ah, 02h 
                cmp byte ptr [di], 0Ah
                jne short print_char
                mov dx, 0Dh
                int 21h
        print_char:
                mov dx, [di]
                int 21h
                jmp read_code

        end: ret

        end_loop:                                       ;------loops--------
                pop si

        start_loop:
                push si
                or [di], bx
                jnz short read_code
                pop si
                search_loop:
                        lodsb                           ; Load into AL
                        cmp al, '['
                        jne short second_part           ; If find '[', nesting++
                        inc cx
                second_part:
                        cmp al, ']'
                        jne short search_loop           ; If !find ']', repeat nesting
                        loop short search_loop          ; If CX != 0, loop, nesting--
                jmp short read_code
end start