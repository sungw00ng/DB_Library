```
materialized view를 공부하다가 문득 반정규화, 커버링 인덱스, 캐시 등이 떠올랐다.
공통점을 검색해보니까 조회 시점에 계산하지 말고 미리 준비해둔다는 것이었다.
인덱스랑 캐시는 뭐 그렇다치고...
materialized view, 반정규화 중점으로 분석해봄.
```

- 대상 쿼리
```sql
explain analyze
SELECT m.name, o.order_id, SUM(oi.price * oi.quantity) as total
FROM orders o
JOIN member m ON o.member_id = m.member_id
JOIN order_item oi ON o.order_id = oi.order_id
GROUP BY m.name, o.order_id;

-- 기존 연산
-> Table scan on <temporary>  (actual time=84263..84291 rows=200000 loops=1)
    -> Aggregate using temporary table  (actual time=84263..84263 rows=199999 loops=1)
        -> Nested loop inner join  (cost=7.8e+6 rows=9.72e+6) (actual time=4.82..26134 rows=10e+6 loops=1)
            -> Nested loop inner join  (cost=4.4e+6 rows=9.72e+6) (actual time=4.8..14802 rows=10e+6 loops=1)
                -> Filter: (oi.order_id is not null)  (cost=995305 rows=9.72e+6) (actual time=4.76..2194 rows=10e+6 loops=1)
                    -> Table scan on oi  (cost=995305 rows=9.72e+6) (actual time=4.75..1822 rows=10e+6 loops=1)
                -> Filter: (o.member_id is not null)  (cost=0.25 rows=1) (actual time=0.00111..0.00116 rows=1 loops=10e+6)
                    -> Single-row index lookup on o using PRIMARY (order_id = oi.order_id)  (cost=0.25 rows=1) (actual time=0.00104..0.00106 rows=1 loops=10e+6)
            -> Single-row index lookup on m using PRIMARY (member_id = o.member_id)  (cost=0.25 rows=1) (actual time=0.00102..0.00104 rows=1 loops=10e+6)

-- 1분 20초 정도 걸림
-- 실무였으면 난리가 났을 상황..
```

- materialized view
```sql
CREATE TABLE orders_materialized AS
SELECT 
    o.order_id,
    m.name,
    SUM(oi.price * oi.quantity) as total_price
FROM orders o
JOIN member m ON o.member_id = m.member_id
JOIN order_item oi ON o.order_id = oi.order_id
GROUP BY o.order_id, m.name;
```

- 결과 
```sql
-- 조인이랑 group by없이 바로 가져올 수 있음.
explain analyze
select name, order_id, total_price 
from orders_materialized;

-> Table scan on orders_materialized  (cost=20155 rows=199545) (actual time=0.0458..74 rows=200000 loops=1)


-- 매우 빠름.(0.0458~74ms)
```

- 반정규화
```sql
-- 1000만개 다 수정하려니 2분 3초 걸림.
alter table order_item add column member_name varchar(100);
update order_item oi
join orders o on oi.order_id=o.order_id
join member m on o.member_id=m.member_id
set oi.member_name=m.name;

explain analyze
select member_name, order_id, sum(price*quantity) as total
from order_item
group by member_name, order_id;

-> Table scan on <temporary>  (actual time=62905..62933 rows=200000 loops=1)
    -> Aggregate using temporary table  (actual time=62905..62905 rows=199999 loops=1)
        -> Table scan on order_item  (cost=1.07e+6 rows=10.1e+6) (actual time=1.38..7570 rows=10e+6 loops=1)

```

- 비교
| 구분                | 방식                           | 실행시간      | 개선율        |
| ----------------- | ---------------------------- | --------- | ---------- |
| 정규화 (order_item)          | 3개 테이블 JOIN + GROUP BY       | 84,263 ms | -          |
| 반정규화 (order_item 수정)             | `member_name` 컬럼 추가, JOIN 제거 | 62,933 ms | 약 25% 감소   |
| Materialized View (orders_materialized)| 집계 결과 별도 테이블 저장              | 76 ms     | 약 99.9% 감소 |

- 결론
```
기준 쿼리를
SELECT m.name, o.order_id, SUM(oi.price * oi.quantity) as total
FROM orders o
JOIN member m ON o.member_id = m.member_id
JOIN order_item oi ON o.order_id = oi.order_id
GROUP BY m.name, o.order_id;
이렇게 두다보니 집계에서 결국 시간이 좀 많이 쓰였음.
만약에 Join하는 테이블이 많았다면 반정규화도 고려해볼만한듯.
반정규화 테이블 생성하는데 2분 3초 걸렸는데 1000만개 수정해서 그런 것 같음.
Update발생하면 변경분만 바꾸는식으로 조금씩 바꾸는 식으로 반정규화는 사용될 것 같음.
materialized view는 테이블 재생성, 반정규화는 컬럼 업데이트 식으로 정리 완.
```
