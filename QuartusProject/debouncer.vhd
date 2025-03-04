library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debouncer is
    Port (
        clock : in STD_LOGIC;
        reset : in STD_LOGIC;
        enable_in : in STD_LOGIC;
        enable_out : out STD_LOGIC
    );
end debouncer;

architecture Behavioral of debouncer is
    signal debounce_counter : integer range 0 to 1000000 := 0; -- Adjust the range as necessary
    signal enable_sync1 : STD_LOGIC := '0';
    signal enable_sync2 : STD_LOGIC := '0';
    signal enable_stable : STD_LOGIC := '0';
begin

    -- Synchronize enable_in to the clock domain
    process(clock, reset)
    begin
        if reset = '1' then
            enable_sync1 <= '0';
            enable_sync2 <= '0';
        elsif rising_edge(clock) then
            enable_sync1 <= enable_in;
            enable_sync2 <= enable_sync1;
        end if;
    end process;

    -- Debounce logic
    process(clock, reset)
    begin
        if reset = '1' then
            debounce_counter <= 0;
            enable_stable <= '0';
        elsif rising_edge(clock) then
            if enable_sync2 /= enable_stable then
                debounce_counter <= debounce_counter + 1;
                if debounce_counter = 1000000 then -- Adjust the threshold as necessary
                    enable_stable <= enable_sync2;
                    debounce_counter <= 0;
                end if;
            else
                debounce_counter <= 0;
            end if;
        end if;
    end process;

    enable_out <= enable_stable;

end Behavioral;
