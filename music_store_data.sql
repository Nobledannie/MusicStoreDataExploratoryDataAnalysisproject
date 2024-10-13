CREATE DATABASE music_store;
-- EXPLORATORY DATA ANALYSIS PROJECT
-- Q1 WHO IS THE MOST SENIOR EMPLOYEE BASED ON JOB TITLE?
SELECT TOP 1 * FROM employee
ORDER BY levels DESC ;

-- Q2 WHICH COUNTRIES HAS THE MOST INVOICES?
SELECT TOP 5 COUNT(*) cnt, billing_country
FROM invoice
GROUP BY billing_country
ORDER BY cnt DESC;

-- Q3 WHAT ARE THE TOP 3 VALUES OF TOTAL INVOICE?
SELECT TOP 3 total
FROM invoice
ORDER BY total DESC;

-- Q4 WHICH CITY HAS THE BEST CUSTOMERS? WRITE A QUERY THAT RETURNS ONE CITY THAT HAS THE HIGHEST
-- SUM OF INVOICE TOTAL. RETURN BOTH THE CITY NAME AND SUM OF ALL INVOICES
SELECT TOP 1
billing_city,
ROUND(SUM(total),2) AS total_invoice
FROM invoice
GROUP BY billing_city
ORDER BY total_invoice DESC;

-- Q5 WHO IS THE BEST CUSTOMER? WRITE A QUERY THAT RETURNS THE PERSON WHO HAS SPENT THE MOST MONEY
SELECT TOP 1 C.customer_id, C.first_name, C.last_name, ROUND(SUM(I.total),2) AS Total
FROM customer C 
JOIN invoice I ON C.customer_id = I.customer_id
GROUP BY C.customer_id, C.first_name, C.last_name
ORDER BY Total DESC ;

-- Q6 WRITE A QUERY TO RETURN THE EMAIL, FIRSTNAME, LASTNAME & GENRE OF ALL ROCK MUSIC LISTENERS
-- RETURN YOUR LIST ALPHABETICALLY BY EMAIL STARTING WITH A
SELECT DISTINCT email, first_name, last_name
FROM customer C
JOIN invoice I ON C.customer_id = I.customer_id
JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
WHERE track_id IN (
	SELECT track_id FROM track T
	JOIN genre G ON T.genre_id = G.genre_id
	WHERE G.name LIKE 'Rock')
	ORDER BY email;

-- WRITE A QUERY THAT RETURNS THE ARTIST NAME AND TOTAL TRACK COUNT OF THE TOP 10 ROCK BANDS
SELECT TOP 10 art.artist_id, art.name, COUNT(art.artist_id) AS num_of_songs
FROM track t
JOIN album alb ON alb.album_id = t.album_id
JOIN artist art ON art.artist_id = alb.artist_id
JOIN genre gen ON gen.genre_id = t.genre_id
WHERE gen.name LIKE 'Rock'
GROUP BY art.artist_id, art.name
ORDER BY num_of_songs DESC;

-- RETURN ALL THE TRACK NAMES THAT HAS A SONG LENTH LONGER THAN THE AVERAGE SONG LENGTH.
-- RETURN THE NAME AND THE MILLISECONDS FOR EACH TRACK. ORDER BY THE SONG LENGTH WITH THE LONGEST 
-- SONGS LISTED FIRST
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)
	ORDER BY milliseconds DESC;

-- FIND HOW MUCH AMOUNT SPENT BY EACH CUSTOMER ON ARTISTS. WRITE A QUERY TO RETURN CUSTOMER
-- NAME, ARTIST NAME AND TOTAL SPENT
WITH best_selling_artist AS (
	SELECT TOP 1 art.artist_id AS artist_id, art.name AS artist_name,
	SUM(il.unit_price * CAST(il.quantity AS FLOAT)) AS total_sales
	FROM invoice_line il
	JOIN track t ON t.track_id = il.track_id
	JOIN  album alb ON alb.album_id = t.album_id
	JOIN artist art ON art.artist_id = alb.artist_id
	GROUP BY art.artist_id, art.name
	ORDER BY total_sales DESC
	)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
	SUM(il.unit_price * CAST(il.quantity AS FLOAT)) AS amount_spent
	FROM invoice i
	JOIN customer c ON c.customer_id = i.customer_id
	JOIN invoice_line il ON il.invoice_id = i.invoice_id
	JOIN track t ON t.track_id = il.track_id
	JOIN album alb ON alb.album_id = t.album_id
	JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
	GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
	ORDER BY 5 DESC;

-- WANT TO FIND OUT THE POPULAR MUSIC GENRE FOR EACH COUNTRY. WRITE A QUERY THAT 
-- RETURNS EACH COUNTRY ALONG WITH THE TOP GENRE. FOR COUNTRIES WHERE THE NUMBER OF 
-- PURCHASES IS SHARED RETURN ALL GENRES
WITH popular_genre AS (
	SELECT COUNT(il.quantity) AS purchases, c.country, gen.name, gen.genre_id,
	ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo
	FROM invoice_line il
	JOIN invoice i ON i.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = i.customer_id
	JOIN track t ON t.track_id = il.track_id
	JOIN genre gen ON gen.genre_id = t.genre_id
	GROUP BY c.country, gen.name, gen.genre_id
	ORDER BY 2 ASC, 1 DESC 
	OFFSET 1 ROWS
	)
SELECT * FROM popular_genre WHERE RowNo <= 1

-- WRITE A QUERY THAT DETERMINES THE CUSTOMER THAT HAS SPENT THE MOST ON MUSIC FOR EACH COUNTRY
-- WRITE A QUERY THAT RETURNS THE COUNTRY ALONG WIGTH THE CUSTOMER AND HOW MUCH SPENT
-- FOR COUNTRIES WHERE THE TOP AMOUNT SPENT IS SHARE, PROVIDE ALL CUSTOMERS WHO SPENT THIS AMOUNT

WITH customer_with_country AS (
		SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(i.total) AS total_spending
		FROM invoice i
		JOIN customer c on c.customer_id = i.customer_id
		GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country
		ORDER BY c.first_name, c.last_name DESC
		OFFSET 0 ROWS),
		
	country_max_spending AS (
		SELECT cc.billing_country, MAX(cc.total_spending) AS max_spending
		FROM customer_with_country cc
		GROUP BY cc.billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending  = ms.max_spending
ORDER BY 1;


WITH customer_with_country AS (
	SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(total) AS total_spending,
	ROW_NUMBER() OVER (PARTITION BY i.billing_country ORDER BY SUM(total) DESC) AS RowNo
	FROM invoice i
	JOIN customer c ON c.customer_id = i.customer_id
	GROUP BY c.customer_id, c.first_name, c.last_name, i.billing_country			
	ORDER BY 4 ASC, 5 DESC
	OFFSET 0 ROWS)
SELECT * FROM customer_with_country WHERE RowNo <= 1