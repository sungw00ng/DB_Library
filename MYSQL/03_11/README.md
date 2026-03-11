## 오늘 작업 요약
1. 데이터 준비
- member, book, orders, order_item 테이블에 각 10,000건 데이터 생성

<br>

2. 실행계획 분석
- EXPLAIN ANALYZE로 조인 쿼리 성능 확인
- 초기 실행계획에서 order_item Table Scan 발생

<br>

3. 인덱스 생성
- JOIN / WHERE 기준으로 인덱스 추가
```sql
CREATE INDEX idx_orders_member ON orders(member_id);
CREATE INDEX idx_orderitem_order ON order_item(order_id);
CREATE INDEX idx_orderitem_book ON order_item(book_id);
```

<br>

4. 복합 인덱스 실험
```sql
CREATE INDEX idx_orderitem_order_book
ON order_item(order_id, book_id);
```
- order_id + book_id 조건 최적화 테스트

<br>

5. 실행계획 재분석
- 옵티마이저가 복합 인덱스 대신 단일 인덱스(order_id) 선택
- order_id 조건 결과가 1 row라서 단일 인덱스로도 충분히 빠름

<br>

6. 불필요 인덱스 제거
```sql
DROP INDEX idx_orderitem_order_book ON order_item;
```

<br>

7. 최종 인덱스 구조
```
orders
  idx_orders_member (member_id)

order_item
  idx_orderitem_order (order_id)
  idx_orderitem_book  (book_id)
```

<br>
