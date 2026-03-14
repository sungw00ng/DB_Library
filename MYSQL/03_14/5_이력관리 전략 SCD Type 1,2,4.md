- SCD Tyoe 1 : update로 덮어쓰기
```sql
-- 현재 가격 확인
SELECT book_id, title, price FROM book WHERE book_id = 1;

-- 가격 변경 (이전 가격 사라짐)
UPDATE book SET price = 99999 WHERE book_id = 1;

-- 변경 후 확인
SELECT book_id, title, price FROM book WHERE book_id = 1;

book_id|title|price|
-------+-----+-----+
      1|책1   |99999|
```

- SCD Type 2 : 변경될 때마다 새 행 추가

| 컬럼명            | 키 유형               | 설명                                     |
| -------------- | ------------------ | -------------------------------------- |
| **book_seq**   | Surrogate Key (PK) | 테이블의 기본키. 시스템에서 생성되는 고유 값 (이력 row 구분용) |
| **book_id**    | Natural Key        | 실제 비즈니스 키. 동일한 책의 이력을 연결하는 기준          |
| **is_current** | 상태 컬럼              | 현재 활성 레코드 여부 (1 = 최신, 0 = 만료)          |
| **valid_from** | 이력 시작일             | 해당 데이터가 유효해진 시작 시점                     |
| **valid_to**   | 이력 종료일             | 해당 데이터가 끝난 시점 (현재 데이터는 NULL)           |

```sql
-- 테이블 구조 변경
ALTER TABLE book MODIFY COLUMN book_id INT NOT NULL;
ALTER TABLE book DROP PRIMARY KEY;
ALTER TABLE book ADD COLUMN book_seq INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- 이력 컬럼 추가
ALTER TABLE book ADD COLUMN is_current TINYINT DEFAULT 1;
ALTER TABLE book ADD COLUMN valid_from DATETIME DEFAULT NOW();
ALTER TABLE book ADD COLUMN valid_to DATETIME DEFAULT NULL;

-- 기존 행 만료 처리
UPDATE book SET is_current = 0, valid_to = NOW() WHERE book_id = 1 AND is_current = 1;

-- 새 이력 처리 insert
INSERT INTO book (book_id, title, author, price, stock, publisher, is_current, valid_from)
SELECT book_id, title, author, 50000, stock, publisher, 1, NOW()
FROM book WHERE book_id = 1 AND is_current = 0
ORDER BY valid_to DESC LIMIT 1;

-- 확인
SELECT * FROM book WHERE book_id = 1;

book_seq|book_id|title|author|price|stock|publisher|is_current|valid_from         |valid_to           |
--------+-------+-----+------+-----+-----+---------+----------+-------------------+-------------------+
       1|      1|책1   |저자1   |99999|   55|         |         0|2026-03-14 15:32:52|2026-03-14 15:36:44|
   50002|      1|책1   |저자1   |50000|   55|         |         1|2026-03-14 15:53:32|                   |

/*
1. 기존 행 만료 처리
   is_current=0, valid_to=NOW()

2. 새 행 INSERT
   is_current=1, valid_to=NULL
*/
```

SCD Type 4 : 이력을 별도 테이블로 관리
```sql
-- book_history(이전 내역 저장 테이블)
CREATE TABLE book_history (
    history_seq INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT,
    title VARCHAR(200),
    author VARCHAR(100),
    price INT,
    stock INT,
    publisher VARCHAR(100),
    changed_at DATETIME DEFAULT NOW()
);

-- trg_book_history로 이전 내역 자동으로 book_history에 저장
create trigger trg_book_history
before update on book
for each row
begin
	insert into book_history (book_id,title,author,price,stock,publisher)
	values (old.book_id,old.title,old.author,old.price,old.stock,old.publisher);
end;

-- 현재 값
SELECT * FROM book WHERE book_id = 1;

book_seq|book_id|title|author|price|stock|publisher|is_current|valid_from         |valid_to           |
--------+-------+-----+------+-----+-----+---------+----------+-------------------+-------------------+
       1|      1|책1   |저자1   |99999|   55|         |         0|2026-03-14 15:32:52|2026-03-14 15:36:44|
   50002|      1|책1   |저자1   |50000|   55|         |         1|2026-03-14 15:53:32|                   |

-- 가격 변경 테스트
UPDATE book SET price = 77777 WHERE book_id = 1 AND is_current = 1;

-- 이력 확인
SELECT * FROM book_history WHERE book_id = 1;

history_seq|book_id|title|author|price|stock|publisher|changed_at         |
-----------+-------+-----+------+-----+-----+---------+-------------------+
          1|      1|책1   |저자1   |50000|   55|         |2026-03-14 16:15:23|
```

