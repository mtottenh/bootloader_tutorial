#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>

char usage_string[] = " Install a bootloader in the first 446 Bytes of a disk \n\
 * Arguments: \n\
 * arg1 - path to bootloader \n\
 * arg2 - path to harddisk image\n";

void usage(void) {
	printf("%s",usage_string);
}

int main(int argc, char **argv) {
	if (argc != 3) {
		usage();
		return 1;
	}
	FILE* bootloader_file = fopen(argv[1],"r");
	int hdd_image = open(argv[2], O_RDWR);
	void* mem = mmap(NULL,1024,PROT_WRITE|PROT_READ,MAP_SHARED,hdd_image,0);
	
	if (bootloader_file == NULL ) {
		perror("Error opening bootloader file");
		return 1;
	}
	if (hdd_image == NULL) {
		perror("Error opening hdd image file");
		return 1;
	}
	if (mem == MAP_FAILED) {
		perror("Error mmaping hdd_image file");
		return 1;
	}
	// write character by character because I'm lazy
	for (int i = 0; i < 446; i++) {
		char a = fgetc(bootloader_file);
		((char*)mem)[i] = a;
	}
	uint16_t boot_signature = 0xaa55;
	
	uint16_t* ptr = &(((char*)mem)[510]);
	*ptr= boot_signature;
	fclose(bootloader_file);
	close(hdd_image);
	return 0;
}

