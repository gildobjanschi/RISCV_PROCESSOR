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

void handle_trap() {
    uint32_t mcause;
    asm volatile("csrr %0, mcause" : "=r"(mcause));

	switch (mcause) {
		case 0x80000007: { // Timer
			// Clear the mip interrupt pending bit
			uint32_t mip = 1 << 7;
			asm volatile("csrc mip, %0" : : "r"(mip));

			// Generate an interrupt after n units of time
			*IO_MTIMECMP = *IO_MTIME + 1000;

			//*((char*)NULL) = (char)1;
		break;
		}

		case 0x8000000b: { // External interrupts
		    // Clear the mip interrupt pending bit
		    uint32_t mip = 1 << 11;
		    asm volatile("csrc mip, %0" : : "r"(mip));
		break;
		}

		case 0: // EX_CODE_INSTRUCTION_ADDRESS_MISALIGNED
		case 1: // EX_CODE_INSTRUCTION_ACCESS_FAULT
			/*
			 * Execution for these exceptions cannot be resumed.
			 * The processor saves 0 in the mtval and the next instruction cannot be
			 * computed upon exiting the interrupt routine.
			 */
			while (1);
		break;

		case 2: // EX_CODE_ILLEGAL_INSTRUCTION
		case 4: // EX_CODE_LOAD_ADDRESS_MISALIGNED
		case 5: // EX_CODE_LOAD_ACCESS_FAULT
		case 6: // EX_CODE_STORE_ADDRESS_MISALIGNED
		case 7: // EX_CODE_STORE_ACCESS_FAULT
			/*
			 * Execution for these exceptions can be resumed (yet it makes no sense for machine).
			 * The processor saves the instruction that caused the fault in the mtval and the
			 * next instruction is computed upon exiting the interrupt routine.
			 */
			while (1);
		break;

		case 3: // EX_CODE_BREAKPOINT
			// The debugger function is not supported.
			// Stop execution
			while (1);
	    break;

		case 8: // EX_CODE_ECALL
			// Do any work you need to do and then...
			while (1);
		break;

		default: // Unhandled exception
			while (1);
		break;
	}
}
