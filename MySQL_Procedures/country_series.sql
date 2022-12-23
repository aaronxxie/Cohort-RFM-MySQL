CREATE DEFINER=`root`@`localhost` PROCEDURE `country_series`(IN country_input VARCHAR(30))
BEGIN
DROP TABLE IF EXISTS time_series;
CREATE TABLE time_series
WITH cte AS
(
SELECT 
    DISTINCT CustomerID,
    MIN(InvoiceDate) AS CohortMonth
FROM report_cohort
WHERE Country = country_input
GROUP BY CustomerID
),
cte2 AS
(
SELECT
    COUNT(CustomerID) AS NewUsers,
    CohortMonth
FROM cte
GROUP BY CohortMonth
)
SELECT
    InvoiceDate,
    COUNT(*) AS TotalOrders,
    ROUND(SUM(TotalRevenue),2) AS TotalRevenue,
    NewUsers,
    Country
FROM report_clean
JOIN cte2
ON InvoiceDate = CohortMonth AND Country = country_input
GROUP BY InvoiceDate;
END