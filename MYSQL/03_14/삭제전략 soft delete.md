- soft delete
```sql
ALTER TABLE member ADD COLUMN is_deleted TINYINT DEFAULT 0;
ALTER TABLE member ADD COLUMN deleted_at DATETIME DEFAULT NULL;

-- soft delete
UPDATE member SET is_deleted = 1, deleted_at = NOW() WHERE member_id = 1;

-- 삭제 안된 회원만 조회
SELECT * FROM member WHERE is_deleted = 0 LIMIT 5;

member_id|name|email         |password|phone      |created_at         |member_type|store_name|level|point|is_deleted|deleted_at|
---------+----+--------------+--------+-----------+-------------------+-----------+----------+-----+-----+----------+----------+
        2|회원2 |user2@test.com|1234    |01000000002|2026-03-13 16:20:32|regular    |          |     |    0|         0|          |
        3|회원3 |user3@test.com|1234    |01000000003|2026-03-13 16:20:32|regular    |          |     |    0|         0|          |
        4|회원4 |user4@test.com|1234    |01000000004|2026-03-13 16:20:32|regular    |          |     |    0|         0|          |
        5|회원5 |user5@test.com|1234    |01000000005|2026-03-13 16:20:32|seller     |          |     |    0|         0|          |
        6|회원6 |user6@test.com|1234    |01000000006|2026-03-13 16:20:32|regular    |          |     |    0|         0|          |

-- 삭제된 회원 조회(물리적으로 지우진 x)
SELECT * FROM member WHERE is_deleted = 1 LIMIT 5;

member_id|name|email         |password|phone      |created_at         |member_type|store_name|level|point|is_deleted|deleted_at         |
---------+----+--------------+--------+-----------+-------------------+-----------+----------+-----+-----+----------+-------------------+
        1|회원1 |user1@test.com|1234    |01000000001|2026-03-13 16:20:32|regular    |          |     |    0|         1|2026-03-14 15:15:19|

- member_id=1이 is_deleted=1, deleted_at=2026-03-14 15:15:19 로 표시되고 실제 데이터는 살아있음.
```



