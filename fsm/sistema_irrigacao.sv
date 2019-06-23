/**
 *  Questão: Sistema de Irrigação
 * 
 *  Descrição:
 *    Implemente o circuito de controle de um sistema de irrigação de uma plantação.
 *    O sistema faz irrigação de duas plantas, um pé de caju e um pé de cacau.
 *    O sistema possui um sensor de chuva e regula o tempo de irrigação conforme a
 *    necessidade.
 *
 *    No reset, todas as saídas de água ficam desligadas.
 *    Enquanto houver muita chuva ou dilúvio, as saídas de água ficam desligadas.
 *    Se durante 2 ciclos de clock consecutivos tiver pouca ou nenhuma chuva, nos
 *    próximos 2 ciclos de clock, ligue a água só do pé de cacau por 1 ciclo de
 *    clock e deixe desligado no ciclo de clock seguinte.
 *    Se durante 3 ciclos de clock consecutivos tiver nenhuma chuva, nos próximos
 *    3 ciclos de clock, ligue a água do pé de cacau por 2 ciclos de clock e a do
 *    pé de caju por 1 ciclo de clock.
 *    Se tiver dilúvio durante 3 ciclos de clock acione o alarme.
 *    
 *    O monitoramento do sensor de chuva fica correndo independentemente do
 *    acionamento das saídas de água, ou seja, a água de irrigação não cai em cima
 *    do sensor de chuva.
 * 
 *  Entradas:
 *    - clock - 1Hz, aparecendo em SEG[7]
 *              podendo ser travado com SWI[7]
 *    - reset - síncrono, SWI[6]
 *    - chuva - 0 - nenhuma, 1 - pouca, 2 - muita, 3 - dilúvio, SWI[1:0]
 *
 *  Saídas:
 *    - caju - aciona a saída de água para o pé de caju, LED[0]
 *    - cacau - aciona a saída de água para o pé de cacau, LED[1]
 *    - alarme - LED[2]
 *
 *  Autor: Marcus Vinícius
 */

parameter NINSTR_BITS = 32;
parameter NBITS_TOP = 8, NREGS_TOP = 32, NBITS_LCD = 64;
module top(input  logic clk_2,
           input  logic [NBITS_TOP-1:0] SWI,
           output logic [NBITS_TOP-1:0] LED,
           output logic [NBITS_TOP-1:0] SEG,
           output logic [NBITS_LCD-1:0] lcd_a, lcd_b,
           output logic [NINSTR_BITS-1:0] lcd_instruction,
           output logic [NBITS_TOP-1:0] lcd_registrador [0:NREGS_TOP-1],
           output logic [NBITS_TOP-1:0] lcd_pc, lcd_SrcA, lcd_SrcB,
             lcd_ALUResult, lcd_Result, lcd_WriteData, lcd_ReadData, 
           output logic lcd_MemWrite, lcd_Branch, lcd_MemtoReg, lcd_RegWrite);

endmodule
