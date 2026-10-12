
ORG 0x7C00 ; the address where the code will be loaded
BITS 16 ; real mode

boot_drive equ 0x7000

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00 ; set the stack

mov [boot_drive], dl    ; acum DS=0, adresa e corectă

load_stage2:
    mov ah, 0x02
    mov al, 1 ; sector of 512 bytes for stage 2 load
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, 0x7E00
    int 13h
    jc error
    jmp 0x7E00

print:
    push ax
.loop:
    mov al, [si]
    inc si
    cmp al, 0
    jz .done
    mov ah, 0x0E
    int 10h
    jmp .loop
.done:
    pop ax
    ret

error:
    mov si, error_loading
    call print

done:
    jmp $ ; halt

; define the data
error_loading       db  'Error loading stage 2 from disk',0

times 510 - ($ - $$) db 0
dw 0xAA55 ; little endian

