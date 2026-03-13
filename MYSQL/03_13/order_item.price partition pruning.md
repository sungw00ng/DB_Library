### 학습목표
```sql
order_item 테이블의 price 분포를 분석한 후,
range 파티셔닝(0~10000 / 10000~20000 / 20000+)을 적용하기.
이후 price 조건 쿼리에서 Partition Pruning이 발생하여
불필요한 파티션 접근을 제거하는 것을 확인하기.
```

- price 분포


- 파티셔닝
```sql
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
```
