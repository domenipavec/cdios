test: cdios.iso ./bochs/bochs-log.txt
	bochs -f ./bochs/bochs-conf.bxrc -q

debug: cdios.iso ./bochs/bochs-log.txt
	java -jar ~/bin/peter-bochs-debugger.jar bochs -f ./bochs/bochs-conf.bxrc

cdios.iso: all
	genisoimage -R -graft-points -b boot/bootsect.bin -no-emul-boot -boot-load-size 4 -o cdios.iso \
	boot/bootsect.bin=./DIloader/trunk/output/bootsect.bin \
	kernel/kernel.e64=./kernel/trunk/output/kernel.e64

all:
	$(MAKE) -C DIloader/trunk all
	$(MAKE) -C kernel/trunk all

clean:
	make -C DIloader/trunk clean
	make -C kernel/trunk clean

doc:
	make -C kernel/trunk doc
