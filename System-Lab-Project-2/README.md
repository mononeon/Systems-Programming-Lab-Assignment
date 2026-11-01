# 8086 MASM Caesar Cipher (+3 Shift) Simulator: Beginner's Guide & System Reference

This document provides a complete, beginner-friendly explanation of the **8086 Assembly Language Caesar Cipher** program implemented in [`CAESAR.ASM`](CAESAR.ASM). If you are new to assembly programming, this guide explains every instruction, directive, custom subroutine, and algorithmic workflow step-by-step.

---

## Table of Contents
1. [Core Concepts of 8086 Architecture for Beginners](#1-core-concepts-of-8086-architecture-for-beginners)
2. [Command-by-Command Reference: Every Instruction & Directive Used](#2-command-by-command-reference-every-instruction--directive-used)
   - [Assembler Directives](#assembler-directives)
   - [Data Movement Instructions](#data-movement-instructions)
   - [Arithmetic & Bitwise Logic Instructions](#arithmetic--bitwise-logic-instructions)
   - [Comparison & Conditional Jump Instructions](#comparison--conditional-jump-instructions)
   - [Subroutine & Loop Control Instructions](#subroutine--loop-control-instructions)
   - [Operating System & BIOS Interrupts](#operating-system--bios-interrupts)
3. [Subroutine-by-Subroutine Explanation: Every Custom Function](#3-subroutine-by-subroutine-explanation-every-custom-function)
   - [`MAIN`](#1-main-proc)
   - [`CLEAR_SCREEN`](#2-clear_screen-proc)
   - [`WAIT_KEY`](#3-wait_key-proc)
   - [`PRINT_STR`](#4-print_str-proc)
   - [`PRINT_CHAR`](#5-print_char-proc)
   - [`PRINT_HEX_BYTE`](#6-print_hex_byte-proc)
   - [`PRINT_TRACE_ROW`](#7-print_trace_row-proc)
4. [The Complete Execution Workflow](#4-the-complete-execution-workflow)
5. [Frequently Asked Questions & Lab Viva Preparation](#5-frequently-asked-questions--lab-viva-preparation)

---

## 1. Core Concepts of 8086 Architecture for Beginners

In high-level languages like Python, C, or Java, variables live in abstract memory managed by a runtime. In 16-bit 8086 Assembly:
* **Registers** are small, ultra-fast storage boxes located directly inside the CPU chip.
* **General-Purpose Registers (16-bit):** `AX`, `BX`, `CX`, `DX`. Each can be split into two 8-bit halves:
  - `AX` $\rightarrow$ `AH` (High byte, bits 15–8) and `AL` (Low byte, bits 7–0).
  - `BX` $\rightarrow$ `BH` and `BL`.
  - `CX` $\rightarrow$ `CH` and `CL` (Often used as hardware loop counters).
  - `DX` $\rightarrow$ `DH` and `DL` (Often used for I/O and DOS interrupts).
* **Index & Pointer Registers (16-bit):**
  - `SI` (Source Index): Points to source data in memory.
  - `DI` (Destination Index): Points to target destination data.
  - `SP` (Stack Pointer): Tracks the active top of the hardware stack.
* **Segment Registers (16-bit):**
  - `DS` (Data Segment): Tells the CPU where program variables are stored.
  - `ES` (Extra Segment): Used for string and memory copy operations.
  - `CS` (Code Segment): Points to where CPU instructions reside.
  - `SS` (Stack Segment): Points to the memory allocated for stack frames.
* **The Flags Register:** Bits that change automatically when math or comparisons happen (e.g., `ZF = 1` if a result is Zero, `CF = 1` if an unsigned Carry or Borrow occurred).

---

## 2. Command-by-Command Reference: Every Instruction & Directive Used

### Assembler Directives
*These are instructions for the assembler (MASM/TASM) during build time; they do not generate machine code instructions for the CPU directly.*

| Directive | Syntax in `CAESAR.ASM` | What it Does (Plain English) |
| :--- | :--- | :--- |
| **`.MODEL`** | `.MODEL SMALL` | Tells MASM the memory layout. `SMALL` means the program uses one 64 KB segment for all code and one 64 KB segment for all data. |
| **`.STACK`** | `.STACK 100H` | Reserves 256 bytes (`100h` in hex) of memory for the stack (temporary register storage and function call return addresses). |
| **`.DATA`** | `.DATA` | Marks the beginning of the Data Segment where variables, buffers, and string constants are declared. |
| **`.CODE`** | `.CODE` | Marks the beginning of the Code Segment where actual CPU instructions reside. |
| **`EQU`** | `SHIFT_KEY EQU 3` | Defines a compile-time constant alias. Wherever `SHIFT_KEY` appears, MASM replaces it with the literal number `3` (like `#define` in C). |
| **`DB`** | `ACTUAL_LEN DB 0` | Stands for **Declare Byte** (8 bits). Allocates one or more bytes in memory initialized with the specified value. |
| **`DUP`** | `MAX_LEN DUP('$')` | Stands for **Duplicate**. Repeatedly creates copies of a value (e.g., creates 64 bytes, each filled with the character `'$'`). |
| **`PROC` / `ENDP`** | `PRINT_STR PROC ... PRINT_STR ENDP` | Defines the start and end of a procedure (subroutine or function). |
| **`END`** | `END MAIN` | Marks the very end of the assembly file and specifies `MAIN` as the starting execution address. |

---

### Data Movement Instructions

| Instruction | Example from Code | What it Does |
| :--- | :--- | :--- |
| **`MOV`** | `MOV AX, @DATA`<br>`MOV DS, AX`<br>`MOV AL, PLAINTEXT[SI]` | **Move (Copy):** Copies data from the source (right) to destination (left). Note: You cannot load an immediate address directly into segment registers like `DS`, so you load `AX` first, then copy `AX` to `DS`. |
| **`LEA`** | `LEA DX, BANNER_TOP`<br>`LEA BX, HEX_DIGITS` | **Load Effective Address:** Computes the 16-bit memory offset of a variable or label and places it into a register (like taking a pointer in C: `dx = &BANNER_TOP`). |
| **`PUSH`** | `PUSH AX`<br>`PUSH BX` | Saves the contents of a register onto the top of the stack. Used at the start of subroutines so the function can use the register without overwriting the caller's data. |
| **`POP`** | `POP BX`<br>`POP AX` | Restores the saved value from the top of the stack back into the register in reverse order (LIFO - Last In, First Out). |
| **`CLD`** | `CLD` | **Clear Direction Flag:** Sets the direction flag `DF = 0`. This ensures string instructions (like `MOVSB`) automatically increment index pointers (`SI` and `DI`) forward through memory. |
| **`REP MOVSB`** | `REP MOVSB` | **Repeat Move String Byte:** Copies `CX` bytes from memory address `DS:SI` to address `ES:DI`. After each byte copied, `SI` and `DI` increment and `CX` decrements until `CX = 0`. Used to copy the default string `"HELLO"`. |
| **`XLAT`** | `XLAT` | **Translate Byte:** Hardware table lookup instruction. Replaces the byte in `AL` with the byte located at `DS:[BX + AL]`. Used in `PRINT_HEX_BYTE` to convert `0..15` into `'0'..'F'` in a single instruction. |

---

### Arithmetic & Bitwise Logic Instructions

| Instruction | Example from Code | What it Does |
| :--- | :--- | :--- |
| **`ADD`** | `ADD AL, SHIFT_KEY` | Adds the value of `SHIFT_KEY` (`+3`) to the byte in register `AL` ($AL = AL + 3$). |
| **`SUB`** | `SUB AL, 26` | Subtracts `26` (`1Ah`) from `AL` ($AL = AL - 26$). Used during encryption to wrap letters past `'Z'` back to `'A'`. |
| **`INC`** | `INC SI` | **Increment:** Adds `1` to `SI` ($SI = SI + 1$). Advances the string index pointer to the next character in the array. |
| **`XOR`** | `XOR BH, BH`<br>`XOR SI, SI` | **Exclusive OR:** When a register is XORed with itself, every bit becomes `0`. This is the fastest, most compact 8086 idiom to zero out a register. |
| **`AND`** | `AND AL, 0FH` | **Bitwise AND:** Masks out bits. `0FH` is binary `00001111b`. This keeps the lower 4 bits (lower nibble) and forces the upper 4 bits to zero. |
| **`SHR`** | `SHR AL, 1` | **Shift Right:** Shifts all bits in `AL` right by 1 position, inserting `0` into the highest bit. Done 4 times, this moves the upper nibble (bits 7..4) down to bits 3..0. |
| **`DIV`** | `DIV CX` | **Unsigned Integer Division:** Divides the 32-bit integer `DX:AX` by register `CX`. The quotient is placed in `AX` and the remainder is placed in `DX`. Used to extract tens and ones digits of `SI` for 2-digit index alignment in table formatting. |

---

### Comparison & Conditional Jump Instructions

| Instruction | Example from Code | Flags Checked & Logic |
| :--- | :--- | :--- |
| **`CMP`** | `CMP AL, 'A'`<br>`CMP AL, 'Z'` | **Compare:** Performs an internal subtraction ($AL - \text{'A'}$) without altering `AL`. It updates the CPU flags (`CF`, `ZF`, `SF`, etc.) so subsequent conditional jumps can make decisions. |
| **`JMP`** | `JMP ENC_STORE` | **Unconditional Jump:** Always jumps immediately to the specified label, regardless of flags. |
| **`JB`** | `JB ENC_STORE` | **Jump if Below (Unsigned `<`):** Jumps if Carry Flag `CF = 1`. Used to skip characters whose ASCII value is strictly less than `'A'` (like spaces or numbers). |
| **`JBE`** | `JBE ENC_UPPER` | **Jump if Below or Equal (Unsigned `\le`):** Jumps if `CF = 1` or Zero Flag `ZF = 1`. Used to confirm a character is between `'A'` and `'Z'`. |
| **`JA`** | `JA ENC_STORE` | **Jump if Above (Unsigned `>`):** Jumps if `CF = 0` and `ZF = 0`. Used to skip characters with ASCII value higher than `'z'`. |
| **`JAE`** | `JAE DEC_STORE` | **Jump if Above or Equal (Unsigned `\ge`):** Jumps if `CF = 0`. Used during decryption to check if a shifted character stayed above `'A'` without underflowing. |
| **`JNE`** | `JNE TERMINATE_INPUT`| **Jump if Not Equal:** Jumps if Zero Flag `ZF = 0` (result was non-zero). Used to check if the user entered 1 or more characters (`ACTUAL_LEN != 0`). |

---

### Subroutine & Loop Control Instructions

| Instruction | Example from Code | What it Does |
| :--- | :--- | :--- |
| **`CALL`** | `CALL PRINT_STR`<br>`CALL CLEAR_SCREEN` | Pushes the address of the next instruction onto the stack, then jumps to the subroutine. |
| **`RET`** | `RET` | **Return:** Pops the saved instruction address off the stack and returns CPU execution back to the caller. |
| **`LOOP`** | `LOOP ENCRYPT_LOOP` | Hardware loop instruction. It automatically decrements `CX` by 1 ($CX = CX - 1$). If $CX \ne 0$, it jumps back to `ENCRYPT_LOOP`; if $CX = 0$, it falls through. |

---

### Operating System & BIOS Interrupts

In real-mode DOS, the CPU communicates with hardware and the operating system via software interrupts (`INT`). You load function codes into `AH`, arguments into other registers, and trigger `INT 21h` (MS-DOS services) or `INT 10h` (BIOS video services).

| Interrupt & Function Code | Inputs | What it Does |
| :--- | :--- | :--- |
| **`INT 10H, AX = 0003H`** | `AX = 0003h` | **BIOS Video Service: Set Video Mode 03h (80x25 Color Text).** Resets the screen buffer, clears all characters, and places the cursor at row 0, column 0. |
| **`INT 21H, AH = 02H`** | `DL = Character` | **DOS Display Character:** Prints the single ASCII character stored in register `DL` to standard output. |
| **`INT 21H, AH = 07H`** | *(None)* | **DOS Direct Character Input Without Echo:** Pauses program execution until the user presses any key. It returns the key in `AL` without printing it on the screen. |
| **`INT 21H, AH = 09H`** | `DS:DX = Pointer` | **DOS Display String:** Prints a string from memory starting at `DS:DX` until it encounters the `'$'` character. |
| **`INT 21H, AH = 0AH`** | `DS:DX = Buffer` | **DOS Buffered Keyboard Input:** Reads a full line of text typed by the user into a structured 3-part buffer until `Enter` is pressed. |
| **`INT 21H, AH = 4CH`** | `AL = Return Code` | **DOS Terminate Program:** Cleanly stops execution, frees memory, and returns control back to the DOS prompt (equivalent to `return 0` in C). |

---

## 3. Subroutine-by-Subroutine Explanation: Every Custom Function

```
+--------------------------------------------------------------------------+
|                       SUBROUTINE CALL HIERARCHY                          |
+--------------------------------------------------------------------------+
|                                                                          |
|  MAIN (Program Orchestrator)                                             |
|   |                                                                      |
|   +---> CLEAR_SCREEN   (Resets display mode to 80x25 text & clears page) |
|   +---> PRINT_STR      (Displays '$'-terminated banner & prompt strings) |
|   +---> INT 21h, 0Ah   (Accepts keyboard input into INPUT_BUF)           |
|   |                                                                      |
|   +---> ENCRYPT_LOOP   (Shifts characters by +3 with modular wrap)       |
|   |       +---> PRINT_TRACE_ROW  (Renders live formatted table row)      |
|   |               +---> PRINT_STR                                        |
|   |               +---> PRINT_CHAR                                       |
|   |               +---> PRINT_HEX_BYTE                                   |
|   |                                                                      |
|   +---> WAIT_KEY       (Pauses execution until user presses any key)     |
|   +---> CLEAR_SCREEN   (Clears page 1 so page 2 starts clean at row 0)   |
|   |                                                                      |
|   +---> DECRYPT_LOOP   (Reverses shift by -3 with modular wrap)          |
|   |       +---> PRINT_TRACE_ROW                                          |
|   |                                                                      |
|   +---> PRINT_STR      (Displays final plaintext / ciphertext summary)   |
|   +---> INT 21h, 4Ch   (Clean exit with return code 0)                   |
+--------------------------------------------------------------------------+
```

---

### 1. `MAIN PROC`
* **Purpose:** The entry point of the entire program. It coordinates memory segment setup, input handling, encryption, screen paging, decryption, and summary output.
* **Key Register Setup:**
  - `MOV AX, @DATA` / `MOV DS, AX` / `MOV ES, AX`: Points both the Data Segment (`DS`) and Extra Segment (`ES`) to the program's data variables.
* **Empty Input Guard:**
  - Inspects `ACTUAL_LEN` after input. If the user hit `Enter` with 0 characters, it copies `"HELLO"` into `PLAINTEXT` using `REP MOVSB` and sets `ACTUAL_LEN = 5`.
* **String Termination:**
  - Overwrites the trailing Carriage Return (`0Dh`) with a `'$'` character at offset `PLAINTEXT[BX]` so DOS Function `09h` can print the final buffers.

---

### 2. `CLEAR_SCREEN PROC`
* **Purpose:** Resets the screen so that both Page 1 (Encryption) and Page 2 (Decryption) fit completely on standard 25-line DOS terminals without any lines scrolling off or being cut.
* **Mechanism:**
  ```assembly
  MOV AX, 0003H    ; Function 00h (Set Video Mode), Mode 03h (80x25 16-color text)
  INT 10H          ; BIOS Video Interrupt
  ```
* **Why this is used:** Setting video mode `03h` automatically flushes video memory (`B800:0000`), clears all 25 rows, and resets the cursor to coordinate $(0, 0)$.

---

### 3. `WAIT_KEY PROC`
* **Purpose:** Pauses execution until the user presses a key so the user can inspect the Step 1 table at their own pace.
* **Mechanism:**
  ```assembly
  MOV AH, 07H      ; Direct console input without echo
  INT 21H
  ```
* **Why Function `07h`:** Unlike Function `01h` (which prints whatever key you typed onto the screen), Function `07h` captures the keystroke silently, leaving the formatted table clean.

---

### 4. `PRINT_STR PROC`
* **Purpose:** Utility function to print any `$`-terminated string to the screen.
* **Input:** `DX` = Offset of the string in the Data Segment.
* **Mechanism:**
  ```assembly
  PUSH AX          ; Save AX so caller's data is not modified
  MOV AH, 09H      ; DOS display string service
  INT 21H
  POP AX           ; Restore AX
  RET
  ```

---

### 5. `PRINT_CHAR PROC`
* **Purpose:** Prints a single ASCII character to standard output.
* **Input:** `DL` = ASCII character code to display.
* **Mechanism:**
  ```assembly
  PUSH AX
  MOV AH, 02H      ; DOS write single character service
  INT 21H
  POP AX
  RET
  ```

---

### 6. `PRINT_HEX_BYTE PROC`
* **Purpose:** Takes an 8-bit byte in `AL` (e.g., `48h` for character `'H'`) and prints it as two readable hexadecimal characters (`4` followed by `8`).
* **Detailed Step-by-Step Logic:**
  1. `MOV AH, AL`: Saves the original byte in `AH`.
  2. **Upper Nibble Extraction:**
     - `SHR AL, 1` (four times): Moves the top 4 bits down to the bottom 4 positions.
     - `AND AL, 0FH`: Masks out any high bits, leaving a value from `0` to `15`.
     - `LEA BX, HEX_DIGITS` / `XLAT`: Looks up the index in `'0123456789ABCDEF'` and replaces `AL` with the ASCII digit.
     - `CALL PRINT_CHAR`: Prints the first hex digit.
  3. **Lower Nibble Extraction:**
     - `MOV AL, AH`: Restores the original byte.
     - `AND AL, 0FH`: Keeps only the bottom 4 bits (`0..15`).
     - `XLAT`: Translates it into its ASCII hex digit.
     - `CALL PRINT_CHAR`: Prints the second hex digit.

---

### 7. `PRINT_TRACE_ROW PROC`
* **Purpose:** Prints one formatted row of the live visualization table:
  ```text
  |   0   |     H     |     48h     |      4Bh      |     K      |
  ```
* **Inputs:**
  - `SI` = Current 0-based character index.
  - `BL` = Input character (Plaintext in Step 1, Ciphertext in Step 2).
  - `BH` = Output character (Ciphertext in Step 1, Plaintext in Step 2).
* **Column Breakdown:**
  1. **Column 1 (Index):** Supports indices from 0 to 63. Divides `SI` by 10 (`DIV CX`). For single-digit indices ($0$--$9$), prints a leading alignment space and the digit; for two-digit indices ($\ge 10$), prints the tens digit followed by the ones digit.
  2. **Column 2 (Input Character):** Loads `BL` into `DL` and calls `PRINT_CHAR`.
  3. **Column 3 (Input Hex ASCII):** Loads `BL` into `AL` and calls `PRINT_HEX_BYTE`.
  4. **Column 4 (Shifted Hex ASCII):** Loads `BH` into `AL` and calls `PRINT_HEX_BYTE`.
  5. **Column 5 (Output Character):** Loads `BH` into `DL` and calls `PRINT_CHAR`.
* **Register Preservation:** Subroutine wraps execution in `PUSH AX, BX, CX, DX` and `POP DX, CX, BX, AX` so the main loops retain their loop counters and pointers intact.

---

## 4. The Complete Execution Workflow

```
[Start Program]
      |
      v
[Initialize DS, ES = @DATA]
      |
      v
[CALL CLEAR_SCREEN] ------------------> Screen reset to row 0, col 0
      |
      v
[Display Title Banner]
      |
      v
[Prompt User Input]
      |
      v
[INT 21h, AH=0Ah] --------------------> Reads input into INPUT_BUF
      |
      v
[Is ACTUAL_LEN == 0 ?]
    /        \
 (Yes)       (No)
  /            \
[Copy HELLO]  [Append '$' at end of buffers]
  \            /
   +-----+----+
         |
         v
[Display Step 1 Table Header]
[Set CX = ACTUAL_LEN, SI = 0]
         |
         +----------------------------------+
         |                                  |
         v                                  |
   [ENCRYPT_LOOP]                           |
   1. Load AL = PLAINTEXT[SI], BL = AL      |
   2. Is AL in 'A'..'Z' or 'a'..'z'?        |
      - If No  -> Skip shift                |
      - If Yes -> ADD AL, 3                 |
                  If AL > 'Z' or 'z':       |
                     SUB AL, 26             |
   3. Store ENCRYPTED_STR[SI] = AL          |
   4. CALL PRINT_TRACE_ROW                  |
   5. INC SI, LOOP ENCRYPT_LOOP             |
         |                                  |
         +----------------------------------+
         | (When CX reaches 0)
         v
[Print Table Separator]
         |
         v
[Print Pause Message: "Press any key..."]
[CALL WAIT_KEY] ----------------------> Halts execution until key pressed
         |
         v
[CALL CLEAR_SCREEN] ------------------> Screen cleared for Page 2
         |
         v
[Display Step 2 Table Header]
[Set CX = ACTUAL_LEN, SI = 0]
         |
         +----------------------------------+
         |                                  |
         v                                  |
   [DECRYPT_LOOP]                           |
   1. Load AL = ENCRYPTED_STR[SI], BL = AL  |
   2. Is AL in 'A'..'Z' or 'a'..'z'?        |
      - If No  -> Skip shift                |
      - If Yes -> SUB AL, 3                 |
                  If AL < 'A' or 'a':       |
                     ADD AL, 26             |
   3. Store DECRYPTED_STR[SI] = AL          |
   4. CALL PRINT_TRACE_ROW                  |
   5. INC SI, LOOP DECRYPT_LOOP             |
         |                                  |
         +----------------------------------+
         | (When CX reaches 0)
         v
[Print Table Separator]
         |
         v
[Display Final Cipher Summary]
- Original Plaintext  : HELLO
- Encrypted (+3 Shift): KHOOR
- Decrypted Plaintext : HELLO
         |
         v
[INT 21h, AH=4Ch] --------------------> Exit back to DOS (Return Code 0)
```

---

## 5. Frequently Asked Questions & Lab Viva Preparation

### Q1: Why use `SUB AL, 26` instead of modular division (`DIV 26`)?
**Answer:** On the Intel 8086 microprocessor, the hardware division instruction `DIV` requires **80 to 90 clock cycles** per execution. In contrast, `ADD` or `SUB` takes only **3 clock cycles**, and a conditional jump takes **4 to 16 cycles**. Because the Caesar shift is fixed at $K = 3$, an alphabetic byte can overflow past `'Z'` by at most 3 positions; subtracting $26$ directly produces the exact modular wrap-around in a fraction of the CPU cycles.

### Q2: How does DOS Interrupt 21h, Function 0Ah know how many characters were typed?
**Answer:** Function `0Ah` uses a structured buffer in memory:
* **Byte 0:** Program provides the maximum capacity (`64`).
* **Byte 1:** DOS writes the actual count of characters entered by the user (excluding `Enter`).
* **Bytes 2+:** DOS stores the actual characters typed.
The program reads `ACTUAL_LEN` (Byte 1) directly into `CL` to configure the hardware loop counter `CX`.

### Q3: Why do all string variables end with a dollar sign (`'$'`)?
**Answer:** DOS Interrupt 21h, Function `09h` (Print String) does not use length counters or null-terminators (`\0` like C). Instead, it scans memory byte-by-byte until it encounters the ASCII character `'$'` (`24h`), which serves as the sentinel delimiter.

### Q4: Why must registers be pushed and popped inside subroutines?
**Answer:** In assembly, registers are shared globally across the entire CPU. If `PRINT_TRACE_ROW` modified `CX` or `SI` without saving them, `ENCRYPT_LOOP` would lose track of its loop counter and array index, causing infinite loops or memory corruption. Pushing registers at the start (`PUSH AX, BX, CX, DX`) and popping them at the end (`POP DX, CX, BX, AX`) guarantees that calling a subroutine causes zero side effects to the caller's state.

### Q5: How does the `XLAT` instruction work in `PRINT_HEX_BYTE`?
**Answer:** `XLAT` (Translate Byte) performs a hardware table lookup: it treats `BX` as the base address of an array and `AL` as an unsigned 8-bit index. It fetches the byte from `DS:[BX + AL]` and places it into `AL`. We point `BX` to `'0123456789ABCDEF'`; when `AL = 10`, `XLAT` immediately returns ASCII `'A'`.
