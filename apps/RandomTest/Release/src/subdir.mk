#subdir.mk
S_UPPER_SRCS += \
../src/riscv_unaligned_load_store_test_0.S


OBJS += \
./src/riscv_unaligned_load_store_test_0.o


S_UPPER_DEPS += \
./src/riscv_unaligned_load_store_test_0.d



src/%.o: ../src/%.S src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv-none-elf-gcc -march=rv32imac_zicsr_zifencei -mabi=ilp32 -msmall-data-limit=8 -mno-save-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


