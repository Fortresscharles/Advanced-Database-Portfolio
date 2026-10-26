
INSERT INTO branch (name, address) VALUES
('Riverbend Main', '12 Market Street'),
('Riverbend North', '48 Oak Avenue'),
('Riverbend East', '7 Harbour Road');

INSERT INTO staff (branch_id, full_name, role) VALUES
(1, 'Amara Chukwu', 'Librarian'),
(1, 'Tunde Bello', 'Assistant'),
(2, 'Grace Obi', 'Librarian'),
(3, 'Emeka Nwosu', 'Administrator');

INSERT INTO book (isbn, title, author, genre, publication_year) VALUES
('9780141439518', 'Pride and Prejudice', 'Jane Austen', 'Classic', 1813),
('9780439708180', 'Harry Potter and the Sorcerer''s Stone', 'J.K. Rowling', 'Fantasy', 1997),
('9780307474278', 'The Da Vinci Code', 'Dan Brown', 'Thriller', 2003),
('9780061120084', 'To Kill a Mockingbird', 'Harper Lee', 'Classic', 1960),
('9780143127550', 'Sapiens', 'Yuval Noah Harari', 'Non-fiction', 2011),
('9780singular1', 'Things Fall Apart', 'Chinua Achebe', 'Classic', 1958);

INSERT INTO book_copy (book_id, branch_id, status) VALUES
(1, 1, 'available'), (1, 2, 'available'),
(2, 1, 'loaned'),    (2, 1, 'available'),
(3, 2, 'available'),
(4, 3, 'loaned'),
(5, 1, 'available'),
(6, 3, 'available'), (6, 1, 'loaned');

INSERT INTO borrower (full_name, email, phone, membership_date, membership_status) VALUES
('Chidinma Okafor', 'chidinma.o@example.com', '0803-555-0101', '2025-02-10', 'active'),
('James Carter', 'james.carter@example.com', '0803-555-0102', '2024-11-05', 'active'),
('Fatima Yusuf', 'fatima.y@example.com', '0803-555-0103', '2025-06-20', 'active'),
('Daniel Umeh', 'daniel.umeh@example.com', '0803-555-0104', '2023-09-15', 'suspended');

INSERT INTO loan (copy_id, borrower_id, staff_id, loan_date, due_date, return_date) VALUES
(3, 1, 1, '2026-09-01', '2026-09-15', NULL),         
(6, 2, 3, '2026-08-20', '2026-09-03', NULL),         
(9, 3, 1, '2026-09-10', '2026-09-24', '2026-09-20'), 
(4, 4, 2, '2026-07-01', '2026-07-15', '2026-07-25'); 

INSERT INTO fine (loan_id, amount, is_paid, issued_date) VALUES
(4, 5.00, FALSE, '2026-07-26');
