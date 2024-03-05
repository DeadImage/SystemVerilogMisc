`timescale 1 ps/ 1 ps
localparam LENGTH = 16;

module cdf5_3_test();
	logic clk;
	logic resetn;
	logic en;
	logic dis;
	logic result;
	logic [7:0] in0;
	logic [7:0] in1;
	logic [7:0] in2;
	logic [7:0] out_s;
	logic [7:0] out_d;
	
	//input and output arrays
    logic [7:0] din[0:LENGTH-1]; //input
	logic [7:0] din_1[0:LENGTH-1];
	
	integer fin;
		
	//device under test
	cdf5_3 uut_inst (
		.clk(clk),
		.resetn(resetn),
		.en(en),
		.dis(dis),
		.in0(in0),
		.in1(in1),
		.in2(in2),
		.out_s(out_s),
		.out_d(out_d),
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
		//skip one edge after reset
		//@(posedge clk);
		en = 0;		
		dis = 0;
		transform_1d();
						
        $fclose(fin);		
		//stop simulation
		$stop;
	end
	
	//Результат готов через 2 такта после подачи in
	task transform_1d();
		int i;
		begin
			for (i = 0; i < LENGTH+10; i = i + 2)
			begin
				@(posedge clk);
				if (i == 0)
					en = 1;
				else
					en = 0;
				in0 = din[i];
				in1 = din[i+1];
				if (i == 14)
					in2 = din[i+1];
				else 
					in2 = din[i+2];
				
				if (i == 16)
					dis = 1;
				else
					dis = 0;
			end
		end
	endtask
	
endmodule
	
