#ifndef _COMPLIANCE_MODEL_H
#define _COMPLIANCE_MODEL_H

#define TEST_CASE_1
#define XLEN	32

#if XLEN == 64
  #define ALIGNMENT 3
#else
  #define ALIGNMENT 2
#endif

#define RVMODEL_DATA_SECTION \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 8; .global tohost; tohost: .dword 0;                     \
        .align 8; .global fromhost; fromhost: .dword 0;                 \
        .popsection;                                                    \
        .align 8; .global begin_regstate; begin_regstate:               \
        .word 128;                                                      \
        .align 8; .global end_regstate; end_regstate:                   \
        .word 4;

//RV_COMPLIANCE_HALT
#define RVMODEL_HALT                    \
    addi x1, x1, 4;                     \
    li x1, 1;                           \
write_tohost:                           \
    sw x1, tohost, t1;                  \
    lui x1, % hi(begin_signature);      \
    addi x1, x1, % lo(begin_signature); \
    lui x2, % hi(end_signature);      \
    addi x2, x2, % lo(end_signature); \
self_loop : j self_loop;

#define RVMODEL_BOOT  \
  lui t0, %hi(_ram_data_begin)              ;\
  addi t0, t0, %lo(_ram_data_begin)         ;\
  lui t3, %hi(_ram_data_end)                ;\
  addi t3, t3, %lo(_ram_data_end)           ;\
  sub t1, t3, t0                            ;\
  srli t5, t1, 2                            ;\
  lui t2, %hi(_rom_copy_to_ram_begin)       ;\
  addi t2, t2, %lo(_rom_copy_to_ram_begin)  ;\
copy_rom_to_ram_words:                      ;\
  beq t5, zero, copy_rom_done               ;\
  lw t4, 0(t2)                              ;\
  addi t2, t2, 4                            ;\
  sw t4, 0(t0)                              ;\
  addi t0, t0, 4                            ;\
  addi t5, t5, -1                           ;\
  j copy_rom_to_ram_words                   ;\
copy_rom_done:                              ;\

//RV_COMPLIANCE_DATA_BEGIN
#define RVMODEL_DATA_BEGIN                                              \
  .align 4; .global begin_signature; begin_signature:

//RV_COMPLIANCE_DATA_END
#define RVMODEL_DATA_END                                                      \
  .align 4; .global end_signature; end_signature:  \
  RVMODEL_DATA_SECTION                                                        \

//RVTEST_IO_INIT
#define RVMODEL_IO_INIT
//RVTEST_IO_WRITE_STR
#define RVMODEL_IO_WRITE_STR(_R, _STR)
//RVTEST_IO_CHECK
#define RVMODEL_IO_CHECK()
//RVTEST_IO_ASSERT_GPR_EQ
#define RVMODEL_IO_ASSERT_GPR_EQ(_S, _R, _I)
//RVTEST_IO_ASSERT_SFPR_EQ
#define RVMODEL_IO_ASSERT_SFPR_EQ(_F, _R, _I)
//RVTEST_IO_ASSERT_DFPR_EQ
#define RVMODEL_IO_ASSERT_DFPR_EQ(_D, _R, _I)

#ifndef RVMODEL_MCLINTBASE
        #define RVMODEL_MCLINTBASE 0x00000000
#endif

#ifndef RVMODEL_MSIP_OFFSET
        #define RVMODEL_MSIP_OFFSET 0x40000344
#endif

#ifndef RVMODEL_MTIMECMP_OFFSET
        #define RVMODEL_MTIMECMP_OFFSET 0xC0004000
#endif

#ifndef RVMODEL_MTIMECMPH_OFFSET
        #define RVMODEL_MTIMECMPH_OFFSET 0xC0004004
#endif

#define RVMODEL_SET_MSW_INT                                                           \
    lui t0,      ((RVMODEL_MCLINTBASE + RVMODEL_MSIP_OFFSET)>> 12);         \
    addi t0, t0, ((RVMODEL_MCLINTBASE + RVMODEL_MSIP_OFFSET) & 0xFFF);      \
    li t1, 1;                                                                         \
    sw t1, (t0);                                                                      \

#define RVMODEL_CLEAR_MSW_INT                                                         \
    lui t0,      ((RVMODEL_MCLINTBASE + RVMODEL_MSIP_OFFSET)>> 12);         \
    addi t0, t0, ((RVMODEL_MCLINTBASE + RVMODEL_MSIP_OFFSET) & 0xFFF);      \
    sw x0, (t0);                                                                      \

#define RVMODEL_SET_MTIMER_INT                                                        \
    lui t0,      ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMP_OFFSET)>> 12);     \
    addi t0, t0, ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMP_OFFSET) & 0xFFF);  \
    sw x0, (t0);                                                                      \
    lui t0,      ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMPH_OFFSET)>> 12);    \
    addi t0, t0, ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMPH_OFFSET) & 0xFFF); \
    sw x0, (t0);                                                                      \

#define RVMODEL_CLEAR_MTIMER_INT                                                      \
    addi t1,x0,1;                                                          \
    neg t1,t1;                                                                         \
    lui t0,      ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMPH_OFFSET)>> 12);    \
    addi t0, t0, ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMPH_OFFSET) & 0xFFF); \
    sw t1, (t0);                                                                      \
    lui t0,      ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMP_OFFSET)>> 12);     \
    addi t0, t0, ((RVMODEL_MCLINTBASE + RVMODEL_MTIMECMP_OFFSET) & 0xFFF);  \
    sw t1, (t0);                                                                      \

#define RVMODEL_CLEAR_MEXT_INT

#endif // _COMPLIANCE_MODEL_H
