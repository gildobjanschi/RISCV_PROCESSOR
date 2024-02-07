#!/usr/bin/bash

OUTPUT_FILE=src/subdir.mk

build_subdirmk()
{
    echo "#subdir.mk" > $OUTPUT_FILE

    echo "S_UPPER_SRCS += \\" >> $OUTPUT_FILE
    echo "../src/$1.S" >> $OUTPUT_FILE
    echo $'\n' >> $OUTPUT_FILE
    echo "OBJS += \\" >> $OUTPUT_FILE
    echo "./src/$1.o" >> $OUTPUT_FILE
    echo $'\n' >> $OUTPUT_FILE
    echo "S_UPPER_DEPS += \\" >> $OUTPUT_FILE
    echo "./src/$1.d" >> $OUTPUT_FILE
    echo $'\n' >> $OUTPUT_FILE
    cat subdir_frag.mk >> $OUTPUT_FILE
}

mkdir -p src

rm src/*
rm *.bin


make clean
build_subdirmk "riscv_arithmetic_basic_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_arithmetic_basic_test_0.bin

make clean
build_subdirmk "riscv_ebreak_debug_mode_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_ebreak_debug_mode_test_0.bin

make clean
build_subdirmk "riscv_ebreak_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_ebreak_test_0.bin

make clean
build_subdirmk "riscv_full_interrupt_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_full_interrupt_test_0.bin

make clean
build_subdirmk "riscv_hint_instr_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_hint_instr_test_0.bin

make clean
build_subdirmk "riscv_illegal_instr_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_illegal_instr_test_0.bin

make clean
build_subdirmk "riscv_jump_stress_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_jump_stress_test_0.bin

make clean
build_subdirmk "riscv_loop_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_loop_test_0.bin

make clean
build_subdirmk "riscv_mmu_stress_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_mmu_stress_test_0.bin

make clean
build_subdirmk "riscv_no_fence_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_no_fence_test_0.bin

make clean
build_subdirmk "riscv_non_compressed_instr_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_non_compressed_instr_test_0.bin

make clean
build_subdirmk "riscv_rand_instr_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_rand_instr_test_0.bin

make clean
build_subdirmk "riscv_rand_jump_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_rand_jump_test_0.bin

make clean
build_subdirmk "riscv_unaligned_load_store_test_0";
echo "================================================================================================================="
make all
mv RandomTest.bin riscv_unaligned_load_store_test_0.bin

