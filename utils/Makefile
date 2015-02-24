CC=gcc
CFLAGS=-std=c99 -Wall -Wextra -Werror
BINDIR=bin
TARGETS=$(BINDIR)/install $(BINDIR)/read
all: $(TARGETS)
	@echo "CLFLAGS: $(CFLAGS)"


$(BINDIR)/install: boot_install.c
	@echo "Creating bootloader installer"
	$(CC) $(CFLAGS) -o $@ $^

$(BINDIR)/read: boot_read.c
	@echo "Creating bootloader reader"
	$(CC) $(CFLAGS) -o $@ $^


clean:
	-rm -rf *.o
	-rm $(BINDIR)/*
.PHONY: clean all
