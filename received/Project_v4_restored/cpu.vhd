
-----------------------------------------------------

-- FSM model consists of two concurrent processes
-- state_reg and comb_logic
-- we use case statement to describe the state 
-- transistion. All the inputs and signals are
-- put into the process sensitive list.  
-----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------

entity cpu is
    port(
        clock   :   in std_logic;
        reset       :   in std_logic;
        clk_1ms     : in std_logic;
        clk_1hz     : in std_logic;
        player_A    : in std_logic; --key3
        player_B    : in std_logic; --key 0
        start       : in std_logic; --key 1
        target_confirm : in std_logic; --key 2
       
        target_score : out unsigned(5 downto 0); --out std_logic_vector(5 downto 0);--HEX7-HEX6
        config_enable_o: out std_logic;
        p1_Hex5_4: out std_logic;
        p2_Hex5_4: out std_logic;
 
        test_cycles : out unsigned(5 downto 0); --HEX5-HEX4
        score_playerA : out unsigned(5 downto 0);--HEX3-HEX2
        score_playerB : out unsigned(5 downto 0);--HEX1-HEX0
        stimulus_playerA : out std_logic_vector(3 downto 0);
        stimulus_playerB : out std_logic_vector(3 downto 0)
        
    );
end cpu;

-----------------------------------------------------------

architecture FSM of cpu is
    
    --define the states of FSM model
    type state_type is( IDLE, CONFIG, WAIT_for_START,
                                     DT_P1, STIMULUS1, WP1, SAVE_P1,
                                     DT_P2, STIMULUS2, WP2, SAVE_P2,
                                     COMPARE, CHECK_TARGET, WINNER,  
                                     Penalty, SP1, SP2);
    signal next_state, current_state: state_type;      

    -- internal registers
    signal target_score_reg :  unsigned(5 downto 0);--:= "000000";
    signal test_cycles_reg :  unsigned(5 downto 0);
    signal score_playerA_reg : unsigned(5 downto 0);--:= "000000";
    signal score_playerB_reg :  unsigned(5 downto 0);--:= "000000";
        
    -- configuration
    signal config_enable : std_logic ;--:='0';
    signal config_done : std_logic;
    --signal target : std_logic;
    
    --timer 
    signal timer_enable : std_logic ;--:='0';
    signal timer_done : std_logic ;--:='0';
    
    --stopwatch
    signal stopwatch_enable1 : std_logic ;--:='0';
    signal stopwatch_enable2 : std_logic ;--:='0';
    signal sp1_done : std_logic;-- :='0';
    signal sp2_done : std_logic;--:='0';
    signal sp1_time : unsigned(23 downto 0);
    signal sp2_time : unsigned(23 downto 0);
    signal sp1_time_w : unsigned(23 downto 0);
    signal sp2_time_w : unsigned(23 downto 0);
   
    -- 1 second signal
    signal sec_en : std_logic ;--:= '0';
    signal sec_done : std_logic ;--:= '0';
    signal sec_count : unsigned(4 downto 0) ;--:= "00000";
    
    -- for 5 second delay
   type state_type_5s is (IDLE_5s, RUN_5s, STOP_5s);
    signal state_5s : state_type_5s := IDLE_5s;
    signal sec5_en : std_logic ;--:= '0';
    signal sec5_done : std_logic ;--:= '0';
    signal sec5_count : unsigned(2 downto 0) ;--:= "000";
    
    --Penalty Counters
    signal p1_penalty_count : unsigned(4 downto 0) ;--:= "00000";
    signal p2_penalty_count : unsigned(4 downto 0) ;--:= "00000";
    
    
    component fsm_configuration
        port (
            clk            : in std_logic;
            reset          : in std_logic;
            inc_button     : in std_logic;
            config_enable  : in std_logic;
            confirm_button : in std_logic;
            target_score   : out unsigned(5 downto 0);
            config_done    : out std_logic
        );
    end component;
       
       -- Component declaration of the unit under test (UUT)
    component random_delay
        port (
            clk       : in std_logic;
            reset     : in std_logic;
            delay_out : out std_logic
        );
    end component;
    
    -- Component declaration of the unit under test (UUT)
    component timer
        port (
            clk_1ms         : in std_logic;
            reset           : in std_logic;
            en              : in std_logic;
            key_pressed     : in std_logic;
            time_out        : out unsigned(23 downto 0);
            swatch_stopped  : out std_logic
        );
    end component;
    
    
    
    
    
    begin

