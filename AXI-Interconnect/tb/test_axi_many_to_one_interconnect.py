import pytest
import os
import subprocess
import logging
import itertools

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.regression import TestFactory

import cocotb_test.simulator

from cocotbext.axi import AxiBus, AxiMaster, AxiRam

from numpy.random import randint

class TB(object):
    def __init__(self, dut):
        self.dut = dut
        self.s_count = dut.C_S_COUNT.value
        self.addr_width = dut.C_ADDR_WIDTH.value
        self.data_width = dut.C_DATA_WIDTH.value
        self.strobe_width = dut.C_STRB_WIDTH.value
        self.id_width = dut.C_ID_WIDTH.value
        self.user_width = dut.C_USER_WIDTH.value

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

        self.axi_masters = [AxiMaster(AxiBus.from_prefix(dut, f"s{k:02d}_axi"), dut.clk, dut.resetn, reset_active_level=False) for k in range(self.s_count)]
        self.axi_ram = AxiRam(AxiBus.from_prefix(dut, "m_axi"), dut.clk, dut.resetn, reset_active_level=False, size=2**32)

        self.axi_ram.write_if.log.setLevel(logging.DEBUG)

    async def cycle_reset(self):
        self.dut.resetn.setimmediatevalue(1)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.resetn.value = 1

    def set_idle_generator(self, generator=None):
        if generator:
            for master in self.axi_masters:
                master.write_if.aw_channel.set_pause_generator(generator())
                master.write_if.w_channel.set_pause_generator(generator())
                master.read_if.ar_channel.set_pause_generator(generator())
            self.axi_ram.write_if.b_channel.set_pause_generator(generator())
            self.axi_ram.read_if.r_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            for master in self.axi_masters:
                master.write_if.b_channel.set_pause_generator(generator())
                master.read_if.r_channel.set_pause_generator(generator())
            self.axi_ram.write_if.aw_channel.set_pause_generator(generator())
            self.axi_ram.write_if.w_channel.set_pause_generator(generator())
            self.axi_ram.read_if.ar_channel.set_pause_generator(generator())


async def run_test_write(dut, s=0, idle_inserter=None, backpressure_inserter=None):
    tb = TB(dut)

    byte_lanes = tb.axi_masters[s].write_if.byte_lanes
    max_burst_size = tb.axi_masters[s].write_if.max_burst_size

    size = randint(0, max_burst_size + 1)

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in list(range(1, byte_lanes*2))+[1024]:
        for offset in list(range(byte_lanes, byte_lanes*2))+list(range(4096-byte_lanes, 4096)):
            tb.log.info("length %d, offset %d, size %d", length, offset, size)

            addr = offset+0x1000
            test_data = bytearray([x % 256 for x in range(length)])

            tb.axi_ram.write(addr-128, b'\xaa'*(length+256))

            await tb.axi_masters[s].write(addr, test_data, size=size)

            tb.log.debug("%s", tb.axi_ram.hexdump_str((addr & ~0xf)-16, (((addr & 0xf)+length-1) & ~0xf)+48))

            assert tb.axi_ram.read(addr, length) == test_data # data arrived at destination
            assert tb.axi_ram.read(addr-1, 1) == b'\xaa' # no lower addresses were hurt
            assert tb.axi_ram.read(addr+length, 1) == b'\xaa' # no higher addresses were hurt

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_read(dut, s=0, idle_inserter=None, backpressure_inserter=None):
    tb = TB(dut)

    byte_lanes = tb.axi_masters[s].write_if.byte_lanes
    max_burst_size = tb.axi_masters[s].write_if.max_burst_size

    size = randint(0, max_burst_size + 1)

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in list(range(1, byte_lanes*2))+[1024]:
        for offset in list(range(byte_lanes, byte_lanes*2))+list(range(4096-byte_lanes, 4096)):
            tb.log.info("length %d, offset %d, size %d", length, offset, size)

            addr = offset+0x1000
            test_data = bytearray([x % 256 for x in range(length)])

            tb.axi_ram.write(addr, test_data)

            data = await tb.axi_masters[s].read(addr, length, size=size)

            assert data.data == test_data

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_test_read_write(dut, idle_inserter=None, backpressure_inserter=None):
    tb = TB(dut)

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    async def run_read(master, ram, offset, aperture, count=16):
        for i in range(count):
            length = randint(1, min(512, aperture))
            addr = offset + randint(0, aperture-length)

            test_data = bytearray([x % 256 for x in range(length)])

            ram.write(addr, test_data)

            data = await master.read(addr, length)

            assert data.data == test_data

    async def run_write(master, ram, offset, aperture, count=16):
        for i in range(count):
            length = randint(1, min(512, aperture))
            addr = offset + randint(0, aperture-length)

            test_data = bytearray([x % 256 for x in range(length)])

            ram.write(addr-128, b'\xaa'*(length+256))

            await master.write(addr, test_data)

            assert ram.read(addr, length) == test_data
            assert ram.read(addr-1, 1) == b'\xaa'
            assert ram.read(addr+length, 1) == b'\xaa'

    workers = []

    for k in range(8):
        workers.append(cocotb.start_soon(run_read(tb.axi_masters[k % len(tb.axi_masters)], tb.axi_ram, k*0x1000, 0x1000)))
        workers.append(cocotb.start_soon(run_write(tb.axi_masters[k % len(tb.axi_masters)], tb.axi_ram, 0x10000 + k*0x1000, 0x1000)))

    while workers:
        await workers.pop(0).join()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def run_stress_test(dut, idle_inserter=None, backpressure_inserter=None):
    tb = TB(dut)

    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    async def worker(master, ram, offset, aperture, count=16):
        for k in range(count):
            length = randint(1, min(512, aperture))
            addr = offset + randint(0, aperture-length)
            test_data = bytearray([x % 256 for x in range(length)])

            await Timer(randint(1, 100), 'ns')

            await master.write(addr, test_data)

            await Timer(randint(1, 100), 'ns')

            data = await master.read(addr, length)
            assert data.data == test_data

    workers = []

    for k in range(16):
        workers.append(cocotb.start_soon(worker(tb.axi_masters[k % len(tb.axi_masters)], tb.axi_ram, k*0x1000, 0x1000, count=16)))

    while workers:
        await workers.pop(0).join()

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)



