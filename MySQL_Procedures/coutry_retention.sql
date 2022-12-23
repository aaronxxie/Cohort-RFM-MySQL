CREATE DEFINER=`root`@`localhost` PROCEDURE `country_retention`(IN country_input VARCHAR(30))
BEGIN
DROP TABLE IF EXISTS retention;
CREATE TABLE retention
WITH cte AS
(
SELECT 
	DISTINCT CustomerID,
    InvoiceDate,
    MIN(InvoiceDate) OVER(PARTITION BY CustomerID) AS CohortMonth
FROM report_cohort
WHERE Country = country_input # The key to change to the country we want
),
cte2 AS
(
SELECT
	*,
    TIMESTAMPDIFF(MONTH, CohortMonth, InvoiceDate) AS CohortIndex
FROM cte
),
cte3 AS
(
SELECT
	DISTINCT CohortMonth,
    SUM(CohortIndex = 0) AS join_mth,
    SUM(CohortIndex = 1) AS mth01,
    SUM(CohortIndex = 2) AS mth02,
    SUM(CohortIndex = 3) AS mth03,
    SUM(CohortIndex = 4) AS mth04,
    SUM(CohortIndex = 5) AS mth05,
    SUM(CohortIndex = 6) AS mth06,
    SUM(CohortIndex = 7) AS mth07,
    SUM(CohortIndex = 8) AS mth08,
    SUM(CohortIndex = 9) AS mth09,
    SUM(CohortIndex = 10) AS mth10,
    SUM(CohortIndex = 11) AS mth11
FROM cte2
GROUP BY CohortMonth
ORDER BY CohortMonth
)
SELECT
    CohortMonth,
    join_mth/join_mth*100 AS join_mth,
    mth01/join_mth*100 AS mth01,
    mth02/join_mth*100 AS mth02,
    mth03/join_mth*100 AS mth03,
    mth04/join_mth*100 AS mth04,
    mth05/join_mth*100 AS mth05,
    mth06/join_mth*100 AS mth06,
    mth07/join_mth*100 AS mth07,
    mth08/join_mth*100 AS mth08,
    mth09/join_mth*100 AS mth09,
    mth10/join_mth*100 AS mth10,
    mth11/join_mth*100 AS mth11
FROM cte3
;
END