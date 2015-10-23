all: ./output/bootsect.bin

test: ./output/bootable.iso ./bochs/bochs-log.txt
	bochs -f ./bochs/bochs-conf.bxrc -q

debug: ./output/bootable.iso ./bochs/bochs-log.txt
	java -jar ~/bin/peter-bochs-debugger.jar bochs -f ./bochs/bochs-conf.bxrc

clean:
	-rm ./output/*
	-rm ./object/*

./output/bootable.iso: ./output/bootsect.bin ./output/kernel.e64
	genisoimage -R -graft-points -b boot/bootsect.bin -no-emul-boot -boot-load-size 4 -o ./output/bootable.iso boot/bootsect.bin=./output/bootsect.bin kernel/kernel.e64=./output/kernel.e64

./output/kernel.e64: ./source/test_kernel.asm
	nasm -f elf64 -o ./object/kernel.o64 ./source/test_kernel.asm
	ld -b elf64-x86-64 -m elf_x86_64 -o ./output/kernel.e64 ./object/kernel.o64

./output/bootsect.bin: ./source/bootsector.asm ./source/enableA20.asm ./source/memoryMap.asm
	nasm -f bin -i ./source/ -o ./output/bootsect.bin ./source/bootsector.asm
	python resizeFile.py ./output/bootsect.bin 2048

