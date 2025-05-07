library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--  Declarando a entidade principal da Máquina de estados
entity main is 
    Port (
        sinal_clock : in std_logic;                      -- Clock
        dados_teclado, clock_teclado: in std_logic;      -- Sinais do teclado
        LCD_DB: out std_logic_vector(7 downto 0);        -- Sinais para o display
        RS, RW, OE: out std_logic;                       -- Sinais de controle para o display
        BOTAOA, BOTAOB, BOTAOC, BOTAO_RST: in std_logic; -- Botões de entrada e reset
        SW : in std_logic;                               -- Switch de seleção de operações
        LEDS: out std_logic_vector(3 downto 0);          -- Leds de saída
        LEDA, LEDB: out std_logic                        -- Leds individuais de saída
    );
end main;

architecture Behavioral of main is

    -- Definição dos estados
    type state is (state0, stateA3, stateA2, stateA1, stateA0, stateB3, stateB2, stateB1, stateB0, stateS, stateZ3, stateZ2, stateZ1, stateZ0);
    signal estadoAtual, estadoAux: state := state0; -- sinais para o estado atual e auxiliar

    -- Componente para decodificação do teclado
	component tc_codigo_teclado is
        Port (
            sinal_clock, sinal_reset: in  std_logic;
            dados_teclado, clock_teclado: in  std_logic;
            receptor_on: in std_logic;
            final_recebimento_byte: out  std_logic;
            dados_saida: out std_logic_vector(7 downto 0)
        );
        end component;
	
    -- Componente para controle do display LCD
	component display_lcd is
       Port ( 
       NUMERO: in std_logic_vector(3 downto 0); --Entrada de 4 bits.
	 BOTAO: in std_logic;                   --Botão de entrada
	 sinal_reset: in std_logic;             --Sinal de reset.
	 sinal_clock: in std_logic;             --Sinal de clock.
				  
      LED: out std_logic; --Saída para controle de um LED.
      LCD_DB: out std_logic_vector(7 downto 0); --Dados de 8 bits para o display LCD.
 -- Register Select - Bit 9 - Se rs: 1 -> registrador de dados (DR), p/ ops de leitura e escrita de dados; rs: 0 -> registrador de instrução (IR), usado para comandos.
	
      RS: out std_logic;     --Sinal de registro de seleção do LCD.
	RW: out std_logic;     -- Read/Write      
                       -- Bit 8 - Se rw: 1 -> leitura; rw: 0 -> escrita   
	OE: out std_logic;          --Sinal de habilitação de saída.
	ok, okWr: out std_logic);   --Sinais de controle de estado.

	end component;
	 
	  
    -- Componente para conversão de ASCII para BCD
	 component tc_traduz_ascii is
		Port (
        tecla_entrada: in std_logic_vector(7 downto 0); -- Código da tecla recebida do teclado.
        tecla_bcd: out std_logic_vector(3 downto 0)     -- Código BCD correspondente à tecla pressionada.
        );
		end component;

	 
	 
	component bcd_multiplier is
		 Port ( 
             A : in  STD_LOGIC_VECTOR (15 downto 0);   -- 4 dígitos BCD
		 B : in  STD_LOGIC_VECTOR (15 downto 0);   -- 4 dígitos BCD
		 Z : out  STD_LOGIC_VECTOR (15 downto 0)); -- Resultado
	end component;
	
	 
	component bcd_adder is
	  Port ( 
            A : in  STD_LOGIC_VECTOR (15 downto 0);    -- 4 dígitos BCD
		B : in  STD_LOGIC_VECTOR (15 downto 0);    -- 4 dígitos BCD
				  SUM : out  STD_LOGIC_VECTOR (15 downto 0); -- Resultado em BCD (4 dígitos)
				  CARRY_OUT : out  STD_LOGIC);               -- Carry out
	end component;
	 
    -- Sinais para comunicação com o teclado
    signal dados_saida : std_logic_vector(7 downto 0);
    signal final_recebimento_byte, receptor_enable: std_logic;

    -- Vetor BCD para conversão
    signal BCD : std_logic_vector(3 downto 0);

    -- Sinais para controle do display
    signal numDisplay : std_logic_vector(3 downto 0); -- Número a ser mostrado no display
    signal led, ok, okWr : std_logic;
    signal read_tecla : std_logic := '0';

    -- Sinais para as operações
    signal A, B, ZMultiplicacao, ZSoma : std_logic_vector(15 downto 0) := "0000000000000000"; -- Vetores para operações
    signal S: std_logic; -- Guarda a seleção

