//=======================================================================
// Tasks
//=======================================================================
// Execute block reset (dataplane + control plane)
task reset();
    automatic bit reset_done;
    automatic string msg;
    env.reset_dut();
    env.wait_reset_done(reset_done, msg);
    `FAIL_IF_LOG((reset_done == 0), msg);
endtask
