import string
import json

#---------------------------------------------------------------------------------------------------
def reg_wr(dev, reg, value):
    exec(f"dev.{reg}={value}")   # writes 'value' to 'reg'.

#---------------------------------------------------------------------------------------------------
def reg_rd(dev, reg):
    value = 0

    vars = locals()
    exec(f"value = dev.{reg}", vars)   # reads 'value' from 'reg'.
    value = int(vars['value'])

    #print(f"value = dev.{reg}", value)
    return value

#---------------------------------------------------------------------------------------------------
def reg_block_rd(dev, block):
    paths = []; vars = locals()
    exec(f"paths = str({block}(formatter='json'))", globals(), vars)

    # extract and read all fields in 'block'.
    fields = parse_reg_json(vars['paths'], 'Field', None)
    for field in fields:
        rd_value = reg_rd(dev, field['path'])
        print(f"{field['path']} = 0x{rd_value:x}")

    # extract and read all remaining registers in 'block' (not already covered by 'field' reads).
    registers = parse_reg_json(vars['paths'], 'Register', None)
    for register in registers:
        skip = False
        for field in fields:
            if field['path'] and field['path'].startswith(register['path']):
                skip = True
                break

        if not skip:
            rd_value = reg_rd(dev, register['path'])
            print(f"{register['path']} = 0x{rd_value:x}")

#---------------------------------------------------------------------------------------------------
def reg_blocks(paths, root, num_p4_proc):
    # parses path list and extracts list of top-level blocks within specified root block.

    blocks = []
    prefix = root.rstrip('.') + '.'
    depth  = len(root.split('.'))

    # omit specified open-nic-shell blocks.
    omit = ['syscfg','qdma_func0','qdma_func1','qdma_subsystem',
            'cmac0','qsfp28_i2c0','cmac_adapter0','cmac1','qsfp28_i2c1','cmac_adapter1',
            'sysmon0','sysmon1','sysmon2','qspi','cms']

    # omit HBM blocks
    omit.append('smartnic_egr_qs')

    if (num_p4_proc==1): omit.append('p4_proc_egr')

    for path in paths:
        if path and path.startswith(prefix):
            levels = path.split('.')
            if len(levels) >= depth:
                block = levels[depth]
                if (block not in blocks) and (block not in omit): blocks.append(block)

    return blocks

#---------------------------------------------------------------------------------------------------
def parse_reg_json(json_str, record_type=None, access_type=None):
    # parses reg json string and extracts records of specified type and access.
    # returns list of dictionaries, each record has keys: 'type','access','path',and 'width'.

    data = json.loads(json_str)

    records = []
    for record in data:
        if record_type is None or record.get('type') == record_type:
            if access_type is None or record.get('access') == access_type:
                field_info = {
                    'type':   record.get('type'),
                    'access': record.get('access'),
                    'path':   record.get('path'),
                    'width':  record.get('data', {}).get('width')
                }
                records.append(field_info)

    return records

#---------------------------------------------------------------------------------------------------
