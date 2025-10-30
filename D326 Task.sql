-- B. Provide original code for function(s) in text format that perform the transformation(s) you identified in part A4.

-- This function transforms the sales_month data type from timestamp to text and displays the name of the month.
CREATE OR REPLACE FUNCTION sales_month (payment_date timestamp)
	RETURNS text
	LANGUAGE plpgsql
AS
$$
DECLARE month_of_sale text;
BEGIN
	SELECT to_char( payment_date, 'Month') into month_of_sale;
	RETURN month_of_sale;
END;
$$

-- Testing function
SELECT sales_month('2007-03-25');


-- C. Provide original SQL code in a text format that creates the detailed and summary tables to hold your report table sections.

-- Code to create detailed table
CREATE TABLE detailed_rentals(
payment_id INT,
payment_date TEXT,
rental_amount NUMERIC(10,2),
category_name VARCHAR(25),
PRIMARY KEY (payment_id)
);

-- Testing Create Table Query
SELECT * FROM detailed_rentals;

-- Code to create summary table
CREATE TABLE summary_rentals(
payment_month TEXT,
rental_amount NUMERIC(10,2),
category_name VARCHAR(25)
);

-- Testing Create Table Query
SELECT * FROM summary_rentals;


-- D. Provide an original SQL query in a text format that will extract the raw data needed 
--    for the detailed section of your report from the source database.

-- Inserts data from dvdrental database into the detailed table
INSERT INTO detailed_rentals
SELECT
p.payment_id,
sales_month(p.payment_date), 
p.amount,
c.name
FROM category c
INNER JOIN film_category fc ON c.category_id = fc.category_id
INNER JOIN inventory i ON fc.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE EXTRACT(YEAR FROM payment_date) = 2007
      AND EXTRACT(MONTH FROM payment_date) = 3
ORDER BY payment_id;

--Testing Insert statement
SELECT * FROM detailed_rentals; -- Should have 5644 rows
SELECT * FROM summary_rentals; -- Should have 32 rows


-- E. Provide original SQL code in a text format that creates a trigger on the detailed table of the report that will 
-- 	  continually update the summary table as data is added to the detailed table.


-- Code to create function that will update the summary table when the detailed table has new inserts
CREATE OR REPLACE FUNCTION update_SUMMARY_table()
RETURNS TRIGGER
LANGUAGE plpgsql
AS 
BEGIN
DELETE FROM summary_rentals;
INSERT INTO SUMMARY_RENTALS
SELECT payment_date, SUM(rental_amount), category_name
FROM detailed_rentals
GROUP BY 1, 3
ORDER BY 2 DESC;
RETURN NEW;
END;
$$;


-- Code to create trigger that executes functi on to refresh summary table with data from detailed table.
CREATE TRIGGER new_summary_rentals
	AFTER INSERT
	ON detailed_rentals
	FOR EACH STATEMENT
	EXECUTE PROCEDURE update_SUMMARY_table();

-- Testing trigger
INSERT INTO detailed_rentals
VALUES (5555, 'March', 1.29, 'Sports')

-- F. Provide an original stored procedure in a text format that can be used to refresh the data in both the detailed 
-- table and summary table.

-- Code to create stored procedure that will update both the detailed and summary tables.
CREATE OR REPLACE PROCEDURE refresh_rental_tables()
LANGUAGE PLPGSQL
AS $$
BEGIN
DELETE FROM detailed_rentals;
DELETE FROM summary_rentals;
INSERT INTO detailed_rentals
SELECT
p.payment_id,
sales_month(p.payment_date), 
p.amount,
c.name
FROM category c
INNER JOIN film_category fc ON c.category_id = fc.category_id
INNER JOIN inventory i ON fc.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE EXTRACT(YEAR FROM payment_date) = 2007
      AND EXTRACT(MONTH FROM payment_date) = 3
ORDER BY payment_id;


INSERT INTO summary_rentals
SELECT payment_date, SUM(rental_amount), category_name
FROM detailed_rentals
GROUP BY 1,3
ORDER BY 2 DESC;

RETURN;
END;
$$;

-- Testing stored procedure
CALL refresh_rental_tables();

SELECT * FROM detailed_rentals;
SELECT * FROM summary_rentals;