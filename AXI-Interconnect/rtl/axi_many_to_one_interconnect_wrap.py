#!/usr/bin/env python
"""
Wrapper Generator
"""

import argparse
from jinja2 import Template

def main():
    parser = argparse.ArgumentParser(description=__doc__.strip())
    parser.add_argument('-s', '--s_count',  type=int, default=[6], nargs='+', help="number of slave interfaces")
    parser.add_argument('-d', '--data_width',  type=int, default=[32], nargs='+', help="width of data channel")
    parser.add_argument('-i', '--id_use', type=int, default=[1], nargs='+', help='usage of ID sognals for multi-transaction control')
    parser.add_argument('-n', '--name',   type=str, help="module name")
    parser.add_argument('-o', '--output', type=str, help="output file name")

    args = parser.parse_args()

    try:
        generate(**args.__dict__)
    except IOError as ex:
        print(ex)
        exit(1)

def generate(s_count=4, data_width=32, id_use=1, name=None, output=None):
    s = s_count if type(s_count) == int else s_count[0]
    d = data_width if type(data_width) == int else data_width[0]
    i = id_use if type(id_use) == int else id_use[0]

    if name is None:
        name = f"axi_many_to_one_interconnect_wrap_{s}_{d}_{i}"

    if output is None:
        output = name + ".sv"

    print(f"Generating AXI Many to One Interconnect wrapper {name} with S_COUNT = {s}, C_DATA_WIDTH = {d}, C_ID_MT_USE = {i}")

    t = Template(u"""
`resetall
`timescale 1ns / 1ps

/*
 * AXI Many to One Interconnect wrapper with S_COUNT = {{s}}, C_DATA_WIDTH = {{d}}, C_ID_MT_USE = {{i}}
 */

 module {{name}} # (
    parameter C_S_COUNT = {{s}},
	parameter C_ADDR_WIDTH = 32,
	parameter C_DATA_WIDTH = {{d}},
	parameter C_STRB_WIDTH = C_DATA_WIDTH / 8,
	parameter C_ID_WIDTH = 4,
	parameter C_USER_WIDTH = 1,
	parameter C_ID_MT_USE = {{i}}
)
(
    // Clock and Resetn
	input logic clk,
	input logic resetn,

	/*
		Slave Interfaces
	*/
	{%- for p in range(s) %}
	input  logic [C_ID_WIDTH-1:0]   s{{'%02d'%p}}_axi_awid,
    input  logic [C_ADDR_WIDTH-1:0] s{{'%02d'%p}}_axi_awaddr,
    input  logic [7:0]              s{{'%02d'%p}}_axi_awlen,
    input  logic [2:0]              s{{'%02d'%p}}_axi_awsize,
    input  logic [1:0]              s{{'%02d'%p}}_axi_awburst,
    input  logic                    s{{'%02d'%p}}_axi_awlock,
    input  logic [3:0]              s{{'%02d'%p}}_axi_awcache,
    input  logic [2:0]              s{{'%02d'%p}}_axi_awprot,
    input  logic [3:0]              s{{'%02d'%p}}_axi_awqos,
    input  logic [C_USER_WIDTH-1:0] s{{'%02d'%p}}_axi_awuser,
    input  logic                    s{{'%02d'%p}}_axi_awvalid,
    output logic                    s{{'%02d'%p}}_axi_awready,
    input  logic [C_DATA_WIDTH-1:0] s{{'%02d'%p}}_axi_wdata,
    input  logic [C_STRB_WIDTH-1:0] s{{'%02d'%p}}_axi_wstrb,
    input  logic                    s{{'%02d'%p}}_axi_wlast,
    input  logic [C_USER_WIDTH-1:0] s{{'%02d'%p}}_axi_wuser,
    input  logic                    s{{'%02d'%p}}_axi_wvalid,
    output logic                    s{{'%02d'%p}}_axi_wready,
    output logic [C_ID_WIDTH-1:0]   s{{'%02d'%p}}_axi_bid,
    output logic [1:0]              s{{'%02d'%p}}_axi_bresp,
    output logic [C_USER_WIDTH-1:0] s{{'%02d'%p}}_axi_buser,
    output logic                    s{{'%02d'%p}}_axi_bvalid,
    input  logic                    s{{'%02d'%p}}_axi_bready,
    input  logic [C_ID_WIDTH-1:0]   s{{'%02d'%p}}_axi_arid,
    input  logic [C_ADDR_WIDTH-1:0] s{{'%02d'%p}}_axi_araddr,
    input  logic [7:0]              s{{'%02d'%p}}_axi_arlen,
    input  logic [2:0]              s{{'%02d'%p}}_axi_arsize,
    input  logic [1:0]              s{{'%02d'%p}}_axi_arburst,
    input  logic                    s{{'%02d'%p}}_axi_arlock,
    input  logic [3:0]              s{{'%02d'%p}}_axi_arcache,
    input  logic [2:0]              s{{'%02d'%p}}_axi_arprot,
    input  logic [3:0]              s{{'%02d'%p}}_axi_arqos,
    input  logic [C_USER_WIDTH-1:0] s{{'%02d'%p}}_axi_aruser,
    input  logic                    s{{'%02d'%p}}_axi_arvalid,
    output logic                    s{{'%02d'%p}}_axi_arready,
    output logic [C_ID_WIDTH-1:0]   s{{'%02d'%p}}_axi_rid,
    output logic [C_DATA_WIDTH-1:0] s{{'%02d'%p}}_axi_rdata,
    output logic [1:0]              s{{'%02d'%p}}_axi_rresp,
    output logic                    s{{'%02d'%p}}_axi_rlast,
    output logic [C_USER_WIDTH-1:0] s{{'%02d'%p}}_axi_ruser,
    output logic                    s{{'%02d'%p}}_axi_rvalid,
    input  logic                    s{{'%02d'%p}}_axi_rready,
    {% endfor %}

    /*
		Master Interface
	*/
	output logic [C_ID_WIDTH-1:0]   m_axi_awid,
    output logic [C_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [7:0]              m_axi_awlen,
    output logic [2:0]              m_axi_awsize,
    output logic [1:0]              m_axi_awburst,
    output logic                    m_axi_awlock,
    output logic [3:0]              m_axi_awcache,
    output logic [2:0]              m_axi_awprot,
    output logic [3:0]              m_axi_awqos,
    output logic [3:0]              m_axi_awregion,
    output logic [C_USER_WIDTH-1:0] m_axi_awuser,
    output logic                    m_axi_awvalid,
    input  logic                    m_axi_awready,
    output logic [C_DATA_WIDTH-1:0] m_axi_wdata,
    output logic [C_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                    m_axi_wlast,
    output logic [C_USER_WIDTH-1:0] m_axi_wuser,
    output logic                    m_axi_wvalid,
    input  logic                    m_axi_wready,
    input  logic [C_ID_WIDTH-1:0]   m_axi_bid,
    input  logic [1:0]              m_axi_bresp,
    input  logic [C_USER_WIDTH-1:0] m_axi_buser,
    input  logic                    m_axi_bvalid,
    output logic                    m_axi_bready,
    output logic [C_ID_WIDTH-1:0]   m_axi_arid,
    output logic [C_ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [7:0]              m_axi_arlen,
    output logic [2:0]              m_axi_arsize,
    output logic [1:0]              m_axi_arburst,
    output logic                    m_axi_arlock,
    output logic [3:0]              m_axi_arcache,
    output logic [2:0]              m_axi_arprot,
    output logic [3:0]              m_axi_arqos,
    output logic [3:0]              m_axi_arregion,
    output logic [C_USER_WIDTH-1:0] m_axi_aruser,
    output logic                    m_axi_arvalid,
    input  logic                    m_axi_arready,
    input  logic [C_ID_WIDTH-1:0]   m_axi_rid,
    input  logic [C_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [1:0]              m_axi_rresp,
    input  logic                    m_axi_rlast,
    input  logic [C_USER_WIDTH-1:0] m_axi_ruser,
    input  logic                    m_axi_rvalid,
    output logic                    m_axi_rready
);

axi_many_to_one_interconnect # (
    .C_S_COUNT(C_S_COUNT),
	.C_ADDR_WIDTH(C_ADDR_WIDTH),
	.C_DATA_WIDTH(C_DATA_WIDTH),
	.C_STRB_WIDTH(C_STRB_WIDTH),
	.C_ID_WIDTH(C_ID_WIDTH),
	.C_USER_WIDTH(C_USER_WIDTH),
	.C_ID_MT_USE(C_ID_MT_USE)
) axi_many_to_one_interconnect_inst (
    .clk(clk),
    .resetn(resetn),
    .s_axi_awid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awaddr({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awaddr{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awlen({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awlen{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awsize({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awsize{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awburst({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awburst{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awlock({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awlock{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awcache({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awcache{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awprot({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awprot{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awqos({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awqos{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awuser({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awuser{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awvalid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_awready({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_awready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_wdata({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_wdata{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_wstrb({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_wstrb{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_wlast({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_wlast{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_wuser({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_wuser{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_wvalid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_wvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_wready({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_wready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_bid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_bid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_bresp({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_bresp{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_buser({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_buser{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_bvalid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_bvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_bready({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_bready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_araddr({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_araddr{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arlen({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arlen{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arsize({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arsize{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arburst({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arburst{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arlock({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arlock{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arcache({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arcache{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arprot({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arprot{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arqos({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arqos{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_aruser({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_aruser{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arvalid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_arready({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_arready{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_rid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_rid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_rdata({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_rdata{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_rresp({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_rresp{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_rlast({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_rlast{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_ruser({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_ruser{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_rvalid({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_rvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
    .s_axi_rready({ {% for p in range(s-1,-1,-1) %}s{{'%02d'%p}}_axi_rready{% if not loop.last %}, {% endif %}{% endfor %} }),
	.m_axi_awid(m_axi_awid),
    .m_axi_awaddr(m_axi_awaddr),
    .m_axi_awlen(m_axi_awlen),
    .m_axi_awsize(m_axi_awsize),
    .m_axi_awburst(m_axi_awburst),
    .m_axi_awlock(m_axi_awlock),
    .m_axi_awcache(m_axi_awcache),
    .m_axi_awprot(m_axi_awprot),
    .m_axi_awqos(m_axi_awqos),
    .m_axi_awregion(m_axi_awregion),
    .m_axi_awuser(m_axi_awuser),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_wdata(m_axi_wdata),
    .m_axi_wstrb(m_axi_wstrb),
    .m_axi_wlast(m_axi_wlast),
    .m_axi_wuser(m_axi_wuser),
    .m_axi_wvalid(m_axi_wvalid),
    .m_axi_wready(m_axi_wready),
    .m_axi_bid(m_axi_bid),
    .m_axi_bresp(m_axi_bresp),
    .m_axi_buser(m_axi_buser),
    .m_axi_bvalid(m_axi_bvalid),
    .m_axi_bready(m_axi_bready),
    .m_axi_arid(m_axi_arid),
    .m_axi_araddr(m_axi_araddr),
    .m_axi_arlen(m_axi_arlen),
    .m_axi_arsize(m_axi_arsize),
    .m_axi_arburst(m_axi_arburst),
    .m_axi_arlock(m_axi_arlock),
    .m_axi_arcache(m_axi_arcache),
    .m_axi_arprot(m_axi_arprot),
    .m_axi_arqos(m_axi_arqos),
    .m_axi_arregion(m_axi_arregion),
    .m_axi_aruser(m_axi_aruser),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_rid(m_axi_rid),
    .m_axi_rdata(m_axi_rdata),
    .m_axi_rresp(m_axi_rresp),
    .m_axi_rlast(m_axi_rlast),
    .m_axi_ruser(m_axi_ruser),
    .m_axi_rvalid(m_axi_rvalid),
    .m_axi_rready(m_axi_rready)
);

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule

`resetall

""")

    print(f"Writing file '{output}'...")

    with open(output, 'w') as f:
        f.write(t.render(
            s=s,
            d=d,
            i=i,
            name=name
        ))
        f.flush()

    print("Done.")

if __name__ == "__main__":
    main()
