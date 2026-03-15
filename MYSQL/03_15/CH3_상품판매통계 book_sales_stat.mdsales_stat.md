- book_sales_stat
```sql
create table book_sales_stat (
	stat_id int auto_increment primary key,
	book_id int,
	stat_date date,
	total_quantity int default 0,
	total_price int default 0,
	order_count int default 0
);


insert into book_sales_stat 
	(book_id, stat_date, total_quantity, total_price, order_count)
select 
	oi.book_id,
	date(o.order_date) as stat_date,
	sum(oi.quantity) as total_quantity,
	sum(oi.price * oi.quantity) as total_price,
	count(*) as order_count
from order_item oi
join orders o on oi.order_id=o.order_id
group by oi.book_id, date(o.order_date);

-- book_id=1 판매 조회
select * from book_sales_stat where book_id = 1 order by stat_date;

stat_id|book_id|stat_date |total_quantity|total_price|order_count|
-------+-------+----------+--------------+-----------+-----------+
  25139|      1|2026-03-13|           631|    9563864|        216|

-- 전체 판매 TOP 10
select book_id, sum(total_quantity) as total_qty
from book_sales_stat
group by book_id
order by total_qty desc
limit 10;

book_id|total_qty|
-------+---------+
  31191|      970|
   5831|      968|
  48283|      949|
  24214|      936|
   3902|      935|
   1736|      934|
  47930|      933|
  41213|      926|
   3600|      923|
   5291|      923|
```



