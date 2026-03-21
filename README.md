## DB_Library
```sql
TABLE_NAME            |TABLE_ROWS|
----------------------+----------+
blacklist             |         1|
book                  |     49890|
book_history          |     99827|
book_like             |         0|
book_sales_stat       |     48229|
category              |        37|
customer1             |     29232|
district1             |        10|
history1              |    167135|
item1                 |     99571|
member                |     99047|
member_uuid           |     99365|
new_orders1           |      7840|
order_item            |   9958815|
order_item_partitioned|   9962966|
order_line1           |   1824905|
orders                |    200096|
orders1               |    165207|
orders_materialized   |    199545|
point_history         |         2|
stock1                |     97848|
tenant                |         3|
warehouse1            |         1|
```

## 요약
1. 데이터 생성 (대용량 데이터 세팅)
2. 인덱스 튜닝 (단일/복합/커버링)
3. 파티셔닝 + 파티션 프루닝
4. 반정규화 vs Materialized View
5. 자동화 트리거 (INSERT/UPDATE/DELETE)
6. DB 설계 <br>
  - 6-1. PK 설계 <br>
  - 6-2. DB 설계 <br>
  - 6-3. 자기참조 <br>
  - 6-4. 슈퍼타입/서브타입
  - 6-5. SOFT DELETE <br>
  - 6-6. 블랙리스트 <br>
  - 6-7. SCD Type 1/2/4 <br>
  - 6-8. 동시성 제어 <br>
  - 6-9. 멀티 테넌시 <br>
7. 테이블 설계 실습 <br>
  - 7-1. CH1_e-commerce 주문 시스템 재설계 <br>
  - 7-2. CH2_상품 좋아요 & Denormalized Counter <br>
  - 7-3. CH3_상품판매통계 book_sales_stat <br>
  - 7-4. CH4_사용자포인트변동내역 <br>
8. sysbench 부하테스트 <br>
  - 8-1. sysbench 
  ```
  oltp_read_write, oltp_read_only
  k_1~k_10 index(o,x)
  ```

  - 8-2. sysbench-tpcc (Percona) <br>
  ```  
  실제 TPC-C 워크로드 시뮬레이션 O
  주문/결제 같은 실제 e-commerce 시나리오 O 
  ```
