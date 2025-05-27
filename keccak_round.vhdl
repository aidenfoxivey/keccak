library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.keccak_constants.all;
use work.keccak_common.all;

entity keccak_round is
    port (
        state_in : in state;
        round_constant : in lane;
        state_out : out state
    );
end entity keccak_round;

architecture rtl of keccak_round is
    signal theta_out : state;
    signal rho_out : state;
    signal chi_out : state;
    signal iota_out : state;

begin
    state_out <= iota_out; -- Final output of the round

    theta_step : process (state_in)
        variable C : plane;
        variable D : plane;
    begin
        -- Calculate the parity of each column
        for x in 0 to 4 loop
            C(x) := state_in(x)(0) xor state_in(x)(1) xor state_in(x)(2) xor state_in(x)(3) xor state_in(x)(4);
        end loop;

        for x in 0 to 4 loop
            D(x) := C((x - 1 + 5) mod 5) xor rotate_left(C((x + 1) mod 5), 1);
        end loop;

        for x in 0 to 4 loop
            for y in 0 to 4 loop
                theta_out(x)(y) <= state_in(x)(y) xor D(x);
            end loop;
        end loop;
    end process theta_step;

    rho_step : process (theta_out)
    begin
        for x in 0 to 4 loop
            for y in 0 to 4 loop
                rho_out(y)((2 * x + 3 * y) mod 5) <= rotate_left(theta_out(x)(y), ROTATION_OFFSETS(x, y));
            end loop;
        end loop;
    end process rho_step;

    chi_step : process (rho_out)
    begin
        for x in 0 to 4 loop
            for y in 0 to 4 loop
                chi_out(x)(y) <= rho_out(x)(y) xor ((not rho_out((x + 1) mod 5)(y)) and rho_out((x + 2) mod 5)(y));
            end loop;
        end loop;
    end process chi_step;

    iota_step : process (chi_out, round_constant)
        variable temp_state : state;
    begin
        temp_state := chi_out;
        temp_state(0)(0) := temp_state(0)(0) xor round_constant;
        iota_out <= temp_state;
    end process iota_step;
end architecture;