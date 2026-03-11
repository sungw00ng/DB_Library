- 재귀 CTE로 생성한 10000개 데이터에 관한 실행계획
```sql
EXPLAIN ANALYZE
SELECT m.name, b.title, oi.quantity, oi.price
FROM orders o
JOIN member m ON o.member_id = m.member_id
JOIN order_item oi ON o.order_id = oi.order_id
JOIN book b ON oi.book_id = b.book_id;
```

```sql
-> Nested loop inner join  (cost=11316 rows=9834) (actual time=0.293..61.7 rows=10000 loops=1)
    -> Nested loop inner join  (cost=7874 rows=9834) (actual time=0.286..42.3 rows=10000 loops=1)
        -> Nested loop inner join  (cost=4432 rows=9834) (actual time=0.279..23.2 rows=10000 loops=1)
            -> Filter: ((oi.order_id is not null) and (oi.book_id is not null))  (cost=990 rows=9834) (actual time=0.263..4.32 rows=10000 loops=1)
                -> Table scan on oi  (cost=990 rows=9834) (actual time=0.262..3.32 rows=10000 loops=1)
            -> Filter: (o.member_id is not null)  (cost=0.25 rows=1) (actual time=0.00158..0.00169 rows=1 loops=10000)
                -> Single-row index lookup on o using PRIMARY (order_id = oi.order_id)  (cost=0.25 rows=1) (actual time=0.00143..0.00147 rows=1 loops=10000)
        -> Single-row index lookup on b using PRIMARY (book_id = oi.book_id)  (cost=0.25 rows=1) (actual time=0.00169..0.00172 rows=1 loops=10000)
    -> Single-row index lookup on m using PRIMARY (member_id = o.member_id)  (cost=0.25 rows=1) (actual time=0.00172..0.00176 rows=1 loops=10000)
```

- 분석
```
oi=10000 rows, o=PK index, b=PK index, m=PK index인 상황에서
옵티마이저는 Table scan, index lookup, index lookup, index lookup 임.
```

- 튜닝 포인트
```
- Table scan on oi 했으니 지금 실행계획에서 가장 문제인 부분임.
```
```sql
-- 일단 3개를 추가
CREATE INDEX idx_orders_member
ON orders(member_id);

CREATE INDEX idx_orderitem_order
ON order_item(order_id);

CREATE INDEX idx_orderitem_book
ON order_item(book_id);
```

- 인덱스 확인
```sql
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'bookstore'
ORDER BY TABLE_NAME, INDEX_NAME;

-- index 결과
TABLE_NAME|INDEX_NAME         |COLUMN_NAME  |NON_UNIQUE|
----------+-------------------+-------------+----------+
book      |PRIMARY            |book_id      |         0|
member    |PRIMARY            |member_id    |         0|
order_item|idx_orderitem_book |book_id      |         1|
order_item|idx_orderitem_order|order_id     |         1|
order_item|PRIMARY            |order_item_id|         0|
orders    |idx_orders_member  |member_id    |         1|
orders    |PRIMARY            |order_id     |         0|
```

- 다시 실행시켜보기(select *)
```
-- 이 정도 차이는 캐시,디스크,CPU 스케줄링 차이로 충분히 발생가능하며 유의미하지 않음. 
-- 여전히 Table scan on oi 발생 중, 테이블 스캔이 더 싸다라고 판단한듯.
-> Nested loop inner join  (cost=11316 rows=9834) (actual time=0.523..57.4 rows=10000 loops=1)
    -> Nested loop inner join  (cost=7874 rows=9834) (actual time=0.486..41.2 rows=10000 loops=1)
        -> Nested loop inner join  (cost=4432 rows=9834) (actual time=0.453..25 rows=10000 loops=1)
            -> Filter: ((oi.order_id is not null) and (oi.book_id is not null))  (cost=990 rows=9834) (actual time=0.4..4.3 rows=10000 loops=1)
                -> Table scan on oi  (cost=990 rows=9834) (actual time=0.399..3.49 rows=10000 loops=1)
            -> Filter: (o.member_id is not null)  (cost=0.25 rows=1) (actual time=0.00183..0.00192 rows=1 loops=10000)
                -> Single-row index lookup on o using PRIMARY (order_id = oi.order_id)  (cost=0.25 rows=1) (actual time=0.00171..0.00174 rows=1 loops=10000)
        -> Single-row index lookup on b using PRIMARY (book_id = oi.book_id)  (cost=0.25 rows=1) (actual time=0.00144..0.00147 rows=1 loops=10000)
    -> Single-row index lookup on m using PRIMARY (member_id = o.member_id)  (cost=0.25 rows=1) (actual time=0.00144..0.00147 rows=1 loops=10000)
```

- 원인
```
1. WHERE 없음
2. 전체 조회
-> 어차피 전부 읽어야 하니까 table scan이 정상이라고 본듯.
```

