- 기존 데이터 전부 삭제
```sql
-- DELETE보다 훨씬 빠름
-- AUTO_INCREMENT 초기화

-- fk 검사 off
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE order_item;
TRUNCATE TABLE orders;
TRUNCATE TABLE book;
TRUNCATE TABLE member;

-- fk 검사 on
SET FOREIGN_KEY_CHECKS = 1;
```

- 재귀 CTE로 대량 데이터 생성
```sql
-- member
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
INSERT INTO member (name,email,password,phone,created_at)
SELECT 
    CONCAT('회원', n),
    CONCAT('user', n, '@test.com'),
    '1234',
    CONCAT('010', LPAD(n,8,'0')),
    NOW()
FROM seq;

-- book
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
INSERT INTO book (title,author,price,stock,publisher)
SELECT
    CONCAT('책', n),
    CONCAT('저자', n),
    FLOOR(RAND()*30000)+10000,
    FLOOR(RAND()*100)+1,
    '출판사'
FROM seq;

-- orders
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
INSERT INTO orders (member_id,order_date,total_price)
SELECT
    FLOOR(RAND()*10000)+1,
    NOW(),
    FLOOR(RAND()*50000)+10000
FROM seq;

-- order_item
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
INSERT INTO order_item (order_id,book_id,quantity,price)
SELECT
    n,
    FLOOR(RAND()*10000)+1,
    FLOOR(RAND()*3)+1,
    FLOOR(RAND()*30000)+10000
FROM seq;

-- 확인 (기존 데이터 삭제 후 생성 전에 동일하게 아래 쿼리로 확인해보기)
SELECT COUNT(*) FROM member;
SELECT COUNT(*) FROM book;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_item;

```

