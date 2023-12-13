#!/usr/bin/env python3
import os
import argparse
import json
import xml.etree.ElementTree as ET
from jinja2 import Template, Environment, FileSystemLoader

# Handle command-line arguments
parser = argparse.ArgumentParser(description='Generate vitisnet component helper files for integration into SmartNIC p4_app')
parser.add_argument ('json_file', help='vitisnet json specification')
parser.add_argument ('--template-dir', '-t', default='.', help='location of Jinja2 template files')
parser.add_argument ('--out_dir', '-o', default='.', help='output directory for generated files')
parser.add_argument ('--extern_ports', '-e', default=False, help='specifies whether to include extern ports in wrapper interface')

args = parser.parse_args()

# Parse XML
with open(args.json_file) as f:
    data = json.load(f)

# Populate component properties
props = {}

# Process VitisNet component spec
component_params = data['ip_inst']['parameters']['component_parameters']

# Function to extract named parameter from parameter array
def get_param_value(param_name):
    try:
        return component_params[param_name][0]['value']
    except:
        raise SystemExit("ERROR: Failed to get value for parameter " + param_name + ".")

# Component name
props['name'] = get_param_value('Component_Name')

# P4 metadata
props['p4_file'] = get_param_value('P4_FILE')

# Extern parameters
props['num_user_externs'] = int(get_param_value('NUM_USER_EXTERNS'))
props['user_extern_in_wid'] = int(get_param_value('USER_EXTERN_IN_WIDTH'))
props['user_extern_out_wid'] = int(get_param_value('USER_EXTERN_OUT_WIDTH'))

# Metadata parameters
props['user_metadata_wid'] = int(get_param_value('USER_META_DATA_WIDTH'))

# Packet rate
props['pkt_rate_mhz'] = get_param_value('PKT_RATE')

# AXI-S parameters
props['axis_clk_freq_mhz'] = float(get_param_value('AXIS_CLK_FREQ_MHZ'))
props['axis_data_byte_wid'] = int(get_param_value('TDATA_NUM_BYTES'))

# AXI-L parameters
props['axil_addr_wid'] = int(get_param_value('S_AXI_ADDR_WIDTH'))
props['axil_data_wid'] = int(get_param_value('S_AXI_DATA_WIDTH'))

# Get number of HBM interfaces
props['hbm_axi_if_num'] = int(get_param_value('M_AXI_HBM_NUM_SLOTS'))
props['hbm_axi_ifs'] = {i:"{:02d}".format(i) for i in range(props['hbm_axi_if_num'])}
props['hbm_axi_if_addr_wid'] = int(get_param_value('M_AXI_HBM_ADDR_WIDTH'))
props['hbm_axi_if_data_wid'] = int(get_param_value('M_AXI_HBM_DATA_WIDTH'))

# CAM mem clock
props['cam_mem_clk_en'] = bool(get_param_value('CAM_MEM_CLK_ENABLE'))
props['cam_mem_clk_freq_mhz'] = float(get_param_value('CAM_MEM_CLK_FREQ_MHZ'))

# Extern ports
props['extern_ports'] = bool(args.extern_ports=='True')

# Write SV file according to Jinja2 template
env = Environment(loader=FileSystemLoader(args.template_dir))
env.add_extension('jinja2.ext.loopcontrols')

t = env.get_template('vitisnetp4_wrapper.j2')
wrapper_filename = props['name'] + '_wrapper.sv'
with open(os.path.join(args.out_dir, wrapper_filename), 'w') as f:
    t.stream(props = props).dump(f)

t = env.get_template('vitisnetp4_app_pkg.j2')
app_pkg_filename = props['name'] + '_app_pkg.sv'
with open(os.path.join(args.out_dir, app_pkg_filename), 'w') as f:
    t.stream(props = props).dump(f)