def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    #s_count = len(cocotb.top.axi_many_to_one_interconnect_inst.s_axi_awvalid)
    # separate reads and writes
    #for test in [run_test_write, run_test_read]:
        #factory = TestFactory(test)
        #factory.add_option("s", range(min(s_count, 2)))
        #factory.add_option("idle_inserter", [None, cycle_pause])
        #factory.add_option("backpressure_inserter", [None, cycle_pause])
        #factory.generate_tests()

    # stress test - separate reads and writes
    factory = TestFactory(run_stress_test)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

    # simultaneous reads and writes
    factory = TestFactory(run_test_read_write)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

# cocotb-test
tests_dir = os.path.abspath(os.path.dirname(__file__))
wrappers_dir = os.path.abspath(os.path.join(tests_dir, 'wrappers'))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', 'rtl'))

@pytest.mark.parametrize("s_count", [1, 4, 8])
@pytest.mark.parametrize("data_width", [32, 128, 512])
@pytest.mark.parametrize("id_use", [0, 1])
def test_axi_many_to_one_interconnect(s_count, data_width, id_use):
    dut = "axi_many_to_one_interconnect"
    wrapper = f"{dut}_wrap_{s_count}_{data_width}_{id_use}"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = wrapper

    # generate wrapper
    wrapper_file = os.path.join(wrappers_dir, f"{wrapper}.sv")
    if not os.path.exists(wrapper_file):
        subprocess.Popen(
            [os.path.join(rtl_dir, f"{dut}_wrap.py"), "-s", f"{s_count}", "-d", f"{data_width}", "-i", f"{id_use}"],
            cwd=wrappers_dir,
            shell=False
        ).wait()

    verilog_sources = [
        wrapper_file,
        os.path.join(rtl_dir, f"{dut}.sv"),
        os.path.join(rtl_dir, "priority_encoder.sv"),
        os.path.join(rtl_dir, "arbiter.sv")
    ]

    sim_build = os.path.join(tests_dir, "sim_build", f"{dut}_{s_count}_{data_width}_{id_use}")

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module = module,
        sim_build=sim_build,
        timescale='1ns/1ps'
    )

