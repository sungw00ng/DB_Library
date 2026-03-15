### CH1. e-commerce 주문 시스템 재설계
- 현 구조
```
TABLE_NAME            |COLUMN_NAME  |
----------------------+-------------+
blacklist             |blacklist_id |
blacklist             |email        |
blacklist             |reason       |
blacklist             |created_at   |
book                  |valid_to     |
book                  |book_id      |
book                  |title        |
book                  |author       |
book                  |price        |
book                  |stock        |
book                  |publisher    |
book                  |is_current   |
book                  |valid_from   |
book                  |book_seq     |
book                  |version      |
book                  |tenant_id    |
book_history          |history_seq  |
book_history          |book_id      |
book_history          |title        |
book_history          |author       |
book_history          |price        |
book_history          |stock        |
book_history          |publisher    |
book_history          |changed_at   |
category              |category_id  |
category              |name         |
category              |parent_id    |
member                |store_name   |
member                |name         |
member                |email        |
member                |password     |
member                |phone        |
member                |created_at   |
member                |member_type  |
member                |member_id    |
member                |level        |
member                |point        |
member                |is_deleted   |
member                |deleted_at   |
member                |tenant_id    |
member_uuid           |member_id    |
member_uuid           |name         |
member_uuid           |email        |
member_uuid           |password     |
member_uuid           |phone        |
member_uuid           |created_at   |
order_item            |book_id      |
order_item            |order_id     |
order_item            |order_item_id|
order_item            |quantity     |
order_item            |price        |
order_item            |tenant_id    |
order_item_partitioned|order_item_id|
order_item_partitioned|order_id     |
order_item_partitioned|book_id      |
order_item_partitioned|quantity     |
order_item_partitioned|price        |
orders                |order_id     |
orders                |member_id    |
orders                |order_date   |
orders                |total_price  |
orders                |tenant_id    |
orders_materialized   |order_id     |
orders_materialized   |name         |
orders_materialized   |total_price  |
tenant                |tenant_id    |
tenant                |name         |
tenant                |created_at   |
```

- 현재 문제점 개선
```sql
-- orders 테이블
/*
배송 정보 없음 (주소, 배송상태)
주문 상태 없음 (주문완료, 결제완료, 배송중, 배송완료, 취소)
결제 정보 없음
*/
-- orders 개선
alter table 
	orders add column status 
	enum('주문완료','결제완료','배송중','배송완료','취소') default '주문완료';
alter table orders add column address varchar(255);
alter table orders add column payment_method 
	enum('카드','계좌이체','무통장입금') default '카드';
alter table orders add column paid_at datetime;

-- order_item 테이블
/*
주문 당시 book 정보 스냅샷 저장(book 가격이 나중에 바뀌어도 주문 당시 가격/제목 추적 가능)
*/
-- order_item 개선
ALTER TABLE order_item ADD COLUMN book_title VARCHAR(200);
ALTER TABLE order_item ADD COLUMN book_author VARCHAR(100);

-- book 테이블
/*
category 연결 없음
이미지 없음
*/
-- book 개선
alter table book add column category_id int;
alter table book add foreign key (category_id) references category(category_id);
/*
1. update book set category_id=(book_id%42)+1 where is_current=1; --> 33~37 category_id가 없어서 FK 에러
2. join (select category_id from category order by rand()) --> 다 문학으로만 나옴
3. ELT(CEIL(RAND() * 37), 1,2,3...38,39,40,41,42) --> 이건됨.
*/ 
UPDATE book b
SET b.category_id = ELT(CEIL(RAND() * 37),
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
    21,22,23,24,25,26,27,28,29,30,31,32,38,39,40,41,42)
WHERE is_current = 1;


-- member 테이블
/*
배송지 주소 없음
*/
member에 따로 안 넣어도 될듯.
orders.address에 주문 당시 배송지 스냅샷으로 사용.

```

-- 바꾼 상태
```
TABLE_NAME            |COLUMN_NAME   |
----------------------+--------------+
blacklist             |blacklist_id  |
blacklist             |email         |
blacklist             |reason        |
blacklist             |created_at    |
book                  |version       |
book                  |book_id       |
book                  |title         |
book                  |author        |
book                  |price         |
book                  |stock         |
book                  |publisher     |
book                  |is_current    |
book                  |valid_from    |
book                  |valid_to      |
book                  |book_seq      |
book                  |tenant_id     |
book                  |category_id   |
book_history          |history_seq   |
book_history          |book_id       |
book_history          |title         |
book_history          |author        |
book_history          |price         |
book_history          |stock         |
book_history          |publisher     |
book_history          |changed_at    |
category              |category_id   |
category              |name          |
category              |parent_id     |
member                |point         |
member                |name          |
member                |email         |
member                |password      |
member                |phone         |
member                |created_at    |
member                |member_type   |
member                |store_name    |
member                |level         |
member                |member_id     |
member                |is_deleted    |
member                |deleted_at    |
member                |tenant_id     |
member_uuid           |member_id     |
member_uuid           |name          |
member_uuid           |email         |
member_uuid           |password      |
member_uuid           |phone         |
member_uuid           |created_at    |
order_item            |tenant_id     |
order_item            |order_id      |
order_item            |book_id       |
order_item            |quantity      |
order_item            |price         |
order_item            |order_item_id |
order_item            |book_title    |
order_item            |book_author   |
order_item_partitioned|order_item_id |
order_item_partitioned|order_id      |
order_item_partitioned|book_id       |
order_item_partitioned|quantity      |
order_item_partitioned|price         |
orders                |member_id     |
orders                |order_id      |
orders                |order_date    |
orders                |total_price   |
orders                |tenant_id     |
orders                |status        |
orders                |address       |
orders                |payment_method|
orders                |paid_at       |
orders_materialized   |order_id      |
orders_materialized   |name          |
orders_materialized   |total_price   |
tenant                |tenant_id     |
tenant                |name          |
tenant                |created_at    |
```
