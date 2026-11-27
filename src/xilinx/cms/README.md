# Card information acquisition

`xilinx_cms_cardinfo_fetch_fsm` owns a 50 MHz CMS AXI-Lite interface during
startup. It debounces reset, starts the MicroBlaze, waits for firmware
readiness, requests card information through the mailbox and caches up to
255 bytes. It then holds the MicroBlaze in reset and forwards host AXI-Lite
transactions to CMS.

The cache uses a byte request/response interface with a length and valid
flag. Fetching and cache state use `cms_srst`, independently of the host
interface reset. After fetching, host reset also resets the downstream CMS
interface so incomplete host transactions are discarded without losing
cached card information.

`error_boot_timeout`, `error_bad_axil_transaction`,
`error_card_info_length` and `error_fetch_timeout` latch failures until
`cms_srst`. `FETCH_TIMEOUT_CYCLES` bounds the entire acquisition, including
stalled AXI address/data/response channels and cleanup writes. Its default
is 5.5 seconds at 50 MHz. On expiry the fetcher resets the downstream
interface and transaction engine for 16 cycles and releases the interface
for host access. Acquisition and resource release are independent of the
VPD consumer.

Run the fetch tests with:

```sh
make -C src/xilinx/cms/tests/xilinx_cms_cardinfo_fetch
```
