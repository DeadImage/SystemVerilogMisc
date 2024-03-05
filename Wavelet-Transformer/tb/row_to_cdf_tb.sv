`timescale 1 ps/ 1 ps
localparam LENGTH = 256;

module row_to_cdf_tb();
	
	// test vector input registers
	logic clk;
	logic resetn;
	logic en;
	logic result;
	logic [7:0] in [LENGTH];
	// module output connections
	logic [7:0] out0, out1, out2;
	
	//input and output arrays
    logic [7:0] din[0:LENGTH-1]; //input
	
	integer fin;
		
	//device under test
	row_to_cdf uut_inst (
		.clk(clk),
		.resetn(resetn),
		.en(en),
		.in(in),
		.out0(out0),
		.out1(out1),
		.out2(out2),
		.result(result)
	);
	
	// create clock
	initial                                                
	begin                                                  
		clk=0;
		forever #10 clk=~clk;
	end

	initial begin
		//Read data
		fin = $fopen("image.bin", "rb");
        $fread(din, fin);
		// reset
		resetn=0;
		@(negedge clk) resetn=1;
		en = 0;	

		@(posedge clk);
		in = din;
		en = 1;
		
		@(posedge clk);
		en = 0;
		
		for (int i = 0; i < LENGTH+4; i = i + 1)
			@(posedge clk);
						
        $fclose(fin);		
		//stop simulation
		$stop;
	end
	
endmodule
	
