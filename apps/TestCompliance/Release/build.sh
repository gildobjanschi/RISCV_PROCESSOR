#!/usr/bin/bash

helpFunction()
{
    echo ""
    echo "Usage: $0 -l -e -s -h"
    echo "    -l: Keep .lst files."
    echo "    -e: Keep .elf files."
    echo "    -s: Generate reference signature files using spike."
    echo "    -h: Help."
    exit 1 # Exit script after printing help
}

SIGNATURE="0"
LST="0"
ELF="0"

while getopts "lesh" flag; do
    case "${flag}" in
        l ) echo "Keeping .lst files."; LST="1";;
        e ) echo "Keeping .elf files."; ELF="1";;
        s ) echo "Generating signature files."; SIGNATURE="1";;
        h ) helpFunction ;;
        * ) helpFunction ;; #Invalid argument
    esac
done

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
rm *.elf
rm *.lst
rm *.map
rm *.sig


build_test()
{
    make clean
    build_subdirmk $1;
    echo "================================================================================================================="
    make all
    if [ "$SIGNATURE" = "1" ] ; then
        echo "Generate signature..."
        spike -m0x600000:16777216,0x80000000:8388608 --isa=RV32IMAC_zifencei_zicsr --misaligned --priv=msu +signature=../reference/$1.sig +signature-granularity=4 TestCompliance.elf
        echo "Signature generated."
    fi

    if [ "$LST" = "1" ] ; then
        mv TestCompliance.lst $1.lst
    fi
    if [ "$ELF" = "1" ] ; then
        mv TestCompliance.elf $1.elf
    fi
    mv TestCompliance.bin $1.bin
}

#build_test "ebreak";
#build_test "ecall";

# Base ISA
build_test "add-01";
build_test "addi-01";
build_test "and-01";
build_test "andi-01";
build_test "auipc-01";
build_test "beq-01";
build_test "bge-01";
build_test "bgeu-01";
build_test "blt-01";
build_test "bltu-01";
build_test "bne-01";
build_test "fence-01";
build_test "jal-01";
build_test "jalr-01";
build_test "lb-align-01";
build_test "lbu-align-01";
build_test "lh-align-01";
build_test "lhu-align-01";
build_test "lui-01";
build_test "lw-align-01";
build_test "or-01";
build_test "ori-01";
build_test "sb-align-01";
build_test "sh-align-01";
build_test "sll-01";
build_test "slli-01";
build_test "slt-01";
build_test "slti-01";
build_test "sltiu-01";
build_test "sltu-01";
build_test "sra-01";
build_test "srai-01";
build_test "srl-01";
build_test "srli-01";
build_test "sub-01";
build_test "sw-align-01";
build_test "xor-01";
build_test "xori-01";

# Priviledged tests
#build_test "ebreak";
#build_test "ecall";
build_test "misalign1-jalr-01";
build_test "misalign2-jalr-01";
build_test "misalign-beq-01";
build_test "misalign-bge-01";
build_test "misalign-bgeu-01";
build_test "misalign-blt-01";
build_test "misalign-bltu-01";
build_test "misalign-bne-01";
build_test "misalign-jal-01";
# These tests are not supported since a word and a half word need to be aligned at even addresses.
#build_test "misalign-lh-01";
#build_test "misalign-lhu-01";
#build_test "misalign-lw-01";
#build_test "misalign-sh-01";
#build_test "misalign-sw-01";

# Compressed extension
build_test "cadd-01";
build_test "caddi-01";
build_test "caddi16sp-01";
build_test "caddi4spn-01";
build_test "cand-01";
build_test "candi-01";
build_test "cbeqz-01";
build_test "cbnez-01";
build_test "cj-01";
build_test "cjal-01";
build_test "cjalr-01";
build_test "cjr-01";
build_test "cli-01";
build_test "clui-01";
build_test "clw-01";
build_test "clwsp-01";
build_test "cmv-01";
build_test "cnop-01";
build_test "cor-01";
build_test "cslli-01";
build_test "csrai-01";
build_test "csrli-01";
build_test "csub-01";
build_test "csw-01";
build_test "cswsp-01";
build_test "cxor-01";

# Multiply/Divide extension
build_test "mul-01";
build_test "mulh-01";
build_test "mulhsu-01";
build_test "mulhu-01";
build_test "div-01";
build_test "divu-01";
build_test "rem-01";
build_test "remu-01";

# Zicsr extension
build_test "csr-01";

# Atomic extension
build_test "amoadd.w-01";
build_test "amoand.w-01";
build_test "amomax.w-01";
build_test "amomaxu.w-01";
build_test "amomin.w-01";
build_test "amominu.w-01";
build_test "amoor.w-01";
build_test "amoswap.w-01";
build_test "amoxor.w-01";

# Zifencei extension
# The test assumes that the instruction memory is writtable which is not the case in this implementation.
#build_test "Fencei";