begin

    -- Mapeamento do componente tc_codigo_teclado
    TECLADO: tc_codigo_teclado port map (
        sinal_clock => sinal_clock,
        sinal_reset => BOTAO_RST,
        dados_teclado => dados_teclado,
        clock_teclado => clock_teclado,
        receptor_on => receptor_enable,
        dados_saida => dados_saida,
        final_recebimento_byte => final_recebimento_byte
    );
    receptor_enable <= NOT final_recebimento_byte;
    read_tecla <= BOTAOC;


    -- Mapeamento do componente display_lcd
    DISPLAY: display_lcd port map (
        NUMERO => numDisplay,
        BOTAO => read_tecla,
        LED => led,
        LCD_DB => LCD_DB,
        RS => RS,
        RW => RW,
        sinal_clock => sinal_clock,
        OE => OE,
        sinal_reset => BOTAO_RST,
        ok => ok,
        okWr => okWr
    );
	 
	 
    -- Mapeamento do componente tc_traduz_ascii
    CONVERSAO: tc_traduz_ascii port map (
        tecla_entrada => dados_saida,
        tecla_bcd => BCD
    );

    -- Mapeamento do componente bcd_multiplier
    MULTIPLICACAO: bcd_multiplier port map ( A, B, ZMultiplicacao);

    -- Mapeamento do componente bcd_adder
    SOMA: bcd_adder port map ( B, A, ZSoma);

