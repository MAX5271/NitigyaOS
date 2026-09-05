all: iso

src/kernel.o: src/kernel.c
	gcc -m32 -ffreestanding -c src/kernel.c -o src/kernel.o

src/loader.o: src/loader.s
	nasm -f elf32 src/loader.s -o src/loader.o

src/kernel.elf: src/loader.o src/kernel.o
	ld -m elf_i386 -T src/link.ld src/loader.o src/kernel.o -o src/kernel.elf

iso: src/kernel.elf
	rm -rf iso
	mkdir -p iso/boot/grub
	cp src/kernel.elf iso/boot/kernel.elf
	cp src/stage2_eltorito iso/boot/grub/
	printf "default 0\ntimeout 0\n\ntitle NitigyaOS\nkernel /boot/kernel.elf\n" > iso/boot/grub/menu.lst
	genisoimage -R -b boot/grub/stage2_eltorito \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-o nitigyaos.iso iso

run: iso
	qemu-system-i386 -cdrom nitigyaos.iso