`timescale 1 ps/ 1 ps

import essentials::*;

module dwt_module_tb();
	// test vector input registers
	logic clk;
	logic resetn;
	logic en;
	logic result;
	logic rdy;
	logic [7:0] in;
	logic [7:0] s, d;
	
	int iteration_num, iteration_num_prev;
	integer fin, fout;
	
	//input and output arrays
    logic [7:0] din[0:(LENGTH*LENGTH)-1]; //input
	logic [7:0] dout[0:(LENGTH*LENGTH)-1]; //output
		
	//device under test
	dwt_module uut_inst (
		.clk(clk),
		.resetn(resetn),
		.en(en),
		.rdy(rdy),
		.in(in),
		.s(s), .d(d),
		.result(result)
	);
	
	// create clock
	initial                                                
	begin                                                  
		clk=0;
		forever #10 clk=~clk;
	end

	// reset circuit and run several transactions
	initial begin
		//Read data
		fin = $fopen("im_Monkey.bin", "rb");
		fout = $fopen("im_Monkey_out.bin", "wb");
        $fread(din, fin);
		
		// reset
		resetn=0;
		@(negedge clk) resetn=1;
		en = 0;
		iteration_num_prev = 0;

		for (int i = 0; i < LENGTH/2; i = i + 1)
		begin
			if (i == 0)
				iteration_num = LENGTH*3;
			else if (i == LENGTH/2 - 1)
				iteration_num = LENGTH;
			else
				iteration_num = LENGTH*2;
			
			while (!rdy)
				@(posedge clk);
			en = 1;
			for (int j = 0; j < iteration_num; j = j + 1)
			begin
				@(posedge clk);
				if (j == 0) en = 0;
				in = din[i*iteration_num_prev + j];
			end

			while (!result)
				@(posedge clk);
			for (int j = 0; j < LENGTH; j = j + 1)
			begin
				@(posedge clk);
				dout[i*LENGTH + j] = s;
				dout[(i + LENGTH/2)*LENGTH + j] = d;
			end
			
			iteration_num_prev = iteration_num;
			
		end
		
		for (int i = 0; i < 100; i = i + 1)
			@(posedge clk);
		
		//Write data
		foreach(dout[i]) 
        begin
            $fwrite(fout, "%c", dout[i]);
        end
		
		$fflush(fout);
		$fclose(fin);
		$fclose(fout);
		
		//stop simulation
		$stop;
	end
	
endmodule
	
