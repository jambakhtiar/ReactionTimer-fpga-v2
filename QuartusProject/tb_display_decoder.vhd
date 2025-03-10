library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_display_decoder is
end tb_display_decoder;

architecture Behavioral of tb_display_decoder is
    signal bcd : STD_LOGIC_VECTOR (3 downto 0);
    signal seg : STD_LOGIC_VECTOR (6 downto 0);

    component display_decoder
        Port (
            bcd : in STD_LOGIC_VECTOR (3 downto 0);
            seg : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component;
begin
    uut: display_decoder Port Map (
        bcd => bcd,
        seg => seg
    );

    process
    begin
        bcd <= "0000"; wait for 10 ns; -- Display 0
        bcd <= "0001"; wait for 10 ns; -- Display 1
        bcd <= "0010"; wait for 10 ns; -- Display 2
        bcd <= "0011"; wait for 10 ns; -- Display 3
        bcd <= "0100"; wait for 10 ns; -- Display 4
        bcd <= "0101"; wait for 10 ns; -- Display 5
        bcd <= "0110"; wait for 10 ns; -- Display 6
        bcd <= "0111"; wait for 10 ns; -- Display 7
        bcd <= "1000"; wait for 10 ns; -- Display 8
        bcd <= "1001"; wait for 10 ns; -- Display 9
        wait;
    end process;
end Behavioral;
