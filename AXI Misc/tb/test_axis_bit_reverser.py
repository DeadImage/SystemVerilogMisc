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

from cocotbext.axi import AxiStreamBus, AxiStreamSource, AxiStreamSink, AxiStreamFrame

from math import ceil
from binascii import hexlify

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.axis_data_width = dut.AXIS_DATA_WIDTH.value
        self.axis_keep_width = int(self.axis_data_width / 8)

        self.test_data = bytearray([x % 256 for x in range(6)] + [x % 256 for x in range(6)] + [0, 46] + [x % 256 for x in range(46)])

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 5, units="ns").start())

        self.axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "s_axis"), dut.clk, dut.rst)
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "m_axis"), dut.clk, dut.rst)

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


async def run_test(dut, packets_count=4):
    tb = TB(dut)

    await tb.reset()
    test_data = tb.test_data[:]

    for i in range(packets_count):
        test_data[-1] = (test_data[-1] + i) % 256
        axis_frame = AxiStreamFrame(test_data)

        tb.log.info(f"Sending frame #{i+1}...")
        await tb.axis_source.send(axis_frame)
        tb.log.info(f"Frame #{i+1} sent.")
        await RisingEdge(tb.dut.clk)

        tb.log.info(f"Receiving reversed frame #{i+1}...")
        axis_data = await tb.axis_sink.recv()
        tb.log.info(f"Reversed frame #{i+1} received.")

        assertion_data = test_data[::-1]
        for i, el in enumerate(assertion_data):
            binary = bin(el)
            reverse = binary[-1:1:-1]
            reverse = reverse + (8 - len(reverse))*'0'
            assertion_data[i] = int(reverse, 2)

        tb.log.info(f"Received data: {hexlify(bytearray(axis_data.tdata))}")
        tb.log.info(f"Expected data: {hexlify(assertion_data)}")

        try:
            assert bytearray(axis_data.tdata) == assertion_data
            tb.log.info("Data assertion successful.")
        except Exception as e:
            tb.log.error("Data assertion failed.")
            raise e

    tb.log.info("Test finished.")

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    factory.add_option("packets_count", [0, 1, 4, 8, 32])
    factory.generate_tests()

# cocotb-test
tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'rtl'))

def test_axis_bit_reverser():
    dut = "axis_bit_reverser"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    test_file = os.path.join(rtl_dir, f"{dut}.v")

    verilog_sources = [test_file]

    sim_build = os.path.join(tests_dir, "sim_build", f"{dut}")

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        sim_build=sim_build,
        timescale='1ns/1ps'
    )
