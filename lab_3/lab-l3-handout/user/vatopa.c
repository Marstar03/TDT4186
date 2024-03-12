#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if(argc > 2) {
        uint64 virtual_address = atoi(argv[1]);
        int pid = atoi(argv[2]);
        uint64 physical_address = va2pa(virtual_address, pid);
        //printf("%p\n", physical_address);
        printf("0x%x\n", physical_address);

    } else if(argc > 1) {
        uint64 virtual_address = atoi(argv[1]);
        uint64 physical_address = va2pa(virtual_address, -1);
        //printf("%p\n", physical_address);
        printf("0x%x\n", physical_address);

    } else {
        printf("Usage: vatopa virtual_address [pid]\n");
    }

    return 0;
}
