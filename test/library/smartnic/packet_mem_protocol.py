__all__ = (
    'PacketMemProtocol',
)

import math
import enum
import time

class PacketMemProtocol():

    class CommandCode(enum.IntEnum):
        NOP = 0
        READ = 1
        WRITE = 2
        CLEAR = 3
    class StatusCode(enum.IntEnum):
        RESET = 0
        READY = 1
        BUSY = 2

    def __init__(self, mem_proxy_if, name='Packet Mem', timeout=100e-3, delay=1e-3, debug=0, **kargs):
        self.name = name
        self.proxy = mem_proxy_if
        self.__DEBUG = debug
        self.__TRACE = 0
        self.__SIZE = int(self.proxy.info_size_upper) << 32 + int(self.proxy.info_size_lower)
        self.__MIN_BURST= int(self.proxy.info_burst.min)
        self.__MAX_BURST = int(self.proxy.info_burst.max)
        self.wait_delay = 1e-3
        self.wait_count = 100
        if self.__DEBUG:
            print(f'# [{self.name}] INIT:')
            print(f'#      Protocol:        PacketMemProtocol')
            print(f'#      Size:            {self.__SIZE}B')
            print(f'#      Mem type:        {self.proxy.info.mem_type}')
            print(f'#      Mem access:      {self.proxy.info.access}')
            print(f'#      Alignment:       {int(self.proxy.info.alignment)}B')
            print(f'#      Burst (min):     {self.__MIN_BURST}B')
            print(f'#      Burst (max):     {self.__MAX_BURST}B')
            print(f'#      Burst Len (max): {self._get_burst_len_max()}')

    def _get_burst_len_max(self):
        return math.floor(self.__MAX_BURST/self.__MIN_BURST)

    def _get_burst_len(self, size_in_bytes):
        burst_len = math.ceil(size_in_bytes/self.__MIN_BURST)
        return min(burst_len, self._get_burst_len_max())

    def _wait_status(self, test):
        count = self.wait_count
        while True:
            status = self.proxy.status().proxy
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
        cmd = self.proxy.command(0).proxy
        cmd.code = int(command)
        self.proxy.command = int(cmd)

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

    def write(self, addr, data):
        size = len(data)
        if self.__DEBUG:
            print(f'# [{self.name}] WRITE {size}B to address 0x{addr:x}')
        while len(data) > 0:
            if (len(data) > self.__MAX_BURST):
                burst_len = self._write_burst(addr, data[0:self.__MAX_BURST])
                data = data[self.__MAX_BURST:]
            else:
                burst_len = self._write_burst(addr, data)
                data = []
            addr += burst_len

    def read(self, addr, size):
        data = []
        if self.__DEBUG:
            print(f'# [{self.name}] READ {size}B from address 0x{addr:x}')
        while len(data) < size:
            if ((size - len(data)) > self.__MAX_BURST):
                (burst_len, new_data) = self._read_burst(addr, self.__MAX_BURST)
                data.extend(new_data)
            else:
                (burst_len, new_data) = self._read_burst(addr, size - len(data))
                data.extend(new_data)
            addr += burst_len
        return data

    def _set_wr_data(self, data):
        size = len(data)
        wr_regs = len(self.proxy.wr_data)
        if self.__TRACE:
            print(f'# [{self.name}] SET_WR_DATA to {data}')
        for i in range(wr_regs):
            wr_data = 0
            for j in range(4):
                byte_idx = i*4 + j
                if (byte_idx < size):
                    wr_data = wr_data + (data[byte_idx] << j*8)
            self.proxy.wr_data[i]._r = wr_data
            if self.__TRACE:
                print(f'#    WR_REG[{i:2d}] = 0x{wr_data:08x}')

    def _get_rd_data(self, size):
        data = [0]*size
        rd_regs = len(self.proxy.rd_data)
        if self.__TRACE:
            print(f'# [{self.name}] GET_RD_DATA')
        for i in range(rd_regs):
            rd_reg = self.proxy.rd_data[i]
            rd_data = int(rd_reg._r)
            for j in range(4):
                byte_idx = i*4 + j
                if (byte_idx < size):
                    data[byte_idx] = (rd_data >> j*8) & 0xff
            if self.__TRACE:
                print(f'#    RD_REG[{i:2d}] = 0x{rd_data:08x}')
        if self.__TRACE:
            print(f'#    DATA: {data}')
        return data

    def _write_burst(self, addr, data):
        size = len(data)
        if (size > self.__MAX_BURST):
            return 0
        if self.__DEBUG:
            print(f'#     WRITE {len(data)}B to address 0x{addr:04x}')
        # Configure transfer
        # - write data
        self._set_wr_data(data)
        # - address
        self.proxy.addr = addr
        # - burst length
        burst_len = self._get_burst_len(size)
        self.proxy.burst.len = burst_len
        # Execute write
        self._transact(self.CommandCode.WRITE)
        return self._get_burst_len(size)

    def _read_burst(self, addr, size):
        if (size > self.__MAX_BURST):
            return 0
        if self.__DEBUG:
            print(f'#     READ {size}B from address 0x{addr:04x}')
        # Configure transfer
        # - address
        self.proxy.addr = addr
        # - burst length
        burst_len = self._get_burst_len(size)
        self.proxy.burst.len = burst_len
        # Execute read
        self._transact(self.CommandCode.READ)
        # Read data
        return (self._get_burst_len(size), self._get_rd_data(size))


        
