# P4 Behavioural Simulation

## Makefile

The execution of P4 behavioural simulations is driven by the Makefile
in the p4/sim/ directory.

This Makefile includes the variable assignments that specify how to run
a p4 behavioural simulation, as well as the name of the p4 file and list
of testcases that should be included in a full simulation run.

Each testcase is captured in a separate subdirectory, which contains the
input and output files for the specified test.  The testcase subdirectories
follow the naming pattern of `test-<NAME>`.

Prior to running a simulation, the user should update the Makefile with the
following variable assignments (all other variable assignments can remain
unchanged):

     P4_SOURCE = <pathname of p4 source file>
     P4BM_DIRS = <testcase subdirectory list>

The Makefile includes execution targets to run (or clean) a single testcase
simulation, or simulation of the full testcase suite.

To simulate a single testcase, execute make with the `P4BM_DIR=` argument
set to the testcase subdirectory of interest.  For example:

     > make P4BM_DIR=test-fwd-p0 sim

Or to simulate all test cases:

     > make sim-all

Note: the `sim-all` target is the default target when make is called without
arguments.

To clean all simulation output products from the p4 directory, type:

     > make clean


## Testcase Input Files

The input stimulus file set for each testcase includes three files:

1. `cli_commands.txt` - Command script to set table entries and initiate input
stimulus. Commands and syntax follow the Xilinx p4bm-vitisnet-cli.

2. `packets_in.user` - Input packet stream user data.  Each byte sequence terminated
by a semicolon (;) represents a packet.  Packets are captured in sequence.  The '%'
character is used to start comments.

    `packets_in.pcap` - PCAP file containing the input packet stream.
                        Alternative format to `packets_in.user` (optional).

3. `packets_in.meta` - Input packet metadata.  Each line corresponds
to a packet in the input PCAP or user file, in sequence.  The syntax of the metadata
is described in the Xilinx VitisnetP4 documentation.  Note: Each metadata record
must be terminated by a semicolon (;).

For more details, see chapter 3 of *Vitis Networking P4 User Guide, UG1308 (v2023.2) October 18, 2023*.


## Testcase Output Files

1. `packets_out.user` - Output packet stream user data. Same syntax as input
packet stream user data.

   `packets_out.pcap` - PCAP file containing the output packet stream,
                        if packets_in format was `packets_in.pcap`.

2. `packets_out.meta` - Output packet metadata.  Each line corresponds
to a packet in the output PCAP file (in sequence).  Same syntax as input
packet metadata.

Note: An expected/ directory is optionally included to capture the expected
output results of a testcase.  This expected output can be used for
automated regression testing.


## Testcases: p4_only

`test-fwd-p0` - The p4_only design includes a single example testcase called
test-fwd-p0.  This testcase programs a small number of table entries that
forward the specified packet flows to destination port 0.  The input
stimulus includes a single packet on each flow to validate that all packets
are forwarded to port 0.  All other packets are forwarded to the egress_port specified
by the input meta data.
