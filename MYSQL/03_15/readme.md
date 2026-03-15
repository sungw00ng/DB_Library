| 실습                            | 구현 내용                                                                                |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| e-commerce 주문 시스템             | `orders` 테이블에 `status`, `payment_method`, `address` 컬럼 추가, `book` 테이블에 `category` 연결 |
| 상품 좋아요 & Denormalized Counter | `book_like` 테이블 생성 + `like_count` 컬럼을 트리거로 자동 동기화                                    |
| 상품 카테고리                       | `category` 테이블 **자기참조 계층구조** 설계 (`WITH RECURSIVE`로 계층 조회)                            |
| 상품 판매 통계                      | `book_sales_stat` **집계 테이블** 설계 + `UNIQUE` 제약 조건 적용                                  |
| 포인트 변동 내역                     | `point_history` 테이블 생성 + **트리거로 포인트 변경 이력 자동 기록**                                    |
| 상품 정보 변경 이력                   | `book_history` 테이블 설계 (**SCD Type 4: 별도 이력 테이블 분리 방식**)                              |
