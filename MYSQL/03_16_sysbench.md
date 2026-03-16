- purpose
```
1. 인덱스 효과 검증, 인덱스가 실제로 쿼리 성능을 개선하는지?
2. 워크로드별 영향 분석, oltp_read_write / oltp_read_only 환경에서 인덱스 영향이 어떻게 다른지?
```
- install sysbench(Mac)
```
brew install sysbench
```

 - test db prepare
```sql
-- 테스트 db prepare
sysbench oltp_read_write \
> --db-driver=mysql \
> --mysql-host=127.0.0.1 \
> --mysql-port=3306 \
> --mysql-user=root \
> --mysql-password=비밀번호 \
> --mysql-db=bookstore \
> --tables=10 \
> --table-size=100000 \
> prepare

-- 생성 중
sysbench 1.0.20 (using system LuaJIT 2.1.1727870382)

Creating table 'sbtest1'...
Inserting 100000 records into 'sbtest1'
Creating a secondary index on 'sbtest1'...
Creating table 'sbtest2'...
Inserting 100000 records into 'sbtest2'
Creating a secondary index on 'sbtest2'...
Creating table 'sbtest3'...
Inserting 100000 records into 'sbtest3'
Creating a secondary index on 'sbtest3'...
Creating table 'sbtest4'...
Inserting 100000 records into 'sbtest4'
Creating a secondary index on 'sbtest4'...
Creating table 'sbtest5'...
Inserting 100000 records into 'sbtest5'
Creating a secondary index on 'sbtest5'...
Creating table 'sbtest6'...
Inserting 100000 records into 'sbtest6'
Creating a secondary index on 'sbtest6'...
Creating table 'sbtest7'...
Inserting 100000 records into 'sbtest7'
Creating a secondary index on 'sbtest7'...
Creating table 'sbtest8'...
Inserting 100000 records into 'sbtest8'
Creating a secondary index on 'sbtest8'...
Creating table 'sbtest9'...
Inserting 100000 records into 'sbtest9'
Creating a secondary index on 'sbtest9'...
Creating table 'sbtest10'...
Inserting 100000 records into 'sbtest10'
Creating a secondary index on 'sbtest10'...
```

- run
```sql
-- read/write test
sysbench oltp_read_write \
> --db-driver=mysql \
> --mysql-host=127.0.0.1 \
> --mysql-port=3306 \
> --mysql-user=root \
> --mysql-password=비밀번호 \
> --mysql-db=bookstore \
> --tables=10 \
> --table-size=100000 \
> --threads=16 \
> --time=60 \
> run

-- 60초 기다려야함(테스트 중)
sysbench 1.0.20 (using system LuaJIT 2.1.1727870382)

Running the test with following options:
Number of threads: 16
Initializing random number generator from current time


Initializing worker threads...

Threads started!

```

- read_write_report
```sql
SQL statistics:
    queries performed:
        read:                            1758316
        write:                           502376
        other:                           251188
        total:                           2511880
    transactions:                        125594 (2092.65 per sec.)
    queries:                             2511880 (41852.92 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0165s
    total number of events:              125594

Latency (ms):
         min:                                    1.08
         avg:                                    7.64
         max:                                  394.62
         95th percentile:                        0.00
         sum:                               959954.38

Threads fairness:
    events (avg/stddev):           7849.6250/65.47
    execution time (avg/stddev):   59.9971/0.00
```

- 분석
```sql
| 지표         | 값         | 의미                    |
| ---------- | --------- | --------------------- |
| TPS        | 2092.65   | 초당 처리된 트랜잭션 수         |
| QPS        | 41852.92  | 초당 실행된 쿼리 수           |
| 평균 Latency | 7.64 ms   | 평균 응답 시간              |
| 최대 Latency | 394.62 ms | 최대 응답 시간              |
| 총 트랜잭션     | 125594    | 60초 동안 처리된 전체 트랜잭션 수 |

/*
TPS 2092는 로컬 환경치고 준수한 편
평균 7.64ms는 양호
최대 394ms는 순간 부하 스파이크
*/

```

