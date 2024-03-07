`resetall
`timescale 1ns / 1ps
`default_nettype wire

// Importing package
import test_base::*;

// DUT IF
interface dut_if # (parameter INPUT_WIDTH = 9) (input bit clk);
    logic resetn;
    logic [INPUT_WIDTH-1:0] dut_input_value;
    logic [INPUT_WIDTH:0]   dut_output_value;
endinterface

// Transaction class
class Transaction # (parameter INPUT_WIDTH = 9);
    rand int                   input_data_incr;
    rand bit [INPUT_WIDTH-1:0] input_data;
    bit      [INPUT_WIDTH-1:0] prev_input_data = 0;
    bit      [INPUT_WIDTH:0]   output_data;

    constraint input_data_ctr {input_data_incr inside {[0:5]};
                               input_data inside {[prev_input_data:prev_input_data+input_data_incr]}; }
endclass

// Generator class
class Generator # (parameter INPUT_WIDTH = 9) extends BaseGenerator # (Transaction); // T = Transaction type for BaseGenerator class
    int num_circles;

    // Set of inputs generation
    // num_circles of full circles 0b000 -> 0b1111 -> 0b0000
    task gen_transaction_set (output Transaction transaction_q[$]);
        int curr_data = 0;
        Transaction tran0;

        for (int i = 0; i < num_circles; i = i + 1) begin
            while (curr_data < 512) begin
                tran0 = new;
                tran0.prev_input_data = curr_data;
                tran0.randomize();

                curr_data = curr_data + tran0.input_data_incr;
                transaction_q.push_front(tran0);
            end
        curr_data = 512 - curr_data;
        end
    endtask
endclass

// Driver class
class Driver extends BaseDriver # (Transaction);
    task apply_transaction_to_vif (input Transaction transaction);
        $display("%0t [Driver] data = 0b%0b", $time, transaction.input_data);
        vif.dut_input_value <= transaction.input_data;
        $display("%0t [Driver] data applied.", $time);
    endtask
endclass

// Monitor class
class Monitor extends BaseMonitor # (Transaction);
    int prev_data = 0;

    // Send input transaction
    task get_in_transaction_from_vif (output Transaction transaction_in);
        transaction_in = new;
        transaction_in.input_data = vif.dut_input_value;
        transaction_in.prev_input_data = prev_data;
        prev_data = transaction_in.input_data;
        $display("%0t [Monitor] DUT input data = 0b%0b", $time, transaction_in.input_data);
    endtask

    // Send output transaction
    task get_out_transaction_from_vif (output Transaction transaction_out);
        transaction_out = new;
        transaction_out.output_data = vif.dut_output_value;
        $display("%0t [Monitor] DUT output data = 0b%0b", $time, transaction_out.output_data);
    endtask
endclass

// Scoreboard class
class Scoreboard # (parameter INPUT_WIDTH = 9) extends BaseScoreboard # (Transaction);
    bit expected_msb = 1'b0;

    // Build reference value based on input transaction
    task get_input_reference (input Transaction transaction_in, output Transaction transaction_ref);
        bit [INPUT_WIDTH:0] expected_data;

        if (transaction_in.input_data[INPUT_WIDTH-1] == 1'b0 && transaction_in.prev_input_data[INPUT_WIDTH-1] == 1'b1) begin
            expected_msb = ~expected_msb;
        end
        expected_data = {expected_msb, transaction_in.input_data[INPUT_WIDTH-1:0]};

        $display("%0t [Scoreboard] DUT input data = 0b%0b", $time, transaction_in.input_data);
        $display("%0t [Scoreboard] Expected DUT output data = 0b%0b", $time, expected_data);

        transaction_ref = new;
        transaction_ref.output_data = expected_data;
    endtask

    // Compare reference value with value from the output transaction
    task check_output (input Transaction transaction_ref, input Transaction transaction_out);
        $display("%0t [Scoreboard] DUT output data = 0b%0b", $time, transaction_out.output_data);

        assert (transaction_out.output_data[INPUT_WIDTH] == transaction_ref.output_data[INPUT_WIDTH]) begin
            $display("%0t [Scoreboard] MSB assertion successful.", $time);
        end else begin
            assertion_fails += 1;
            $error("%0t [Scoreboard] MSB assertion error.", $time);
        end

        assert (transaction_out.output_data[INPUT_WIDTH-1:0] == transaction_ref.output_data[INPUT_WIDTH-1:0]) begin
            $display("%0t [Scoreboard] main data assertion successful.", $time);
        end else begin
            assertion_fails += 1;
            $error("%0t [Scoreboard] main data assertion error.", $time);
        end
    endtask
endclass

// Environment class
class Environment # (parameter INPUT_WIDTH = 9) extends BaseEnvironment # (Generator # (INPUT_WIDTH), Driver, Monitor, Scoreboard # (INPUT_WIDTH));
    function new();
        super.new();
        mon0.wait_cycles = 1;
    endfunction
endclass

// Test class
class Test # (parameter INPUT_WIDTH = 9) extends BaseTest # (Environment # (INPUT_WIDTH));
    function new(string name, int num_circles);
        super.new(name);
        env0.gen0.num_circles = num_circles;
    endfunction
endclass

// Testbench
module test_bit_expand_counter # (parameter INPUT_WIDTH = 9);

bit clk;
always #3 clk = ~clk;
dut_if _if(clk);

bit_expand_counter # (
    .INPUT_WIDTH(INPUT_WIDTH)
) dut_inst (
    .clk(clk),
    .resetn(_if.resetn),
    .input_value(_if.dut_input_value),
    .output_value(_if.dut_output_value)
);

initial begin
    localparam NUM_TESTS = 3;
    localparam int circles [NUM_TESTS] = {2, 4, 8};
    string test_name;

    Test tests [3];

    clk <= 0;

    for (int i = 0; i < NUM_TESTS; i = i + 1) begin
        Test # (INPUT_WIDTH) t0;
        test_name = $sformatf("Test #%0d", i+1);

        t0 = new(test_name, circles[i]);
        t0.env0.vif = _if;

        _if.resetn <= 1;
        #3 _if.resetn <= 0;
        _if.dut_input_value <= 0;
        #10 _if.resetn <= 1;

        t0.run();
        tests[i] = t0;
    end

    for (int i = 0; i < NUM_TESTS; i = i + 1) begin
        tests[i].test_report();
    end

    $finish;
end

initial begin
    $dumpfile("waves.vcd");
    $dumpvars;
end

endmodule

`resetall
