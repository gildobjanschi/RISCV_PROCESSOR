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

    mkdir -p src

    rm -f src/*
    rm -f *.bin
    rm -f *.elf
    rm -f *.lst
    rm -f *.map
    rm -f *.sig

    if [ "$SIGNATURE" = "1" ] ; then
        if ! [ -x "$(command -v spike)" ]; then
            echo -e "\033[0;31m     Error: spike is not installed. See https://github.com/riscv-software-src/riscv-isa-sim for instructions to build it.\033[0m"
            exit 1
        fi
    fi

build_test()
{
    make clean
    make target="$1/$2" all

    if [ $? -eq 0 ]; then
        echo -e "\033[0;32mGenerated: $2.bin\033[0m"
        mv TestCompliance.bin $2.bin

        if [ "$SIGNATURE" = "1" ] ; then
            echo "Generating signature with spike..."
            spike -m0x600000:16777216,0x80000000:8388608 --isa=RV32IMAC_zifencei_zicsr_zicond_zba_zbb_zbc_zbs --misaligned --priv=msu +signature=../reference/$2.sig +signature-granularity=4 TestCompliance.elf
            if [ $? -eq 0 ]; then
                echo -e "\033[0;32mGenerated: ../reference/$2.sig\033[0m"
            else
                echo -e "\033[0;31mCannot generate signature ../reference/$2.sig\033[0m"
            fi
        fi

        if [ "$LST" = "1" ] ; then
            echo -e "\033[0;32mGenerated: $2.lst\033[0m"
            mv TestCompliance.lst $2.lst
        fi

        if [ "$ELF" = "1" ] ; then
            mv TestCompliance.elf $2.elf
            echo -e "\033[0;32mGenerated: $2.elf\033[0m"
        fi
    else
        echo -e "\033[0;31mCannot generate $2.bin\033[0m"
    fi

    echo "=================================================================================================================================================="
}

# Base ISA
build_test "rv32i_m/I/src" "add-01";
build_test "rv32i_m/I/src" "addi-01";
build_test "rv32i_m/I/src" "and-01";
build_test "rv32i_m/I/src" "andi-01";
build_test "rv32i_m/I/src" "auipc-01";
build_test "rv32i_m/I/src" "beq-01";
build_test "rv32i_m/I/src" "bge-01";
build_test "rv32i_m/I/src" "bgeu-01";
build_test "rv32i_m/I/src" "blt-01";
build_test "rv32i_m/I/src" "bltu-01";
build_test "rv32i_m/I/src" "bne-01";
build_test "rv32i_m/I/src" "fence-01";
build_test "rv32i_m/I/src" "jal-01";
build_test "rv32i_m/I/src" "jalr-01";
build_test "rv32i_m/I/src" "lb-align-01";
build_test "rv32i_m/I/src" "lbu-align-01";
build_test "rv32i_m/I/src" "lh-align-01";
build_test "rv32i_m/I/src" "lhu-align-01";
build_test "rv32i_m/I/src" "lui-01";
build_test "rv32i_m/I/src" "lw-align-01";
build_test "rv32i_m/I/src" "misalign1-jalr-01";
build_test "rv32i_m/I/src" "or-01";
build_test "rv32i_m/I/src" "ori-01";
build_test "rv32i_m/I/src" "sb-align-01";
build_test "rv32i_m/I/src" "sh-align-01";
build_test "rv32i_m/I/src" "sll-01";
build_test "rv32i_m/I/src" "slli-01";
build_test "rv32i_m/I/src" "slt-01";
build_test "rv32i_m/I/src" "slti-01";
build_test "rv32i_m/I/src" "sltiu-01";
build_test "rv32i_m/I/src" "sltu-01";
build_test "rv32i_m/I/src" "sra-01";
build_test "rv32i_m/I/src" "srai-01";
build_test "rv32i_m/I/src" "srl-01";
build_test "rv32i_m/I/src" "srli-01";
build_test "rv32i_m/I/src" "sub-01";
build_test "rv32i_m/I/src" "sw-align-01";
build_test "rv32i_m/I/src" "xor-01";
build_test "rv32i_m/I/src" "xori-01";

# Zba extension
build_test "rv32i_m/B/src" "sh1add-01";
build_test "rv32i_m/B/src" "sh2add-01";
build_test "rv32i_m/B/src" "sh3add-01";

# Zbb extension
build_test "rv32i_m/B/src" "clz-01";
build_test "rv32i_m/B/src" "cpop-01";
build_test "rv32i_m/B/src" "ctz-01";
build_test "rv32i_m/B/src" "max-01";
build_test "rv32i_m/B/src" "maxu-01";
build_test "rv32i_m/B/src" "min-01";
build_test "rv32i_m/B/src" "minu-01";
build_test "rv32i_m/B/src" "orcb_32-01";
build_test "rv32i_m/B/src" "orn-01";
build_test "rv32i_m/B/src" "rev8_32-01";
build_test "rv32i_m/B/src" "rol-01";
build_test "rv32i_m/B/src" "ror-01";
build_test "rv32i_m/B/src" "rori-01";
build_test "rv32i_m/B/src" "sext.b-01";
build_test "rv32i_m/B/src" "sext.h-01";
build_test "rv32i_m/B/src" "xnor-01";
build_test "rv32i_m/B/src" "zext.h_32-01";

# Zbc extension
build_test "rv32i_m/B/src" "clmul-01";
build_test "rv32i_m/B/src" "clmulh-01";
build_test "rv32i_m/B/src" "clmulr-01";

# Zbs extension
build_test "rv32i_m/B/src" "bclr-01";
build_test "rv32i_m/B/src" "bclri-01";
build_test "rv32i_m/B/src" "bext-01";
build_test "rv32i_m/B/src" "bexti-01";
build_test "rv32i_m/B/src" "binv-01";
build_test "rv32i_m/B/src" "binvi-01";
build_test "rv32i_m/B/src" "bset-01";
build_test "rv32i_m/B/src" "bseti-01";

# Priviledged tests
build_test "rv32i_m/privilege/src" "ebreak";
build_test "rv32i_m/privilege/src" "ecall";
build_test "rv32i_m/privilege/src" "misalign2-jalr-01";
build_test "rv32i_m/privilege/src" "misalign-beq-01";
build_test "rv32i_m/privilege/src" "misalign-bge-01";
build_test "rv32i_m/privilege/src" "misalign-bgeu-01";
build_test "rv32i_m/privilege/src" "misalign-blt-01";
build_test "rv32i_m/privilege/src" "misalign-bltu-01";
build_test "rv32i_m/privilege/src" "misalign-bne-01";
build_test "rv32i_m/privilege/src" "misalign-jal-01";
# These tests are not supported since a word and a half word need to be aligned at even addresses.
#build_test "rv32i_m/privilege/src" "misalign-lh-01";
#build_test "rv32i_m/privilege/src" "misalign-lhu-01";
#build_test "rv32i_m/privilege/src" "misalign-lw-01";
#build_test "rv32i_m/privilege/src" "misalign-sh-01";
#build_test "rv32i_m/privilege/src" "misalign-sw-01";
# Zicsr extension
build_test "rv32i_m/privilege/src" "csr-01";

# Compressed extension
build_test "rv32i_m/C/src" "cadd-01";
build_test "rv32i_m/C/src" "caddi-01";
build_test "rv32i_m/C/src" "caddi16sp-01";
build_test "rv32i_m/C/src" "caddi4spn-01";
build_test "rv32i_m/C/src" "cand-01";
build_test "rv32i_m/C/src" "candi-01";
build_test "rv32i_m/C/src" "cbeqz-01";
build_test "rv32i_m/C/src" "cbnez-01";
build_test "rv32i_m/C/src" "cebreak-01";
build_test "rv32i_m/C/src" "cj-01";
build_test "rv32i_m/C/src" "cjal-01";
build_test "rv32i_m/C/src" "cjalr-01";
build_test "rv32i_m/C/src" "cjr-01";
build_test "rv32i_m/C/src" "cli-01";
build_test "rv32i_m/C/src" "clui-01";
build_test "rv32i_m/C/src" "clw-01";
build_test "rv32i_m/C/src" "clwsp-01";
build_test "rv32i_m/C/src" "cmv-01";
build_test "rv32i_m/C/src" "cnop-01";
build_test "rv32i_m/C/src" "cor-01";
build_test "rv32i_m/C/src" "cslli-01";
build_test "rv32i_m/C/src" "csrai-01";
build_test "rv32i_m/C/src" "csrli-01";
build_test "rv32i_m/C/src" "csub-01";
build_test "rv32i_m/C/src" "csw-01";
build_test "rv32i_m/C/src" "cswsp-01";
build_test "rv32i_m/C/src" "cxor-01";

# Multiply/Divide extension
build_test "rv32i_m/M/src" "mul-01";
build_test "rv32i_m/M/src" "mulh-01";
build_test "rv32i_m/M/src" "mulhsu-01";
build_test "rv32i_m/M/src" "mulhu-01";
build_test "rv32i_m/M/src" "div-01";
build_test "rv32i_m/M/src" "divu-01";
build_test "rv32i_m/M/src" "rem-01";
build_test "rv32i_m/M/src" "remu-01";

# Atomic extension
build_test "rv32i_m/A/src" "amoadd.w-01";
build_test "rv32i_m/A/src" "amoand.w-01";
build_test "rv32i_m/A/src" "amomax.w-01";
build_test "rv32i_m/A/src" "amomaxu.w-01";
build_test "rv32i_m/A/src" "amomin.w-01";
build_test "rv32i_m/A/src" "amominu.w-01";
build_test "rv32i_m/A/src" "amoor.w-01";
build_test "rv32i_m/A/src" "amoswap.w-01";
build_test "rv32i_m/A/src" "amoxor.w-01";

# Zifencei extension
# The test assumes that the instruction memory is writtable which is not the case in this implementation.
#build_test "rv32i_m/Zifencei/src" "Fencei";

#Zicond extension
build_test "rv32i_m/Zicond/src" "czero.eqz-01";
build_test "rv32i_m/Zicond/src" "czero.nez-01";

