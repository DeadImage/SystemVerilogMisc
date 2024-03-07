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

        self.data = bytearray([x % 256 for x in range(50)] + [116, 0] + [x % 256 for x in range(6)] + [0 for x in range(6)])

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk_tx, 3.1, units="ns").start())
        cocotb.start_soon(Clock(dut.clk_rx, 3, units="ns").start())

        self.rx_axis_source = AxiStreamSource(AxiStreamBus.from_prefix(dut, "rx_s_axis"), dut.clk_rx, dut.aresetn, reset_active_level=False)
        self.rx_axis_sink = AxiStreamSink(AxiStreamBus.from_prefix(dut, "rx_m_axis"), dut.clk_rx, dut.aresetn, reset_active_level=False)

    async def reset(self):
        self.dut.aresetn.setimmediatevalue(1)
        self.dut.tx_axis_tvalid.setimmediatevalue(0)
        self.dut.tx_axis_tready.setimmediatevalue(0)

        await RisingEdge(self.dut.clk_tx)
        await RisingEdge(self.dut.clk_tx)
        self.dut.aresetn.value = 0
        await RisingEdge(self.dut.clk_tx)
        await RisingEdge(self.dut.clk_tx)
        self.dut.aresetn.value = 1
        await RisingEdge(self.dut.clk_tx)
        await RisingEdge(self.dut.clk_tx)

async def run_test(dut, packets_count=4):
    tb = TB(dut)

    await tb.reset()
    test_data = tb.data[:]

    for i in range(packets_count):
        tb.log.info(f"Sending frame #{i+1}...")

        # TX imitation
        tb.log.info("Sending TX frame...")
        await RisingEdge(tb.dut.clk_tx)
        tb.dut.tx_axis_tvalid.setimmediatevalue(1)
        tb.dut.tx_axis_tready.setimmediatevalue(1)
        await RisingEdge(tb.dut.clk_tx)
        tb.dut.tx_axis_tvalid.setimmediatevalue(0)
        tb.dut.tx_axis_tready.setimmediatevalue(0)
        tb.log.info("TX frame sent.")

        # Wait some RX time
        tb.log.info("Waiting approximate time till frame gets to RX...")
        for j in range(50):
            await RisingEdge(tb.dut.clk_rx)

        # Send RX packet
        tb.log.info("Sending RX frame...")
        axis_frame = AxiStreamFrame(test_data)
        await tb.rx_axis_source.send(axis_frame)
        await RisingEdge(tb.dut.clk_rx)
        tb.log.info("RX frame sent.")

        tb.log.info("Recovering RX frame...")
        axis_data = await tb.rx_axis_sink.recv()
        tb.log.info("RX frame recovered.")

        # Recover data
        tb.log.info(f"Received data: {hexlify(bytearray(axis_data.tdata))}")
        tb.log.info(f"Original data: {hexlify(test_data)}")

        # Assert data
        try:
            assert bytearray(axis_data.tdata[:-6]) == test_data[:-6]
            assert bytearray(axis_data.tdata[-6:]) != bytearray([0 for x in range(6)])
            tb.log.info("Data assertion successful.")
        except Exception as e:
            tb.log.error("Data assertion failed.")
            raise e

        # Wait some time before the next packet
        for j in range(25):
            await RisingEdge(tb.dut.clk_rx)

if cocotb.SIM_NAME:
    factory = TestFactory(run_test)
    # factory.add_option("packets_count", [0, 1, 4, 8, 32])
    factory.add_option("packets_count", [4])
    factory.generate_tests()

# cocotb-test
tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'src'))

def test_timing_checks():
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = "test_timing_checks"

    test_file = os.path.join(tests_dir, "test_timing_checks.sv")
    rtl_files = [os.path.join(rtl_dir, "tx_timing_checker.v"), os.path.join(rtl_dir, "rx_timing_checker.v")]

    verilog_sources = [test_file] + rtl_files

    sim_build = os.path.join(tests_dir, "sim_build", "test_timing_checks")

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        sim_build=sim_build,
        timescale='1ns/1ps'
    )
