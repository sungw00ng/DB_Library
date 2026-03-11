- 기존 데이터 전부 삭제
```sql
-- DELETE보다 훨씬 빠름
-- AUTO_INCREMENT 초기화

SET FOREIGN_KEY_CHECKS = 0;  -- 1. FK 검사 off

TRUNCATE TABLE order_item;   -- 2. 자식 테이블 먼저
TRUNCATE TABLE orders;
TRUNCATE TABLE book;
TRUNCATE TABLE member;       -- 3. 부모 테이블 나중에

SET FOREIGN_KEY_CHECKS = 1;  -- 4. FK 검사 on
```

- 재귀 CTE로 대량 데이터 생성
```sql
-- 재귀 제한 방지
SET SESSION cte_max_recursion_depth = 10000;

-- member
INSERT INTO member (name,email,password,phone,created_at)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT 
    CONCAT('회원', n),
    CONCAT('user', n, '@test.com'),
    '1234',
    CONCAT('010', LPAD(n,8,'0')),
    NOW()
FROM seq;

-- book
INSERT INTO book (title,author,price,stock,publisher)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    CONCAT('책', n),
    CONCAT('저자', n),
    FLOOR(RAND()*30000)+10000,
    FLOOR(RAND()*100)+1,
    '출판사'
FROM seq;

-- orders
INSERT INTO orders (member_id,order_date,total_price)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    FLOOR(RAND()*10000)+1,
    NOW(),
    FLOOR(RAND()*50000)+10000
FROM seq;

-- order_item
INSERT INTO order_item (order_id,book_id,quantity,price)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 10000
)
SELECT
    n,
    FLOOR(RAND()*10000)+1,
    FLOOR(RAND()*3)+1,
    FLOOR(RAND()*30000)+10000
FROM seq;

-- 확인 
SELECT 
(SELECT COUNT(*) FROM member) AS member_count,
(SELECT COUNT(*) FROM book) AS book_count,
(SELECT COUNT(*) FROM orders) AS orders_count,
(SELECT COUNT(*) FROM order_item) AS order_item_count;

```

