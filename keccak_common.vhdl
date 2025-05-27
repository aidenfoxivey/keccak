library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

package keccak_common is
    constant planes : integer := 5;
    constant sheets : integer := 5;
    constant length : integer := 64;

    subtype lane is std_logic_vector(length - 1 downto 0);
    type plane is array (sheets - 1 downto 0) of lane;
    type state is array (planes - 1 downto 0) of plane;

    function rotate_left (value : lane; shift : natural) return lane;
end package;

package body keccak_common is
    function rotate_left (value : lane; shift : natural) return lane is
        variable result_unsigned : unsigned(value'range); -- Use unsigned for the shift operation
        variable effective_shift : natural;
    begin
        if value'length = 0 then
            return (others => '0');
        end if;

        effective_shift := shift mod value'length; -- Ensure shift wraps around

        -- Cast std_logic_vector to unsigned for the shift operation
        result_unsigned := (unsigned(value) sll effective_shift) or
            (unsigned(value) srl (value'length - effective_shift));

        -- Cast the result back to std_logic_vector
        return std_logic_vector(result_unsigned);
    end function rotate_left;
end package body;