__all__ = (
    'PacketCaptureProtocol',
)

import math
import enum
import time

from smartnic.lib.packet_mem_protocol import PacketMemProtocol

class PacketCaptureProtocol():

    class CommandCode(enum.IntEnum):
        NOP = 0
        CAPTURE = 1

    class StatusCode(enum.IntEnum):
        RESET = 0
        DISABLED = 1
        READY = 2
        BUSY = 3

    def __init__(self, proxy, name='Capture', debug=0, **kargs):
        self.name = name
        self.proxy = proxy
        self.__DEBUG = debug
        self.__TRACE = 0
        self.__MEM_SIZE = int(self.proxy.control.info.mem_size)
        self.__META_BITS = int(self.proxy.control.info.meta_width)
        self.wait_delay = 1e-3
        self.wait_count = 100
        # Initialize packet memory agent
        self.packetmem = PacketMemProtocol(proxy.data, f'{name} Mem', debug=self.__DEBUG)

        if self.__DEBUG:
            print(f'# [{self.name}] INIT:')
            print(f'#      Type: Capture')
            print(f'#      Size: {self.__MEM_SIZE}B')
            print(f'#      Meta width: {self.__META_BITS}b')

    def enable(self):
        control = self.proxy.control.control().proxy
        control.enable = 1
        self.proxy.control.control = control

    def disable(self):
        control = self.proxy.control.control().proxy
        control.enable = 0
        self.proxy.control.control = control

    def _wait_status(self, test, count=None):
        while True:
            status = self.proxy.control.status().proxy
            if test(status):
                return status

            if count is None: # Loop infinitely for condition...
                continue

            if count <= 0:
                return None
            count -= 1
            time.sleep(self.wait_delay)

    def _transact(self, command):
        # Setup for the transaction.
        status = self._wait_status(lambda st: st.code == self.StatusCode.READY, count=self.wait_count)
        if status is None:
            raise TimeoutError('Controller not ready')

        # Trigger the transaction.
        cmd = self.proxy.control.command(0).proxy
        cmd.code = int(command)
        self.proxy.control.command = int(cmd)

        # Wait for the transaction to complete.
        status = self._wait_status(lambda st: st.done or st.error)
        if status is None:
            raise TimeoutError('Controller timeout')
        if status.error:
            raise IOError('Transaction error')

    def trigger(self):
        # Setup for the transaction.
        status = self._wait_status(lambda st: st.code == self.StatusCode.READY, count=self.wait_count)
        if status is None:
            raise TimeoutError('Controller not ready')

        # Trigger the transaction.
        cmd = self.proxy.control.command(0).proxy
        cmd.code = int(self.CommandCode.CAPTURE)
        self.proxy.control.command = int(cmd)

        if (self.__DEBUG):
            print(f'# [{self.name}] TRIGGERED')

    def wait_on_capture(self):
        # Wait for the transaction to complete.
        status = self._wait_status(lambda st: st.done or st.error, None)
        if status is None:
            raise TimeoutError('Controller timeout')
        if status.error:
            raise IOError('Transaction error')
        size = int(status.packet_bytes)
        if self.__DEBUG:
            print(f'# [{self.name}] CAPTURE DONE ({size}B captured)')
        return self._get_capture(size)

    def _get_meta(self):
        __META_BYTES = math.ceil(self.__META_BITS/8)
        __META_REGS = math.ceil(__META_BYTES/4)

        if self.__TRACE:
            print(f'# [{self.name}] GET META')

        meta = 0
        for i in range(__META_REGS):
            meta_reg = int(self.proxy.control.meta[i]._r)
            if self.__TRACE:
                print(f'#    META[{i}] = 0x{meta_reg:08x}')
            for j in range(4):
                byte_idx = i*4 + j
                if (byte_idx < __META_BYTES):
                    meta = (meta << 8) + (meta_reg & 0xff)
                    meta_reg >>= 8
        if self.__TRACE:
            print(f'#     META = 0x{meta:x}')
        return meta

    def _get_capture(self, size):
        meta = self._get_meta()
        if self.__DEBUG:
            print(f'#     META = 0x{meta:x}')
        return (self.packetmem.read(0, size), meta)

    def nop(self):
        self._transact(self.CommandCode.NOP)

    def capture(self):
        self.trigger()
        return self.wait_on_capture()
