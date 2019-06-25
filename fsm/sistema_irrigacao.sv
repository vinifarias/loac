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
 *    Se durante 2 ciclos de clock consecutivos tiver pouca chuva, nos
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

  //  Estados
  parameter MONITORAMENTO = 0, CACAU = 1, CAJU = 2, DESLIGADA = 3, ALARME = 4;

  logic reset, caju, cacau, alarme, cacau_cont;
  logic [1:0] chuva, dil_cont, pc_cont, nc_cont, chuva_anterior;
  logic [2:0] est_atual;
  logic [24:0] clock_lento;

  //  Clock lento
  always_ff@(posedge clk_2) begin
    clock_lento <= clock_lento + 1;
  end

  //  Entradas
  always_comb begin
    reset <= SWI[6];
    chuva <= SWI[1:0];
  end

  //  Execução do loop da máquina de estados
  always_ff @(posedge clock_lento[0] or posedge reset) begin
    if(reset) begin
      caju <= 0;
      cacau <= 0;
      dil_cont = 0;
      pc_cont = 0;
      nc_cont = 0;
      alarme <= 0;
      est_atual <= MONITORAMENTO;
    end
    else begin
      unique case(est_atual)

        MONITORAMENTO: begin
          caju <= 0;
          cacau <= 0;

          unique case(chuva)

            0: begin
              if(chuva_anterior != chuva) nc_cont = 0;
              nc_cont = nc_cont + 1;
              chuva_anterior = 0;
              cacau_cont = 1;
              if(nc_cont == 3) est_atual <= CACAU;
            end

            1: begin
              if(chuva_anterior != chuva) pc_cont = 0;
              pc_cont = pc_cont + 1;
              chuva_anterior = 1;
              cacau_cont = 0;
              if(pc_cont == 2) est_atual <= CACAU;
            end

            3: begin
              if(chuva_anterior != chuva) dil_cont = 0;
              dil_cont = dil_cont + 1;
              chuva_anterior = 3;
              if(dil_cont == 3) est_atual <= ALARME;
            end

          endcase
        end

        CACAU: begin
          cacau <= 1;
          caju <= 0;
          if(cacau_cont == 0) begin
            if(nc_cont == 3) est_atual <= CAJU;
            else est_atual <= DESLIGADA;
          end
          cacau_cont = cacau_cont - 1;
        end

        CAJU: begin
          caju <= 1;
          cacau <= 0;
          est_atual <= DESLIGADA;
        end

        DESLIGADA: begin
          cacau <= 0;
          caju <= 0;
          dil_cont = 0;
          nc_cont = 0;
          pc_cont = 0;

          est_atual <= MONITORAMENTO;
        end

        ALARME: alarme <= 1;

      endcase
    end
  end

  //  Saídas
  always_comb begin
    LED[0] <= caju;
    LED[1] <= cacau;
    LED[2] <= alarme;
    LED[7] <= clock_lento[0];
  end

endmodule
