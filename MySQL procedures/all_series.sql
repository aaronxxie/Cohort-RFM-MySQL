CREATE DEFINER=`root`@`localhost` PROCEDURE `all_series`()
BEGIN
DROP TABLE IF EXISTS time_series;
CREATE TABLE time_series
WITH cte AS
(
SELECT 
    DISTINCT CustomerID,
    MIN(InvoiceDate) AS CohortMonth
FROM report_cohort
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
    'All Countries' AS Country
FROM report_clean
JOIN cte2
ON InvoiceDate = CohortMonth
GROUP BY InvoiceDate;
END