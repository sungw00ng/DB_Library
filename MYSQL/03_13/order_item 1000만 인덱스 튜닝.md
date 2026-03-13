## DB규모(재귀 CTE)
```
member       100,000
book          50,000
orders       200,000
order_item 10,000,000 (DBeaver로 3분 15초 소요..) 
```

### 실험 계획
```sql
-- 아래 쿼리를 대상으로 인덱스 X, 복합, 커버링 순으로 성능 측정
SELECT *
FROM order_item
WHERE order_id = 50000
AND book_id = 1200
AND quantity >= 2;
 
-- 인덱스는 PK만 존재하게끔 설정
TABLE_NAME|INDEX_NAME|COLUMN_NAME  |SEQ_IN_INDEX|
----------+----------+-------------+------------+
book      |PRIMARY   |book_id      |           1|
member    |PRIMARY   |member_id    |           1|
order_item|PRIMARY   |order_item_id|           1|
orders    |PRIMARY   |order_id     |           1|
```

### 결과
| 구분          | 인덱스                                                 | 실행 시간     | 실행 방식                     | 조회 Rows    |
| ----------- | --------------------------------------------------- | --------- | ------------------------- | ---------- |
| **인덱스 없음**  | 없음                                                  | 1951 ms   | Table Scan                | 10,000,000 |
| **복합 인덱스**  | (order_id, book_id, quantity)                       | 0.0581 ms | Index Range Scan          | 1          |
| **커버링 인덱스** | (order_id, book_id, quantity, price) | 0.0341 ms | Covering Index Range Scan | 1          |
 

