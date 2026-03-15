- 비정규 카운터 like_count와 book_like
```sql
-- 빠른 조회용 카운터
alter table book add column like_count int default 0;

-- 중복 방지, 누가 눌렀는지 추적
create table book_like (
	like_id int auto_increment primary key,
	member_id int,
	book_id int,
	created_at datetime,
	unique key unique_like (member_id, book_id) -- 같은 회원이 같은 책에 좋아요 중복 못 하게 막아야함
);
```

- 좋아요 자동화 트리거도 달기
```sql
-- 좋아요 추가 트리거(trg_book_like_count)
create trigger trg_book_like_count
after insert on book_like
for each row
begin
	update book set like_count=like_count+1
	where book_id=new.book_id and is_current=1;
end;

-- 좋아요 취소 트리거(trg_book_like_delete)
create trigger trg_book_like_delete
after delete on book_like
for each row
begin
	update book set like_count=like_count-1
	where book_id=old.book_id and is_current=1;
end;
```

- test
```sql
insert into book_like (member_id,book_id) values (1,1);
insert into book_like (member_id,book_id) values (2,1);
insert into book_like (member_id,book_id) values (3,1);
delete from book_like where member_id=1 and book_id=1;

select book_id,like_count from book where book_id=1 and is_current=1;

book_id|like_count|
-------+----------+
      1|         2|

```


