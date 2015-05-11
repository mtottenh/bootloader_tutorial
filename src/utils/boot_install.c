#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdbool.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
/* Global vars */
const uint16_t BOOT_SIGNATURE = 0xaa55;
const uint16_t BOOT_SIGNATURE_OFFSET = 510;
const uint16_t MAX_STAGE1_5_FILE_SIZE = 17408;
const char USAGE_STRING[] = " Install a bootloader in the first 446 Bytes of a \
disk\n\
 * Arguments: \n\
 * arg1 - path to bootloader stage1 \n\
 * arg2 - path to bootloader stage1_5 \n\
 * arg3 - path to harddisk image\n";

void usage(void) {
	printf("%s",USAGE_STRING);
}

int check_file_access(FILE *s1, FILE *s1_5, int hdd, void *mem) {
  if (s1 == NULL ) {
		perror("Error opening stage 1 ");
		return 1;
	}
	if (s1_5 == NULL ) {
		perror("Error opening stage 1.5");
		return 1;
	}
	if (hdd == 0) {
		perror("Error opening hdd image file");
		return 1;
	}
	if (mem == MAP_FAILED) {
		perror("Error mmaping hdd_image file");
		return 1;
	}
  return 0;
}

FILE* embed_stage1(void* mem, FILE* file) {
	fread(mem,sizeof(char),446,file);
  fclose(file);
  return 0;
}

FILE* embed_stage1_5(void* mem, FILE* file) {
  void* offset = mem + BOOT_SIGNATURE_OFFSET + sizeof(BOOT_SIGNATURE);
  fread(offset,sizeof(char),MAX_STAGE1_5_FILE_SIZE,file);
  fclose(file);
  return 0;
}

void write_boot_signature(void* mem) {
  uint16_t *offset = mem + BOOT_SIGNATURE_OFFSET;
  *offset = BOOT_SIGNATURE;
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

  if (check_file_access(stage1_file,stage1_5_file,hdd_image,mem)) {
      return 1;
  }
	stage1_file = embed_stage1(mem,stage1_file);
  write_boot_signature(mem);
  stage1_5_file = embed_stage1_5(mem,stage1_5_file);
	close(hdd_image);
	return 0;
}
