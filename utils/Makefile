CC=gcc
CFLAGS=-std=c99 -Wall -Wextra -Werror
BINDIR=bin
TARGETS=$(BINDIR)/install $(BINDIR)/read
all: $(TARGETS)
	@echo "CLFLAGS: $(CFLAGS)"


$(BINDIR)/install: boot_install.c
	@echo -e "\tCreating bootloader installer"
	@if [ ! -d $(BINDIR) ]; then mkdir -p $(BINDIR) ; fi 
	$(CC) $(CFLAGS) -o $@ $^

$(BINDIR)/read: boot_read.c
	@echo -e "\t Creating bootloader reader"
	$(CC) $(CFLAGS) -o $@ $^


clean:
	-rm -rf *.o
	-rm $(BINDIR)/*
.PHONY: clean all
