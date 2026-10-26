
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS fine;
DROP TABLE IF EXISTS loan;
DROP TABLE IF EXISTS book_copy;
DROP TABLE IF EXISTS borrower;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS branch;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE branch (
    branch_id   INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    address     VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE staff (
    staff_id    INT AUTO_INCREMENT PRIMARY KEY,
    branch_id   INT NOT NULL,
    full_name   VARCHAR(100) NOT NULL,
    role        VARCHAR(50) NOT NULL CHECK (role IN ('Librarian', 'Assistant', 'Administrator')),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
) ENGINE=InnoDB;

CREATE TABLE book (
    book_id            INT AUTO_INCREMENT PRIMARY KEY,
    isbn               VARCHAR(20) NOT NULL UNIQUE,
    title              VARCHAR(255) NOT NULL,
    author             VARCHAR(150) NOT NULL,
    genre              VARCHAR(60),
    publication_year   INT CHECK (publication_year > 1400)
) ENGINE=InnoDB;

CREATE TABLE book_copy (
    copy_id     INT AUTO_INCREMENT PRIMARY KEY,
    book_id     INT NOT NULL,
    branch_id   INT NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'available'
                CHECK (status IN ('available', 'loaned', 'lost', 'in_repair')),
    FOREIGN KEY (book_id) REFERENCES book(book_id),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
) ENGINE=InnoDB;

CREATE TABLE borrower (
    borrower_id         INT AUTO_INCREMENT PRIMARY KEY,
    full_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(150) NOT NULL UNIQUE,
    phone               VARCHAR(30),
    membership_date     DATE NOT NULL DEFAULT (CURRENT_DATE),
    membership_status   VARCHAR(20) NOT NULL DEFAULT 'active'
                         CHECK (membership_status IN ('active', 'suspended', 'expired'))
) ENGINE=InnoDB;

CREATE TABLE loan (
    loan_id      INT AUTO_INCREMENT PRIMARY KEY,
    copy_id      INT NOT NULL,
    borrower_id  INT NOT NULL,
    staff_id     INT NOT NULL,
    loan_date    DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date     DATE NOT NULL,
    return_date  DATE,
    FOREIGN KEY (copy_id) REFERENCES book_copy(copy_id),
    FOREIGN KEY (borrower_id) REFERENCES borrower(borrower_id),
    FOREIGN KEY (staff_id) REFERENCES staff(staff_id),
    CHECK (due_date > loan_date),
    CHECK (return_date IS NULL OR return_date >= loan_date)
) ENGINE=InnoDB;

CREATE TABLE fine (
    fine_id      INT AUTO_INCREMENT PRIMARY KEY,
    loan_id      INT NOT NULL,
    amount       DECIMAL(6,2) NOT NULL CHECK (amount >= 0),
    is_paid      BOOLEAN NOT NULL DEFAULT FALSE,   -- BOOLEAN is an alias for TINYINT(1) in MySQL
    issued_date  DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (loan_id) REFERENCES loan(loan_id)
) ENGINE=InnoDB;

-- Helpful indexes beyond the automatic PK indexes (justified further in Portfolio 2)
-- NOTE: MySQL does not support partial/filtered indexes (the Postgres
-- "WHERE return_date IS NULL" clause used in the earlier design), so this
-- is a full index on due_date instead. The query itself still filters on
-- return_date IS NULL at query time; it just can't be baked into the index.
CREATE INDEX idx_loan_borrower ON loan(borrower_id);
CREATE INDEX idx_loan_copy ON loan(copy_id);
CREATE INDEX idx_loan_due_date ON loan(due_date);
CREATE INDEX idx_book_title ON book(title);
CREATE INDEX idx_book_author ON book(author);
