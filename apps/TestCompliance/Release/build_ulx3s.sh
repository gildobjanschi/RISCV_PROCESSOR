#!/usr/bin/bash

mkdir -p src

rm src/*
rm *.bin

make -f makefile_ulx3s clean
cp subdir_add-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin add-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_addi-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin addi-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_and-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin and-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_andi-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin andi-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_auipc-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin auipc-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_beq-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin beq-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_bge-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin bge-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_bgeu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin bgeu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_blt-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin blt-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_bltu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin bltu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_bne-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin bne-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cadd-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cadd-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_caddi-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin caddi-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_caddi16sp-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin caddi16sp-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_caddi4spn-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin caddi4spn-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cand-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cand-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_candi-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin candi-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cbeqz-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cbeqz-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cbnez-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cbnez-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cj-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cj-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cjal-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cjal-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cjalr-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cjalr-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cjr-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cjr-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cli-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cli-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_clui-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin clui-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_clw-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin clw-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_clwsp-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin clwsp-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cmv-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cmv-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cnop-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cnop-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cor-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cor-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cslli-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cslli-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_csr-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin csr-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_csrai-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin csrai-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_csrli-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin csrli-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_csub-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin csub-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_csw-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin csw-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cswsp-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cswsp-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_cxor-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin cxor-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_div-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin div-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_divu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin divu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_jal-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin jal-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_jalr-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin jalr-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_lb-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin lb-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_lbu-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin lbu-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_lh-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin lh-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_lhu-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin lhu-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_lui-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin lui-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_lw-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin lw-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_misalign1-jalr-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin misalign1-jalr-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_mul-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin mul-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_mulh-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin mulh-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_mulhsu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin mulhsu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_mulhu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin mulhu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_or-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin or-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_ori-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin ori-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_rem-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin rem-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_remu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin remu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sb-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sb-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sh-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sh-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sll-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sll-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_slli-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin slli-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_slt-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin slt-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_slti-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin slti-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sltiu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sltiu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sltu-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sltu-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sra-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sra-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_srai-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin srai-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_srl-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin srl-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_srli-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin srli-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sub-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sub-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_sw-align-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin sw-align-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_xor-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin xor-01.bin
rm src/subdir.mk

make -f makefile_ulx3s clean
cp subdir_xori-01.mk src/subdir.mk
echo "================================================================================================================="
make -f makefile_ulx3s all
mv TestCompliance.bin xori-01.bin
rm src/subdir.mk
