import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge

@cocotb.test()
async def test_systolic_array(dut):
    clock = Clock(dut.clk, 20, units="ns") # 50MHz
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)

    # Helper function to send data with a command bit
    async def send_val(command_bit, val):
        # Shift val left by 4 because data is ui_in[7:4]
        dut.ui_in.value = (1 << command_bit) | (val << 4)
        await FallingEdge(dut.clk)

    # 1. Load Matrix A: [[2, 3], [4, 5]]
    # cmd_load_a is bit 0
    for v in [2, 3, 4, 5]:
        await send_val(0, v)
    dut.ui_in.value = 0
    await FallingEdge(dut.clk)

    # 2. Load Matrix B: [[1, 2], [3, 4]]
    # cmd_load_b is bit 1
    for v in [1, 2, 3, 4]:
        await send_val(1, v)
    dut.ui_in.value = 0
    await FallingEdge(dut.clk)

    # 3. Compute
    # cmd_compute is bit 2
    dut.ui_in.value = 0x04 
    await Timer(200, units="ns") # Wait for the 8-cycle counter in Verilog
    dut.ui_in.value = 0
    await FallingEdge(dut.clk)

    # 4. Read Results
    # cmd_read is bit 3
    expected = [11, 16, 19, 28]
    for exp in expected:
        dut.ui_in.value = 0x08 # cmd_read
        await FallingEdge(dut.clk)
        actual = int(dut.uo_out.value)
        assert actual == exp, f"Error: Got {actual}, expected {exp}"
    
    dut._log.info("Matrix Multiplication Successful!")
