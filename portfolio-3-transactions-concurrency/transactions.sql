-- =====================================================================
-- Portfolio 3: Transactions and Concurrency — Fortress Community Library
-- Target engine: MySQL 8.0+ or MariaDB 10.4+ (as bundled with XAMPP) —
-- both use the InnoDB storage engine, which is required for all of this
-- (InnoDB is the only engine here that supports transactions, row
-- locking, and foreign keys); confirm tables use ENGINE=InnoDB as set in
-- schema.sql. Everything below runs identically on MySQL and MariaDB —
-- this file, unlike Portfolio 2's EXPLAIN/ANALYZE syntax, needs no
-- engine-specific changes.
-- =====================================================================

-- -----------------------------------------------------------------
-- DEMO 1: A successful transaction (COMMIT) — "borrow a book"
-- Borrowing must: (a) mark the copy as loaned, (b) insert the loan row.
-- Both must succeed together, or neither should happen.
-- -----------------------------------------------------------------
START TRANSACTION;

UPDATE book_copy SET status = 'loaned' WHERE copy_id = 1;

INSERT INTO loan (copy_id, borrower_id, staff_id, loan_date, due_date)
VALUES (1, 3, 2, CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL 14 DAY));

COMMIT;
-- Verify: SELECT * FROM book_copy WHERE copy_id = 1;  -> status = 'loaned'


-- -----------------------------------------------------------------
-- DEMO 2: A failed transaction (ROLLBACK) — attempted double-loan
-- Business rule: you cannot loan a copy that's already loaned.
-- Simulated here by catching the error in application logic; shown
-- directly in SQL via an explicit ROLLBACK after detecting the conflict.
-- -----------------------------------------------------------------
START TRANSACTION;

-- Check current status first (application would do this, or use a
-- trigger/constraint in production)
SELECT status FROM book_copy WHERE copy_id = 1 LIMIT 1 FOR UPDATE;
-- NOTE: the explicit "LIMIT 1" here (before FOR UPDATE) is required when
-- running this through phpMyAdmin — phpMyAdmin auto-appends its own
-- "LIMIT 0, 25" to SELECT queries for pagination, and if your query has
-- no LIMIT of its own, phpMyAdmin's gets appended AFTER "FOR UPDATE",
-- which is invalid clause order in MariaDB/MySQL and throws a syntax
-- error. Including LIMIT 1 yourself prevents phpMyAdmin from adding one.
-- Suppose this returns 'loaned' — the attempted loan is invalid.

ROLLBACK;
-- Nothing is written. book_copy and loan tables are unchanged.


-- -----------------------------------------------------------------
-- DEMO 3: Isolation levels — READ COMMITTED vs SERIALIZABLE
-- Run Session A and Session B concurrently (two separate mysql client
-- terminals, or two separate browser tabs in phpMyAdmin / two query tabs
-- in MySQL Workbench / DBeaver)
-- -----------------------------------------------------------------

-- NOTE: MySQL/InnoDB's default isolation level is REPEATABLE READ (not
-- READ COMMITTED like Postgres). To make the first part of this demo
-- match the "non-repeatable read" behaviour described, explicitly set
-- READ COMMITTED for Session A before starting the transaction:

-- SESSION A:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT status FROM book_copy WHERE copy_id = 2;  -- sees 'available'
-- ... pause here, let Session B run and COMMIT its UPDATE ...
SELECT status FROM book_copy WHERE copy_id = 2;  -- now sees 'loaned'
                                                   -- (READ COMMITTED allows
                                                   -- this non-repeatable read)
COMMIT;

-- SESSION A re-run with SERIALIZABLE:
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
SELECT status FROM book_copy WHERE copy_id = 2;  -- sees 'available'
-- ... Session B attempts to update the same row concurrently ...
UPDATE book_copy SET status = 'available' WHERE copy_id = 2;
COMMIT;
-- EXPECTED (per documentation): under SERIALIZABLE, InnoDB takes locking
-- reads for plain SELECTs too, so Session B's concurrent UPDATE on the
-- same row should BLOCK (rather than fail after the fact as in Postgres)
-- until Session A commits.
--
-- ACTUALLY OBSERVED on this MariaDB 10.4.28 (XAMPP) instance via
-- phpMyAdmin: Session B's UPDATE did NOT block — it completed in under a
-- millisecond, and Session A's own re-read of the row afterwards showed
-- Session B's new value, a non-repeatable read that SERIALIZABLE is
-- meant to prevent. This was re-tested carefully (keeping both sessions
-- on the same phpMyAdmin page throughout, after an earlier run gave a
-- misleading result due to a page-navigation issue silently ending the
-- transaction) and reproduced consistently. See
-- portfolio-3-transactions-concurrency/README.md, "Demo 4b", for full
-- screenshots and discussion. By contrast, the EXPLICIT row lock in
-- DEMO 3 above (SELECT ... FOR UPDATE) blocked a concurrent session
-- exactly as expected — so explicit locking, not the SERIALIZABLE
-- isolation level alone, is the dependable mechanism demonstrated in
-- this environment.


-- -----------------------------------------------------------------
-- DEMO 4: Concurrency control — preventing a "lost update"
-- Scenario: two staff members process a return for the SAME loan at the
-- same moment and both try to mark the fine as paid.
-- -----------------------------------------------------------------

-- WITHOUT protection (race condition): both sessions read is_paid = FALSE,
-- both independently decide to update it, second UPDATE silently
-- overwrites the first — not itself dangerous here, but demonstrates the
-- pattern for cases where it would be (e.g., decrementing a copy count).

-- WITH protection, using row-level locking:
START TRANSACTION;
SELECT * FROM fine WHERE fine_id = 1 LIMIT 1 FOR UPDATE;  -- locks this row
                                                    -- (LIMIT 1 added for the
                                                    -- same phpMyAdmin
                                                    -- pagination reason noted
                                                    -- above);
                                                    -- the second concurrent
                                                    -- session attempting the
                                                    -- same SELECT ... FOR UPDATE
                                                    -- will BLOCK until this
                                                    -- transaction commits
UPDATE fine SET is_paid = TRUE WHERE fine_id = 1;
COMMIT;
-- The second session's blocked SELECT now proceeds, sees is_paid = TRUE
-- already, and can safely skip re-processing — the lost update is prevented.
