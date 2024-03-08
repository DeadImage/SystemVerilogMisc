# AXI Many-To-One Interconnect

## Overall description

AXI4-Interconnect, initially specifically designed to be a 6-Master-to-1-Slave. With parametrization, any number of Masters is possible. Only one Slave, though.

The order of Masters access to the Slave-side is determined with an arbiter. The Arbiter module is taken from Alex Forenchich, that's the only thing I did not write myself. `AxVALID` signals here act as `request` signals for the Arbiter. Arbiter's grants take form of `AxREADY` signals, issued to specific Master (Slave with respect to the Interconnect) interfaces. After the grant is issued, signals from corresponding interfaces are multiplexed into the internal regfile. From there they're applied to their output interfaces.

Module input parameters include:
- `C_S_COUNT` - Number of internal Slave interfaces (outer Masters);
- `C_ADDR_WIDTH` - Address bus width in bits;
- `C_DATA_WIDTH` - Data bus width in bits. NOTE: Address and Data lines of every interface connected to the Interconnect must have the same width;
- `C_STRB_WIDTH` - Strobe bus width in bits. Calculated automatically;
- `C_ID_WIDTH` - ID bus width in bits;
- `C_USER_WIDTH` - User data bus width in bits;
- `C_ID_MT_USE` - A special parameter, enabling use of AXI ID for multitransaction control (1 - enabled, 0 - disabled). This feature will be described below.

Interconnect supports simultaneous Read and Write transactions from the same Master by default. Note that the Interconnect does not provide any address overlapping checks.
If `C_ID_MT_USE = 1`, multitransactions are supported, but they must use AXI ID field for this feature to work properly.

## Design

![module](img/image7.png)

Arbiter is launched by any of the `AxVALID` signals. When Arbiter produces a Grant, multiplexing of the input from one of the internal Slave intefaces takes place.

Multitransactions are possible, if `C_ID_MT_USE = 1`. If, once a transaction is started, `AxVALID` signal from the selected internal Slave interface is asserted again, it will start another transaction without waiting for the previous one to finish. This will occur only if the value of `AxID` field of the new transaction is the same as the first one's. The Interconnect will keep the connection between Master and Slave interfaces until all of the transactions with the same AXI ID are complete.

If AXI ID is not used, then the Interconnect should be instantiated with `C_ID_MT_USE = 0`. There will be no multitransactions feature provided in this case. It will be only one transaction from one interface per time. However, the Interconnect will still allow simultaneous Write/Read transactions to take place. For example, Master#0 issues a Write transaction request by asserting `AWVALID`, it receives a Grant from the Arbiter and starts the transaction. While this transaction is taking place, Master#0 also issues a Read transaction request by asserting `ARVALID`. This request will be granted, if the Write transaction is not finished yet. Moreover, if the Write transaction takes long enough to complete, several Read transactions can be completed. This works vice versa for Read and Write. In other words, a Read/Write transaction that triggers Arbiter request, is performed once per grant, while Read/Write transactions that appear during that first transaction taking place (let us call those Auxiliary transactions), can be performed in any number, just until that first transaction is completed.

The Interconnect uses a system of internal counters and flags to monitor the number of transactions performed. Here's a quick list.

Counters (synthesized and used with `C_ID_MT_USE = 1` only):
- `write_declared_transaction_counter` - Increments when both `AWVALID` and `AWREADY` on the internal Slave-side are asserted;
- `write_completed_transaction_counter` - Increments when both `BVALID` and `BREADY` on the internal Slave-side are asserted;
- `read_declared_transaction_counter` - Increments when both `ARVALID` and `ARREADY` on the internal Slave-side are asserted;
- `read_completed_transaction_counter` - Increments when `RVALID`, `RREADY`, `RLAST` on the internal Slave-side are asserted.

Counters (synthesized and used with `C_ID_MT_USE = 0` only, used for Auxiliary transactions):
- `declared_transaction_counter` - Increments when both `AxVALID` and `AxREADY` on the internal Slave-side are asserted;
- `completed_transaction_counter` - Increments when both `BVALID` and `BREADY` (for Write) or `RVALID`, `RREADY`, `RLAST` (for Read) on the internal Slave-side are asserted.

Flags:
- `write_finish_flag` - With `C_ID_MT_USE = 1`, asserted when `write_declared_transaction_counter` == `write_completed_transaction_counter`. With `C_ID_MT_USE = 0`, asserted when `declared_transaction_counter` == `completed_transaction_counter` if Write transaction is auxuliary, after the first transaction otherwise;
- `read_finish_flag` - With `C_ID_MT_USE = 1`, asserted when `read_declared_transaction_counter` == `read_completed_transaction_counter`. With `C_ID_MT_USE = 0`, asserted when `declared_transaction_counter` == `completed_transaction_counter` if Read transaction is auxuliary, after the first transaction otherwise.

The Interconnect uses exactly one register slice for storing intermediate data. It is needed to store data in case the other side isn't ready to accept it.

Interconnect logic uses simple FSM with only three states: `ST_IDLE`, `ST_TRANSACTION`, `ST_FINISH`.

1. `ST_IDLE` - No transactions, no grants, Arbiter is active and can receive requests. State changes to `ST_TRANSACTION` once the Arbiter issues a Grant;
2. `ST_TRANSACTION` - Interface that received a Grant, performs its transaction(s). When all of those are finished, state is changed to `ST_FINISH`;
3. `ST_FINISH` - Takes exactly one clock cycle. All of the internal flags are deasserted, counters dropped to 0. The next state is `ST_IDLE`.
