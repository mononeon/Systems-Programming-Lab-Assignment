; =============================================================================
; PROGRAM : CAESAR.ASM
; TITLE   : 8086 MASM Simulation of Caesar Cipher (Shift = +3)
; PURPOSE :
;   a. Accept plaintext strings repeatedly in an interactive loop.
;   b. Encrypt each string using Caesar shift of +3 (letters and digits).
;   c. Decrypt each encrypted string to retrieve the original plaintext.
;   d. Terminate cleanly when the user presses ENTER on an empty line.
; TARGET  : Intel 8086 Real Mode, MS-DOS / EMU8086 / DOSBox
; =============================================================================

.model small
.stack 100h

; =============================================================================
; DATA SEGMENT: CONFIGURATION CONSTANTS, BUFFERS AND MESSAGES
; =============================================================================
.data
    ; Configuration constants: modifying these values updates the entire program
    shift_key       equ 3               ; Caesar shift distance
    alpha_mod       equ 26              ; Alphabet modulo length (A-Z, a-z)
    digit_mod       equ 10              ; Decimal digit modulo length (0-9)
    max_len         equ 64              ; Maximum buffer capacity

    ; DOS buffered keyboard input structure (INT 21h, AH=0Ah)
    ; Byte 0 : maximum capacity (64)
    ; Byte 1 : count of characters read by DOS
    ; Byte 2+: string data entered by user
    input_buf       db max_len
    actual_len      db 0
    plaintext       db max_len dup('$')

    ; Buffers for transformed strings
    encrypted_str   db max_len dup('$')
    decrypted_str   db max_len dup('$')

    ; Console prompt and labels
    title_msg       db '=== 8086 Caesar Cipher Simulator (+3 Shift) ===', 13, 10
                    db 'Enter string to transform, or press ENTER on empty line to exit.', 13, 10, '$'
    prompt_msg      db 13, 10, 'Enter plaintext string: $'

    result_header   db 13, 10, '--- Cipher Results ---', 13, 10, '$'
    lbl_plain       db 'Original Plaintext  : $'
    lbl_cipher      db 13, 10, 'Encrypted (+3 Shift): $'
    lbl_decrypt     db 13, 10, 'Decrypted Plaintext : $'
    crlf            db 13, 10, '$'

    exit_msg        db 13, 10, 'Empty input detected (ENTER pressed). Program terminated.', 13, 10, '$'

; =============================================================================
; CODE SEGMENT & MAIN EXECUTION
; =============================================================================
.code
main proc
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Display application title banner
    lea dx, title_msg
    call print_str

    ; -------------------------------------------------------------------------
    ; Main Interactive Loop: Repeatedly accept input until ENTER only is pressed
    ; -------------------------------------------------------------------------
input_loop:
    lea dx, prompt_msg
    call print_str

    ; Ensure buffer capacity byte is set prior to INT 21h, AH=0Ah
    mov input_buf, max_len
    lea dx, input_buf
    mov ah, 0ah
    int 21h

    ; Check if user pressed ENTER on an empty line (actual_len == 0)
    mov cl, actual_len
    cmp cl, 0
    je  exit_loop

    ; Terminate current string buffers with '$' for DOS INT 21h, AH=09h display
    xor bx, bx
    mov bl, actual_len
    mov plaintext[bx], '$'
    mov encrypted_str[bx], '$'
    mov decrypted_str[bx], '$'

    ; -------------------------------------------------------------------------
    ; 1. Encrypt Plaintext using Modular encrypt_char Subroutine
    ; -------------------------------------------------------------------------
    xor cx, cx
    mov cl, actual_len
    xor si, si

encrypt_loop:
    mov al, plaintext[si]
    call encrypt_char
    mov encrypted_str[si], al
    inc si
    loop encrypt_loop

    ; -------------------------------------------------------------------------
    ; 2. Decrypt Ciphertext using Modular decrypt_char Subroutine
    ; -------------------------------------------------------------------------
    xor cx, cx
    mov cl, actual_len
    xor si, si

