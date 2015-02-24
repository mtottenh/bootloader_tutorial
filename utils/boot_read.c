#include <string.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <stdlib.h>

char usage_string[] = " Dump the msdos Partition Table\n\
 * Arguments: \n\
 * arg1 - path to harddisk image\n";

void usage(void) {
	printf("%s",usage_string);
}
#pragma pack(push,1)
struct chs_address {
	uint8_t track;
	uint8_t sector;
	uint8_t cylinder;
	
};
typedef struct chs_address chs_addr_t;
struct partition_data {
	uint8_t active;
	chs_addr_t first_sector;
	uint8_t partition_type;
	chs_addr_t last_sector;
	uint32_t lba_first_sector;
	uint32_t num_sectors;
};

struct bios_param_block {
	uint16_t bps; //bytes per sector *logical*
	uint8_t spc; //sectors per cluster *logical* - DON'T USE
	uint16_t resv_sect; //reserved sectors
	uint8_t num_fats;
	uint16_t root_dir;
	uint16_t total_sect; 
	uint8_t media_desc;
	uint16_t spf; //sectors per fat
};
typedef struct bios_param_block bpb_t;

struct bios_param_block_extended {
	bpb_t bpb_2;
	uint16_t spt; //sectors per track
	uint16_t no_heads; //number of heads
	uint32_t hidden_sectors ;
	uint32_t total_sectors;
};
typedef struct bios_param_block_extended  ebpb_t;
typedef struct partition_data partition_data_t;
#pragma pack(pop)

void printBits(size_t const size, void const * const ptr)
{
    unsigned char *b = (unsigned char*) ptr;
    unsigned char byte;
    int i, j;

    for (i=size-1;i>=0;i--)
    {
        for (j=7;j>=0;j--)
        {
            byte = b[i] & (1<<j);
            byte >>= j;
            printf("%u", byte);
        }
    }
}

int main(int argc, char **argv) {
	if (argc != 2) {
		usage();
		return 1;
	}
	struct stat sb;
	int hdd_image = open(argv[1], O_RDWR);
	fstat(hdd_image,&sb);
	void* mem = mmap(NULL,sb.st_size,PROT_WRITE|PROT_READ,MAP_SHARED,hdd_image,0);
	
	if (hdd_image == -1) {
		perror("Error opening hdd image file");
		return 1;
	}
	if (mem == MAP_FAILED) {
		perror("Error mmaping hdd_image file");
		return 1;
	}
	char* memc = (char*)mem;
	// write character by character because I'm lazy
	printf("-- BIOS PARAMATER BLOCK --\n");
	ebpb_t* bpb = (ebpb_t*)(memc+11);
	printf("Total Sectors: %u\n", bpb->total_sectors);
	printf("----\n");
	printf("-- Dumping Partition Table -- \n");
	int j =0;
	char *hexdump = malloc(sizeof(char)*200);
	sprintf(hexdump,"hexdump -Cv -s 446 -n 66 %s", argv[1]);
	system(hexdump);
	free(hexdump);
	printf("-- Interpreted output follows --\n");
	for (int i = 446; i < 510; i+=16) {
		if (j % 16 == 0) {
			printf("Partition %d\n", (j/16));
		}
		partition_data_t *p = (partition_data_t*)(memc+i);
		printf("Active Byte: ");
		printBits(sizeof(uint8_t),&(p->active));
		printf("\nFirst Sector:");
		printf("\tH: ");
		printBits(sizeof(uint8_t),&(p->first_sector.track));
		printf("(%u)\tS: ",p->first_sector.track);
		printBits(sizeof(uint8_t),&(p->first_sector.sector));
		printf("(%u)\tC: ",p->first_sector.sector);
		printBits(sizeof(uint8_t),&(p->first_sector.cylinder));
		printf("(%u)\tType: 0x%x",p->first_sector.cylinder,p->partition_type);
		printf("\nAddress of first sector (LBA) %#x",p->lba_first_sector);	
		printf("\tNumber of Sectors: %u",p->num_sectors);
		printf("\n");
		j+=16;
	}
	close(hdd_image);
	return 0;
}

