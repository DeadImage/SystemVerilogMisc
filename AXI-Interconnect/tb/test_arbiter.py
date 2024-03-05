import cocotb
from cocotb.triggers import Timer

import cocotb_test.simulator
import pytest
import os
import subprocess
import logging

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

from numpy.random import randint

class TB(object):
    def __init__(self, dut):
        self.dut = dut
        self.ports = dut.PORTS.value
        self.round_robin = dut.ARB_TYPE_ROUND_ROBIN.value
        self.block = dut.ARB_BLOCK.value
        self.block_ack = dut.ARB_BLOCK_ACK.value
        self.lsb_priority = dut.ARB_LSB_HIGH_PRIORITY.value

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    async def cycle_reset(self):
        self.dut.resetn.setimmediatevalue(1)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 1

    def generate_request(self):
        request = randint(0, 2**self.ports)
        return request

    def request_putdown(self, request, n):
        remainder = request % 2**n
        main_part = int(request / 2**(n+1)) << (n + 1)

        return main_part + remainder

    def generate_grants(self, request):
        grants = list()
        i = 0
        while request > 0:
            bit = request % 2
            request = int(request / 2)

            if bit > 0:
                grants.append(i)

            i += 1

        return grants

    def generate_acknowledge(self, n):
        return 2**n


async def run_test_arbitration(dut):
    tb = TB(dut)

    # reset inputs
    tb.dut.request.value = 0
    tb.dut.acknowledge.value = 0

    await tb.cycle_reset()

    # generate requests
    requests = [tb.generate_request() for i in range(10)]

    for j in range(len(requests)):
        request = requests[j]
        grants = tb.generate_grants(request)

        i = 0
        tb.dut.request.value = request
        while request > 0:
            await RisingEdge(dut.clk)
            tb.dut.acknowledge.value = 0
            await RisingEdge(dut.clk)

            while tb.dut.grant_valid.value != 1:
                await RisingEdge(dut.clk)

            assert tb.dut.grant_encoded.value in grants, f"Error: expected grant on request {grants[i]}, got {tb.dut.grant_encoded.value} instead. Request: {tb.dut.request.value}, iteration: {i}"

            # generate acknowledge
            tb.dut.acknowledge.value = tb.generate_acknowledge(grants[i])

            # Deassert request bit
            request = tb.request_putdown(request, grants[i])
            tb.dut.request.value = request

            i += 1
            await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


if cocotb.SIM_NAME:
    factory = TestFactory(run_test_arbitration)
    factory.generate_tests()

# cocotb-test
tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'rtl'))

def test_arbiter():
    dut = "arbiter"
    testbench = f"test_{dut}"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = testbench

    test_file = os.path.join(tests_dir, f"{testbench}.sv")

    verilog_sources = [
        test_file,
        os.path.join(rtl_dir, "priority_encoder.sv"),
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
