# bootloader-wipe

Bare-metal x86 disk wiper. 2-stage real-mode bootloader that enumerates
all BIOS drives via INT 13h and zero-fills every sector using LBA
(extended write, AH=43h).