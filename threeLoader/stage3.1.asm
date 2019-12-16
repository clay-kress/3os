
[bits 16]
[org 0x7c00]

jmp 0x0000:start

bootDrive db 0x00
string db "Hi there!", 0x00

start:
  ; Inits all relevant registers------------------------------------------
  xor si,si
  xor di,di
  
  mov ax, 0x7c00
  mov bp, ax
  mov sp, ax
  
  mov ax, 0x0000
  mov ss, ax
  mov ds, ax
  mov es, ax
  mov fs, ax
  ; Inits all relevant registers------------------------------------------
  mov [bootDrive], dl
  
  ; Boot code goes here---------------------------------------------------
  mov ax, 0x0000
  int 0x10
  
  
jmp $



printStr:               ; Routine: print the string pointed to by si
      pusha
      mov ah, 0x0E      ; ah= 0x0E: teletype output
                        ; AL = Character, BH = Page Number, BL = Color (only in graphic mode)
      .loopStr:
        lodsb           ; load the byte in [si] into al
        cmp al, 0x00    ; If it is zero, then terminate the string
        je .doneStr
        int 0x10        ; else: print character
      jmp .loopStr
      
      .doneStr:
      popa
      ret



printHex:               ; Routine: print value in (dx) as hexadecimal
      pusha
      mov cx, 0x4
      
      mov bx, outputHex ; Sets bx to the address of outputHex
      add bx, 0x2       ; Keeps the '0x' the same
      add bx, 0x3       ; Sets the address to the last char
      
      .loopHex:
        dec cx
        
        mov ax, dx
        shr dx, 0x4     ; Cuts successive hex chars off of dx
        and ax, 0x000f  ; Masks successive hex chars in to ax
        
        cmp al, 0xa
        jge .letter     ; If its a letter
        jl  .number     ; If its a number
        
        .letter:
          sub al, 0x9   ; Since hex letters start at 10, we subtract 10 and add 1
          or al, 0x60   ; The first nibble of a lowercase letter is always 0110
          jmp .setChar
          
        .number:
          sub al, 0x0   ; Numbers start at 0 so we dont need to unbias them
          or al, 0x30   ; The first nibble of a number is always 0011
          jmp .setChar
        
        .setChar:
          mov [bx], al  ; Write our char to the output var
          sub bx, 0x1   ; bx should now point to the previous char
          
      cmp cx, 0x0
      jne .loopHex
      
      .doneHex:
        mov si, outputHex
        call printStr
        
        popa
        ret
      
      outputHex db "0x0000", 10, 13, 0x00



readDisk:               ; Routine: read disk, output message and freeze if error occurs
      pusha
      
      int 0x13          ; The interrupt that we use
      jc .DiskError     ; CF is set on error
      jmp .done         ; If no error, then skip error msg
      
      .DiskError:
        mov si, errStr  ; Prints "Warning; Fatal Disk Error"
        call printStr
        
        mov si, errNum  ; Prints "Error code (AX): "
        call printStr
        
        mov dx, ax      ; Prints AX
        call printHex
        
        jmp $
      
      .done:
        popa
        ret
        
      errStr db "Warning; Fatal Disk Error", 10, 13, 0x00
      errNum db "Error code (AX): ", 0x00



; Define a partition table: [3 MiB Partition], [Rest of Disk]
times 440-($-$$) db 0x00

dw 0xae75
dw 0x20e0
dw 0x0000
dw 0x2000
dw 0x0021
dw 0xfa83
dw 0x6c4e
dw 0x0800
dw 0x0000
dw 0x7000
dw 0x0059

times 510-($-$$) db 0x00
dw 0xaa55                     ; This number tells the BIOS that the disk is bootable
