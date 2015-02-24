ASM=nasm
OBJDIR=obj
BINDIR=bin
TARGETS=$(OBJDIR)/stage1 $(OBJDIR)/stage1_5
UTILS=$(BINDIR)/install $(BINDIR)/read
device=/dev/loop1
FAT=16
all: $(TARGETS) $(UTILS)

$(OBJDIR)/stage1: stage1.asm
	@if [ ! -d $(OBJDIR) ]; then mkdir -p $(OBJDIR); fi
	$(ASM) -f bin -o $@ $^

$(OBJDIR)/stage1_5: stage1_5.asm
	$(ASM) -f bin -o $@ $^

hdd_image: $(TARGETS) $(UTILS)
	@echo -e "\n\n-- Creating Disk Image --\n"
	qemu-img create -f raw $@ 2048M
	@echo -e "\n-- Setting up Partition Table (1 Partition) -- \n"
	#initialize it with one FAT16 partition
	parted -s $@ mktable msdos
	parted -s $@ unit S mkpart p fat16 2048 64260
	parted -s $@ set 1 boot on
	@echo -e "\n-- Creating Filesystem (FAT$(FAT)) --\n"
	sudo kpartx -a $@
	export MTPT=`sudo kpartx -l $@ | awk '{print $$1}'`; sudo mkfs.vfat -n rootfs -F $(FAT) -S 512 -i deadbeef /dev/mapper/$$MTPT
	@echo -e "\n-- Installing Bootloader --\n"
	./bin/install $(TARGETS) ./$@ 
	sudo kpartx -d $@
	@echo -e "\n\n\n*** DUMP IMAGE INFORMATION ***\n"
	./bin/read $@

$(UTILS): 
	@if [ ! -d $(BINDIR) ]; then mkdir -p $(BINDIR); fi
	$(MAKE) -C utils $@
	cp utils/$@ $@

run:
	qemu-system-x86_64 -hda hdd_image
clean:
	-rm -rf $(TARGETS)
	-rm -f $(BINDIR)/*
	$(MAKE) -C utils clean

.PHONY: all run clean
