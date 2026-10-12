ASM = nasm
ASMFLAGS = -f bin
QEMU = qemu-system-i386

SRC1 = boot.asm
SRC2 = stage2.asm
OUT1 = stage1.bin
OUT2 = stage2.bin
DISK = disk.bin
TARGET = target.img

.PHONY: all run run-curses verify clean

all: $(DISK)

$(OUT1): $(SRC1)
	$(ASM) $(ASMFLAGS) $< -o $@

$(OUT2): $(SRC2)
	$(ASM) $(ASMFLAGS) $< -o $@

$(DISK): $(OUT1) $(OUT2)
	cat $(OUT1) $(OUT2) > $@

$(TARGET):
	dd if=/dev/zero bs=1M count=1000 2>/dev/null | tr '\000' '\377' > $@

run: $(DISK) $(TARGET)
	timeout 20 $(QEMU) \
		-drive format=raw,file=$(DISK),if=ide,index=0 \
		-drive format=raw,file=$(TARGET),if=ide,index=1 \
		-display none || true

run-curses: $(DISK) $(TARGET)
	$(QEMU) \
		-drive format=raw,file=$(DISK),if=ide,index=0 \
		-drive format=raw,file=$(TARGET),if=ide,index=1 \
		-curses

verify:
	@n=$$(tr -d '\000' < $(TARGET) | wc -c); \
	if [ $$n -eq 0 ]; then \
		echo "OK - target.img is all zero, wipe successful"; \
	else \
		echo "FAIL - $$n bytes left unwiped"; \
	fi

clean:
	rm -f $(OUT1) $(OUT2) $(DISK) $(TARGET)