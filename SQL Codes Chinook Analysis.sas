libname chinook "C:\Users\pshah\Documents\BRT_SQL_Matthijs Meire\Chinook dataset-20200923";


  /********************/
 /**** FINANCIALS ****/
/********************/

/* 1. */
/* Annual Sales from 2009 - 2013 */

PROC SQL;
	SELECT DISTINCT year(datepart(i.InvoiceDate)) AS Year, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Sales
	FROM chinook.invoices AS i
	GROUP BY 1;
QUIT;

/* 2. */
/* Monthly Sales from 2009 - 2013 */

PROC SQL;
	SELECT DISTINCT month(datepart(i.InvoiceDate)) AS Month, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Sales
	FROM chinook.invoices AS i
	GROUP BY month(datepart(i.InvoiceDate));
QUIT;

/* 3. */
/* Monthly Sales from 2009 - 2013 */
/* No particular trend observed hence not included in the report */

PROC SQL;
	SELECT month(datepart(i.InvoiceDate)) as Month, 
		   year(datepart(i.invoicedate)) as Year, 
		   sum(i.total) FORMAT=DOLLAR13.2 as Sales
	FROM chinook.invoices AS i
	GROUP BY 1, 2;
QUIT;

/* 4. */
/* Average sale per invoice */

PROC SQL;
	SELECT avg(i.total) FORMAT=DOLLAR13.2 AS AvgSalePerInvoice
	FROM chinook.invoices AS i;
QUIT;

/* 5. */
/* Invoices with sales 2 times greater than the average sales per invoice */

PROC SQL;
	SELECT year(datepart(i.InvoiceDate)) AS Year, 
		   i.invoiceid AS InvoiceId, 
		   c.FirstName AS Customer, 
		   c.Country AS Country, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Sales
	FROM chinook.invoices AS i,
		 chinook.customers AS c
	WHERE i.customerid = c.customerid
	GROUP BY i.invoiceid
	HAVING i.total >
					(SELECT avg(i.total)*2 AS AvgSales_Per_Invoice
					 FROM chinook.invoices AS i)
	ORDER BY 5 DESC;
QUIT;


  /*******************/
 /**** CUSTOMERS ****/
/*******************/

/* 1. */
/* Total number of customers */

PROC SQL;
	SELECT count(DISTINCT c.customerid) AS Total_Customers
	FROM chinook.customers AS c;
QUIT;

/* 2. */
/* Total Sales */

PROC SQL;
	SELECT sum(Total) FORMAT=DOLLAR13.2 AS Total_Sales
	FROM chinook.invoices as i;
QUIT;

/* 3. */
/* Total number of unique customers who placed at least 1 order during the year, for all years */

PROC SQL;
	SELECT DISTINCT year(datepart(i.InvoiceDate)) AS Year, 
	       count(DISTINCT i.customerid) AS Nbr_of_unique_customers
	FROM chinook.invoices AS i
	GROUP BY 1;
QUIT;

/* 4. */
/* Sales by corporate and individual clients */

PROC SQL;
	SELECT Client_Type, count(DISTINCT customerid) AS Nbr_of_Customers, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Sales, 
		   round((sum(i.total)))/(SELECT sum(total) FROM chinook.invoices) FORMAT=Percent8.2 AS Percent
	FROM chinook.invoices AS i,
			(SELECT
				CASE 
					WHEN Company = "NA" THEN "Individual"
					ELSE "Corporate" END AS Client_Type
				FROM chinook.customers
				GROUP BY Client_Type)
	WHERE i.customerid = customers.customerid
	GROUP BY 1;
QUIT;

/* 5. */
/* Corporate customers per country and their sales */

PROC SQL;
	SELECT country AS Countries_with_corporate_clients, 
		   Count(DISTINCT customers.customerid) As Nbr_of_Clients, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Revenue
	FROM chinook.customers,
		 chinook.invoices as i
	WHERE customers.customerid = i.customerid AND 
		  company NOT = "NA" 
	GROUP BY country
	ORDER BY 2 DESC;
QUIT;

/* 6. */
/* Overview of all customers sorted by highest paying customers, with information such as 
   Name, Country, Total Sales, Tenure with Chinook, Days since last purchase (recency),
   Number of transactions (frequency), Average customer spend (monetary value) */

