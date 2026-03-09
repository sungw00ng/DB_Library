-- member 10명
INSERT INTO member (name,email,password,phone,created_at) VALUES
('김철수','kim1@test.com','1234','01011110001',NOW()),
('이영희','lee2@test.com','1234','01011110002',NOW()),
('박민수','park3@test.com','1234','01011110003',NOW()),
('최지훈','choi4@test.com','1234','01011110004',NOW()),
('정다은','jung5@test.com','1234','01011110005',NOW()),
('한승우','han6@test.com','1234','01011110006',NOW()),
('강다현','kang7@test.com','1234','01011110007',NOW()),
('오세진','oh8@test.com','1234','01011110008',NOW()),
('윤서현','yoon9@test.com','1234','01011110009',NOW()),
('송지우','song10@test.com','1234','01011110010',NOW());
-- 책 10권
INSERT INTO book (title,author,price,stock,publisher) VALUES
('데이터베이스 입문','홍길동',25000,10,'한빛출판사'),
('SQL 완전정복','김영희',30000,8,'길벗'),
('자바 프로그래밍','박철수',28000,15,'한빛출판사'),
('파이썬 입문','이민수',27000,12,'영진닷컴'),
('웹 개발 기초','최지훈',22000,20,'길벗'),
('알고리즘 문제풀이','정다은',32000,5,'한빛미디어'),
('머신러닝 입문','한승우',35000,7,'에이콘출판사'),
('리액트 실전','강다현',30000,10,'길벗'),
('Node.js 프로그래밍','오세진',28000,9,'한빛미디어'),
('데이터 분석','윤서현',27000,11,'영진닷컴');
-- 주문 10개 (회원 1~10번이 각각 1개 주문)
INSERT INTO orders (member_id,order_date,total_price) VALUES
(1,NOW(),25000),
(2,NOW(),30000),
(3,NOW(),28000),
(4,NOW(),27000),
(5,NOW(),22000),
(6,NOW(),32000),
(7,NOW(),35000),
(8,NOW(),30000),
(9,NOW(),28000),
(10,NOW(),27000);
-- 주문 상세 10개 (각 주문마다 1권 책)
INSERT INTO order_item (order_id,book_id,quantity,price) VALUES
(1,1,1,25000),
(2,2,1,30000),
(3,3,1,28000),
(4,4,1,27000),
(5,5,1,22000),
(6,6,1,32000),
(7,7,1,35000),
(8,8,1,30000),
(9,9,1,28000),
(10,10,1,27000);
-- 확인용 JOIN 쿼리
SELECT m.name AS 회원, b.title AS 책, oi.quantity AS 수량, oi.price AS 가격
FROM orders o
JOIN member m ON o.member_id = m.member_id
JOIN order_item oi ON o.order_id = oi.order_id
JOIN book b ON oi.book_id = b.book_id;