decrypt_loop:
    mov al, encrypted_str[si]
    call decrypt_char
    mov decrypted_str[si], al
    inc si
    loop decrypt_loop

    ; -------------------------------------------------------------------------
    ; 3. Display Results for Current String
    ; -------------------------------------------------------------------------
    lea dx, result_header
    call print_str

    lea dx, lbl_plain
    call print_str
    lea dx, plaintext
    call print_str

    lea dx, lbl_cipher
    call print_str
    lea dx, encrypted_str
    call print_str

    lea dx, lbl_decrypt
    call print_str
    lea dx, decrypted_str
    call print_str

    lea dx, crlf
    call print_str

    ; Return to prompt for next input string
    jmp input_loop

    ; -------------------------------------------------------------------------
    ; 4. Exit Handler: User pressed ENTER on an empty line
    ; -------------------------------------------------------------------------
exit_loop:
    lea dx, exit_msg
    call print_str

    mov ax, 4c00h
    int 21h
main endp

; =============================================================================
; SUBROUTINE: encrypt_char
; Purpose   : Encrypts a single character in AL using configured shift_key
;             - Letters shift by (+shift_key mod alpha_mod)
;             - Digits shift by (+shift_key mod digit_mod)
;             - Non-alphanumeric symbols remain unchanged
; Inputs    : AL = character to encrypt
; Outputs   : AL = encrypted character
; Preserves : All registers except AL
; =============================================================================
encrypt_char proc
    ; Check decimal digit: '0' (30h) <= AL <= '9' (39h)
    cmp al, '0'
    jb  enc_alpha
    cmp al, '9'
    jbe enc_is_digit

enc_alpha:
    ; Check uppercase letter: 'A' <= AL <= 'Z'
    cmp al, 'A'
    jb  enc_done
    cmp al, 'Z'
    jbe enc_is_upper

    ; Check lowercase letter: 'a' <= AL <= 'z'
    cmp al, 'a'
    jb  enc_done
    cmp al, 'z'
    ja  enc_done

enc_is_lower:
    add al, shift_key
    cmp al, 'z'
    jbe enc_done
    sub al, alpha_mod
    ret

enc_is_upper:
    add al, shift_key
    cmp al, 'Z'
    jbe enc_done
    sub al, alpha_mod
    ret

enc_is_digit:
    add al, shift_key
    cmp al, '9'
    jbe enc_done
    sub al, digit_mod

enc_done:
    ret
encrypt_char endp

; =============================================================================
; SUBROUTINE: decrypt_char
; Purpose   : Decrypts a single character in AL by reversing shift_key
;             - Letters shift by (-shift_key mod alpha_mod)
;             - Digits shift by (-shift_key mod digit_mod)
;             - Non-alphanumeric symbols remain unchanged
; Inputs    : AL = character to decrypt
; Outputs   : AL = decrypted character
; Preserves : All registers except AL
; =============================================================================
decrypt_char proc
    ; Check decimal digit: '0' (30h) <= AL <= '9' (39h)
    cmp al, '0'
    jb  dec_alpha
    cmp al, '9'
    jbe dec_is_digit

dec_alpha:
    ; Check uppercase letter: 'A' <= AL <= 'Z'
    cmp al, 'A'
    jb  dec_done
    cmp al, 'Z'
    jbe dec_is_upper

    ; Check lowercase letter: 'a' <= AL <= 'z'
    cmp al, 'a'
    jb  dec_done
    cmp al, 'z'
    ja  dec_done

dec_is_lower:
    sub al, shift_key
    cmp al, 'a'
    jae dec_done
    add al, alpha_mod
    ret

dec_is_upper:
    sub al, shift_key
    cmp al, 'A'
    jae dec_done
    add al, alpha_mod
    ret

dec_is_digit:
    sub al, shift_key
    cmp al, '0'
    jae dec_done
    add al, digit_mod

dec_done:
    ret
decrypt_char endp

; =============================================================================
; SUBROUTINE: print_str
; Purpose   : Writes a '$'-terminated string to standard output (DOS AH=09h)
; Inputs    : DS:DX = pointer to string
; Preserves : AX
; =============================================================================
print_str proc
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
print_str endp

end main
