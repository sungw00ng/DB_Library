- DB 분리(tenant마다 별도 DB), 스키마 분리(tenant마다 별도 schema), 테이블 공유 방식 등이 있음.
- 테이블 공유 방식으로, tenant_id 컬럼으로 구분하는 것을 목표로.
```sql
-- 지금 bookstore가 단일 쇼핑몰인데, 여러 쇼핑몰이 같은 DB를 쓰는 구조로 바꾸기
ALTER TABLE member ADD COLUMN tenant_id INT NOT NULL DEFAULT 1;
ALTER TABLE orders ADD COLUMN tenant_id INT NOT NULL DEFAULT 1;
ALTER TABLE book ADD COLUMN tenant_id INT NOT NULL DEFAULT 1;
ALTER TABLE order_item ADD COLUMN tenant_id INT NOT NULL DEFAULT 1;

-- 어떤 쇼핑몰들이 이 플랫폼을 쓰고 있는지 관리하는 테이블
CREATE TABLE tenant (
    tenant_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    created_at DATETIME DEFAULT NOW()
);

-- 현황
bookstore 
├── 쇼핑몰A (tenant_id=1)
├── 쇼핑몰B (tenant_id=2)
└── 쇼핑몰C (tenant_id=3)

INSERT INTO tenant (name) VALUES ('쇼핑몰A'), ('쇼핑몰B'), ('쇼핑몰C');


-- 쇼핑몰A 회원만 조회
SELECT tenant_id, COUNT(*) as cnt
FROM member
GROUP BY tenant_id;

tenant_id|cnt  |
---------+-----+
        2|33334|
        3|33333|
        1|33333|

```

