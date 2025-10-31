__all__ = (
    'PacketPlaybackProtocol',
)

import math
import enum
import time

from smartnic.lib.packet_mem_protocol import PacketMemProtocol

class PacketPlaybackProtocol():

    class CommandCode(enum.IntEnum):
        NOP = 0
        SEND_ONE = 1
        SEND_BURST = 2
        SEND_CONTINUOUS = 3
        STOP = 4

    class StatusCode(enum.IntEnum):
        RESET = 0
        DISABLED = 1
        READY = 2
        BUSY = 3

    def __init__(self, proxy, name='Playback', debug=0, **kargs):
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

        if (self.__DEBUG):
            print(f'# [{self.name}] INIT:')
            print(f'#      Type: Playback')
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

    def _set_config(self, size, burst_size=1):
        config = self.proxy.control.config().proxy
        config.packet_bytes = size
        config.burst_size = burst_size
        self.proxy.control.config = config

    def _set_meta(self, meta):
        __META_BYTES = math.ceil(self.__META_BITS/8)
        __META_REGS = math.ceil(__META_BYTES/4)

        if self.__TRACE:
            print(f'# [{self.name}] SET META: 0x{meta:x}')

        meta_bytes = []
        for i in range(__META_BYTES):
            meta_bytes.append(meta & 0xff)
            meta >>= 8

        for i in range(__META_REGS):
            meta_reg = 0
            for j in range(4):
                byte_idx = i*4 + j
                if (byte_idx < __META_BYTES):
                    meta_reg = meta_reg  + (meta_bytes.pop() << 8*j)
            if self.__TRACE:
                print(f'#     META[{i}] = 0x{meta_reg:08x}')
            self.proxy.control.meta[i]._r = meta_reg

    def _wait_status(self, test):
        count = self.wait_count
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
        status = self._wait_status(lambda st: st.code == self.StatusCode.READY)
        if status is None:
            raise TimeoutError('Controller not ready')

        # Trigger the transaction.
        cmd = self.proxy.control.command(0).proxy
        cmd.code = int(command)
        self.proxy.control.command = int(cmd)

        # Wait for the transaction to complete.
        status = self._wait_status(lambda st: st.done or st.timeout or st.error)
        if status is None:
            raise TimeoutError('Controller timeout')
        if status.timeout:
            raise TimeoutError('Transaction timeout')
        if status.error:
            raise IOError('Transaction error')

    def nop(self):
        self._transact(self.CommandCode.NOP)

    def send(self, data, meta=0, err=0, burst=1):
        size = len(data)
        if (self.__DEBUG):
            print(f'# [{self.name}] SEND:')
            print(f'#     SIZE: {size:d}B')
            print(f'#     META: 0x{meta:x}')
        # Configure transaction
        self._set_config(size, burst)
        self._set_meta(meta)
        # Write packet memory
        self.packetmem.write(0, data)
        # Issue transaction
        if burst > 1:
            self._transact(self.CommandCode.SEND_BURST)
        elif burst < 1:
            self._transact(self.CommandCode.SEND_CONTINUOUS)
        else:
            self._transact(self.CommandCode.SEND_ONE)
