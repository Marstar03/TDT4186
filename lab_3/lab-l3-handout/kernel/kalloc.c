// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define PAGE_ARRAY_LENGTH (PHYSTOP / PGSIZE)

uint64 MAX_PAGES = 0;
uint64 FREE_PAGES = 0;

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
    struct run *next;
};

struct
{
    struct spinlock lock;
    struct run *freelist;
} kmem;

//Added structs
/* struct pages_counts_struct
{
    uint64 pages_array[4096];
} pages_counts; */

/* struct page_struct
{
    uint64 count;
    uint64 address;
}; */

// Endre 100 til maks antall pages
// Hva menes med "how many pages do we need to track at maximum"?
//struct page_struct page_array1[MAX_PAGES];
/* struct page_struct page_array[100];
int page_index = 0; */

// Added "global" array to access in both kalloc.c and vm.c
/* struct page_struct
{
    uint64 count;
    uint64 address;
}; */


//const PAGE_ARRAY_LENGTH = PHYSTOP / PGSIZE;

//struct page_struct page_array[PAGE_ARRAY_LENGTH]; // Endre 100 til antall pages vi må holde styr på om gangen

uint64 new_array[PAGE_ARRAY_LENGTH] = {0};

void increment_page_count(uint64 physical_address) {
    new_array[physical_address / PGSIZE] ++;
    //printf("%d\n", FREE_PAGES);
}

void decrement_page_count(uint64 physical_address) {
    new_array[physical_address / PGSIZE] ++;
}


// maxmemorysize for hele systemet blir satt. Del page size. Får antall sider man har
// Phystop/ pgsize blir antall sider

/* int page_index = 0;

void increment_page_count(uint64 physical_address) {
    for (int i = 0; i < MAX_PAGES; i++) {
        if (page_array[i].address == physical_address) {
            page_array[i].count ++;
        }
    }
}

void decrement_page_count(uint64 physical_address) {
    for (int i = 0; i < MAX_PAGES; i++) {
        if (page_array[i].address == physical_address) {
            page_array[i].count --;
            //FREE_PAGES++;
        }
    }
} */

void kinit()
{
    initlock(&kmem.lock, "kmem");
    freerange(end, (void *)PHYSTOP);
    MAX_PAGES = FREE_PAGES;

    /* // Added
    page_array_length = MAX_PAGES; */
    //FREE_PAGES++;

    // ---------------------
    /* for (int i = 0; i < PAGE_ARRAY_LENGTH; i++) {
        new_array[i] = 0;
    } */
    // ---------------------
}

void freerange(void *pa_start, void *pa_end)
{
    char *p;
    p = (char *)PGROUNDUP((uint64)pa_start);
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    {
        kfree(p);
    }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    // Added
    /* for (int i = 0; i < MAX_PAGES; i++) {
        if (page_array[i].address == (uint64)pa) {
            //decrement_page_count((uint64)pa);

            if (page_array[i].count > 0) {
                return;
            } else {
                break;
                // panic("kfree");
            }
        }
    }  */


    // ---------------------
    /* if (new_array[(uint64)pa / PGSIZE] <= 0) {
        return;
    } */
    if (new_array[(uint64)pa / PGSIZE] > 0) {
        new_array[(uint64)pa / PGSIZE] --;
        return;
    }
    // ---------------------

    if (MAX_PAGES != 0) // On kinit MAX_PAGES is not yet set
        assert(FREE_PAGES < MAX_PAGES);
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
        panic("kfree");

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);

    r = (struct run *)pa;

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    FREE_PAGES++;
    release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    assert(FREE_PAGES > 0);
    struct run *r;

    acquire(&kmem.lock);
    r = kmem.freelist;
    if (r)
        kmem.freelist = r->next;
    release(&kmem.lock);

    if (r) {
        memset((char *)r, 5, PGSIZE); // fill with junk

        //Added
        /* page_array[page_index].address = (uint64)r;
        page_array[page_index].count = 0;
        page_index ++;
        if (page_index >= PAGE_ARRAY_LENGTH) {
            page_index = 0;
        } */
        // ---------------------
        //new_array[(uint64)r / PGSIZE] = 0;
        // ---------------------
    }
    FREE_PAGES--;
    return (void *)r;
}