- 유의미한 코드 작성
```sql
-- 회원 주문 조회
-- use : orders(member_id), order_item(order_id)
SELECT *
FROM orders o
JOIN order_item oi ON o.order_id = oi.order_id
WHERE o.member_id = 7777;

order_id|member_id|order_date         |total_price|order_item_id|order_id|book_id|quantity|price|
--------+---------+-------------------+-----------+-------------+--------+-------+--------+-----+
    8197|     7777|2026-03-11 16:17:07|      37685|         8197|    8197|   3136|       2|20644|

-> Nested loop inner join  (cost=0.7 rows=1) (actual time=0.0445..0.0467 rows=1 loops=1)
    -> Index lookup on o using idx_orders_member (member_id = 7777)  (cost=0.35 rows=1) (actual time=0.0303..0.0309 rows=1 loops=1)
    -> Index lookup on oi using idx_orderitem_order (order_id = o.order_id)  (cost=0.35 rows=1) (actual time=0.0129..0.0142 rows=1 loops=1)

-- 특정 책 주문 조회
-- use : order_item(book_id)
SELECT *
FROM order_item oi
JOIN orders o ON oi.order_id = o.order_id
WHERE oi.book_id = 1;

order_item_id|order_id|book_id|quantity|price|order_id|member_id|order_date         |total_price|
-------------+--------+-------+--------+-----+--------+---------+-------------------+-----------+
         3536|    3536|      1|       3|25283|    3536|      566|2026-03-11 16:17:07|      49241|
         5598|    5598|      1|       3|38331|    5598|     8765|2026-03-11 16:17:07|      39573|
         9360|    9360|      1|       1|24713|    9360|     9636|2026-03-11 16:17:07|      55404|

-> Nested loop inner join  (cost=2.1 rows=3) (actual time=2.1..2.23 rows=3 loops=1)
    -> Filter: (oi.order_id is not null)  (cost=1.05 rows=3) (actual time=1.67..1.79 rows=3 loops=1)
        -> Index lookup on oi using idx_orderitem_book (book_id = 1)  (cost=1.05 rows=3) (actual time=1.66..1.77 rows=3 loops=1)
    -> Single-row index lookup on o using PRIMARY (order_id = oi.order_id)  (cost=0.283 rows=1) (actual time=0.0771..0.0771 rows=1 loops=3)

-- 회원 + 특정 책
-- use : orders(member_id), order_item(order_id, book_id) //우측은 새로 하나 만들어야함.  
-- Leftmost Prefix Rule
SELECT *
FROM orders o
JOIN order_item oi ON o.order_id = oi.order_id
WHERE o.member_id = 4126
AND   oi.book_id = 8939;

order_id|member_id|order_date         |total_price|order_item_id|order_id|book_id|quantity|price|
--------+---------+-------------------+-----------+-------------+--------+-------+--------+-----+
       1|     4126|2026-03-11 16:17:07|      52569|            1|       1|   8939|       2|16214|

-- 단일일 때 orders(member_id) 
-> Nested loop inner join  (cost=0.7 rows=0.05) (actual time=0.537..0.544 rows=1 loops=1)
    -> Index lookup on o using idx_orders_member (member_id = 4126)  (cost=0.35 rows=1) (actual time=0.117..0.119 rows=1 loops=1)
    -> Filter: (oi.book_id = 8939)  (cost=0.255 rows=0.05) (actual time=0.0378..0.0423 rows=1 loops=1)
        -> Index lookup on oi using idx_orderitem_order (order_id = o.order_id)  (cost=0.255 rows=1) (actual time=0.0364..0.0407 rows=1 loops=1)

-- 단일 + 복합일 때 orders(member_id), order_item(order_id, book_id)
-> Nested loop inner join  (cost=0.7 rows=0.05) (actual time=0.227..0.231 rows=1 loops=1)
    -> Index lookup on o using idx_orders_member (member_id = 4126)  (cost=0.35 rows=1) (actual time=0.152..0.153 rows=1 loops=1)
    -> Filter: (oi.book_id = 8939)  (cost=0.255 rows=0.05) (actual time=0.0668..0.0688 rows=1 loops=1)
        -> Index lookup on oi using idx_orderitem_order (order_id = o.order_id)  (cost=0.255 rows=1) (actual time=0.065..0.0669 rows=1 loops=1)

```

- 바뀌어야 할 부분
```sql
-- 회원 + 특정 책일 때는 결과 같음. (복합인덱스를 쓰지 않았음.)
-- order_id 인덱스에서 row 1개가 나왔으니, 굳이 book_id 필터를 하였는데 비용이 거의 0이니 굳이 복합 인덱스 필요 없다고 판단한 듯 싶다.
-- 따라서 복합 인덱스를 지워야 한다.

DROP INDEX idx_orderitem_order_book ON order_item;

```

- 재확인 및 검토
```sql
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'bookstore'
ORDER BY TABLE_NAME, INDEX_NAME;

TABLE_NAME|INDEX_NAME         |COLUMN_NAME  |NON_UNIQUE|
----------+-------------------+-------------+----------+
book      |PRIMARY            |book_id      |         0|
member    |PRIMARY            |member_id    |         0|
order_item|idx_orderitem_book |book_id      |         1|
order_item|idx_orderitem_order|order_id     |         1|
order_item|PRIMARY            |order_item_id|         0|
orders    |idx_orders_member  |member_id    |         1|
orders    |PRIMARY            |order_id     |         0|
```

