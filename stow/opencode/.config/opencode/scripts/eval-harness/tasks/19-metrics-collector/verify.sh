#!/bin/bash
python3 -c "
class Metrics:
    def __init__(self):
        self.counters = {}
        self.histograms = {}
        self.gauges = {}
    def inc(self, name, labels={}, value=1):
        key = (name, tuple(sorted(labels.items())))
        self.counters[key] = self.counters.get(key, 0) + value
    def histogram(self, name, value, labels={}):
        key = (name, tuple(sorted(labels.items())))
        if key not in self.histograms:
            self.histograms[key] = []
        self.histograms[key].append(value)
    def export_prometheus(self):
        lines = []
        for (name, labels), value in self.counters.items():
            label_str = '{' + ','.join(f'{k}="{v}"' for k,v in labels) + '}'
            lines.append(f'{name}{label_str} {value}')
        return '\n'.join(lines)

m = Metrics()
m.inc('requests_total', {'method': 'GET', 'status': '200'})
m.inc('requests_total', {'method': 'POST', 'status': '201'})
output = m.export_prometheus()
assert 'requests_total{method="GET",status="200"} 1' in output
print('Metrics collector works!')
"