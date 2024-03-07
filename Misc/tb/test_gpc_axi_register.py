import pytest
import os
import subprocess
import logging
import itertools
import asyncio

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

import cocotb_test.simulator

from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame, AxiLiteBus, AxiLiteMaster

from math import ceil
from binascii import hexlify

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.axil_addr_width = dut.AXIL_ADDR_WIDTH.value
        self.axil_data_width = dut.AXIL_DATA_WIDTH.value
        self.axis_data_width = dut.AXIS_DATA_WIDTH.value

        self.axil_strobe_width = int(self.axil_data_width / 8)
        self.axis_keep_width = int(self.axis_data_width / 8)

        self.reg_memory_size = ceil(480 / self.axil_data_width) + 1

        self.test_data = bytearray([x % 256 for x in range(6)] + [x % 256 for x in range(6)] + [0, 46] + [x % 256 for x in range(46)])

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 5, units="ns").start())

        self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.rst)
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk, dut.rst)
        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.clk, dut.rst)

    async def reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)

async def axil_single_read(tb, test_data):
    data_received = False
    read_data = []

    while not data_received:
        read_addr = 8 * (tb.reg_memory_size - 1)
        tb.log.info(f"AXI-Lite: Reading validity cell from addr 0x{read_addr:08X}...")
        val_cell = await tb.axil_master.read(read_addr, length=tb.axil_strobe_width)
        tb.log.info(f"AXI-Lite: Validity cell read. Value: {hexlify(val_cell.data)}")

        if val_cell.data != bytearray([0 for m in range(tb.axil_strobe_width)]):
            tb.log.info("AXI-Lite: Register has valid data.")
            tb.log.info(f"AXI-Lite: Reading {tb.reg_memory_size - 1} beats of data, {tb.axil_data_width} bits each...")

            for k in range(tb.reg_memory_size-1):
                read_addr = k*8
                tb.log.info(f"AXI-Lite: Reading beat #{k+1} from addr 0x{read_addr:08X}...")
                data = await tb.axil_master.read(read_addr, length=tb.axil_strobe_width)
                tb.log.info(f"AXI-Lite: Beat #{k+1} read, data: {hexlify(data.data)}, resp: {data.resp}")
                read_data.extend(data.data)

            tb.log.info(f"AXI-Lite: All beats read, complete data frame: {hexlify(bytearray(read_data))}")
            tb.log.info(f"AXI-Lite: Original data: {hexlify(test_data)}")

            data_received = True

        else:
            tb.log.info("AXI-Lite: No valid data in the register. Skipping 2 clock cycles...")
            await RisingEdge(tb.dut.clk)
            await RisingEdge(tb.dut.clk)

    return read_data[:-4] # drop 4 zero bytes just for convenience

async def axil_single_write(tb, test_data):
    write_ready = False
    read_addr = 8 * (2*tb.reg_memory_size - 1)

    while not write_ready:
        tb.log.info(f"AXI-Lite: Reading write validity cell from addr 0x{read_addr:08X}...")
        val_cell = await tb.axil_master.read(read_addr, length=tb.axil_strobe_width)
        tb.log.info(f"AXI-Lite: Write validity cell read. Value: {hexlify(val_cell.data)}")

        if val_cell.data == bytearray([0 for m in range(tb.axil_strobe_width)]):
            tb.log.info("AXI-Lite: Register is not ready for write. Skipping 2 clock cycles...")
            await RisingEdge(tb.dut.clk)
            await RisingEdge(tb.dut.clk)
        else:
            write_ready = True

    tb.log.info("AXI-Lite: Register is ready for write.")
    tb.log.info(f"AXI-Lite: Writing {tb.reg_memory_size - 1} beats of data, {tb.axil_data_width} bits each...")
    for k in range(tb.reg_memory_size-1):
        write_addr = 8*k + 8*tb.reg_memory_size
        write_data = test_data[8*k:8*k+8]
        tb.log.info(f"AXI-Lite: Writing beat #{k+1} to addr 0x{write_addr:08X}...")
        await tb.axil_master.write(write_addr, write_data)
        tb.log.info(f"AXI-Lite: Beat #{k+1} written to register.")

    tb.log.info("AXI-Lite: All beats written to register.")

