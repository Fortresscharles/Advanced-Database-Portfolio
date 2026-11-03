
SET SESSION max_recursive_iterations = 10000;   -- MariaDB
-- SET SESSION cte_max_recursion_depth = 10000; -- MySQL (comment the line above, uncomment this one, if you're on real MySQL)

INSERT INTO loan (copy_id, borrower_id, staff_id, loan_date, due_date, return_date)
WITH RECURSIVE seq AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 8000
)
SELECT
    (SELECT copy_id FROM book_copy ORDER BY RAND() LIMIT 1) AS copy_id,
    (SELECT borrower_id FROM borrower ORDER BY RAND() LIMIT 1) AS borrower_id,
    (SELECT staff_id FROM staff ORDER BY RAND() LIMIT 1) AS staff_id,
    DATE_SUB(CURRENT_DATE, INTERVAL (8000 - n) * 3 HOUR) AS loan_date,
    DATE_ADD(DATE_SUB(CURRENT_DATE, INTERVAL (8000 - n) * 3 HOUR), INTERVAL 14 DAY) AS due_date,
    CASE WHEN RAND() < 0.7
         THEN DATE_ADD(DATE_SUB(CURRENT_DATE, INTERVAL (8000 - n) * 3 HOUR), INTERVAL FLOOR(RAND() * 20) DAY)
         ELSE NULL
    END AS return_date
FROM seq;

ANALYZE TABLE loan;   -- refreshes MariaDB/MySQL's internal statistics so the
                       -- optimizer's row estimates reflect the new data size

