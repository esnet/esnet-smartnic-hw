from robot.api.deco import keyword, library

#---------------------------------------------------------------------------------------------------
@library
class Library:
    # One instance of this library + server per Robot Test Suite
    ROBOT_LIBRARY_SCOPE = 'SUITE'

    def __new__(cls, p4_hw_env, *args, **kwargs):
        if cls is Library:
            if p4_hw_env == 'p4bm-sim':
                import p4_robot_p4bm
                return p4_robot_p4bm.Library(*args, **kwargs)
            elif p4_hw_env == 'rtl-sim':
                import p4_robot_rtl
                return p4_robot_rtl.Library(*args, **kwargs)
            elif p4_hw_env == 'smartnic':
                import p4_robot_smartnic
                return p4_robot_smartnic.Library(*args, **kwargs)

        # For subclasses or unknown types, use normal object creation
        return super().__new__(cls)

    def __init__(self, *args, **kwargs):
        pass

class API:
    def __init__(self, *args, **kwargs):
        raise NotImplementedError

    @keyword
    def p4_start_server(self, p4_json_path):
        pass

    @keyword
    def p4_stop_server(self):
        pass

    @keyword
    def p4_get_config(self):
        raise NotImplementedError

    @keyword
    def p4_reset_cmd_log(self):
        raise NotImplementedError

    @keyword
    def p4_write_cmd_log(self, cmd_log_filename):
        raise NotImplementedError

    @keyword
    def p4_apply_cmd_log(self, cmd_log_filename):
        raise NotImplementedError

    @keyword
    def p4_cmd(self, line):
        raise NotImplementedError

    @keyword
    def p4_reset_state(self):
        raise NotImplementedError

    @keyword
    def p4_run_traffic(self, pcap_path):
        raise NotImplementedError

    @keyword
    def p4_read_counter(self, counter_name, index):
        raise NotImplementedError

    @keyword
    def p4_counter_reset_one(self, counter_name):
        raise NotImplementedError

    @keyword
    def p4_counter_reset_all(self):
        raise NotImplementedError
