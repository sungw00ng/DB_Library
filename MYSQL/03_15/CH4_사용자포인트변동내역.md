- table : point_history 
```sql
create table point_history (
	history_id int auto_increment primary key,
	member_id int,
	point_change int,
	reason varchar(255),
	created_at datetime default now(),
	foreign key (member_id) references member(member_id)
);
```

- trigger : trg_point_history
```sql
create trigger trg_point_history
after update on member
for each row
begin
	if old.point != new.point then
		insert into point_history (member_id, point_change, reason)
		values (new.member_id, new.point - old.point, '포인트 변동');
	end if;
end;
```

- test
```
-- 포인트 추가
update member set point = point+1000 where member_id=1;

-- 포인트 차감
update member set point = point-500 where member_id=1;

-- 이력 확인
select * from point_history where member_id=1;

history_id|member_id|point_change|reason|created_at         |
----------+---------+------------+------+-------------------+
         1|        1|        1000|포인트 변동|2026-03-15 18:46:02|
         2|        1|        -500|포인트 변동|2026-03-15 18:46:03|
```