async def run_test_read(dut, packets_count=4):
    tb = TB(dut)

    await tb.reset()
    test_data = tb.test_data[:]

    for i in range(packets_count):
        # Send AXI-Stream data
        test_data[-1] = (test_data[-1] + i) % 256
        axis_frame = AxiStreamFrame(test_data)

        tb.log.info(f"AXI-Stream: Sending frame #{i+1}...")
        await tb.axis_source.send(axis_frame)
        tb.log.info(f"AXI-Stream: Frame #{i+1} sent.")
        await RisingEdge(tb.dut.clk)

        # AXI-Lite read behavior
        read_data = await axil_single_read(tb, test_data)
        try:
            assert bytearray(read_data) == test_data
            tb.log.info("AXI-Lite: Data assertion successful.")
        except Exception as e:
            tb.log.error("AXI-Lite: Data assertion failed.")
            raise e

        tb.log.info(f"Frame #{i+1} acquired by GPC.")

    tb.log.info("Read test finished.")


async def run_test_write(dut, packets_count=4):
    tb = TB(dut)

    await tb.reset()
    test_data = tb.test_data[:]

    for i in range(packets_count):
        test_data[-1] = (test_data[-1] + i) % 256

        # AXI-Lite write behavior
        await axil_single_write(tb, test_data)

        # AXI-Stream send data out
        tb.log.info(f"AXI-Stream: Receiving frame #{i+1}...")
        axis_data = await tb.axis_sink.recv()
        tb.log.info(f"AXI-Stream: Frame #{i+1} received.")

        tb.log.info(f"AXI-Stream: received data: {hexlify(bytearray(axis_data.tdata))}")
        tb.log.info(f"AXI-Stream: original data: {hexlify(test_data)}")

        try:
            assert bytearray(axis_data.tdata) == test_data
            tb.log.info("AXI-Stream: Data assertion successful.")
        except Exception as e:
            tb.log.error("AXI-Stream: Data assertion failed.")
            raise e

    tb.log.info("Write test finished.")


async def run_test_read_write(dut, packets_count=4):
    tb = TB(dut)

    await tb.reset()
    test_data = tb.test_data[:]

    for i in range (packets_count):
        # Read from AXIS to AXIL
        # Send AXI-Stream data
        test_data[-1] = (test_data[-1] + i) % 256
        axis_frame = AxiStreamFrame(test_data)

        tb.log.info(f"AXI-Stream: Sending frame #{i+1}...")
        await tb.axis_source.send(axis_frame)
        tb.log.info(f"AXI-Stream: Frame #{i+1} sent.")
        await RisingEdge(tb.dut.clk)

        # AXI-Lite read behavior
        read_data = await axil_single_read(tb, test_data)

        # Modify data (increment last byte)
        write_data = read_data[:-1]
        write_data.append((read_data[-1] + 1) % 256)

        # Write from AXIL to AXIS
        # AXI-Lite write behavior
        await axil_single_write(tb, write_data)

        # AXI-Stream send data out
        tb.log.info(f"AXI-Stream: Receiving frame #{i+1}...")
        axis_data = await tb.axis_sink.recv()
        tb.log.info(f"AXI-Stream: Frame #{i+1} received.")

        assertion_data = test_data[:-1]
        assertion_data.append((test_data[-1] + 1) % 256)
        tb.log.info(f"AXI-Stream: received data: {hexlify(bytearray(axis_data.tdata))}")
        tb.log.info(f"AXI-Stream: original data: {hexlify(test_data)}")
        tb.log.info(f"AXI-Stream: supposed data: {hexlify(assertion_data)}")

        # Assert the result
        try:
            assert bytearray(axis_data.tdata) == assertion_data
            tb.log.info("AXI-Stream: Data assertion successful.")
        except Exception as e:
            tb.log.error("AXI-Stream: Data assertion failed.")
            raise e

    tb.log.info("Read-Write test finished.")

if cocotb.SIM_NAME:
    for test in [run_test_read, run_test_write, run_test_read_write]:
        factory = TestFactory(test)
        factory.add_option("packets_count", [0, 1, 4, 8, 32])
        factory.generate_tests()

# cocotb-test
tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'rtl'))

def test_gpc_axi_register():
    dut = "gpc_axi_register"
    testbench = f"test_{dut}"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = testbench

    test_file = os.path.join(tests_dir, f"{testbench}.sv")

    verilog_sources = [
        test_file,
        os.path.join(rtl_dir, f"{dut}.sv")
    ]

    sim_build = os.path.join(tests_dir, "sim_build", f"{dut}")

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        sim_build=sim_build,
        timescale='1ns/1ps'
    )
