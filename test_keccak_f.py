import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.result import TestFailure
from CompactFIPS202 import KeccakF1600


NUM_PLANES = 5
NUM_SHEETS = 5
LANE_WIDTH = 64


async def reset_dut(dut):
    """Reset the DUT."""
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


def convert_bytes_to_dut_state_format(byte_array):
    """
    Converts a flat list of 200 bytes (from KeccakF1600 output)
    into a 5x5 list of 64-bit integers, matching DUT's state structure.
    """
    state_matrix = [[0] * NUM_SHEETS for _ in range(NUM_PLANES)]
    for y in range(NUM_SHEETS):
        for x in range(NUM_PLANES):
            lane_val = 0
            # Reconstruct 64-bit integer from 8 bytes, LSB first (little-endian)
            for byte_idx in range(8):
                lane_val |= byte_array[(x + y * NUM_PLANES) * 8 + byte_idx] << (
                    byte_idx * 8
                )
            state_matrix[x][y] = hex(lane_val)
    return state_matrix


@cocotb.test()
async def test_keccak_reset(dut):
    """Test reset functionality."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)
    assert dut.ready.value == 1, "Ready should be high after reset"
    dut._log.info("Reset test passed")


RC = {
    0: 0x0000000000000001,
    1: 0x0000000000008082,
    2: 0x800000000000808A,
    3: 0x8000000080008000,
    4: 0x000000000000808B,
    5: 0x0000000080000001,
    6: 0x8000000080008081,
    7: 0x8000000000008009,
    8: 0x000000000000008A,
    9: 0x0000000000000088,
    10: 0x0000000080008009,
    11: 0x000000008000000A,
    12: 0x000000008000808B,
    13: 0x800000000000008B,
    14: 0x8000000000008089,
    15: 0x8000000000008003,
    16: 0x8000000000008002,
    17: 0x8000000000000080,
    18: 0x000000000000800A,
    19: 0x800000008000000A,
    20: 0x8000000080008081,
    21: 0x8000000000008080,
    22: 0x0000000080000001,
    23: 0x8000000080008008,
}


@cocotb.test()
async def verify_round_constants(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.clk)

    for i in range(24):
        assert dut.rc.value == BinaryValue(RC[i], n_bits=64, bigEndian=False), (
            f"Round constant mismatch at round {i}: expected {RC[i]}, got {dut.rc.value}"
        )
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_keccak_zero_input(dut):
    """Test with zero input using Python reference."""
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    initial_state_dut_format = [[0] * NUM_SHEETS for _ in range(NUM_PLANES)]
    for x in range(NUM_PLANES):
        for y in range(NUM_SHEETS):
            rand_lane_val = 0
            dut.i_state[x][y].value = BinaryValue(
                rand_lane_val, bigEndian=False, n_bits=LANE_WIDTH
            )
            initial_state_dut_format[x][y] = rand_lane_val  # Store for reference

    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    await RisingEdge(dut.clk)

    cycle_count = 0
    max_cycles = 50
    while dut.ready.value == 0 and cycle_count < max_cycles:
        await RisingEdge(dut.clk)
        cycle_count += 1

    if cycle_count >= max_cycles:
        raise TestFailure(
            f"Operation did not complete within {max_cycles} cycles. Ready signal did not go high."
        )

    assert dut.ready.value == 1, "Operation should complete and ready should be high"

    assert cycle_count == 25  # 24 + 1 for the final state

    s = [
        [hex(int(dut.o_state[x][y])) for x in range(NUM_PLANES)]
        for y in range(NUM_SHEETS)
    ]

    initial_state_bytes = [0 for _ in range(NUM_PLANES * NUM_SHEETS * 8)]

    reference_output_bytes = KeccakF1600(initial_state_bytes)
    reference_output_matrix = convert_bytes_to_dut_state_format(reference_output_bytes)

    for x in range(NUM_PLANES):
        for y in range(NUM_SHEETS):
            assert s[y][x] == reference_output_matrix[x][y]
