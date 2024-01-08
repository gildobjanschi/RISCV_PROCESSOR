################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../src/xor-01.S \
../src/pre_start.S 

OBJS += \
./src/xor-01.o \
./src/pre_start.o 

S_UPPER_DEPS += \
./src/xor-01.d \
./src/pre_start.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.S src/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU RISC-V Cross Assembler'
	riscv-none-elf-gcc -march=rv32imczicsr -msmall-data-limit=8 -mno-save-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -g -x assembler-with-cpp -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


