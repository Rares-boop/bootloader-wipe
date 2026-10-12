
ORG 0x7E00
BITS 16

boot_drive equ 0x7000
zero_buffer equ 0x9000  ; fix address in RAM

prepare_zero_buffer:
    cld 
    mov di, zero_buffer
    mov cx, 512
    xor al, al
    rep stosb

start_wipe:
    ; check if BIOS supports LBA
    mov ah, 0x41 ; check extensions function
    mov bx, 0x55AA 
    mov dl, [boot_drive] ; get the hard disk
    int 13h
    jc no_ext ; CF set = not supported
    cmp bx, 0xAA55 ; check if signature was swapped
    jne no_ext

    mov si, lba_supported
    call print

    mov dl, 0x80 ; address of the first disk
.next_drive:
    mov ah, 0x48
    mov si, drive_params
    mov word [si], 0x1A
    int 13h
    jc .done_drivers

    ; wipe loop pentru DL drive
    ; take the total sectors from buffer
    mov eax, [drive_params + 0x10]
    mov [total_sectors], eax

    ; reset LBA to zero for this drive
    xor eax, eax
    mov [dap_lba], eax

.wipe_loop:
    mov eax, [dap_lba]
    cmp eax, [total_sectors]
    jae .drive_done

    mov ah, 0x43 ; extended write
    mov al, 0 ; without verify
    mov si, dap ; DL is set to the current driver
    int 13h
    jc .drive_done ; error let the driver and go to the next one

    inc dword [dap_lba] ; LBA++
    jmp .wipe_loop

.drive_done:
    inc dl ; next drive
    jmp .next_drive ; go to the loop and see if the next driver exists

.done_drivers:
    ; memory E820 (the map of the RAM memory)
    jmp done
    
no_ext:
    mov si, err_no_lba
    call print
    jmp done

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

done:
    cli
    hlt

err_no_lba          db 'LBA not supported, cannot wipe', 0
lba_supported       db  'LBA supported', 0
drive_params:       times 26    db  0
total_sectors:      dd 0

; Disk Address Packet (DAP) - 16-byte structure passed to INT 13h AH=43h
; via DS:SI. Describes an extended (LBA) disk write: how many sectors,
; the source buffer in RAM, and the starting LBA on disk.
dap:
    db 0x10              ; size of packet (always 16 bytes)
    db 0                 ; reserved, always 0
    dw 1                 ; number of sectors to write per call
    dw zero_buffer       ; buffer offset
    dw 0                 ; buffer segment
dap_lba:
    dd 0                 ; starting LBA (low 32 bits)
    dd 0                 ; high 32 bits (always 0)
