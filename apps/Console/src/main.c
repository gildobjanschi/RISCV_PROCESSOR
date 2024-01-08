/*
 Name        : main.c
 Author      : Gil
 Version     :
 Copyright   :
 Description : RISC-V console
 */

#define IO_BASE 0xc0000000
#define IO_MTIME (volatile uint64_t *)(IO_BASE + 0x00004000)
#define IO_MTIMECMP (volatile uint64_t *)(IO_BASE + 0x00004008)

#define MAX_CMD_LEN 64

#include <stdio.h>
#include <stdint.h>
#include <string.h>

void handle_command(char* cmd) {
	uint32_t counter;
	uint32_t i;
	if (strcmp(cmd, "c") == 0) {
	    asm volatile("csrr %0, mcycle" : : "r"(counter));
		printf("Cycles:                 %u\n", counter);

	    asm volatile("csrr %0, minstret" : : "r"(counter));
		printf("Instructions retired:   %u\n", counter);

	    asm volatile("csrr %0, mhpmcounter3" : : "r"(counter));
		printf("Instructions from ROM:  %u\n", counter);

	    asm volatile("csrr %0, mhpmcounter4" : : "r"(counter));
		printf("Instructions from RAM:  %u\n", counter);

	    asm volatile("csrr %0, mhpmcounter5" : : "r"(counter));
		printf("Cache hits:             %u\n", counter);

	    asm volatile("csrr %0, mhpmcounter6" : : "r"(counter));
		printf("Load from ROM:          %u\n", counter);

		asm volatile("csrr %0, mhpmcounter7" : : "r"(counter));
		printf("Load from RAM:          %u\n", counter);

		asm volatile("csrr %0, mhpmcounter8" : : "r"(counter));
		printf("Store to RAM:           %u\n", counter);

		asm volatile("csrr %0, mhpmcounter9" : : "r"(counter));
		printf("Load from IO:           %u\n", counter);

		asm volatile("csrr %0, mhpmcounter10" : : "r"(counter));
		printf("Store to IO:            %u\n", counter);

		asm volatile("csrr %0, mhpmcounter11" : : "r"(counter));
		printf("Load from CSR:          %u\n", counter);

		asm volatile("csrr %0, mhpmcounter12" : : "r"(counter));
		printf("Store to CSR:           %u\n", counter);

		asm volatile("csrr %0, mhpmcounter13" : : "r"(counter));
		printf("Timer IRQ:              %u\n", counter);

		asm volatile("csrr %0, mhpmcounter14" : : "r"(counter));
		printf("External IRQ:           %u\n", counter);
	} else if (strcmp(cmd, "?") == 0) {
		printf("c -- View the High Performance Counters\n");
	} else {
		/*
		for (i=0; i<MAX_CMD_LEN; i++) {
			if (cmd[i] != 0) {
				printf("%02x ", (unsigned char)cmd[i]);
			} else {
				break;
			}
		}
		printf("\n");
		*/
		printf("?\n");
	}
	printf(">");
}

/*
 * Console application
 */
int main(void) {
	printf("\n");
	printf("****************\n");
	printf("**** RISC-V ****\n");
	printf("****************\n");
	printf("Type ? for help\n>");
	char ch;
	char cmd[MAX_CMD_LEN];
	int index = 0;
	while(1) {
		if (fread(&ch, 1, 1, stdin) > 0) {
			if (ch == '\r') {
				cmd[index] = 0;

				//printf("%s\n", cmd);
				handle_command(cmd);

				index = 0;
			} else if (index < MAX_CMD_LEN){
				cmd[index] = ch;
				index++;
			} else {
				index = 0;
				printf("Command too long\n>");
			}
		}
	}

	return 0;
}

