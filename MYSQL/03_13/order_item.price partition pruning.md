### 학습목표
```sql
order_item 테이블의 price 분포를 분석한 후,
range 파티셔닝(0~10000 / 10000~20000 / 20000+)을 적용하기.
이후 price 조건 쿼리에서 Partition Pruning이 발생하여
불필요한 파티션 접근을 제거하는 것을 확인하기.
```

- price 분포
```sql
-- 1% 샘플링해서 .csv로 export 후 python colab환경에서 처리(DBeaver Pro 버전 아니라서 차트를 못씀)
SELECT price 
FROM order_item
WHERE order_item_id % 100 = 0;
```
<img width="800" height="400" src="https://github.com/user-attachments/assets/29475a8c-0de9-45fb-84da-e5177b80c867" />

<br>
<br>

- 파티셔닝
```sql
-- 파티션 테이블 생성
CREATE TABLE order_item_partitioned (
    order_item_id BIGINT,
    order_id BIGINT,
    book_id BIGINT,
    quantity INT,
    price INT
)
PARTITION BY RANGE(price) (
    PARTITION p_low VALUES LESS THAN (10000),
    PARTITION p_mid VALUES LESS THAN (20000),
    PARTITION p_high VALUES LESS THAN MAXVALUE
);

-- 옮기기
INSERT INTO order_item_partitioned
SELECT * FROM order_item;

-- 파티션 생성 확인
SELECT
PARTITION_NAME,
TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'order_item_partitioned';

-- 조회 결과
PARTITION_NAME|TABLE_ROWS|
--------------+----------+
p_high        |   2492451|
p_low         |   2488243|
p_middle      |   4983600|
```

- 문제점
```sql
-- p_high는 2492451인데, 옵티마이저는 rows=830834로 서로 다른 결과값이 나타남.
-- 옵티마이저가 전체 rows를 1000만이 아닌, p_high의 249만을 기준으로 대충 3분의 1이겠지? 계산해버림.
-- 파티션을 나눴어도 통계는 여전히 테이블 단위로만 관리하는 MySQL의 한계. (파티셔닝이 조회검색속도 향상 목적은 아니라서 그런듯)
EXPLAIN ANALYZE
SELECT *
FROM order_item_partitioned
WHERE price > 20000;

-> Filter: (order_item_partitioned.price > 20000)  (cost=258761 rows=830734) (actual time=1.37..752 rows=2.5e+6 loops=1)
    -> Table scan on order_item_partitioned  (cost=258761 rows=2.49e+6) (actual time=1.37..653 rows=2.5e+6 loops=1)

```

- mysql 옵티마이저의 한계
```
p_high 안에 뭐가 있는지는 모르고
그냥 price > 20000 이면 전체(여기서는 p_high가 전체인 상황)의 33% 라는 
테이블 전체 통계만 알고 있는 거
price>20000
price>21000
price>22000
price>23000 찍어도 결과 같아짐.(3분의 1)
>
```

- 결론
```
파티셔닝 후 파티션 프루닝은 잘됨. 그런데, 조회 함부로 찍지 말자.
이런 문제 상황에서는 인덱스 추가해도 더 이상해짐.
```
