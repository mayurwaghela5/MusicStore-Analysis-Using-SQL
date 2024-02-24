/*
Q1. Who is the senior most employee based on job title?
*/

SELECT Top 1 title, first_name, last_name, levels from employee 
order by levels desc;

/*
Q2. Which countries have the most Invoices?
*/

SELECT Top 1 billing_country, count(billing_country) as Country_with_most_Invoice 
from invoice
group by billing_country
order by Country_with_most_Invoice desc;

/*
Q3. What are top 3 values of total invoice?
*/
SELECT Top 3 total as Top3_Invoices from invoice
order by total desc;

/*
Q4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals
*/
SELECT Top 1 billing_city as City, sum(total) as Highest_Invoice_Total from invoice
group by billing_city
order by Highest_Invoice_Total desc;

/*
Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money
*/


/* Without Join */
SELECT first_name, last_name from customer 
where customer_id=(
SELECT Top 1 customer_id from invoice
group by customer_id 
order by sum(total) desc
);

/* With Join */
SELECT Top 1 [invoice].[customer_id],[customer].[first_name],[customer].[last_name],SUM([invoice].[total]) as Total_spent from [customer]
inner join [invoice]
ON [customer].[customer_id]=[invoice].[customer_id]
group by [invoice].[customer_id],[customer].[first_name],[customer].[last_name]
order by Total_spent desc;

/*
Q6. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A
*/

SELECT distinct customer.email, customer.first_name, customer.last_name, genre.name from customer
JOIN  invoice
ON customer.customer_id=invoice.customer_id
JOIN invoice_line
ON invoice.invoice_id=invoice_line.invoice_id
JOIN track
ON invoice_line.track_id=track.track_id
JOIN genre
ON track.genre_id=genre.genre_id
where genre.name='Rock'
order by email;

/*
Q7. Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands
*/

select top 10 artist.name,COUNT(track.track_id) as total_track_count from artist
join album
ON artist.artist_id=album.artist_id
join track
On album.album_id=track.album_id
where track.genre_id LIKE 1
group by artist.name
order by total_track_count desc;

/*
Q8. Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. 
*/

select track.track_id, track.name,track.milliseconds as Length_of_Song_inMillSec from track
where track.milliseconds > (Select AVG(track.milliseconds) from track)
order by track.milliseconds desc;

/*
Q9. --Write a query which retrieves information about customers(id and name) who have made purchases of tracks belonging to the best-selling artist and total spent
*/

WITH best_selling_artist AS (
    SELECT 
        artist.artist_id AS artist_id, 
        artist.name AS artist_name, 
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM 
        invoice_line
    JOIN track ON track.track_id = invoice_line.track_id
    JOIN album ON album.album_id = track.album_id
    JOIN artist ON artist.artist_id = album.artist_id
    GROUP BY 
        artist.artist_id, 
        artist.name
),
sorted_best_selling_artist AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
    FROM 
        best_selling_artist
)
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name, 
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM 
    invoice AS i
JOIN 
    customer AS c ON c.customer_id = i.customer_id
JOIN 
    invoice_line AS il ON il.invoice_id = i.invoice_id
JOIN 
    track AS t ON t.track_id = il.track_id
JOIN 
    album AS alb ON alb.album_id = t.album_id
JOIN 
    sorted_best_selling_artist AS bsa ON bsa.artist_id = alb.artist_id
WHERE 
    bsa.rn = 1
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name
ORDER BY 
    SUM(il.unit_price * il.quantity) DESC;

/*
Q10. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres.
*/

WITH popular_genre AS 
(
    SELECT 
        COUNT(invoice_line.quantity) AS purchases, 
        customer.country, 
        genre.name, 
        genre.genre_id, 
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM 
        invoice_line 
    JOIN 
        invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN 
        customer ON customer.customer_id = invoice.customer_id
    JOIN 
        track ON track.track_id = invoice_line.track_id
    JOIN 
        genre ON genre.genre_id = track.genre_id
    GROUP BY 
        customer.country, 
        genre.name, 
        genre.genre_id
)
SELECT 
    purchases, 
    country, 
    name AS genre_name, 
    genre_id
FROM 
    popular_genre 
WHERE 
    RowNo <= 1
ORDER BY 
    country ASC;


/*
Q11.Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount.
*/

WITH Customer_with_country AS (
    SELECT 
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        SUM(total) AS total_spending,
        ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
    FROM 
        invoice
    JOIN 
        customer ON customer.customer_id = invoice.customer_id
    GROUP BY 
        customer.customer_id,
        first_name,
        last_name,
        billing_country
)
SELECT 
    customer_id,
    first_name,
    last_name,
    billing_country,
    total_spending
FROM 
    Customer_with_country 
WHERE 
    RowNo <= 1
ORDER BY 
    billing_country ASC;