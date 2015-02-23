ASM=nasm
OBJDIR=obj
TARGETS=$(OBJDIR)/stage1 $(OBJDIR)/stage1_5
all: hdd_image

$(OBJDIR)/stage1: stage1.asm
	$(ASM) -f bin -o $@ $^

$(OBJDIR)/stage1_5: stage1_5.asm
	$(ASM) -f bin -o $@ $^

hdd_image: $(TARGETS)
	dd if=$(OBJDIR)/stage1 of=$@ bs=512 count=1
	dd if=$(OBJDIR)/stage1_5 of=$@ bs=512 seek=1

run:
	qemu-system-x86_64 -hda hdd_image
clean:
	rm -rf $(TARGETS)

.PHONY: all run clean
