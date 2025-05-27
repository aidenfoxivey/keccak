library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.keccak_constants.all;
use work.keccak_common.all;

entity keccak_f is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    start : in std_logic;
    i_state : in state;
    o_state : out state;
    ready : out std_logic
  );
end keccak_f;

architecture rtl of keccak_f is
  signal current_state : state;
  signal next_state : state;
  signal round_counter : natural range 0 to 24;
  signal rc : lane;
  signal busy : std_logic;
  signal result_state : state;
  component keccak_round is
    port (
      state_in : in state;
      round_constant : in lane;
      state_out : out state
    );
  end component;

begin
  keccak_round_inst : keccak_round
  port map(
    state_in => current_state,
    round_constant => rc,
    state_out => next_state
  );

  process (clk, rst_n)
    variable v_round_counter : natural range 0 to 24;
  begin
    if rst_n = '0' then
      current_state <= (others => (others => (others => '0')));
      result_state <= (others => (others => (others => '0')));
      v_round_counter := 0;
      round_counter <= 0;
      busy <= '0';
      rc <= ROUND_CONSTANTS(0);
    elsif rising_edge(clk) then
      if start = '1' and busy = '0' then
        current_state <= i_state;
        v_round_counter := 0;
        round_counter <= 0;
        busy <= '1';
        rc <= ROUND_CONSTANTS(0);
      elsif busy = '1' then
        if v_round_counter < 24 then
          current_state <= next_state;

          v_round_counter := v_round_counter + 1;
          round_counter <= v_round_counter;

          if v_round_counter < 24 then
            rc <= ROUND_CONSTANTS(v_round_counter);
          else
            null;
          end if;

        else
          result_state <= next_state;
          v_round_counter := 0;
          round_counter <= 0;
          busy <= '0';
          rc <= ROUND_CONSTANTS(0);
        end if;
      end if;
    end if;
  end process;

  ready <= not busy;
  o_state <= current_state;

end rtl;