-- Instantiate the Unit Under Test (UUT)
    uut1: fsm_configuration
        port map (
            clk            => clk_1hz,
            reset          => reset,
            inc_button     => player_B, --key0
            config_enable  => config_enable,
            confirm_button => target_confirm,
            target_score   => target_score_reg, --HEX7-HEX6
            config_done    => config_done
        );

    uut2: random_delay
        port map (
            clk       => clk_1ms,
            reset     => reset,
            delay_out => timer_done
        );


    -- Instantiate the Unit Under Test (UUT)
    spA: timer
        port map (
            clk_1ms        => clk_1ms,
            reset          => reset,
            en             => stopwatch_enable1,
            key_pressed    => player_A,
            time_out       => sp1_time_w,
            swatch_stopped => sp1_done
        );
spB: timer
        port map (
            clk_1ms        => clk_1ms,
            reset          => reset,
            en             => stopwatch_enable2,
            key_pressed    => player_B,
            time_out       => sp2_time_w,
            swatch_stopped => sp2_done
        );







        --concurrent process#1: state registers
        state_reg: process(clock, reset)
        begin

            if(reset ='1') then
                current_state <= IDLE;
            elsif (clock'event and clock='1') then
                current_state <= next_state;
            end if;
        end process;

        --concurrent process#2: combinational logic
        comb_logic: process(current_state, start, player_A, player_B, config_done,
                    timer_done ,sp1_done, sp2_done, sec_done, sec5_done)
        begin

            --use case statement to show the state transition
            case current_state is
                when IDLE =>    
                                test_cycles_reg <= "000000";--"010010"; --HEX5-HEX4
                                score_playerA_reg <= "000000";--HEX3-HEX2
                                score_playerB_reg <= "000000";--HEX1-HEX0
                                stimulus_playerA <= "0000";
                                stimulus_playerB <= "0000";
                                config_enable <= '0';
                                timer_enable <='0';
                                stopwatch_enable1 <= '0';
                                stopwatch_enable2 <= '0';
                                sec_en <= '0';
                                sec5_en <= '0';
                               
										 p1_Hex5_4 <= '0';
                                p2_Hex5_4 <= '0';
                                
                            if start='1' then
                                next_state <=CONFIG;
                            --else
                             --   next_state <=IDLE;
                            end if;
                
                when CONFIG =>
                                test_cycles_reg <= "000000";--"010001"; --HEX5-HEX4
                                score_playerA_reg <= "000000";--HEX3-HEX2
                                score_playerB_reg <= "000000";--HEX1-HEX0
                                stimulus_playerA <= "0000";
                                stimulus_playerB <= "0000";
                                config_enable <= '1';
                               
										 p1_Hex5_4 <= '0';
                                p2_Hex5_4 <= '0';
                               
                               if config_done = '1' then
                                   next_state <= WAIT_for_START;
                               --else
                                --   next_state <= CONFIG;
                               end if;
                               
                when WAIT_for_START=>
                                config_enable <= '0';
                                sec_en <= '0';
                                
										  if (start = '1') then
                                    next_state <= DT_P1;
                                --else
                                  --  next_state <= WAIT_for_START;
                                end if;
										  
										 -- p1_Hex5_4 <= '1';
                                --p2_Hex5_4 <= '0';
										  --test_cycles_reg <= "000001";
                
                --------- Player A -----------------
                when DT_P1=>
                                
                                sec_en <= '0';
										  
                                if player_A = '1' then 
                                    next_state <= SP1;
                                elsif ((p1_penalty_count>0) and (p2_penalty_count>0)) then
                                        next_state <= CONFIG;    
                                elsif p1_penalty_count>0 then
                                        next_state <= DT_P2;
                                else    
                                    if timer_done = '1' then
                                        next_state <= STIMULUS1;
                                    --else
                                     --   next_state <= DT_P1;
                                    end if;
                                end if;
										  
										   p1_Hex5_4 <= '1';
                                p2_Hex5_4 <= '0';
										  --test_cycles_reg <= "000010";
										  
                when STIMULUS1 =>
                                p1_Hex5_4 <= '1';
                                p2_Hex5_4 <= '0';                                
                                --stopwatch_enable <= '1';
                                stimulus_playerA <= "1111";
                                sec_en <= '1';
                                --stimulus_playerB <= "1111";
                                
										  if sec_done = '1' then
											next_state <= WP1;
                                end if;
										  
										  --test_cycles_reg <= "000011";
                                
                when WP1 =>
                                sec_en <= '0';
											stopwatch_enable1 <= '1';
                                stimulus_playerA <= "0000";
                               -- stimulus_playerB <= "0000";                                
                                
										  if (sp1_done ='1') then
                                    next_state <= SAVE_P1;
                                    sp1_time <=sp1_time_w;
                                    --sp2_time <=sp2_time_w; 
                                end if;
										  
										  --test_cycles_reg <= "000100";
										  
                 when SAVE_P1 =>
                                stopwatch_enable1 <= '0';                                
                                if(start = '1') then
                                    next_state <= DT_P2;
                                   end if;
											  
											 -- test_cycles_reg <= "000101";
                                
                                --test_cycles_reg <= test_cycles_reg + 1;
                                
                               -- if sp1_time < sp2_time then
                               --     score_playerA_reg <= score_playerA_reg + 1;
                               -- elsif sp2_time < sp1_time then
                               --     score_playerB_reg <= score_playerB_reg + 1;
                               -- end if;
										 
                 
                 
                 --------- Player B -----------------                 
                 when DT_P2 =>
                                 
											 p1_Hex5_4 <= '0';
                                 p2_Hex5_4 <= '1';  
											sec_en <= '0';
											--stopwatch_enable1 <= '0';
											stopwatch_enable2 <= '0';
											
                                if player_B = '1' then 
                                    next_state <= SP1;
                                elsif ((p1_penalty_count>0) and (p2_penalty_count>0)) then
                                        next_state <= CONFIG;
                                elsif p2_penalty_count>0 then
                                        next_state <= DT_P1;
                                else    
                                    if timer_done = '1' then
                                        next_state <= STIMULUS2;
                                    --else
                                    --    next_state <= DT_P2;
                                    end if;
                                end if;                               
                               -- sec_en <= '0';
                               -- if player_B = '1' then 
                                 --   next_state <= SP2;
                               -- else
                                   -- if timer_done = '1' then
                                     ---   next_state <= STIMULUS2;
                                    --else
                                      --  next_state <= DT_P2;
                                    --end if;
                                --end if;
										  
										 -- test_cycles_reg <= "000110";
                                
                when STIMULUS2 =>
                                p1_Hex5_4 <= '0';
                                p2_Hex5_4 <= '1';                                
                                --stopwatch_enable <= '1';
                                --stimulus_playerA <= "1111";
                                sec_en <= '1';
                                stimulus_playerB <= "1111";
                                
										  if sec_done = '1' then
												next_state <= WP2;
                                end if;
										  
										 -- test_cycles_reg <= "000111"; and how can we solve it? or we cant? t
                                
                when WP2 =>
                                p1_Hex5_4 <= '0';
                                p2_Hex5_4 <= '1';
										  sec_en <= '0';
											--stopwatch_enable1 <= '1';
											stopwatch_enable2 <= '1';
                                --stimulus_playerA <= "0000";
                                stimulus_playerB <= "0000";                                
                                
                                --if (sp1_done ='1') then
										  if (sp2_done ='1') then
                                    next_state <= SAVE_P2;
                                    --sp2_time <=sp1_time_w;
                                    sp2_time <=sp2_time_w; 
                                end if;
										  --
										  --test_cycles_reg <= "001000";
                 when SAVE_P2 =>
                                
										   p1_Hex5_4 <= '0';
                                p2_Hex5_4 <= '1';
										  --stopwatch_enable1 <= '0';
                                stopwatch_enable2 <= '0';
                                if(start = '1') then
                                    next_state <= COMPARE;
                                   end if;
											  
											 -- test_cycles_reg <= "001001";
                                
                  
                  when COMPARE =>
                                p1_Hex5_4 <= '0';
                                p2_Hex5_4 <= '0';
										  
                                test_cycles_reg <=  test_cycles_reg + 1;                               
                                next_state <= CHECK_TARGET;
                               
										 if sp1_time < sp2_time then
                                    score_playerA_reg <= score_playerA_reg + 1;
                                elsif sp2_time < sp1_time then
                                    score_playerB_reg <= score_playerB_reg + 1;
                                end if;
										  
										 -- test_cycles_reg <= "001010";
                                

                   when CHECK_TARGET =>
                                --if ( (score_playerA_reg = target_score_reg) or (score_playerB_reg = target_score_reg)) then
                                if ( test_cycles_reg = target_score_reg ) then
                                    next_state <= WINNER;
                                elsif(start = '1')then
                                    next_state <= DT_P1;
                                end if;

										--	test_cycles_reg <= "001011";										  
                               
                  when WINNER =>
                                    sec5_en <= '1';
                               if sec5_done = '1' then
                                    next_state <= CONFIG;
                               end if;       
                               
                               if score_playerA_reg > score_playerB_reg then
                                    stimulus_playerA <= "1111";
                                    stimulus_playerB <= "0000";
                                    p1_Hex5_4 <= '1';
                                    p2_Hex5_4 <= '0';
                                elsif score_playerB_reg > score_playerA_reg then
                                    stimulus_playerA <= "0000";
                                    stimulus_playerB <= "1111";
                                    p1_Hex5_4 <= '0';
                                    p2_Hex5_4 <= '1';
                                elsif score_playerA_reg = score_playerB_reg then
                                    stimulus_playerA <= "1111";
                                    stimulus_playerB <= "1111";
                                    p1_Hex5_4 <= '0';
                                    p2_Hex5_4 <= '0';
                                end if;         
                               
										-- test_cycles_reg <= "001100";
                  when SP1 => 
                               --score_playerA_reg <= score_playerA_reg - 2;
                               sec_en <= '0';
                               next_state <= PENALTY;
										 
										 --test_cycles_reg <= "001101";
                  when SP2 =>
                               --score_playerB_reg <= score_playerB_reg - 2;
                               sec_en <= '0';
                               next_state <= PENALTY;
										 
										-- test_cycles_reg <= "001110";
                  when PENALTY =>
                            sec_en <= '1';
                            stimulus_playerA <= "1111";
                            stimulus_playerB <= "1111";
                        
                        if (sec_done = '1') then
                                next_state <= WAIT_for_START;
                         end if;
								 
								-- test_cycles_reg <= "001111";
                when others =>
                        
                            next_state <= IDLE;
									 
									-- test_cycles_reg <= "010000";
                                       
            end case;        
        end process;
              
        second_delay: process(reset, clk_1ms) begin
            if reset = '1' then
                sec_count <= "00000";
                sec_done <= '0';
             elsif rising_edge(clk_1ms) then
                if sec_en = '1' then
                   
                    if sec_count = "01111" then --31 ms delay
                        sec_done <= '1';
                        sec_count <= "00000";
                    else 
                        sec_done <= '0';
								 sec_count <= sec_count + 1;
                    end if;
                 end if;
             end if;         
        end process;
        
        five_sec_delay: process (clk_1hz, reset)
    begin
        if reset = '1' then
            state_5s <= IDLE_5s;
            sec5_done <= '0';
        elsif rising_edge(clk_1hz) then
            case state_5s is
                when IDLE_5s =>
                    sec5_done <= '0';
                    if sec5_en = '1' then
                        state_5s <= RUN_5s;
                    end if;

                when RUN_5s =>
                        sec5_count <= sec5_count + 1;
                        if sec5_count = "101" then
                            state_5s <= STOP_5s;
                         end if;   

                when STOP_5s =>
                    sec5_done <= '1';
                    sec5_count <= "000";
                    state_5s <= IDLE_5s;
            end case;
        end if;
    end process;
     
     
     
     
     
     penalty_countP1: process(reset, clock) begin
            if reset = '1' then
                p1_penalty_count <= "00000";
             elsif rising_edge(clock) then
                if current_state = SP1 then
                    p1_penalty_count <= p1_penalty_count + 1;
                    end if;
             end if;         
        end process;
     
     penalty_countP2: process(reset, clock) begin
            if reset = '1' then
                p2_penalty_count <= "00000";
             elsif rising_edge(clock) then
                if current_state = SP2 then
                    p2_penalty_count <= p2_penalty_count + 1;
                    end if;
             end if;         
        end process;
     
     
     
     
        
        
    config_enable_o <= config_enable;
    target_score <= target_score_reg;
    score_playerA <= score_playerA_reg;
    score_playerB <= score_playerB_reg;
    test_cycles <= test_cycles_reg;
 end FSM;

                                