PROC SQL;
	SELECT DISTINCT c.customerid as ID, 
		    c.FirstName AS Name, 
		    c.country AS Country, 
			sum(i.total) FORMAT=DOLLAR13.2 AS Sales, 
			round(('31dec13'd -datepart(min(i.invoicedate)))/365) AS Tenure_Yrs,
			round(('31dec13'd -datepart(max(i.invoicedate)))) AS Days_Since_Last_Purch,
			count(*) AS Nbr_Trans_Freq,
			sum(i.total)/count(*) AS Avg_Spend_Per_Trans_MV
	FROM chinook.customers as c INNER JOIN chinook.invoices as i
	ON c.customerid = i.customerid
	GROUP BY 1
	ORDER BY 4 DESC;
QUIT;

/* 7. */
/* Sales per country */

PROC SQL;
	SELECT DISTINCT c.country AS Country, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Sales, 
	       sum(i.total)/(SELECT sum(total) FROM chinook.invoices) FORMAT=Percent8.2 AS Percentage
	FROM chinook.customers as c,
		 chinook.invoices as i
	WHERE c.customerid = i.customerid
	GROUP BY 1
	ORDER BY 2 DESC;
QUIT;

/* 8. */
/* Sales per continent */

PROC SQL;
	SELECT Continent AS Continent, 
		   sum(i.total) FORMAT=DOLLAR13.2 AS Sales, 
		   (sum(i.total))/(SELECT sum(total) FROM chinook.invoices) FORMAT=Percent8.2 AS Percent,
		   sum(i.total)/count(DISTINCT customers.Country) FORMAT=DOLLAR13.2 AS Avg_Per_Country
	FROM chinook.invoices AS i,
			(SELECT
				CASE 
					WHEN Country = "USA" THEN "North America"
					WHEN Country = "Canada" THEN "North America"
					WHEN Country = "Brazil" THEN "South America"
					WHEN Country = "Chile" THEN "South America"
					WHEN Country = "Argentina" THEN "South America"
					WHEN Country = "India" THEN "Asia"
					WHEN Country = "Australia" THEN "Oceania"
					ELSE "Europe" END AS Continent
				FROM chinook.customers
				GROUP BY Continent)
	WHERE customers.customerid = i.customerid
	GROUP BY 1
	ORDER BY 2 DESC;
QUIT;


/* 9. */
/* Oldest customers (2009) who are still buying from Chinook (made a purchase in last 2 months/60 days) 
   AND are also in the list of top 10 customers */

PROC SQL ;

	SELECT DISTINCT c.customerid as ID, 
		    c.FirstName,
			c.LastName, 
		    c.country AS Country
	FROM chinook.customers as c INNER JOIN chinook.invoices as i
	ON c.customerid = i.customerid
	GROUP BY 1
	HAVING sum(i.total) > 42 AND
		   round(('31dec13'd - datepart(min(invoices.invoicedate)))/365) > 4 AND
       	   round('31dec13'd - datepart(max(invoices.invoicedate))) <= 60
	ORDER BY 2 DESC;

QUIT;


  /********************/
 /***** INTERNAL *****/
/********************/

 /* 1. */
/* Sales by Genres */


PROC SQL OUTOBS=5;

SELECT g.genreid AS GID, 
	   g.Name AS Name, 
       sum(ii.quantity * ii.unitprice) FORMAT=DOLLAR13.2 AS Sales, 
	   sum(ii.quantity * ii.unitprice)/(SELECT sum(quantity * unitprice) FROM chinook.invoice_items) FORMAT=Percent8.2 AS Percent_of_Sales,
       count(ii.trackid) AS Nbr_of_Tracks,
	   count(ii.trackid)/(SELECT count(trackid) FROM Chinook.tracks) FORMAT=Percent8.2 AS Percent_of_total_tracks
FROM chinook.genres AS g,
	 chinook.tracks AS t,
	 chinook.invoice_items AS ii
WHERE g.genreid = t.genreid AND
	  t.trackid = ii.trackid
GROUP BY 1, 2
ORDER BY 3 DESC;

QUIT;

 /* 2. */
/* Country-wise contribution to sales of Rock  */

PROC SQL;

SELECT c.country AS Countries_Purchasing_Rock,
	   sum(ii.quantity * ii.unitprice) FORMAT=DOLLAR13.2 AS Sale,
	   sum(ii.quantity * ii.unitprice)/(SELECT sum(ii.quantity * ii.unitprice)
				FROM chinook.genres AS g,
					 chinook.tracks AS t,
					 chinook.invoice_items AS ii
				WHERE g.genreid = t.genreid AND
					  t.trackid = ii.trackid AND 
					  g.name CONTAINS 'Rock') FORMAT=Percent8.2 AS Percent
