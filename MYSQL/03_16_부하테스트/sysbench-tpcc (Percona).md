- purpose
```
실제 TPC-C 워크로드 시뮬레이션를 github에서 가져와서 사용해보자
주문/결제 같은 실제 e-commerce 시나리오
```

- clone
```sql
git clone https://github.com/Percona-Lab/sysbench-tpcc.git
cd sysbench-tpcc
```

- test
```sql
sysbench tpcc.lua \
> --db-driver=mysql \
> --mysql-host=127.0.0.1 \
> --mysql-port=3306 \
> --mysql-user=root \
> --mysql-password=558agers1 \
> --mysql-db=bookstore \
> --threads=4 \
> --tables=1 \
> --scale=1 \
> prepare
```

- run
```sql
sysbench tpcc.lua \
> --db-driver=mysql \
> --mysql-host=127.0.0.1 \
> --mysql-port=3306 \
> --mysql-user=root \
> --mysql-password=558agers1 \
> --mysql-db=bookstore \
> --threads=4 \
> --tables=1 \
> --scale=1 \
> --time=60 \
> run
```

- analyze
```sql
SQL statistics:
    queries performed:
        read:                            1048058
        write:                           1087759
        other:                           161866
        total:                           2297683
    transactions:                        80927  (1348.59 per sec.)
    queries:                             2297683 (38289.23 per sec.)
    ignored errors:                      320    (5.33 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0083s
    total number of events:              80927

Latency (ms):
         min:                                    0.21
         avg:                                    2.97
         max:                                  303.05
         95th percentile:                        0.00
         sum:                               239959.82

Threads fairness:
    events (avg/stddev):           20231.7500/119.65
    execution time (avg/stddev):   59.9900/0.00
```

- difference

| 지표             | sysbench (oltp_read_write) | TPC-C          |
| -------------- | -------------------------- | -------------- |
| TPS            | 2,092                      | 1,348.59       |
| QPS            | 41,852.92                  | 38,289.23      |
| 평균 Latency     | 7.64 ms                    | 2.97 ms        |
| 최대 Latency     | –                          | 303.05 ms      |
| Ignored Errors | –                          | 320 (5.33/sec) |


```
tps가 기존보다 낮은데 latency는 더 빠름.
에러 차지 비율은, Ignored Errors / TPS = 0.395% 로 나옴.
TPC BENCHMARK™ C
Standard Specification
Revision 5.11 에서
2.4의 The New-Order Transaction 중, 
2.4.1.4 A fixed 1% of the New-Order transactions are chosen at random to simulate user data entry errors and
exercise the performance of rolling back update transactions. This must be implemented by generating a random
number rbk within [1 .. 100]. 라고 나오므로
TPC-C 스펙상 New Order가 전체의 45%니까
new order부분에서는 고의적인 롤백 1%가 나와야함.
정말 1%가 나왔을지 검증을 할 필요가 있어보임.
```

- error 조사
```sql
-- 일단 세부적으로 들어감.
sysbench tpcc.lua \
  --db-driver=mysql \
  --mysql-host=127.0.0.1 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=558agers1 \
  --mysql-db=bookstore \
  --threads=4 \
  --tables=1 \
  --scale=1 \
  --time=60 \
  --report-interval=10 \
  --db-ps-mode=disable \
  run
```

- analyze
```sql
[ 10s ] thds: 4 tps: 1286.43 qps: 36676.84 (r/w/o: 16733.46/17368.92/2574.45) lat (ms,95%): 0.00 err/s 6.20 reconn/s: 0.00
[ 20s ] thds: 4 tps: 1508.19 qps: 42653.31 (r/w/o: 19471.67/20165.26/3016.38) lat (ms,95%): 0.00 err/s 7.30 reconn/s: 0.00
[ 30s ] thds: 4 tps: 1242.19 qps: 35638.23 (r/w/o: 16255.63/16898.22/2484.37) lat (ms,95%): 0.00 err/s 5.70 reconn/s: 0.00
[ 40s ] thds: 4 tps: 1311.01 qps: 37686.44 (r/w/o: 17203.11/17861.31/2622.01) lat (ms,95%): 0.00 err/s 5.90 reconn/s: 0.00
[ 50s ] thds: 4 tps: 1331.37 qps: 38148.74 (r/w/o: 17393.03/18092.96/2662.75) lat (ms,95%): 0.00 err/s 5.00 reconn/s: 0.00
[ 60s ] thds: 4 tps: 1320.44 qps: 37624.26 (r/w/o: 17156.86/17826.93/2640.47) lat (ms,95%): 0.00 err/s 5.10 reconn/s: 0.00
SQL statistics:
    queries performed:
        read:                            1042226
        write:                           1082228
        other:                           160018
        total:                           2284472
    transactions:                        80003  (1333.25 per sec.)
    queries:                             2284472 (38070.67 per sec.)
    ignored errors:                      352    (5.87 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0059s
    total number of events:              80003

Latency (ms):
         min:                                    0.21
         avg:                                    3.00
         max:                                  336.24
         95th percentile:                        0.00
         sum:                               239959.37

Threads fairness:
    events (avg/stddev):           20000.7500/162.81
    execution time (avg/stddev):   59.9898/0.00
```

```sql
구간별 계산
TPC-C 스펙상 New Order가 전체의 45%라고 가정하면,
10s: err 6.20 / (1286.43 * 45%) = 6.20 / 578.9 = 1.07%
20s: err 7.30 / (1508.19 * 45%) = 7.30 / 678.7 = 1.08%
30s: err 5.70 / (1242.19 * 45%) = 5.70 / 558.9 = 1.02%
40s: err 5.90 / (1311.01 * 45%) = 5.90 / 589.9 = 1.00%
50s: err 5.00 / (1331.37 * 45%) = 5.00 / 599.1 = 0.83%
60s: err 5.10 / (1320.44 * 45%) = 5.10 / 594.2 = 0.86%
대략 1%에 근접함.
스레드 적은거랑 시간이 오차에 영향을 준 것이 한몫하는듯.
결론: 잘 돌아감.
```