- drop index
```
DROP INDEX k_1 ON sbtest1;
DROP INDEX k_2 ON sbtest2;
DROP INDEX k_3 ON sbtest3;
DROP INDEX k_4 ON sbtest4;
DROP INDEX k_5 ON sbtest5;
DROP INDEX k_6 ON sbtest6;
DROP INDEX k_7 ON sbtest7;
DROP INDEX k_8 ON sbtest8;
DROP INDEX k_9 ON sbtest9;
DROP INDEX k_10 ON sbtest10;
```

- read_write_report(index k_1~k_10 x)
```
SQL statistics:
    queries performed:
        read:                            2696190
        write:                           770340
        other:                           385170
        total:                           3851700
    transactions:                        192585 (3208.73 per sec.)
    queries:                             3851700 (64174.63 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0187s
    total number of events:              192585

Latency (ms):
         min:                                    1.02
         avg:                                    4.98
         max:                                  302.67
         95th percentile:                        0.00
         sum:                               959897.56

Threads fairness:
    events (avg/stddev):           12036.5625/82.69
    execution time (avg/stddev):   59.9936/0.00
```

- analyze(read/write)
```
| 지표            | 인덱스 있을 때  | 인덱스 없을 때  |
| ------------- | --------- | --------- |
| TPS (초당 트랜잭션) | 2,092.65  | 3,208.73  |
| QPS (초당 쿼리)   | 41,852.92 | 64,174.63 |
| 평균 Latency    | 7.64 ms   | 4.98 ms   |

sysbench oltp_read_write는 read뿐만 아니라 write도 많이 하는 테스트인데,
인덱스가 있으면 insert/update 시 인덱스도 같이 갱신해야 해서 오히려 write 성능이 떨어진 것으로 추측.
```

- run(read_only)
```sql
sysbench oltp_read_only \
  --db-driver=mysql \
  --mysql-host=127.0.0.1 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=비밀번호 \
  --mysql-db=bookstore \
  --tables=10 \
  --table-size=100000 \
  --threads=16 \
  --time=60 \
  run
```

- read-only_report (index k_1~k_10 x)
```sql
SQL statistics:
    queries performed:
        read:                            4493188
        write:                           0
        other:                           641884
        total:                           5135072
    transactions:                        320942 (5348.22 per sec.)
    queries:                             5135072 (85571.45 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0089s
    total number of events:              320942

Latency (ms):
         min:                                    0.74
         avg:                                    2.99
         max:                                  193.29
         95th percentile:                        0.00
         sum:                               959871.85

Threads fairness:
    events (avg/stddev):           20058.8750/227.09
    execution time (avg/stddev):   59.9920/0.00
```

- add index
```sql
CREATE INDEX k_1 ON sbtest1(k);
CREATE INDEX k_2 ON sbtest2(k);
CREATE INDEX k_3 ON sbtest3(k);
CREATE INDEX k_4 ON sbtest4(k);
CREATE INDEX k_5 ON sbtest5(k);
CREATE INDEX k_6 ON sbtest6(k);
CREATE INDEX k_7 ON sbtest7(k);
CREATE INDEX k_8 ON sbtest8(k);
CREATE INDEX k_9 ON sbtest9(k);
CREATE INDEX k_10 ON sbtest10(k);
```

-read_only_report
```
SQL statistics:
    queries performed:
        read:                            4227776
        write:                           0
        other:                           603968
        total:                           4831744
    transactions:                        301984 (5032.24 per sec.)
    queries:                             4831744 (80515.86 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          60.0096s
    total number of events:              301984

Latency (ms):
         min:                                    0.77
         avg:                                    3.18
         max:                                  164.52
         95th percentile:                        0.00
         sum:                               959852.83

Threads fairness:
    events (avg/stddev):           18874.0000/238.75
    execution time (avg/stddev):   59.9908/0.00
```

- analyze
```
| 워크로드 유형     | index k_1~k_10 (O)                 | X                 |
| ------------- |  ---------------------- | ---------------------- |
| read/write      | TPS 2,092 / QPS 41,852 | TPS 3,208 / QPS 64,174 |
| read_only       | TPS 5,032 / QPS 80,515 | TPS 5,348 / QPS 85,571 |

/*
어느 상황에서도 인덱스가 없는 편이 TPS, QPS가 더 높았다.
sysbench가 PK 기반 조회를 많이 해서 index overhead가 발생한 것 같다.
인덱스가 있을 때의 효과가 잘 안 보이는 한계가 있는듯.
*/
```