FROM chinook.genres AS g,
	 chinook.tracks AS t,
	 chinook.invoice_items AS ii,
	 chinook.invoices AS i,
	 chinook.customers AS c
WHERE g.genreid = t.genreid AND
	  t.trackid = ii.trackid AND
	  ii.invoiceid = i.invoiceid AND
	  i.customerid = c.customerid AND
	  g.name CONTAINS 'Rock'				
GROUP BY 1
ORDER BY 2 DESC;

QUIT;


 /* 3. */
/* Best Selling Artists and how many tracks of these artists do we sell at Chinook */

PROC SQL OUTOBS=5;

SELECT a.name AS BestSelling_Artist, 
       sum(ii.quantity * ii.unitprice) FORMAT=DOLLAR13.2 AS Sale_Per_Artist, 
	   sum(ii.quantity * ii.unitprice)/(SELECT sum(quantity * unitprice) FROM chinook.invoice_items) FORMAT=Percent8.2 AS Percent_of_Sales,
	   count(ii.trackid) AS Nbr_of_Tracks,
	   count(ii.trackid)/(SELECT count(trackid) FROM Chinook.tracks) FORMAT=Percent8.2 AS Percent_of_total_tracks
FROM chinook.artists AS a,
	 chinook.albums AS ab,
	 chinook.tracks AS t,
	 chinook.invoice_items AS ii
WHERE a.artistid = ab.artistid AND
	  ab.albumid = t.albumid AND
	  t.trackid = ii.trackid
GROUP BY 1
ORDER BY 2 DESC;

QUIT;

 /* 4. */
/* Number of Tracks with 0.99 unitprice */

PROC SQL;
	SELECT 
		CASE 
			WHEN unitprice = 0.99 THEN 0.99
			ELSE 1.99 END AS Unit_Price,
			count(*) AS Nbr_of_tracks
	FROM chinook.tracks
	GROUP BY Unit_Price;
QUIT;

 /* 5. */
/* Sale Per Track */ 

PROC SQL OUTOBS=5;

SELECT DISTINCT t.name, sum(DISTINCT i.total) FORMAT=DOLLAR13.2 AS Sales, a.name AS Artist 
FROM chinook.invoice_items AS ii,
	 chinook.tracks AS t,
	 chinook.invoices as i,
	 chinook.albums AS al,
	 chinook.artists AS a
WHERE t.trackid = ii.trackid AND
	  i.invoiceid = ii.invoiceid AND
	  a.artistid = al.artistid AND
	  al.albumid = t.albumid
GROUP BY 1
ORDER BY 2 DESC;

QUIT; 

 /* 6. */
/* Tracks classification based on performance */

PROC SQL;

SELECT
	  CASE WHEN i.total > 15 THEN "Good Performance"
	  	   WHEN i.total > 6 THEN "Average Performance"
		   ELSE "Low Perfromance" END AS Performance,
		   count(*) AS Nbr_of_Tracks
FROM chinook.invoice_items AS ii,
	 chinook.tracks AS t,
	 chinook.invoices as i
WHERE t.trackid = ii.trackid AND
	  i.invoiceid = ii.invoiceid
GROUP BY Performance
ORDER BY 2 DESC;

QUIT; 


 /* 7. */
/* Tracks that are never sold and % of bytes it occupies */
PROC SQL;

SELECT count(*) AS Tracks_Never_Sold, 
	   sum(bytes) AS Unsold_Bytes,
	   (SELECT sum(bytes) FROM chinook.tracks) AS Total_Bytes,
	   sum(bytes)/(SELECT sum(bytes) FROM chinook.tracks) FORMAT=Percent8.2 AS Unsold_Bytes_Percentage
FROM 
	(SELECT trackid
	 FROM chinook.tracks
	 EXCEPT
	 SELECT trackid
	 FROM chinook.invoice_items) AS a,
	      chinook.tracks as t
WHERE a.trackid = t.trackid;

QUIT;


 /* 8. */
/* Sale per Media Type */ 

PROC SQL;

SELECT mt.name AS MediaType, 
       sum(ii.quantity * ii.unitprice) FORMAT=DOLLAR13.2 AS Sale_Per_MediaType, 
	   sum(ii.quantity * ii.unitprice)/(SELECT sum(quantity * unitprice) FROM chinook.invoice_items) FORMAT=Percent8.2 AS Percent_of_Sales
