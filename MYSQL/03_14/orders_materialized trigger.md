- trg_order_item_insert
```sql
-- order_item에 INSERT 완료 후 자동으로 orders_materialized 집계 결과 최신 상태로 자동
create trigger trg_order_item_insert
after insert on order_item
for each row
begin
	if exists (select 1 
			   from orders_materialized 
			   where order_id = new.order_id) then
		update orders_materialized
		set total_price=total_price+(new.price*new.quantity)
		where order_id=new.order_id;
	else
		insert into orders_materialized (order_id,name,total_price)
		select new.order_id, m.name, new.price * new.quantity
		from orders o
		join member m on o.member_id=m.member_id
		where o.order_id=new.order_id;
	end if;
end;
```

- insert test
```sql
SELECT * FROM orders_materialized WHERE order_id = 1;

order_id|name   |total_price|
--------+-------+-----------+
       1|회원36698|    1883725|

INSERT INTO order_item (order_id, book_id, quantity, price)
VALUES (1, 1, 2, 10000);

order_id|name   |total_price|
--------+-------+-----------+
       1|회원36698|    1903725|

-- total_price가 20000 오름(성공)
```

- trg_order_item_update
```sql
-- 기존 금액 빼고 새 금액 더하기
create trigger trg_order_item_update
after update on order_item
for each row
begin
    update orders_materialized
    set total_price=total_price
        -(old.price*old.quantity)
        +(new.price*new.quantity)
__    where order_id=new.order_id;__
end;
```

- update test
```sql
UPDATE order_item SET price = 99999 WHERE order_item_id = 1;
SELECT * FROM orders_materialized WHERE order_id = 40438;
-- total_price가 1522941 - 20000 + 99999 = 1602940(성공)
```

- trg_order_item_delete
```sql
-- 삭제된 금액만 빼기
create trigger trg_order_item_delete
after delete on order_item
for each row
begin
	update orders_materialized
	set total_price=total_price-(old.price*old.quantity)
	where order_id=old.order_id;
end;
```

- delete test
```
DELETE FROM order_item WHERE order_item_id = 1;
SELECT * FROM orders_materialized WHERE order_id = 40438;

order_id|name   |total_price|
--------+-------+-----------+
   40438|회원32268|    1502941|

1602940-99999=1502941(성공)
```