-- Processo para alterar o estado atual no clock
process(sinal_clock, estadoAux)
begin
    if(sinal_clock'event and sinal_clock = '1') then
        estadoAtual <= estadoAux; -- alteramos o estado no clock
    end if;
end process;


-- Processo principal da máquina de estados
process
begin    
    if (BOTAO_RST = '1') then -- caso tenhamos RST, voltamos para o primeiro estado
        estadoAux <= stateA3;
    else
        case estadoAtual is
            when state0 =>
                if (ok = '1' ) then
                    estadoAux <= stateA3;
                else
                    estadoAux <= state0;
                end if;

            -- stateA3, stateA2, stateA1, stateA0: capturam os quatro dígitos do número A.
            
            when stateA3 => -- Primeiro digito de A (Mais significativo)
                LEDA <= '1';
                LEDB <= '0';
                LEDS <= BCD;
                numDisplay <= BCD;
                    if (BOTAOA = '1') then
                    A(15 downto 12) <= BCD;
                    estadoAux <= stateA2;
                else
                    estadoAux <= stateA3;
                end if;

            when stateA2 => -- Segundo digito de A
                LEDA <= '0';
                LEDB <= '1';
                LEDS <= BCD;
                numDisplay <= BCD;

                      
                if (BOTAOB = '1') then
                    A(11 downto 8) <= BCD;
                    estadoAux <= stateA1;
                else
                    estadoAux <= stateA2;
                end if;

            when stateA1 => -- Terceiro digito de A
                LEDA <= '1';
                LEDB <= '0';
                LEDS <= BCD;
                numDisplay <= BCD;
                    if (BOTAOA = '1') then
                    A(7 downto 4) <= BCD;
                    estadoAux <= stateA0;
                else
                    estadoAux <= stateA1;
                end if;

            when stateA0 => -- Quarto digito de A (Menos significativo)
                LEDA <= '0';
                LEDB <= '1';
                LEDS <= BCD;
                numDisplay <= BCD;
                    
                    if (BOTAOB = '1') then
                    A(3 downto 0) <= BCD;
                    estadoAux <= stateB3;
                else
                    estadoAux <= stateA0;
                end if;

            
            -- stateB3, stateB2, stateB1, stateB0: capturam os quatro dígitos do número B.  

            when stateB3 => -- Primeiro digito de B (Mais significativo)
                LEDA <= '1';
                LEDB <= '0';
                LEDS <= BCD;
                numDisplay <= BCD;
                if (BOTAOA = '1') then
                    B(15 downto 12) <= BCD;
                    estadoAux <= stateB2;
                        else
                        estadoAux <= stateB3;
                    end if;

            when stateB2 => -- Segundo digito de B
                LEDA <= '0';
                LEDB <= '1';
                LEDS <= BCD;
                numDisplay <= BCD;
                    
                    if (BOTAOB = '1') then
                    B(11 downto 8) <= BCD;
                    estadoAux <= stateB1;]

                        else
                        estadoAux <= stateB2;
                    end if;

            when stateB1 => -- Terceiro digito de B
                LEDA <= '1';
                LEDB <= '0';
                LEDS <= BCD;
                numDisplay <= BCD;

                    if (BOTAOA = '1') then
                    B(7 downto 4) <= BCD;
                    estadoAux <= stateB0;
                        else
                        estadoAux <= stateB1;
                    end if;

            when stateB0 => -- Quarto digito de A (Menos significativo)
                LEDA <= '0';
                LEDB <= '1';
                LEDS <= BCD;
                numDisplay <= BCD;
                    
                    if (BOTAOB = '1') then
                    B(3 downto 0) <= BCD;
                    estadoAux <= stateS;
                    else
                    estadoAux <= stateB0;
                end if;


        -- stateS: seleciona a operação (soma ou multiplicação) baseada no valor do switch (SW).
        when stateS =>
            LEDA <= '1';
            LEDB <= '1';

            if (BOTAOA = '1') then
                S <= SW;
                estadoAux <= stateZ3;
                
                else
                estadoAux <= stateS;

            end if;

        -- stateZ3, stateZ2, stateZ1, stateZ0: exibem os dígitos do resultado da operação (soma ou multiplicação) no display e nos LEDs.        
        when stateZ3 =>
            LEDA <= '0';
            LEDB <= '0';

            --  S = '1' (soma), o valor exibido será o dígito mais significativo do resultado da soma (ZSoma(15 downto 12)).
            if (S = '1' ) then
                LEDS <= ZSoma(15 downto 12);
                numDisplay <= ZSoma(15 downto 12);
                
                -- S = '0' (multiplicação), o valor exibido será o dígito mais significativo do resultado da multiplicação (ZMultiplicacao(15 downto 12)).
                else
                LEDS <= ZMultiplicacao(15 downto 12);
                numDisplay <= ZMultiplicacao(15 downto 12);
                
            end if;
                
                -- O estado muda para stateZ2 quando o botão BOTAOB é pressionado. 
                if (BOTAOB = '1') then
                    estadoAux <= stateZ2;

                            -- Caso contrário, o estado permanece em stateZ3.
                            else
                            estadoAux <= stateZ3;
                            
                        end if;

                when stateZ2 =>
                    LEDA <= '0';
                    LEDB <= '0';

                    if (S = '1' ) then
                        LEDS <= ZSoma(11 downto 8);
                        numDisplay <= ZSoma(11 downto 8);

                        else
                        LEDS <= ZMultiplicacao(11 downto 8);
                        numDisplay <= ZMultiplicacao(11 downto 8);
                        
                    end if;
                        
                        -- O próximo estado é stateZ1 se o botão BOTAOA for pressionado. 
                        if (BOTAOA = '1') then
                        estadoAux <= stateZ1;

                            -- Caso contrário, o estado permanece em stateZ2.
                            else
                            estadoAux <= stateZ2;
                        end if;

                when stateZ1 =>
                    LEDA <= '0';
                    LEDB <= '0';

                    if (S = '1' ) then
                        LEDS <= ZSoma(7 downto 4);
                        numDisplay <= ZSoma(7 downto 4);
                            
                        else
                        LEDS <= ZMultiplicacao(7 downto 4);
                        numDisplay <= ZMultiplicacao(7 downto 4);
                    end if;

                        -- O próximo estado é stateZ0 se o botão BOTAOB for pressionado. 
                        if (BOTAOB = '1') then
                            estadoAux <= stateZ0;

                            -- Caso contrário, o estado permanece em stateZ1.
                            else
                            estadoAux <= stateZ1;
                        end if;

                when stateZ0 =>
                    LEDA <= '0';
                    LEDB <= '0';
                        
                
                    if (S = '1' ) then
                        LEDS <= ZSoma(3 downto 0);
                        numDisplay <= ZSoma(3 downto 0);

                        else
                        LEDS <= ZMultiplicacao(3 downto 0);
                        numDisplay <= ZMultiplicacao(3 downto 0);
                    end if;

                        -- Se o botão BOTAOA for pressionado, o sistema retorna ao estado stateA3 para permitir a entrada de um novo número. 
                        if (BOTAOA = '1') then
                            estadoAux <= stateA3;
                            
                            --Caso contrário, o estado permanece em stateZ0.
                            else
                            estadoAux <= stateZ0;
                        end if;

                end case;
        end if;
end process;
end Behavioral;


                
