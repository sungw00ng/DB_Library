- test sql
```sql
EXPLAIN
SELECT m.name AS 회원, b.title AS 책, oi.quantity AS 수량, oi.price AS 가격
FROM orders o
JOIN member m ON o.member_id = m.member_id
JOIN order_item oi ON o.order_id = oi.order_id
JOIN book b ON oi.book_id = b.book_id;
```

- 실행계획 (Program: Dbeaver, insert 10개)
```
-> Nested loop inner join  (cost=11.8 rows=10)
    -> Nested loop inner join  (cost=8.25 rows=10)
        -> Nested loop inner join  (cost=4.75 rows=10)
            -> Filter: (o.member_id is not null)  (cost=1.25 rows=10)
                -> Covering index scan on o using member_id  (cost=1.25 rows=10)
            -> Single-row index lookup on m using PRIMARY (member_id = o.member_id)  (cost=0.26 rows=1)
        -> Filter: (oi.book_id is not null)  (cost=0.26 rows=1)
            -> Index lookup on oi using order_id (order_id = o.order_id)  (cost=0.26 rows=1)
    -> Single-row index lookup on b using PRIMARY (book_id = oi.book_id)  (cost=0.26 rows=1)
```

- 분석
```
insert 10개라서 nl 조인인건 당연하다고 봄.
orders -> member -> order_item -> book 흐름임.
Covering index scan on o using member_id -> orders 테이블에서 member_id 인덱스를 사용
Single-row index lookup on m using PRIMARY -> member PK(member_id) 인덱스 사용
Index lookup on oi using order_id -> order_item.order_id 인덱스 사용
Single-row index lookup on b using PRIMARY -> book.book_id PK 인덱스 사용
```

