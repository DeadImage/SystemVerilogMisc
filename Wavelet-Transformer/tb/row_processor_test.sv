`timescale 1 ps/ 1 ps
localparam LENGTH = 256;

module row_processor_test();
	// test vector input registers
	logic clk;
	logic resetn;
	logic en;
	logic result;
	logic [7:0] in [LENGTH];
	// module output connections
	logic [7:0] s, d;
	
	//input and output arrays
    logic [7:0] din[0:LENGTH-1]; //input	
	integer fin;
		
	//device under test
	row_processor uut_inst (
		.clk(clk),
		.resetn(resetn),
		.en(en),
		.in(in),
		.s(s),
		.d(d),
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

		for (int i = 0; i < LENGTH/2 + 5; i = i + 1)
		begin
			@(posedge clk);
			if (i == 0) en = 0;
		end
        
		$fclose(fin);
		
		//stop simulation
		$stop;
	end
	
endmodule
	
