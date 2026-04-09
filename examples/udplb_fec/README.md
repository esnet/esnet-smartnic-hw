# Example Design: udplb_fec

The 'udplb_fec' example design provides preliminary versions of the custom ingress and egress RTL functions ('smartnic_app_igr' and 'smartnic_app_egr') for the version of the 'udplb' application that introduces support for RS FEC encoding and decoding in the datapath.

For the purpose of RTL testing, this preliminary example simply copies the P4 source code and behavioural simulation testcases from the 'p4_multi_proc' example design.
