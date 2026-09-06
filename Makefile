CFLAGS = -m32 -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -Wall -Wextra -Werror

LDFLAGS = -T src/link.ld -melf_i386

ISO_DIR = iso
ISO_FILE = nitigyaos.iso

all: $(ISO_FILE)

src/loader.o: src/loader.s
	nasm -f elf32 src/loader.s -o src/loader.o

src/kernel.o: src/kernel/kernel.c
	gcc $(CFLAGS) -Isrc -c src/kernel/kernel.c -o src/kernel.o

src/framebuffer.o: src/drivers/framebuffer/framebuffer.c
	gcc $(CFLAGS) -Isrc -c src/drivers/framebuffer/framebuffer.c -o src/framebuffer.o

src/kernel.elf: src/loader.o src/kernel.o src/framebuffer.o
	ld $(LDFLAGS) -o src/kernel.elf src/loader.o src/kernel.o src/framebuffer.o

$(ISO_FILE): src/kernel.elf src/stage2_eltorito
	mkdir -p $(ISO_DIR)/boot/grub
	cp src/kernel.elf $(ISO_DIR)/boot/kernel.elf
	cp src/stage2_eltorito $(ISO_DIR)/boot/grub/stage2_eltorito
	printf 'default 0\ntimeout 0\ntitle NitigyaOS\nroot (cd)\nkernel /boot/kernel.elf\n' > $(ISO_DIR)/boot/grub/menu.lst
	genisoimage -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o $(ISO_FILE) $(ISO_DIR)

run: $(ISO_FILE)
	qemu-system-i386 -cdrom $(ISO_FILE)

clean:
	rm -rf $(ISO_DIR) $(ISO_FILE) src/*.o src/kernel.elf

.PHONY: all run clean