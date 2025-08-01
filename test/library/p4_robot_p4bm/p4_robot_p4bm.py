from robot.api.deco import keyword, library

from robot.libraries.BuiltIn import BuiltIn

import os
import subprocess
import time
import sys
import json

sys.path.insert(0, os.environ['XILINX_VIVADO'] + '/tps/lib/python3.8')

from p4_robot import API as P4RobotAPI

import bmpy_utils as utils

# p4bm runtime "standard"/base API
from bm_runtime.standard import Standard
from bm_runtime.standard.ttypes import *

# p4bm runtime vitisnetp4 extensions API ("run_traffic" and "exit")
from bm_vitisnetp4_runtime import BmVitisNetP4

from runtime_CLI import load_json_config, parse_match_key, parse_param
# p4bm runtime CLI interpreter with vitisnet extensions
from bm_vitisnetp4_cli import BmVitisNetP4API

#---------------------------------------------------------------------------------------------------
@library
class Library(P4RobotAPI):
    def __init__(self, *args, **kwargs):
        self.cmd_log = []

    @keyword
    def p4_start_server(self, p4_json_path, externs=None, **kwargs):
        # Look up the user-provided output directory
        robot_built_in = BuiltIn()
        output_dir = robot_built_in.get_variable_value('${OUTPUT DIR}')

        # Generate any target-specific options
        target_options = []
        if externs is not None and len(externs) > 0:
            # Generate a comma separated list of loadable modules to simulate externs
            target_options.append("--load-modules")
            target_options.append(",".join(externs))

        stdout = open(output_dir + '/p4bm-vitisnet.err.txt', 'w')
        self.s = subprocess.Popen(["p4bm-vitisnet",
                                   "--thrift-port", "9090",
                                   "--log-file", output_dir + '/p4bm-vitisnet.log',
                                   "--log-flush",
                                   p4_json_path]
                                  +
                                  ["--"]
                                  +
                                  target_options,
                                  stdout=stdout,
                                  stderr=subprocess.STDOUT)

        # Give the sim some time to start up to prevent stderr noise when trying to connect below
        time.sleep(0.5)

        if self.s.poll() is not None:
            # Failed to start the p4bm process
            raise Exception("Failed to start p4bm simulator.  See p4bm-vitisnet.err.log for details.")

        try:
            # See: .../tps/lib/python3.8/runtime_CLI.py
            services = [("standard", Standard.Client)]
            services += [(None, None)]  # What is this for??

            # See: .../tps/lib/python3.8/bm_vitisnetp4_cli.py
            services += [("bm_vitisnetp4", BmVitisNetP4.Client)]

            standard_client, mc_client, bm_vitisnetp4_client = utils.thrift_connect(
                '127.0.0.1',
                9090,
                2,
                [
                    ("standard", Standard.Client),
                    (None, None),
                    ("bm_vitisnetp4", BmVitisNetP4.Client)
                ])
            self.standard = standard_client
            self.mc = mc_client
            self.vitisnetp4 = bm_vitisnetp4_client

            load_json_config(standard_client, None)
            self.cli = BmVitisNetP4API(None, standard_client, mc_client, bm_vitisnetp4_client)
        except:
            raise Exception("Failed to connect to p4bm simulator.  See p4bm-vitisnet.err.log for details.")

    @keyword
    def p4_stop_server(self):
        self.vitisnetp4.exit()

    @keyword
    def p4_get_config(self):
       config = self.standard.bm_get_config()
       print(config)

    @keyword
    def p4_reset_cmd_log(self):
        self.cmd_log = []

    @keyword
    def p4_write_cmd_log(self, cmd_log_filename):
        with open(cmd_log_filename, 'w') as f:
            for l in self.cmd_log:
                f.write(l)
                f.write('\n')

    @keyword
    def p4_apply_cmd_log(self, cmd_log_filename):
        with open(cmd_log_filename, 'r') as f:
            for l in f.readlines():
                self.p4_cmd(l)

    # Execute a command via the high level p4bm CLI language and show the result
    @keyword
    def p4_cmd(self, line):
        print(self.cli.onecmd(line))
        self.cmd_log.append(line)

    @keyword
    def p4_reset_state(self):
        self.standard.bm_reset_state()
        self.cmd_log = []

    @keyword
    def p4_run_traffic(self, pcap_path):
        self.vitisnetp4.run_traffic([pcap_path])

    @keyword
    def p4_read_counter(self, counter_name, index):
        ctr = self.standard.bm_counter_read(None, counter_name, int(index))
        return(ctr)

    @keyword
    def p4_counter_reset_one(self, counter_name):
        self.standard.bm_counter_reset_all(None, counter_name)

    @keyword
    def p4_counter_reset_all(self):
        config = json.loads(self.standard.bm_get_config())
        for counter in config['counter_arrays']:
            self.standard.bm_counter_reset_all(None, counter['name'])

