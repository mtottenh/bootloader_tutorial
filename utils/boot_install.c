#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>

char usage_string[] = " Install a bootloader in the first 446 Bytes of a disk \n\
 * Arguments: \n\
 * arg1 - path to bootloader stage1 \n\
 * arg2 - path to bootloader stage2 \n\
 * arg3 - path to harddisk image\n";

void usage(void) {
	printf("%s",usage_string);
}

int main(int argc, char **argv) {
	if (argc != 4) {
		usage();
		return 1;
	}
	struct stat sb;
	FILE* stage1_file = fopen(argv[1],"r");
	FILE* stage1_5_file = fopen(argv[2],"r");
	int hdd_image = open(argv[3], O_RDWR);
	fstat(hdd_image,&sb);
	void* mem = mmap(NULL,sb.st_size,PROT_WRITE|PROT_READ,MAP_SHARED,hdd_image,0);
	
	if (stage1_file == NULL ) {
		perror("Error opening stage 1 ");
		return 1;
	}
	if (stage1_5_file == NULL ) {
		perror("Error opening stage 1.5");
		return 1;
	}
	if (hdd_image == 0) {
		perror("Error opening hdd image file");
		return 1;
	}
	if (mem == MAP_FAILED) {
		perror("Error mmaping hdd_image file");
		return 1;
	}
	char* memc = (char*) mem;
	// write character by character because I'm lazy
	for (int i = 0; i < 446; i++) {
		char a = fgetc(stage1_file);
		memc[i] = a;
	}
	uint16_t boot_signature = 0xaa55;
	// Ensure there is a boot signature.
	uint16_t* ptr = (uint16_t *)(memc+510);
	*ptr= boot_signature;
	fclose(stage1_file);

	//Now write the stage1_5 loader after the first sector
	bool eof = false;
	for (int i = 512; i < 17408 && !eof; i++) {
		char c = fgetc(stage1_5_file);
		if (feof(stage1_5_file)) {
			memc[i] = c;
		} else {
			eof = true;
		}
	}
	fclose(stage1_5_file);
	close(hdd_image);
	return 0;
}

