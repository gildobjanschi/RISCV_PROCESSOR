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
build_subdirmk "add-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin add-01.bin

make clean
build_subdirmk "addi-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin addi-01.bin

make clean
build_subdirmk "and-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin and-01.bin

make clean
build_subdirmk "andi-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin andi-01.bin


make clean
build_subdirmk "auipc-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin auipc-01.bin


make clean
build_subdirmk "beq-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin beq-01.bin


make clean
build_subdirmk "bge-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin bge-01.bin


make clean
build_subdirmk "bgeu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin bgeu-01.bin


make clean
build_subdirmk "blt-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin blt-01.bin


make clean
build_subdirmk "bltu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin bltu-01.bin


make clean
build_subdirmk "bne-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin bne-01.bin


make clean
build_subdirmk "cadd-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cadd-01.bin


make clean
build_subdirmk "caddi-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin caddi-01.bin


make clean
build_subdirmk "caddi16sp-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin caddi16sp-01.bin


make clean
build_subdirmk "caddi4spn-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin caddi4spn-01.bin


make clean
build_subdirmk "cand-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cand-01.bin


make clean
build_subdirmk "candi-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin candi-01.bin


make clean
build_subdirmk "cbeqz-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cbeqz-01.bin


make clean
build_subdirmk "cbnez-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cbnez-01.bin


make clean
build_subdirmk "cj-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cj-01.bin


make clean
build_subdirmk "cjal-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cjal-01.bin


make clean
build_subdirmk "cjalr-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cjalr-01.bin


make clean
build_subdirmk "cjr-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cjr-01.bin



make clean
build_subdirmk "cli-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cli-01.bin


make clean
build_subdirmk "clui-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin clui-01.bin


make clean
build_subdirmk "clw-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin clw-01.bin


make clean
build_subdirmk "clwsp-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin clwsp-01.bin



make clean
build_subdirmk "cmv-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cmv-01.bin


make clean
build_subdirmk "cnop-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cnop-01.bin


make clean
build_subdirmk "cor-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cor-01.bin


make clean
build_subdirmk "cslli-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cslli-01.bin


make clean
build_subdirmk "csr-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin csr-01.bin


make clean
build_subdirmk "csrai-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin csrai-01.bin


make clean
build_subdirmk "csrli-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin csrli-01.bin


make clean
build_subdirmk "csub-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin csub-01.bin


make clean
build_subdirmk "csw-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin csw-01.bin


make clean
build_subdirmk "cswsp-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cswsp-01.bin


make clean
build_subdirmk "cxor-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin cxor-01.bin



make clean
build_subdirmk "div-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin div-01.bin


make clean
build_subdirmk "divu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin divu-01.bin


make clean
build_subdirmk "fence-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin fence-01.bin


make clean
build_subdirmk "jal-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin jal-01.bin


make clean
build_subdirmk "jalr-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin jalr-01.bin


make clean
build_subdirmk "lb-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin lb-align-01.bin


make clean
build_subdirmk "lbu-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin lbu-align-01.bin


make clean
build_subdirmk "lh-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin lh-align-01.bin


make clean
build_subdirmk "lhu-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin lhu-align-01.bin


make clean
build_subdirmk "lui-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin lui-01.bin


make clean
build_subdirmk "lw-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin lw-align-01.bin


make clean
build_subdirmk "misalign1-jalr-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign1-jalr-01.bin


make clean
build_subdirmk "misalign2-jalr-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign2-jalr-01.bin


make clean
build_subdirmk "misalign-beq-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-beq-01.bin


make clean
build_subdirmk "misalign-bge-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-bge-01.bin


make clean
build_subdirmk "misalign-bgeu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-bgeu-01.bin


make clean
build_subdirmk "misalign-blt-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-blt-01.bin


make clean
build_subdirmk "misalign-bltu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-bltu-01.bin


make clean
build_subdirmk "misalign-bne-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-bne-01.bin


make clean
build_subdirmk "misalign-jal-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-jal-01.bin


make clean
build_subdirmk "misalign-lh-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-lh-01.bin


make clean
build_subdirmk "misalign-lhu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-lhu-01.bin


make clean
build_subdirmk "misalign-lw-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-lw-01.bin


make clean
build_subdirmk "misalign-sh-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-sh-01.bin


make clean
build_subdirmk "misalign-sw-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin misalign-sw-01.bin


make clean
build_subdirmk "mul-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin mul-01.bin


make clean
build_subdirmk "mulh-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin mulh-01.bin


make clean
build_subdirmk "mulhsu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin mulhsu-01.bin


make clean
build_subdirmk "mulhu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin mulhu-01.bin


make clean
build_subdirmk "or-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin or-01.bin


make clean
build_subdirmk "ori-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin ori-01.bin


make clean
build_subdirmk "rem-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin rem-01.bin


make clean
build_subdirmk "remu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin remu-01.bin


make clean
build_subdirmk "sb-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sb-align-01.bin


make clean
build_subdirmk "sh-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sh-align-01.bin


make clean
build_subdirmk "sll-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sll-01.bin


make clean
build_subdirmk "slli-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin slli-01.bin


make clean
build_subdirmk "slt-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin slt-01.bin


make clean
build_subdirmk "slti-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin slti-01.bin


make clean
build_subdirmk "sltiu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sltiu-01.bin


make clean
build_subdirmk "sltu-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sltu-01.bin


make clean
build_subdirmk "sra-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sra-01.bin


make clean
build_subdirmk "srai-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin srai-01.bin


make clean
build_subdirmk "srl-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin srl-01.bin


make clean
build_subdirmk "srli-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin srli-01.bin


make clean
build_subdirmk "sub-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sub-01.bin


make clean
build_subdirmk "sw-align-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin sw-align-01.bin


make clean
build_subdirmk "xor-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin xor-01.bin


make clean
build_subdirmk "xori-01";
echo "================================================================================================================="
make all
mv TestCompliance.bin xori-01.bin

