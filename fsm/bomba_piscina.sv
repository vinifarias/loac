/**
 *  Questão: Bomba de uma Piscina
 * 
 *  Descrição:
 *    Implemente o circuito de controle da bomba de filtro de uma piscina.
 *    A bomba pode ser alimentada por painéis solares ou pela rede elétrica.
 *    A bomba deve ser ligada para prover filtragem da piscina em média 1
 *    segundo a cada 2 segundos.
 *    No reset, as saídas ficam em 0. Quando houver incidência solar suficiente,
 *    a bomba deve ser ligada aos painéis solares durante 1 segundo a cada 2
 *    segundos (1 segundo ligado, 1 segundo desligado). Quando não houver incidência
 *    solar suficiente, a bomba pode ficar desligada. Se após 2 segundos desligado
 *    a incidência voltar a ficar suficiente, a bomba deve ser ligada durante 2
 *    segundos. Se após 3 segundos desligado a incidência solar voltar a ficar 
 *    suficiente, a bomba deve ser ligada durante 3 segundos. Se a bomba não pode
 *    ser ligada nos painéis solares durante mais do que 3 segundos, ligue-a na
 *    rede. Quando a incidência solar voltar a ser suficiente, volte a operar
 *    pelos painéis solares.
 * 
 *  Entradas: 
 *    - clock – 1 Hz, aparecendo em LED[7]
 *    - reset – assíncrono em SWI[0]
 *    - sol – incidência solar suficiente em SWI[1]
 *
 *  Saídas:
 *    - painel – liga bomba aos paineis solares em LED[0]
 *    - rede – liga bomba na rede elétrica em LED[1]
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
  parameter PAINEL=0, REDE=1, DESLIGADA=2;

  logic reset, sol, painel, rede;
  logic [1:0] state;
  logic [2:0] cont_sol_insuf;

  //  Entradas
  always_comb begin
    reset <= SWI[0];
    sol <= SWI[1];
  end

  //  Execução do loop da máquina de estados
  always_ff@(posedge clk_2 or posedge reset) begin
    if(reset) begin
      painel <= 0;
      rede <= 0;
      cont_sol_insuf <= 0;
    end
    else begin
      unique case (state)

        PAINEL: begin
          rede <= 0;
          if(cont_sol_insuf > 1) begin
            painel <= 1;
            cont_sol_insuf <= cont_sol_insuf - 1;
          end
          else painel <= ~painel;
        end

        REDE: begin
          rede <= 1;
          painel <= 0;
        end

        DESLIGADA: begin
          painel <= 0;
          rede <= 0;
          cont_sol_insuf <= cont_sol_insuf + 1;
        end

      endcase
    end
  end

  //  Definição do estado a partir das entradas
  always_comb begin
    if(sol) state <= PAINEL;
    else begin
      if(cont_sol_insuf > 3) state <= REDE;
      else state <= DESLIGADA;
    end
  end

  //  Saídas
  always_comb begin
    LED[0] <= painel;
    LED[1] <= rede;
    LED[7] <= clk_2;
    LED[6:4] <= cont_sol_insuf;

    unique case (state)
      0: SEG <= 8'b00111111;
      1: SEG <= 8'b00000110;
      2: SEG <= 8'b01011011;
    endcase
  end

endmodule