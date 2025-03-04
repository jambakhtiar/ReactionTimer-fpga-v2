library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_configuration is
    port (
        clk            : in std_logic;
        reset          : in std_logic;
        inc_button     : in std_logic;
        config_enable     : in std_logic;
        confirm_button : in std_logic;
        target_score   : out unsigned(5 downto 0); -- Scores from 1 to 50
        config_done    : out std_logic
    );
end entity;

architecture Behavioral of fsm_configuration is
    type state_type is (IDLE, CONFIG, CONFIRM);
    signal state : state_type := IDLE;
    signal score : unsigned(5 downto 0);-- := to_unsigned(6, 6); -- Default 6
begin
    process (clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            score <= "000110";--to_unsigned(6, 6);
            config_done <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    config_done <= '0';
                    if config_enable = '1' then
                        state <= CONFIG;
                    end if;

                when CONFIG =>
                    if inc_button = '1' then
                            if score = "01001" then
                                score <= "000010";
                            else
                                score <= score + 1;--score <= to_unsigned(1, 6);
                            end if;
                      end if;
                      
                    if confirm_button = '1' then
                        state <= CONFIRM;
                    end if;

                when CONFIRM =>
                    config_done <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;

    target_score <= score;
end architecture;
