#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#define MAX_CYLINDERS 1024
#define SECTOR_SIZE 512
#define SECTOR_PER_TRACK 63
#define NO_HEADS 255
#define SECTOR_MASK 0b00111111;
#define  __packed __attribute__((packed))

struct chs_addr {
    uint8_t head;
    uint8_t sector;
    uint8_t cylinder;
} __packed;

struct partition_entry {
    uint8_t status;
    struct chs_addr first_sector;
    uint8_t type;
    struct chs_addr last_sector;
    uint32_t lba_first_sector;
    uint32_t num_sectors;
} __packed;


struct partition_table {
    struct partition_entry pent[4];
} __packed;


static void usage(void) {
    printf("set_boot <device> <on|off>\n");
    exit(EXIT_SUCCESS);
}

static void hex_dump_map(const char* device) {
    printf("Bootsector:\n");
    printf("Offset(Hex)\tValue\n");
    for (int j = 0; j < 64; j++) {
        int print = 1;
        for (int i = 0; i < 8; i++)
            print = print && device[j*8 + i] == 0;
        if (!print)
            printf("\t%x:\t",j*8);
           
        for (int i = 0; i < 8; i++) {
            if (!print)
               printf("%0*x ", 2, ((uint8_t*)device)[j*8 + i]);
        }
        if (!print)
            printf("\n");
    }
    printf("\n");
}

static void dump_partition(struct partition_entry pent) {
    printf("\t");
    const uint8_t* dev = (const uint8_t*)&pent;
    for (int i = 0; i < 16; i++) {
        printf("%0x ",dev[i]);
    }
    printf("\n\tStatus: %x\tType: %x\n", pent.status, pent.type);
//    uint8_t first_sector = pent.first_sector.sector & SECTOR_MASk;
//    uint8_t last_sector = pent.last_sector.sector & SECTOR_MASK;

    printf("\tStart: %u\tEnd: %u\n", pent.lba_first_sector, pent.lba_first_sector + pent.num_sectors);
//    printf("\tNew Status: %x", new_status);
    printf("\n");
}

static void dump_partition_table(const char* device) {
    struct partition_table *ptable =(struct partition_table*)&device[446];
    for (int i = 0; i < 4; i++) {
        printf("Partition Number: %d\n", i);
        dump_partition(ptable->pent[i]);
    }
}

int main(int argc, char** argv) {
    if (argc < 3)
        usage();
    if (strcmp(argv[2], "off") && strcmp(argv[2], "on")) 
        usage();
    int fd = open(argv[1], O_RDWR);
    if (fd == -1) {
        perror("open");
        exit(EXIT_FAILURE);
    }
    char* device = mmap(NULL, 512, PROT_WRITE, MAP_SHARED, fd, 0);
    if (device == MAP_FAILED) {
        perror("mmap");
        exit(EXIT_FAILURE);
    }
    printf("Successfully opened %s for RW\n", argv[1]);
    hex_dump_map((const char*)device);
    dump_partition_table((const char*)device);
    printf("Disabling boot for %s\n", argv[1]);
    if (strcmp(argv[2],"off") == 0) {
        device[510] = 0x00;
        device[511] = 0x00;
    } else {
        device[510] = 0x55;
        device[511] = 0xaa;

    }
    if (strcmp(argv[3], "force_reboot") == 0) {
        device[73] = 0xcd; // Force reboot instead of jmp $
        device[74] = 0x19;
    }
    hex_dump_map((const char*)device);
    munmap(device, 512);
    close(fd);
    return 0;
}
