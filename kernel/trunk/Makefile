CPATH = /usr/cross/bin/
CC = $(CPATH)x86_64-elf-g++
NASM = nasm
FLAGS = -c -iquote include \
	-ffreestanding -fomit-frame-pointer -finline-functions -nostdlib \
	-fno-builtin -fno-exceptions -fno-rtti \
	-Wall -Wextra -pedantic -Wshadow -Wpointer-arith -Wcast-align \
	-Wwrite-strings -Wmissing-declarations \
	-Wredundant-decls -Winline -Wno-long-long \
	-Wconversion
COBJ = object/main.o object/kernel.o object/dalloc.o object/malloc.o \
	object/serialPort.o object/c_isr.o object/stream.o
AOBJ = object/asm_isr.o object/start.o

all: ./output/kernel.e64

clean:
	-rm ./output/*
	-rm ./object/*

doc: Doxyfile
	doxygen

./output/kernel.e64: $(COBJ) $(AOBJ) linker.ld
	@echo Linking $@
	@$(CPATH)x86_64-elf-ld -T linker.ld -z max-page-size=1 -o output/kernel.e64 $(COBJ) $(AOBJ)

$(COBJ): source/$(subst o,cpp,$(@F)) include/*.h
	@echo Compiling $@
	@$(CC) $(FLAGS) -o $@ source/$(subst .o,.cpp,$(@F))

$(AOBJ): assembler/$(subst o,asm,$(@F))
	@echo Assembling $@
	@$(NASM) -f elf64 -o $@ assembler/$(subst o,asm,$(@F))

