/*
    TEST_BASE SystemVerilog Package

The purpose of this package is to offer a basic set of classes for a usual Testbench.
It does not aim to be universal, more like suitable for most small and medium designs.

Package provides base classes for Generator, Driver, Monitor, Scoreboard, Environment and Test.
Basic workflow is defined already, all one needs to do is
    1. Implement Transaction class;
    2. Implement certain tasks which can't be implemented in base classes, cuz they depend on DUT interface data format.

You'll see that the classes are type parametrized. BaseGenerator, BaseDriver, BaseMonitor, and BaseScoreboard use T parameter.
This one is meant to hold your own Transaction class, once you implement it. BaseEnvironment uses G, D, M, S parameters, which stand for
Generator, Driver, Monitor, Scoreboard types. Once you implement child classes for base versions of those, substitute G, D, M, S with their types.
Same thing goes for BaseTest and E parameter (Environment type).

This version isn't invariant in any way. It can be modified as one's wishes to suit their needs and/or correct any mistakes.

*/


package test_base;

// Direct assertions fails counter variable
int assertion_fails;

// Base class for the Generator;
// Generates a queue of transactions, puts them into mailbox, shuts down.
// 'gen_transaction_set' task is responsible for generation of excatly one set of input values.
// This task is the only thing that has to be implemented in child class.
// Object 'tran0' is already defined, task just needs to instantiate it, fill with data, and put into 'transaction_q'.
class BaseGenerator # (type T = logic);
    mailbox gen2drv;
    T tran0;
    T tran_q [$];

    task run();
        int q_size;
        $display("%0t [Generator] started.", $time);

        $display("%0t [Generator] generating a single set of Transactions...", $time);
        gen_transaction_set(tran_q);
        $display("%0t [Generator] finished generating.", $time);

        q_size = tran_q.size();

        $display("%0t [Generator] putting generated data into mailbox...", $time);
        for (int i = 0; i < q_size; i = i + 1) begin
            tran0 = tran_q.pop_back();
            gen2drv.put(tran0);
        end

        $display("%0t [Generator] stopped.", $time);
    endtask

    virtual task gen_transaction_set (output T transaction_q[$]); endtask
endclass

// Base class for the Driver;
// Receives transactions from the Generator through mailbox, drives them to DUT interface.
// After the mailbox is empty, shuts down, triggering the event 'driver_done'.
// Task 'apply_transaction_to_vif' takes data from the transaction tran0 and applies it to DUT interface.
// It has to be implemented in child class.
class BaseDriver # (type T = logic);
    mailbox gen2drv;
    virtual dut_if vif;
    T tran0;
    event driver_done;

    task run();
        $display("%0t [Driver] started.", $time);
        @ (posedge vif.clk);

        while (gen2drv.num() > 0) begin
            while (~vif.resetn) begin
                $display("%0t [Driver] DUT interface is in reset. Skipping to the next clock cycle...", $time);
                @ (posedge vif.clk);
            end

            $display("%0t [Driver] getting transaction from the mailbox...", $time);
            gen2drv.get(tran0);

            $display("%0t [Driver] applying transaction data to DUT interface...", $time);
            apply_transaction_to_vif(tran0);

            @ (posedge vif.clk);
        end
        $display("%0t [Driver] stopped.", $time);
        -> driver_done;
    endtask

    virtual task apply_transaction_to_vif (input T transaction); endtask
endclass

// Base class for the Monitor;
// Gathers data from the DUT interface, packs it into transaction(s), puts them into the mailbox.
// Uses seprate mailboxes for transactions with data from the input and output sides of the interface.
// Input interface data needed for reference model inside the Scoreboard.
// Field 'wait_cycles' should be given a value inside child class instance.
// 'wait_cycles' value represents the amount of clock cycles delay in the DUT between when the input data
// is applied and when the corresponding output can be collected.
// Tasks 'get_in_transaction_from_vif' and 'get_out_transaction_from_vif' are implemented in child classes.
// 'get_in_transaction_from_vif' gathers input data from vif and puts into a transcation.
// 'get_out_transaction_from_vif' does the same with output data.
// Shuts down once all the data is transmitted.
class BaseMonitor # (type T = logic);
    mailbox mon2scb_out;
    mailbox mon2scb_in;
    virtual dut_if vif;
    T tran_in;
    T tran_out;

    event driver_done;
    event monitor_done;
    bit dd_triggered;

    int wait_cycles = 0;
    int cycles_remaining;

    task run();
        int num_of_run;
        dd_triggered = 1'b0;
        cycles_remaining = wait_cycles;

        $display("%0t [Monitor] started.", $time);
        @ (posedge vif.clk);

        fork
            begin
                wait (driver_done.triggered);
                dd_triggered = 1'b1;
            end

            while (cycles_remaining > 0) begin
                if (dd_triggered) cycles_remaining = cycles_remaining - 1;

                if (~vif.resetn) begin
                    num_of_run = 0;
                    $display("%0t [Monitor] DUT interface is in reset. Skipping to the next clock cycle...", $time);
                end else begin
                    $display("%0t [Monitor] reading data from the DUT...", $time);

                    fork
                        get_in_transaction_from_vif(tran_in);
                        if (num_of_run >= wait_cycles) get_out_transaction_from_vif(tran_out);
                    join

                    $display("%0t [Monitor] sending transactions to Scoreboard...", $time);
                    mon2scb_in.put(tran_in);

                    if (num_of_run < wait_cycles) num_of_run = num_of_run + 1;
                    else mon2scb_out.put(tran_out);
                end

                @ (posedge vif.clk);
            end
        join
        -> monitor_done;
        $display("%0t [Monitor] stopped.", $time);
    endtask

    virtual task get_in_transaction_from_vif (output T transaction_in); endtask
    virtual task get_out_transaction_from_vif (output T transaction_out); endtask
