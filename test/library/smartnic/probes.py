import sn_cfg
import sys
import time

# Temporary workaround for silencing verbose logging in underlying gRPC C library.
import os
os.environ['GRPC_VERBOSITY'] = 'ERROR'


#---------------------------------------------------------------------------------------------------
def clear_switch_stats():
    client = sn_cfg.connect_client(tls_insecure=True)
    clr_switch_stats(client)

#---------------------------------------------------------------------------------------------------
def clr_switch_stats(client):
    resp = next(client.ClearSwitchStats(sn_cfg.proto.SwitchStatsRequest(dev_id=0)))
    if resp.error_code == sn_cfg.proto.ErrorCode.EC_OK:
        print('ClearSwitchStats request OK.')
    else:
        print(f'ERROR: Failed to clear switch stats [{sn_cfg.proto.ErrorCode.Name(resp.error_code)}].')
        sys.exit(1)
    return resp.stats

#---------------------------------------------------------------------------------------------------
def check_probes(names, pkts, bytes, check_zeros=1):
    client = sn_cfg.connect_client(tls_insecure=True)
    stats = get_stats(client)
    metrics = stats_metrics_to_map(stats)
    #dump_metrics(metrics, 'Metrics')

    for name in names:
        m = metrics[name+'.pkt_count']
        rx_pkts = m['value']
        #if (m['value'] != pkts): raise AssertionError(f'Number of packets received {m['value']} did NOT match expected {pkts}!')
        if (rx_pkts != pkts): raise AssertionError(f'Number of packets received {rx_pkts} did NOT match expected {pkts}!')

        m = metrics[name+'.byte_count']
        if (m['value'] != bytes): raise AssertionError(f'Number of bytes received did NOT match expected!')

    if check_zeros and (len(metrics) != 2*len(names)):  # each 'non-zero' metric has 'pkt' and 'byte' count.
        print(metrics)
        raise AssertionError(f'A counter expected to be ZERO did NOT match!')

#---------------------------------------------------------------------------------------------------
def get_stats(client):
    resp = next(client.GetSwitchStats(sn_cfg.proto.SwitchStatsRequest(
        dev_id=0, filters=sn_cfg.proto.StatsFilters(non_zero=True))))
    if resp.error_code == sn_cfg.proto.ErrorCode.EC_OK:
        print('Switch stats query OK.')
    else:
        print(f'ERROR: Failed to query switch stats [{sn_cfg.proto.ErrorCode.Name(resp.error_code)}].')
        sys.exit(1)
    return resp.stats

#---------------------------------------------------------------------------------------------------
def stats_metrics_to_map(stats):
    metrics = {}
    for metric in stats.metrics:
        name = f'{metric.scope.block}.{metric.name}'
        last_update = metric.last_update.seconds * 1e6 + metric.last_update.nanos * 1e-3 # to usecs

        metrics[name] = {
            'value': metric.values[0].u64,
            'last_update': last_update,
        }

    return metrics

#---------------------------------------------------------------------------------------------------
def stats_metrics_diff(metrics_a, metrics_b):
    diffs = {}
    for name, mb in metrics_b.items():
        ma = metrics_a.get(name)
        if ma is None:
            continue
             
        value = mb['value'] - ma['value']
        lu = mb['last_update'] - ma['last_update']
        rate = value / lu if lu > 0.0 else 0 # count/us

        diffs[name] = {
            'value': value,
            'last_update': lu,
            'rate': rate,
        }
    return diffs

#---------------------------------------------------------------------------------------------------
def stats_metrics_rate(metrics):
    rates = {}
    i=0
    for name, m in metrics.items():
        if i%2 == 0:
            value = m['value']
            lu = m['last_update']
            rate = value / lu if lu > 0.0 else 0 # count/us
            pkts = value
        else:
            value = m['value']
            lu = m['last_update']
            rate = ( value*8 + pkts*(20+4)*8 ) / lu if lu > 0.0 else 0 # count/us

        rates[name] = {
            'value': value,
            'last_update': lu,
            'rate': rate,
        }
        i=i+1
            
    return rates

#---------------------------------------------------------------------------------------------------
def dump_metrics(metrics, label):
    name_len = max(len(name) for name in metrics)

    print('=' * 80)
    print(f'Switch stats metrics [{label}]:')
    for name in sorted(metrics):
        m = metrics[name]
        row = f'    {name:>{name_len}}: {m["value"]}  [{m["last_update"]} us]'
        if 'rate' in m:
            row += f'  <{m["rate"]} count/us>'
        print(row)
    print('=' * 80)

#---------------------------------------------------------------------------------------------------
def check_rates(port, pkts, bytes):
    client = sn_cfg.connect_client(tls_insecure=True)

    time.sleep(1) # wait in seconds, for stats collection.

    stats = get_stats(client)
    before = stats_metrics_to_map(stats)
    dump_metrics(before, 'Before')

    time.sleep(5) # wait in seconds, accumulates counts for rate calculation.

    stats = get_stats(client)
    after = stats_metrics_to_map(stats)
    #dump_metrics(after, 'After')

    diffs = stats_metrics_diff(before, after)
    rates = stats_metrics_rate(diffs) 
    dump_metrics(rates, 'Rates')

    precision = 0.005

    if (port==0 or port==2):
        m = rates['probe_to_cmac_0.pkt_count']['rate']
        if (m < (1-precision)*pkts or m > (1+precision)*pkts):
            raise AssertionError(f'CMAC0 packet rate {m} did NOT match expected {pkts}!')

        m = rates['probe_to_cmac_0.byte_count']['rate']
        if (m < (1-precision)*bytes or m > (1+precision)*bytes):
            raise AssertionError(f'CMAC0 byte rate {m} did NOT match expected {bytes}!')

    if (port==1 or port==2):
        m = rates['probe_to_cmac_1.pkt_count']['rate']
        if (m < (1-precision)*pkts or m > (1+precision)*pkts):
            raise AssertionError(f'CMAC1 packet rate {m} did NOT match expected {pkts}!')

        m = rates['probe_to_cmac_1.byte_count']['rate']
        if (m < (1-precision)*bytes or m > (1+precision)*bytes):
            raise AssertionError(f'CMAC1 byte rate {m} did NOT match expected {bytes}!')

#---------------------------------------------------------------------------------------------------
