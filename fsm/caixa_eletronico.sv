/**
 *  Questão: Caixa Eletrônico
 * 
 *  Descrição: 
 *    Implemente o circuito de um caixa eletrônico. No reset, as saídas ficam em 0.
 *    Depois do usuário inserir o cartão no caixa, ele precisa colocar o código de acesso,
 *    formado pelos valores 1, 3 e 7. O usuário pode demorar quanto tempo quiser para iniciar
 *    a colocação do código e pode demorar o quanto tempo quiser de um valor para o próximo, 
 *    mas precisa pelo menos demorar 1 ciclo de clock para cada valor. Depois do código estiver
 *    recebido corretamente, o dinheiro sai. A saída do dinheiro demora 1 ciclo de clock.
 *    Após três tentativas fracassadas de colocar o código correto, o cartão é destruído.
 *    Isso demora 1 ciclo de clock.
 * 
 *  Entradas: 
 *    - clock – 1 Hz, aparecendo em LED[7]
 *    - reset – assíncrono em SWI[0]
 *    - cartão – o usuário inseriu um cartão no caixa em SWI[1]
 *    - código de acesso – valores de 0 à 7 em SWI[6:4]
 *
 *  Saídas:
 *    - dinheiro – saída de dinheiro em LED[0]
 *    - destrói – destruição do cartão em LED[1] 
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
  parameter INICIO=0, RECEBE_VALOR1=1, RECEBE_VALOR2=2, RECEBE_VALOR3=3, VALIDA_SENHA=4, SAI_DINHEIRO=5, DESTROI_CARTAO=6;

  logic reset, cartao, dinheiro, destroi;
  logic [2:0] state;
  logic [2:0] cod, val1, val2, val3;
  logic [1:0] cont_erro;

  //  Entradas
  always_comb begin
    reset <= SWI[0];
    cartao <=  SWI[1];
    cod <= SWI[6:4];
  end

  //  Execução do loop da máquina de estados
  always_ff@(posedge clk_2 or posedge reset) begin
    if(reset) begin
      destroi <= 0;
      dinheiro <= 0;
      state <= INICIO;
      cont_erro = 0;
    end
    else begin
      unique case (state)

        INICIO: begin
          val1 <= 0;
          val2 <= 0;
          val3 <= 0;

          if(cartao && cod == 0) state <= RECEBE_VALOR1;
        end

        RECEBE_VALOR1: begin
          if(cod != 0) begin
            val1 <= cod;
            state <= RECEBE_VALOR2;
          end
        end

        RECEBE_VALOR2: begin
          if(cod != val1) begin
            val2 <= cod;
            state <= RECEBE_VALOR3;
          end
        end

        RECEBE_VALOR3: begin
          if(cod != val2) begin
            val3 <= cod;
            state <= VALIDA_SENHA;
          end
        end

        VALIDA_SENHA: begin
          if(val1 == 1 && val2 == 3 && val3 == 7) state <= SAI_DINHEIRO;
          else begin
            cont_erro = cont_erro + 1;

            if(cont_erro == 3) state <= DESTROI_CARTAO;
            else state <= INICIO;
          end   
        end

        SAI_DINHEIRO: dinheiro <= 1;

        DESTROI_CARTAO: destroi <= 1;
      endcase 
    end
  end

  // Saídas
  always_comb begin
    LED[0] <= dinheiro;
    LED[1] <= destroi;
    LED[7] <= clk_2;

    unique case (state)
        0: SEG <= 8'b00111111;
        1: SEG <= 8'b00000110;
        2: SEG <= 8'b01011011;
        3: SEG <= 8'b01001111;
        4: SEG <= 8'b01100110;
        5: SEG <= 8'b01101101;
        6: SEG <= 8'b01111101;
    endcase
  end

endmodule