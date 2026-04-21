import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge

@cocotb.test()
async def test_matrix_mul(dut):
    # 1. Start the clock (10ns period = 100MHz)
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # 2. Reset the design
    dut._log.info("Resetting DUT...")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)

    # 3. Load Matrix A: [[2, 3], [4, 5]]
    # Command for Load A is bit 4 (0001_0000 = 0x10)
    dut._log.info("Loading Matrix A...")
    matrix_a = [2, 3, 4, 5]
    for val in matrix_a:
        dut.ui_in.value = 0x10 | val  # Set Load A bit + data
        await FallingEdge(dut.clk)
    
    dut.ui_in.value = 0
    await FallingEdge(dut.clk)

    # 4. Load Matrix B: [[1, 2], [3, 4]]
    # Command for Load B is bit 5 (0010_0000 = 0x20)
    dut._log.info("Loading Matrix B...")
    matrix_b = [1, 2, 3, 4]
    for val in matrix_b:
        dut.ui_in.value = 0x20 | val  # Set Load B bit + data
        await FallingEdge(dut.clk)

    dut.ui_in.value = 0
    await FallingEdge(dut.clk)

    # 5. Start Computation
    # Command for Compute is bit 2 (0000_0100 = 0x04)
    dut._log.info("Starting Computation...")
    dut.ui_in.value = 0x04
    await Timer(100, units="ns")
    dut.ui_in.value = 0
    await FallingEdge(dut.clk)

    # 6. Read Results
    # Command for Read is bit 3 (0000_1000 = 0x08)
    dut._log.info("Reading Results...")
    expected_results = [11, 16, 19, 28]
    dut.ui_in.value = 0x08
    
    for expected in expected_results:
        await FallingEdge(dut.clk)
        actual = int(dut.uo_out.value)
        dut._log.info(f"Read: {actual}, Expected: {expected}")
        assert actual == expected, f"Matrix mismatch! Got {actual}, wanted {expected}"

    dut.ui_in.value = 0
    dut._log.info("Test passed successfully!")
