CC=gcc
CFLAGS=-std=c99
all: install read


install: boot_install.c
	$(CC) $(CFLAGS) -o $@ $^

read: boot_read.c
	$(CC) $(CFLAGS) -o $@ $^


clean:
	-rm -rf *.o
	-rm install
	-rm read
.PHONY: clean all
