; =============================================================================
; PROGRAM : CAESAR.ASM
; TITLE   : 8086 MASM Simulation of Caesar Cipher (Shift = +3)
; PURPOSE :
;   a. Accept plaintext strings repeatedly in an interactive loop.
;   b. Full backspace support: user can edit/backspace typed characters,
;      while preventing backspacing past the prompt.
;   c. Encrypt each string using Caesar shift of +3 (letters and digits).
;   d. Decrypt each encrypted string to retrieve the original plaintext.
;   e. Terminate cleanly when the user presses ENTER on an empty line.
; TARGET  : Intel 8086 Real Mode, MS-DOS / EMU8086 / DOSBox
; =============================================================================

.model small
.stack 100h

; =============================================================================
; DATA SEGMENT: CONFIGURATION CONSTANTS, BUFFERS AND MESSAGES
; =============================================================================
.data
    ; Configuration constants: changing shift_key updates the entire cipher
    shift_key       equ 3               ; Caesar shift distance
    alpha_mod       equ 26              ; Alphabet modulo length (A-Z, a-z)
    digit_mod       equ 10              ; Decimal digit modulo length (0-9)
    max_len         equ 64              ; Maximum buffer capacity

    actual_len      db 0
    plaintext       db max_len dup('$')
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

    ; Read user input with full backspace support
    call read_string

    ; Check if user pressed ENTER on an empty line (actual_len == 0)
    mov cl, actual_len
    cmp cl, 0
    je  exit_loop

    ; Terminate transformed string buffers with '$' for DOS INT 21h, AH=09h
    xor bx, bx
    mov bl, actual_len
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
; SUBROUTINE: read_string
; Purpose   : Reads a string from console via BIOS INT 16h with real-time echo
;             and full Backspace editing. Prevents backspacing past the prompt.
; Outputs   : actual_len = count of characters entered
;             plaintext  = '$'-terminated ASCII string
; Preserves : AX, BX, DX, SI
; =============================================================================
read_string proc
    push ax
    push bx
    push dx
    push si

    xor si, si                          ; SI = current character count

read_char_loop:
    ; Read key without waiting/echo (BIOS INT 16h, AH=00h)
    mov ah, 00h
    int 16h                             ; AL = ASCII code

    ; Check for Enter key (ASCII 13 = 0Dh)
    cmp al, 13
    je  read_done

    ; Check for Backspace key (ASCII 8 = 08h)
    cmp al, 8
    je  handle_backspace

    ; Normal character: ensure buffer limit is not exceeded
    cmp si, max_len - 1
    jae read_char_loop                  ; Buffer full: ignore key

    ; Store character in plaintext buffer
    mov plaintext[si], al
    inc si

    ; Echo typed character to screen (DOS INT 21h, AH=02h)
    mov dl, al
    mov ah, 02h
    int 21h
    jmp read_char_loop

handle_backspace:
    ; Guard: Do not allow backspacing past the beginning of the prompt!
    cmp si, 0
    je  read_char_loop

    ; Decrement character count
    dec si

    ; Visual erase on console: Backspace, Space, Backspace
    mov ah, 02h
    mov dl, 8
    int 21h
    mov dl, ' '
    int 21h
    mov dl, 8
    int 21h
    jmp read_char_loop

read_done:
    ; Record actual length
    mov ax, si
    mov actual_len, al

    ; Terminate plaintext with '$'
    mov plaintext[si], '$'

    pop si
    pop dx
    pop bx
    pop ax
    ret
read_string endp

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
