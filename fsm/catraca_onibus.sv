/**
 *  Questão: Catraca de Ônibus
 * 
 *  Descrição:
 *    Implemente o circuito de controle de uma catraca de ônibus.
 *    Só existem 2 passageiros em todo o território do sistema de transporte.
 *    Só existe 1 ônibus.
 *
 *    No reset, o dinheiro armazenado nos cartões é zerado e a catraca travada.
 *    Quando um passageiro passa o cartão, na subida do clock, se ele tiver
 *    dinheiro, no próximo pulso do clock, a catraca trava e o dinheiro dele
 *    diminui em 1 unidade.
 *    Se os dois passageiros passam o cartão ao mesmo tempo, nada acontece.
 *    Se um passageiro passa o cartão antes que a catraca tenha travado após
 *    a passagem do passageiro anterior, nada diferente acontece.
 *    Quando um passageiro carregar um valor (entrada carrega >0 no momento
 *    da subida do clock), o dinheiro armazenado aumenta pelo valor da
 *    entrada carregada correspondente.
 *    O valor armazenado não pode passar de 5.
 *    Ninguém precisa ficar em fila de espera para carregar o cartão.
 * 
 *  Entradas:
 *    - clock - 1Hz, aparecendo em SEG[7]
 *              podendo ser travado com SWI[7]
 *    - reset - síncrono, SWI[6]
 *    - passe1 - passageiro 1 está passando o cartão dele - SWI[0]
 *    - passe2 - passageiro 2 está passando o cartão dele - SWI[1]
 *    - carrega1 - carregamento para o cartão do passageiro 1 - SWI[3:2]
 *    - carrega2 - carregamento para o cartão do passageiro 2 - SWI[5:4]
 *
 *  Saídas:
 *    - conta - dinheiro armazenado no cartão daquele passageiro
 *              que está passando o cartão dele - SEG[6:0]
 *    - catraca - sinal que libera a catraca - LED[0]
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
  parameter LIBERADA=1, TRAVADA=0;
  
  logic reset, passe1, passe2, catraca, state;
  logic [1:0] carrega1, carrega2;
  logic [2:0] conta, cartao1, cartao2;

  //  Entradas
  always_comb begin
    reset <= SWI[6];
    passe1 <= SWI[0];
    passe2 <= SWI[1];
    carrega1 <= SWI[3:2];
    carrega2 <= SWI[5:4];
  end

  //  Execução do loop da máquina de estados
  always_ff@(posedge clk_2 or posedge reset) begin
    if(reset) begin
      catraca <= 0;
      conta = 0;
      state <= TRAVADA;
    end
    else begin

      if((carrega1 + cartao1) > 5) cartao1 <= 5;
      else cartao1 <= cartao1 + carrega1;

      if((carrega2 + cartao2) > 5) cartao2 <= 5;
      else cartao2 <= cartao2 + carrega2;

      unique case (state)

        TRAVADA: begin
          catraca <= 0;
          conta = 0;

          if(passe1 && passe2) state <= TRAVADA;
          else if(passe1) begin
            if(cartao1 > 0) begin
              state <= LIBERADA;
              cartao1 <= cartao1 - 1;
            end
          end
          else if(passe2) begin
            if(cartao2 > 0) begin
              state <= LIBERADA;
              cartao2 <= cartao2 - 1;
            end
          end
        end

        LIBERADA: begin
          catraca <= 1;
          state <= TRAVADA;
        end
      endcase
    end
  end

  //  Saídas
  always_comb begin
    LED[0] <= catraca;
    SEG[7] <= clk_2;

    if(passe1) conta = cartao1;
    else if(passe2) conta = cartao2;

    unique case (conta)
      0: SEG[6:0] <= 7'b0111111;
      1: SEG[6:0] <= 7'b0000110;
      2: SEG[6:0] <= 7'b1011011;
      3: SEG[6:0] <= 7'b1001111;
      4: SEG[6:0] <= 7'b1100110;
      5: SEG[6:0] <= 7'b1101101;
    endcase
  end
endmodule