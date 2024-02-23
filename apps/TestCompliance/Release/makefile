RM := rm -rf

OBJS := src/obj.o

# target is a parameter to the makefile eg.: makefile target=rv32i_m/I/src/add-01 all
$(OBJS): ../src/$(target).S
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv-none-elf-gcc -march=rv32imac_zicsr_zifencei_zicond_zba_zbb_zbc_zbs -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g -x assembler-with-cpp -I../src/env -MMD -MP -MF"$(@:obj.o=dep.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

# Add inputs and outputs from these tool invocations to the build variables
SECONDARY_FLASH += \
TestCompliance.bin \

SECONDARY_LIST += \
TestCompliance.lst \

SECONDARY_MAP += \
TestCompliance.map \

SECONDARY_SIZE += \
TestCompliance.siz \

# All Target
all: main-build

# Main-build Target
main-build: TestCompliance.elf secondary-outputs

# Tool invocations
TestCompliance.elf: $(OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GNU RISC-V Cross C Linker'
	riscv-none-elf-gcc -march=rv32imac_zicsr_zifencei_zicond_zba_zbb_zbc_zbs -msmall-data-limit=8 -mno-save-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g -nostartfiles -nodefaultlibs -nostdlib -Xlinker --gc-sections -Wl,-Map,"TestCompliance.map" --specs=nosys.specs -T ../link.ld -o "TestCompliance.elf" $(OBJS)
	@echo 'Finished building target: $@'
	@echo ' '

TestCompliance.bin: TestCompliance.elf
	@echo 'Invoking: GNU RISC-V Cross Create Flash Image'
	riscv-none-elf-objcopy -O binary "TestCompliance.elf"  "TestCompliance.bin"
	@echo 'Finished building: $@'
	@echo ' '

TestCompliance.lst: TestCompliance.elf
	@echo 'Invoking: GNU RISC-V Cross Create Listing'
	riscv-none-elf-objdump --source --all-headers --demangle --line-numbers --wide "TestCompliance.elf" > "TestCompliance.lst"
	@echo 'Finished building: $@'
	@echo ' '

TestCompliance.siz: TestCompliance.elf
	@echo 'Invoking: GNU RISC-V Cross Print Size'
	riscv-none-elf-size --format=berkeley "TestCompliance.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS) $(SECONDARY_FLASH) $(SECONDARY_LIST) $(SECONDARY_MAP) $(SECONDARY_SIZE) TestCompliance.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_LIST) $(SECONDARY_MAP) $(SECONDARY_SIZE)

.PHONY: all clean dependents main-build