endclass

// Base class for the Scoreboard;
// Gathers input and output transactions from corresponding mailboxes.
// Input transactions are used to build a reference expected output. 'get_input_reference' task
// does exactly that. Expected output is compared to data from the output transactions, with the
// 'check_output' task. Scoreboard shuts down right after Monitor.
class BaseScoreboard # (type T = logic);
    mailbox mon2scb_out;
    mailbox mon2scb_in;
    T tran_in;
    T tran_out;
    T tran_ref;
    bit md_triggered;

    event monitor_done;

    task run();
        $display("%0t [Scoreboard] started.", $time);
        md_triggered = 1'b0;

        fork
            begin
                wait (monitor_done.triggered);
                md_triggered = 1'b1;
            end

            while (!md_triggered) begin
                $display("%0t [Scoreboard] getting transactions from mailboxes...", $time);
                mon2scb_in.get(tran_in);
                mon2scb_out.get(tran_out);

                $display("%0t [Scoreboard] building an output reference...", $time);
                get_input_reference(tran_in, tran_ref);

                $display("%0t [Scoreboard] comparing output data with the reference...", $time);
                check_output(tran_ref, tran_out);
            end
        join
        $display("%0t [Scoreboard] stopped.", $time);
    endtask

    virtual task get_input_reference (input T transaction_in, output T transaction_ref); endtask
    virtual task check_output (input T transaction_ref, input T transaction_out); endtask
endclass

// Base Environment class;
// Instantiates, connects together and launches all the test environment objects.
// Runs until all the instances of Generator, Driver, Monitor and Scoreboard are shut down.
class BaseEnvironment # (type G = BaseGenerator, type D = BaseDriver, type M = BaseMonitor, type S = BaseScoreboard);
    G gen0;
    D drv0;
    M mon0;
    S scb0;

    mailbox gen2drv;
    mailbox mon2scb_in;
    mailbox mon2scb_out;

    event driver_done;
    event monitor_done;

    virtual dut_if vif;

    function new();
        gen0 = new;
        drv0 = new;
        mon0 = new;
        scb0 = new;

        gen2drv     = new();
        mon2scb_in  = new();
        mon2scb_out = new();

        gen0.gen2drv     = gen2drv;
        drv0.gen2drv     = gen2drv;
        mon0.mon2scb_in  = mon2scb_in;
        mon0.mon2scb_out = mon2scb_out;
        scb0.mon2scb_in  = mon2scb_in;
        scb0.mon2scb_out = mon2scb_out;

        drv0.driver_done = driver_done;
        mon0.driver_done = driver_done;
        mon0.monitor_done = monitor_done;
        scb0.monitor_done = monitor_done;
    endfunction

    task run();
        drv0.vif = vif;
        mon0.vif = vif;

        gen0.run();

        fork
            drv0.run();
            mon0.run();
            scb0.run();
        join_none

        @ (monitor_done);
        @ (posedge vif.clk);
        @ (posedge vif.clk);
    endtask
endclass

// Base class for the Test;
// Contains at least one Environment. Starts the Environment, waits till it performs all of
// the needed operations and shuts down.
class BaseTest # (type E = BaseEnvironment);
    E env0;
    string test_name;
    int local_assertion_fails = 0;

    function new(string name);
        env0 = new;
        test_name = name;
    endfunction

    task run();
        assertion_fails = 0;

        $display("%0t [Test] %s started.", $time, test_name);
        env0.run();
        local_assertion_fails = assertion_fails;
        $display("%0t [Test] %s finished.", $time, test_name);
    endtask

    task test_report();
        if (local_assertion_fails > 0) begin
            $display("[Test] %s failed with %0d assertion errors.", test_name, local_assertion_fails);
        end else begin
            $display("[Test] %s passed.", test_name);
        end
    endtask
endclass

endpackage
