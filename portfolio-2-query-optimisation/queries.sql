-- =====================================================================
-- Portfolio 2: Query Processing and Optimisation
-- Fortress Community Library
-- =====================================================================

-- Q1: Simple filter — all currently available copies of a given title
SELECT bc.copy_id, b.title, br.name AS branch
FROM book_copy bc
JOIN book b ON b.book_id = bc.book_id
JOIN branch br ON br.branch_id = bc.branch_id
WHERE b.title = 'Pride and Prejudice' AND bc.status = 'available';

-- Q2: Join across 4 tables — currently active (unreturned) loans with borrower
-- and book details
SELECT l.loan_id, bo.full_name AS borrower, b.title, l.loan_date, l.due_date
FROM loan l
JOIN borrower bo ON bo.borrower_id = l.borrower_id
JOIN book_copy bc ON bc.copy_id = l.copy_id
JOIN book b ON b.book_id = bc.book_id
WHERE l.return_date IS NULL
ORDER BY l.due_date;

-- Q3: Overdue loans as of today (no return_date and due_date has passed)
SELECT l.loan_id, bo.full_name, b.title, l.due_date,
       DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue  -- MySQL/MariaDB: use DATEDIFF, not date subtraction
FROM loan l
JOIN borrower bo ON bo.borrower_id = l.borrower_id
JOIN book_copy bc ON bc.copy_id = l.copy_id
JOIN book b ON b.book_id = bc.book_id
WHERE l.return_date IS NULL AND l.due_date < CURRENT_DATE;

-- Q4: Aggregate — most-borrowed books (top 5) across all time
SELECT b.title, COUNT(*) AS times_borrowed
FROM loan l
JOIN book_copy bc ON bc.copy_id = l.copy_id
JOIN book b ON b.book_id = bc.book_id
GROUP BY b.title
ORDER BY times_borrowed DESC
LIMIT 5;

-- Q5: Aggregate with HAVING — borrowers with more than 1 unpaid fine
SELECT bo.full_name, COUNT(f.fine_id) AS unpaid_fines, SUM(f.amount) AS total_owed
FROM borrower bo
JOIN loan l ON l.borrower_id = bo.borrower_id
JOIN fine f ON f.loan_id = l.loan_id AND f.is_paid = FALSE
GROUP BY bo.full_name
HAVING COUNT(f.fine_id) >= 1
ORDER BY total_owed DESC;

-- Q6: Subquery — borrowers who have never borrowed a book (NOT IN)
SELECT bo.full_name, bo.email
FROM borrower bo
WHERE bo.borrower_id NOT IN (SELECT DISTINCT borrower_id FROM loan);

-- Q7: Correlated subquery — books that have more than the average number
-- of copies across all titles
SELECT b.title,
       (SELECT COUNT(*) FROM book_copy bc WHERE bc.book_id = b.book_id) AS copy_count
FROM book b
WHERE (SELECT COUNT(*) FROM book_copy bc WHERE bc.book_id = b.book_id)
      > (SELECT COUNT(*) * 1.0 / COUNT(DISTINCT book_id) FROM book_copy);

-- Q8: Window function — rank branches by number of active loans
SELECT br.name,
       COUNT(l.loan_id) AS active_loans,
       RANK() OVER (ORDER BY COUNT(l.loan_id) DESC) AS branch_rank
FROM branch br
JOIN book_copy bc ON bc.branch_id = br.branch_id
JOIN loan l ON l.copy_id = bc.copy_id AND l.return_date IS NULL
GROUP BY br.name;

-- Q9: Full-text style search — catalogue search by partial title or author
-- MySQL's and MariaDB's default collations (e.g. utf8mb4_0900_ai_ci on
-- MySQL 8, utf8mb4_general_ci on MariaDB) are both case-insensitive, so
-- plain LIKE behaves like Postgres's ILIKE here on either engine.
SELECT title, author, genre
FROM book
WHERE title LIKE '%harry%' OR author LIKE '%harry%';


-- =====================================================================
-- Indexing case study — three queries that isolate idx_loan_due_date
-- and show the optimizer making a genuine cost-based choice about
-- whether to use it. Run each with ANALYZE SELECT (MariaDB) or
-- EXPLAIN ANALYZE (MySQL 8.0.18+). See README.md for the full findings.
-- =====================================================================

-- Q10a: the Q3 join query — index exists but is NOT chosen; the
-- optimizer drives the plan off idx_loan_copy from the join instead.
ANALYZE SELECT l.loan_id, bo.full_name, b.title, l.due_date,
       DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue
FROM loan l
JOIN borrower bo ON bo.borrower_id = l.borrower_id
JOIN book_copy bc ON bc.copy_id = l.copy_id
JOIN book b ON b.book_id = bc.book_id
WHERE l.return_date IS NULL AND l.due_date < CURRENT_DATE;

-- Q10b: isolated, broad WHERE clause — index still exists in
-- possible_keys but is declined again. ~29% of rows match, which is
-- too large a share for the optimizer to prefer an index lookup over
-- a full scan.
ANALYZE SELECT * FROM loan WHERE return_date IS NULL AND due_date < CURRENT_DATE;

-- Q10c: isolated, narrow (highly selective) WHERE clause — same index,
-- now USED, because only a handful of rows match a single exact date.
ANALYZE SELECT * FROM loan WHERE due_date = '2026-09-15';
