/**
 *  Questão: Elevador
 * 
 *  Descrição:
 *    Implemente o circuito de controle de um elevador.
 *    O elevador leva pessoas do andar A para o andar B.
 *    Ele não leva pessoas de B para A. A capacidade máxima do elevador é de
 *    2 pessoas.
 *    
 *    Quando a porta no andar A estiver aberta, pessoas podem entrar no
 *    elevador, uma a cada clock. Tem um sensor na porta que detecta a
 *    entrada de uma pessoa.
 *    Quando tiverem 2 pessoas dentro do elevador, a porta se fecha e o
 *    elevador vai para o andar B.
 *    Quando tiver somente 1 pessoa dentro do elevador mas ela já esperou
 *    durante 2 ciclos de clock, a porta se fecha e o elevador vai para o
 *    andar B.
 *    Depois de 2 ciclos de clock ele chega no andar B, a porta se abre por
 *    tantos ciclos de clock quanto tem passageiros, e volta para o andar A
 *    em 2 ciclos de clock.
 *    No andar A a porta se abre e tudo recomeça do início.
 *    
 *    No reset, a porta deve estar aberta e o elevador deve estar no andar A
 *    e ele estar vazio.
 *    A entrada de uma pessoa é sinalizada na subida do clock.
 *    Se o sinal fica ativo durante duas subidas de clock, duas pessoas entraram.

 *    
 *
 *  Entradas:
 *    - clock - 0,5Hz, aparecendo em SEG[7]
 *    - reset - SWI[7]
 *    - pessoa - sinaliza entrada de 1 pessoa no elevador, SWI[0]
 *
 *  Saídas:
 *    - andar - 0: andar A
 *              1: andar B
 *              LED[0]
 *    - porta - sinaliza que a porta está aberta, LED[1]
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
  parameter ANDAR_A=0, CAMINHO=1, ANDAR_B=2;

  logic andar, reset, porta, pessoa;
  logic [1:0] cont_pessoa, cont_clock, state;
  logic clock_1sec, clock_2sec;

  //  Entradas
  always_comb begin
    reset <= SWI[7];
    pessoa <= SWI[0];
  end

  //  Clock de 1Hz (1s)
  always_ff@(posedge clk_2) begin
    clock_1sec <= ~clock_1sec;
  end

  //  Clock de 0.5Hz (2s)
  always_ff@(posedge clock_1sec) begin
    clock_2sec <= ~clock_2sec;
  end

  //  Execução do loop da máquina de estados
  always_ff @(posedge clock_2sec) begin
    if(reset) begin
      porta <= 1;
      andar <= 0;
      cont_pessoa <= 0;
      cont_clock = 0;
    end
    else begin
      unique case(state)

        ANDAR_A: begin
          andar <= 0;
          porta <= 1;

          if(pessoa) cont_pessoa <= cont_pessoa + 1;

          if(cont_pessoa == 2) begin
            porta <= 0;
            state <= CAMINHO;
          end
          else if(cont_pessoa == 1) begin
            if(cont_clock == 2) begin
              cont_clock = 0;
              state <= CAMINHO;
            end
            cont_clock = cont_clock + 1;
          end
        end

        CAMINHO: begin
          porta <= 0;
          cont_clock = cont_clock + 1;

          if(cont_clock == 2) begin
            cont_clock = cont_pessoa;
            if(andar == 0) state <= ANDAR_B;
            else state <= ANDAR_A;
          end
        end

        ANDAR_B: begin
          andar <= 1;
          porta <= 1;
          cont_clock = cont_clock - 1;

          if(cont_clock == 0) begin
            cont_clock = 0;
            cont_pessoa <= 0;
            state <= CAMINHO;
          end
        end

      endcase
    end
  end

  //  Saídas
  always_comb begin
    LED[0] <= andar;
    LED[1] <= porta;
    LED[7:6] <= cont_pessoa;
    SEG[7] <= clock_2sec;
  end

endmodule