FROM chinook.media_types as mt,
	 chinook.tracks as t,
	 chinook.invoice_items as ii,
	 chinook.invoices as i
WHERE mt.mediatypeid = t.mediatypeid AND
	  t.trackid = ii.trackid AND
	  ii.invoiceid = i.invoiceid
GROUP BY 1
ORDER BY 2 DESC;

QUIT;



 /* 9. */
/* Albums never sold */

PROC SQL;

SELECT count(*)
FROM chinook.albums as ab,
	 chinook.tracks as t,
	 chinook.invoice_items as ii,
	 chinook.invoices as i
WHERE ab.albumid = t.albumid AND
	  t.trackid = ii.trackid AND
	  ii.invoiceid = i.invoiceid
GROUP BY ab.albumid
HAVING sum(i.total) = 0;

QUIT;


  /*********************/
 /***** EMPLOYEES *****/
/*********************/

 /* 1. */
/* Employees - Age and Tenure */

PROC SQL;

SELECT FirstName, LastName, Title, round((today() - datepart(birthdate))/365) AS Age, round((today() - datepart(hiredate))/365) AS Tenure 
FROM chinook.employees 
ORDER BY 4 DESC;

QUIT;


 /* 2. */
/* Different roles and their count */ 

PROC SQL;

SELECT DISTINCT Title, count(*) AS Count
FROM chinook.employees
GROUP BY 1;

QUIT;


 /* 3. */
/* How many sales does each of the salespeople have? How many sales does each of the supervisors have? 
What areas do they serve? */

PROC SQL;

SELECT e.FirstName as Name,
	   sum(i.total) FORMAT=DOLLAR13.2 as Sales,
	   sum(i.total)/(SELECT sum(quantity * unitprice) FROM chinook.invoice_items) FORMAT=Percent8.2 AS Percent
FROM chinook.invoices as i,
     chinook.customers as c,
	 chinook.employees as e
WHERE e.employeeid = c.supportrepid AND
	  c.customerid = i.customerid AND 
	  e.title = 'Sales Support Agent'
GROUP BY 1
ORDER BY 2 DESC; 
QUIT;

 /* 4. */
/* Which employee is handling the most corporate clients */

PROC SQL;

SELECT DISTINCT e.firstname as Employee, 
	   count(DISTINCT c.company) as Nbr_corporate_clients, 
	   sum(i.total) FORMAT=DOLLAR13.2 as Sales
FROM chinook.employees as e LEFT JOIN chinook.customers as c
ON e.employeeid = c.supportrepid
LEFT JOIN chinook.invoices as i 
ON c.customerid = i.customerid
WHERE c.company NOT CONTAINS "NA" AND
	  e.title = "Sales Support Agent"
GROUP BY e.employeeid;

QUIT;

 /* 5. */
/* Country-wise sales by the best employee - Jane */

PROC SQL;

SELECT DISTINCT c.country AS Country, sum(i.total) FORMAT=DOLLAR13.2 AS Sales_by_Jane
FROM chinook.invoices as i,
     chinook.customers as c,
	 chinook.employees as e
WHERE e.employeeid = c.supportrepid AND
	  c.customerid = i.customerid AND 
	  e.employeeid = 3
GROUP BY e.employeeid, c.country
ORDER BY 2 DESC;

QUIT;

 /* 6. */
/* Country-wise sales by Margaret */

PROC SQL;

SELECT DISTINCT c.country AS Country, sum(i.total) FORMAT=DOLLAR13.2 AS Sales_by_Margaret
FROM chinook.invoices as i,
     chinook.customers as c,
	 chinook.employees as e
WHERE e.employeeid = c.supportrepid AND
	  c.customerid = i.customerid AND 
	  e.employeeid = 4
GROUP BY e.employeeid, c.country
ORDER BY 2 DESC;

QUIT;

 /* 7. */
/* Country-wise sales by Steve */

PROC SQL;

SELECT DISTINCT c.country AS Country, sum(i.total) FORMAT=DOLLAR13.2 AS Sales_by_Steve
FROM chinook.invoices as i,
     chinook.customers as c,
	 chinook.employees as e
WHERE e.employeeid = c.supportrepid AND
	  c.customerid = i.customerid AND 
	  e.employeeid = 5
GROUP BY e.employeeid, c.country
ORDER BY 2 DESC;

QUIT;