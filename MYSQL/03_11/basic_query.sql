-- 회원 주문 조회
SELECT *
FROM orders
WHERE member_id = 1;

-- 책 검색
SELECT *
FROM book
WHERE title LIKE '%데이터%';

-- 베스트셀러
SELECT b.title, SUM(oi.quantity) AS 판매량
FROM order_item oi
JOIN book b ON oi.book_id = b.book_id
GROUP BY b.title
ORDER BY 판매량 DESC;






