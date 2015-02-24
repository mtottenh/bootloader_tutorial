ASM=nasm
OBJDIR=obj
TARGETS=$(OBJDIR)/stage1 $(OBJDIR)/stage1_5
all: hdd_image
device=/dev/loop1

$(OBJDIR)/stage1: stage1.asm
	$(ASM) -f bin -o $@ $^

$(OBJDIR)/stage1_5: stage1_5.asm
	$(ASM) -f bin -o $@ $^

hdd_image: $(TARGETS) bin/install
	qemu-img create -f raw $@ 32M
	#initialize it with one FAT16 partition
	parted -s $@ mktable msdos
	parted -s $@ mkpart p fat16 1 33
	parted -s $@ set 1 boot on
	sudo kpartx -a $@
	export MTPT=`sudo kpartx -l $@ | awk '{print $$1}'`; sudo mkfs.vfat -n rootfs -F 16 -S 512 -i deadbeef /dev/mapper/$$MTPT
#	./bin/install ./obj/stage1 ./$@ 
	sudo kpartx -d $@
	./bin/read $@
#	dd if=$(OBJDIR)/stage1_5 of=$@ bs=512 seek=1

bin/install: installer/*
	cd installer && $(MAKE)
	cp installer/install ./bin/install
	cp installer/read ./bin/read
run:
	qemu-system-x86_64 -hda hdd_image
clean:
	rm -rf $(TARGETS)
	$(MAKE) -C installer clean

.PHONY: all run clean
