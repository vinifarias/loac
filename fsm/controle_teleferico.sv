/**
 *  Questão: Controle Teleférico
 * 
 *  Descrição:
 *    Implemente o circuito de controle de um teleférico.
 *    O teleférico tem duas cabines grandes. Estas cabines estão conectadas
 *    a um só cabo de tração fechado em laço, passando da base para o topo
 *    e voltando para a base. Sendo assim, quando uma cabine está na estação
 *    no topo da montanha, a outra se encontra na estação base e quando uma
 *    estiver subindo, a outra está descendo.
 *    
 *    Cada cabine conta com um operador humano que sinaliza quando a cabine
 *    está pronta para partir.
 *    
 *    Em cada estação tem um sensor que sinaliza quando uma cabine está perto
 *    e outra quando a cabine está na posição de estacionamento.
 *    
 *    No reset, o motor fica desligado e em marcha lenta e sem alarme.
 *    Após o reset, a cabine A tem que estar no topo e a cabine B na base    
 *    Caso um dos sensores (chegou_base ou chegou_topo) estiver desativado
 *    deve-se ligar logo o alarme.
 *    Quando uma cabine estiver na estação, o operador pode sinalizar
 *    que está pronto para partir. Quando as duas cabines estiverem
 *    prontas, o motor liga em marcha lenta.
 *    Dentro de 3 segundos ambas as cabines devem estar longe das suas
 *    estações (sensor de proximidade desativado), caso contrário se
 *    liga o alarme.
 *    Estando longe das estações, o motor passa a andar em velocidade
 *    normal.
 *    Em no máximo 5 segundos ambas as cabines devem estar novamente
 *    próximo das estações, caso contrário é ligado o alarme.
 *    Estando próximos, o motor passa para marcha lenta.
 *    Dentro de 3 segundos ambas as cabines devem ter chegado nas suas
 *    estações, se não dá alarme. Assim que ambas chegaram o motor é
 *    desligado.
 *    Em qualquer condição de alarme o motor deve ser desligado.
 *
 *  Entradas:
 *    - clock - 1Hz, aparecendo em SEG[7]
 *    - reset - síncrono, SWI[7]
 *    - A_pronta - cabine A está pronta para partir - SWI[0]
 *    - B_pronta - cabine B está pronta para partir - SWI[1]
 *    - perto_base - uma cabine está próxima da estação base - SWI[2]
 *    - perto_topo - uma cabine está próxima da estação topo - SWI[3]
 *    - chegou_base - cabine na estação base - SWI[4]
 *    - chegou_topo - cabine na estação topo - SWI[5]
 *
 *  Saídas:
 *    - subir_A - motor está ligado no sentido que faz a cabine A subir
 *                e a cabine B descer - SEG[0]
 *    - subir_B - motor está ligado no sentido que faz a cabine B subir
 *                e a cabine A descer - SEG[3]
 *    - lento - coloca o motor em marcha lenta - LED[0]
 *    - alarme - indica algum problema no funcionamento - LED[7]
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
  parameter INICIO = 0, MARCHA_LENTA = 1, MARCHA_NORMAL = 2, ALARME = 3;

  logic reset, marcha_saindo, A_pronta, B_pronta, perto_base, perto_topo, chegou_base, chegou_topo,
        subir_A, subir_B, lento, alarme, A_topo;
  logic [1:0] cont_marcha_lenta, state;
  logic [2:0] cont_marcha_normal;
  logic [24:0] clock_lento;

  //  Entradas
  always_comb begin
    A_pronta <= SWI[0];
    B_pronta <= SWI[1];
    perto_base <= SWI[2];
    perto_topo <= SWI[3];
    chegou_base <= SWI[4];
    chegou_topo <= SWI[5];
    reset <= SWI[7];
  end

  //  Clock lento
  always_ff@(posedge clk_2) begin
    clock_lento <= clock_lento + 1;
  end

  //  Execução do loop da máquina de estados
  always_ff @(posedge clock_lento[0]) begin
    if(reset) begin
      lento <= 1;
      alarme <= 0;
      subir_A <= 0;
      subir_B <= 0;
      state <= INICIO;
      A_topo <= 1;
    end
    else begin
      unique case(state)

        INICIO: begin

          if(chegou_base == 0 || chegou_topo == 0) state <= ALARME;
          else if(A_pronta && B_pronta) begin
            state <= MARCHA_LENTA;
            cont_marcha_lenta <=  3;
            marcha_saindo <= 1;
            
            if(A_topo) begin
              subir_B <= 1;
              subir_A <= 0;
            end
            else begin
              subir_B <= 0;
              subir_A <= 1;
            end
          end
        end

        MARCHA_LENTA: begin
          lento <= 1;
          cont_marcha_lenta <= cont_marcha_lenta - 1;

          if(cont_marcha_lenta == 0) begin
            if(marcha_saindo == 1 && perto_base == 0 && perto_topo == 0) begin
              cont_marcha_normal <= 5;
              state <= MARCHA_NORMAL;
            end
            else if(marcha_saindo == 0 && chegou_base == 1 && chegou_topo == 1) begin
              state <= INICIO;
              A_topo <= ~A_topo;
            end
            else state <= ALARME;
          end
        end

        MARCHA_NORMAL: begin
          lento <= 0;
          cont_marcha_normal <= cont_marcha_normal - 1;

          if(cont_marcha_normal == 0) begin
            if(perto_base == 1 && perto_topo == 1) begin
              cont_marcha_lenta <= 3; 
              state <= MARCHA_LENTA;
            end
            else state <= ALARME;
          end
        end

        ALARME: begin
          subir_A <= 0;
          subir_B <= 0;
          alarme <= 1;
        end

      endcase
    end
  end

  //  Saídas
  always_comb begin
    SEG[4] <= subir_A;
    SEG[5] <= subir_B;
    LED[0] <= lento;
    LED[7] <= alarme;
    SEG[7] <= clock_lento;
  end

endmodule