# Customer Cohort and RFM Automation
#### with MySQL and Power BI
Aaron Xie

___
<a id="top"></a>
# Table of Content
* [1. The Problem](#problem)
    * [The Goal](#goal)
* [2. Data Preparation](#preparation)
* [3. Data Processing](#processing)
    * [Dataset Basic Info](#info)
    * [Removing Duplicate Rows](#duplicate)
    * [Dealing with missing values](#missing)
    * [Detecting Anormal Values/Outliers](#outliers)

#### Data Analysis Part I
* [4. Cohort Analysis](#cohort)
    * [Cohort Analysis by Countries](#bycountry)
* [5. Trending Analysis](#trending)
* [6. Data Sharing I](#sharing1)
    * [Dashboard 1](#dashboard1)
* [7. Summary I](#summary1)

#### Data Analysis Part II
* [8. RFM Analysis](#rfm)
* [9. Additional Analysis](#additional)
* [10. Data Sharing II](#sharing2)
    * [Dashboard 2](#dashboard2)
* [11. Summary II](#summary2)
___

<a id="problem"></a>
# 1. The Problem
Customer retention and churn rates are important for businesses to have sustainable revenues, especially for e-commerce businesses. The retention rate of e-commerce is not as obvious as those businesses that rely on subscriptions. Subscription businesses can easily find those who unsubscribe, but e-commerce businesses only have sales reports with a large amount of transactions. This difference raises the questions: 
* How can the e-commerce business keep track of customer retention easily? 
* How can they create the customer segmentation of the business for improving the retention rate?
* Can they use MySQL and/or Power BI to automate these processes?

<a id="goal"></a>
### The Goal
* Use SQL language to extract tables from the database to conduct cohort, trending, and RFM analysis.
* Connect Power BI to MySQL database and visualize the data analyses results on dashboards.
* Use the stored procedure function of MySQL and Power BI to automate the cohort and trending analyses.
* Use the Power Query Editor and DAX language in Power BI to automate RFM analysis.
* This project is for exploring the probability of MySQL and Power BI, so don't use Python!

<a id="preparation"></a>
# 2. Data Preparation
This project uses a [Online Retail Data Set](https://archive.ics.uci.edu/ml/datasets/online+retail) from the UCI Machine Learning Repository

Because this is a MySQL project, the first step is to upload the data set to MySQL database.

Creating a table
~~~~sql
DROP TABLE IF EXISTS project.sales_report;
CREATE TABLE project.sales_report 
(`InvoiceNo` varchar(255), 
`StockCode` varchar(255), 
`Description` varchar(1000), 
`Quantity` int, 
`InvoiceDate` varchar(255), 
`UnitPrice` double, 
`CustomerID` varchar(255), 
`Country` varchar(255));
~~~~


The csv file is large, so we use LOAD DARA INFILE method to upload the data set. This method is much faster.
~~~~sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Online Retail.csv' 
INTO TABLE sales_report
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;
~~~~
![image.png](attachment:image.png)
It took only 4 seconds to import a csv with 541K rows.

Note: to ensure MySQL can detect each column from csv file, I used Excel to replace comma with semicolon
![image.png](attachment:image.png)

[Go back to the top](#top)

<a id="processing"></a>
# 3. Data Processing

<a id="info"></a>
### Dataset Basic Info

~~~~sql
DESCRIBE sales_report
~~~~
![image.png](attachment:image.png)

As a sales report, the invoice number should be unique. Let's check.
~~~~sql
SELECT 
	InvoiceNo,
    COUNT(InvoiceNo)
FROM sales_report
GROUP BY InvoiceNo
HAVING COUNT(InvoiceNo) > 1;
~~~~
![image.png](attachment:image.png)
Apparently the InvoiceNo is not the primary key as I thought.

<a id="duplicate"></a>
### Removing duplicate rows

Creating a view to store
~~~~sql
CREATE VIEW report_unique
AS
SELECT DISTINCT *
FROM sales_report;
~~~~

Let's check
~~~~sql
SELECT
	'W/ Duplicates' AS 'table',
	COUNT(*) 
FROM sales_report
UNION
SELECT
	'W/O Duplicates' AS 'table',
	COUNT(*)
FROM report_unique
~~~~
![image.png](attachment:image.png)
We removed around 5000 duplicates!

<a id="missing"></a>
### Dealing with missing values

#### Checking missing values
~~~~sql
SELECT
	*
FROM report_unique
WHERE COALESCE(Quantity, InvoiceDate, UnitPrice, CustomerID, Country) IS NULL
~~~~
Great! No missing value detected!

For practice. What if there are missing values?
* drop the missing rows
* use imputation

Example: creating another view with mean imputation for UnitPrice
~~~~sql
CREATE VIEW report_imputed
AS
SELECT
    *,
    COALESCE(UnitPrice, AVG(UnitPirce)) AS UnitPrice
FROM report_unique
~~~~

#### Checking whether the records of the last month is complete.
~~~~sql
SELECT
	* 
FROM sales_report
WHERE invoicedate LIKE '%12/%/%2011%'
ORDER BY invoicedate DESC;
~~~~
![image-2.png](attachment:image-2.png)
No, the transactions after 12/09/2011 were not recorded. Need to delete the transctions of this month for trending analysis.

[Go back to the top](#top)

<a id="outliers"></a>
### Detecting Anormal Values/Outliers

The data set has two numeric variables that need attention: Quantity and UnitPrice.
~~~~sql
SELECT
	'Quantity' AS 'Column',
    MAX(Quantity) AS MAX,
    MIN(Quantity) AS MIN,
    round(AVG(Quantity),2) AS AVG,
    round(STDDEV(Quantity),2) AS STD
FROM report_unique
UNION
SELECT    
	'UnitPrice' AS 'Column',
    MAX(UnitPrice) AS MAX,
    MIN(UnitPrice) AS MIN,
    round(AVG(UnitPrice),2) AS AVG,
    round(STDDEV(UnitPrice),2) STD
FROM report_unique
~~~~
![image-2.png](attachment:image-2.png)
The result indicates some anormalies:
* The values include negative numbers; nagetive quantity may indicate that the order was returned, while negative price should be an error.
* The maximum values are too large compared to the average and standard deviation

#### Checking negative price
~~~~sql
SELECT
	InvoiceNo,
	UnitPrice
FROM report_unique
WHERE UnitPrice < 0 
~~~~
![image.png](attachment:image.png)
Only two rows have negative price; need to delete them
~~~~sql
SET SQL_SAFE_UPDATES = 0; 
DELETE FROM sales_report
WHERE UnitPrice < 0;
SET SQL_SAFE_UPDATES = 1;
~~~~
Note: when SQL_SAFE_UPDATES = 1, cannot delete rows based on non-primary key

#### Checking negative quantity
~~~~sql
SELECT
	InvoiceNo,
	Quantity,
	UnitPrice
FROM report_unique
WHERE Quantity < 0
LIMIT 1000, 10
~~~~
![image.png](attachment:image.png)
This sample shows that negative quantity may be associated with either invoice number starting with "c" or 0 unit price. According to UCI website, c indicates canceled orders. Let's check.
~~~~sql
SELECT
	invoiceno,
    Quantity,
    UnitPrice
FROM report_unique
WHERE Quantity < 0
AND UnitPrice > 0
AND invoiceno NOT LIKE "C%"
~~~~
![image-2.png](attachment:image-2.png)
The empty results shows that negative quantity must be an canceled order or have 0 unit price. We can ignore all these orders based on our purpose.

Creating another view with the only data we need.
~~~~sql
CREATE VIEW report_positive
AS
SELECT
	*
FROM report_unique
WHERE Quantity > 0
AND UnitPrice > 0
~~~~

#### Handling Outliers

Using Boxplot to better visualize outliers
(Opitional because this is no Python project)


```python
import sqlalchemy
import pandas as pd
engine = sqlalchemy.create_engine('mysql://root:ftgbvnth10@localhost/project')
engine.connect()
df = pd.read_sql('select * from report_positive', con = engine)
```


```python
import seaborn as sns
import matplotlib.pyplot as plt
plt.rcParams['figure.figsize'] = (12,6)
```

#### Quantity outliers


```python
sns.boxplot(x = df.Quantity)
```




    <AxesSubplot: xlabel='Quantity'>




    
![png](output_32_1.png)
    


Checking the two extreme outliers
~~~~sql
SELECT * 
FROM project.report_positive
WHERE Quantity > 70000;
~~~~
![image.png](attachment:image.png)
Although the business has many wholesaler customers according to the UCI website, these two quantity values are still too large for "storage jar" and "paper craft." It does not make sense for wholesalers to store this amount of products in their warehouse.

#### UnitPrice outliers


```python
sns.boxplot(x = df.UnitPrice)
```




    <AxesSubplot: xlabel='UnitPrice'>




    
![png](output_35_1.png)
    


Checking outliers
~~~~sql
SELECT * 
FROM project.report_positive
WHERE UnitPrice > 7000;
~~~~
![image.png](attachment:image.png)
Based on the description, although these values are large, they can still make sense because they are not the unit price of gift products.

When we see these anomalies in a data set, the best practice is to talk to the data set creaters or related people. Now since I don't have this resource, I choose **to keep the UnitPrice values and to replace the two outliers in Quantity with the average** because:
* Outliers are not related to cohort analysis.
* This data set is huge and outliers won't have too much negative impact on the result.
* Eliminating outliers may omit some information.

Creating another view for cohort analysis
~~~~sql
CREATE VIEW report_cohort
AS
SELECT
	InvoiceNo,
    StockCode,
    Description,
    IF(Quantity > 70000, 10, Quantity) AS Quantity,
    DATE_FORMAT(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'), '%Y-%m-01') AS InvoiceDate,
    UnitPrice,
    CustomerID,
    LEFT(Country, CHAR_LENGTH(Country) - 1) AS Country
FROM report_positive
WHERE CustomerID <> '' AND InvoiceDate NOT LIKE '%12/%/%2011%'
~~~~
![image.png](attachment:image.png)
Changes made:
* Replaced outliers with the average 10.
* Cast the 'InvoiceDate' from VARCHAR data type into DATE data type; only kept the month and year.
* Removed rows with empty 'CustomerID'
* Removed the non-ascii white space, which can't be removed by TRIM(), at the last character of the country column.
* Removed the transactions of the last month 12/2011.

[Go back to the top](#top)

<a id="cohort"></a>
# 4. Cohort Analysis

Step 1: get the cohort month (the month the customers first joined)
~~~~sql
SELECT 
	DISTINCT CustomerID,
    InvoiceDate,
    MIN(InvoiceDate) OVER(PARTITION BY CustomerID) AS CorhortMonth
FROM report
ORDER BY CustomerID, InvoiceDate
~~~~
![image.png](attachment:image.png)

Step 2: get the cohort index (The time difference between invoice date and cohort month)
~~~~sql
WITH cte AS
(
SELECT 
	DISTINCT CustomerID,
    InvoiceDate,
    MIN(InvoiceDate) OVER(PARTITION BY CustomerID) AS CohortMonth
FROM report
ORDER BY CustomerID, InvoiceDate
)

SELECT
	*,
    TIMESTAMPDIFF(MONTH, CohortMonth, InvoiceDate) AS CohortIndex
FROM cte
~~~~
![image-2.png](attachment:image-2.png)

Step 3: create a cohort pivot table
~~~~sql
CREATE VIEW cohort_pivot
AS
WITH cte AS
(
SELECT 
	DISTINCT CustomerID,
    InvoiceDate,
    MIN(InvoiceDate) OVER(PARTITION BY CustomerID) AS CohortMonth
FROM report
ORDER BY CustomerID, InvoiceDate
),
cte2 AS
(
SELECT
	*,
    TIMESTAMPDIFF(MONTH, CohortMonth, InvoiceDate) AS CohortIndex
FROM cte
)
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
~~~~
![image-4.png](attachment:image-4.png)
The downside of using mysql to get pivot table is that it does not have a PIVOT command, so it is not very scalable when we need to calculate the retention rate for a very long period. However, calculating monthly retention rate for a year would not be a problem.

Step 4: get retention rates (in percentage).
~~~~sql
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
FROM cohort_pivot
~~~~
![image-2.png](attachment:image-2.png)
We get a table of total retention rate.
<br>
To automate this calculation, I created a stored procedure without parameter called all_retention(). 

Now, what if we want to see the retention of each country?

<a id="bycountry"></a>
### Cohort Analysis by Country

Creating a stored procedure with IN parameter to achieve that; also adding WHERE clause to the first cte.
~~~~sql
DELIMITER $$
USE `project`$$
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
FROM report
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
END$$
DELIMITER ;
;
~~~~
With this procedure, every time I run:
~~~~sql
CALL country_retention(<country name>);
~~~~
That country's retention rate will be recorded to "retention" table.

For example:
~~~~sql
CALL country_retention('United Kingdom');
SELECT * FROM retention;
~~~~
![image-3.png](attachment:image-3.png)

The reason to store the output into retention table is that I could update the visualization on Power BI by simply refresh the data.
![image.png](attachment:image.png)
The retention heatmap
![image-4.png](attachment:image-4.png)

[Go back to the top](#top)

<a id="trending"></a>
# 5. Trending Analysis

Creating another VIEW called report_clean for this purpose
~~~~sql
DROP VIEW IF EXISTS report_clean;
CREATE VIEW report_clean
AS
SELECT
	InvoiceNo,
    StockCode,
    Description,
    IF(Quantity > 70000, 10, Quantity) AS Quantity,
    DATE_FORMAT(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'), '%Y-%m-01') AS InvoiceDate,
    UnitPrice,
    ROUND(IF(Quantity > 70000, 10, Quantity)*UnitPrice,2) AS TotalRevenue,
    CustomerID,
    LEFT(Country, CHAR_LENGTH(Country) - 1) AS Country
FROM report_positive
~~~~

Creating a time series table for trending analysis.
<br>
Same as the retention rate, creating two stored procedures to save the result to the table "time_series".
* country_series(<country name>): getting time series table for each country. 

~~~~sql
DELIMITER $$
USE `project`$$
CREATE PROCEDURE `country_series` (IN country_input VARCHAR(30))
BEGIN
DROP TABLE IF EXISTS time_series;
CREATE TABLE time_series
WITH cte AS
(
SELECT 
    DISTINCT CustomerID,
    MIN(InvoiceDate) AS CohortMonth
FROM report
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
END$$
DELIMITER ;
~~~~
Running:
~~~~sql
CALL country_series('United Kingdom');
~~~~
![image-2.png](attachment:image-2.png)

* all_series(): getting the overall series table

~~~~sql
DELIMITER $$
USE `project`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `all_series`()
BEGIN
DROP TABLE IF EXISTS time_series;
CREATE TABLE time_series
WITH cte AS
(
SELECT 
    DISTINCT CustomerID,
    MIN(InvoiceDate) AS CohortMonth
FROM report
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
    NewUsers
FROM report_clean
JOIN cte2
ON InvoiceDate = CohortMonth
GROUP BY InvoiceDate;
END$$
DELIMITER ;
~~~~

[Go back to the top](#top)

<a id="sharing1"></a>
# 6. Data Sharing Part I
With the "time_series" table and "retention" table, creating the first dashboard.

<a id="dashboard1"></a>
### Dashboard 1

![image-4.png](attachment:image-4.png)

The visualization on dashboard 1 shows in United Kingdom:
* There are much more new customers in Dec 2010 and their retention rates are higher than those who joined later. These customers may include more wholesalers and have higher demands for the products of the company, so they learned about the business fast and have higher loyalty. 
* The number of order is positively correlated to the total revenue.
* After the first month, the number of new customers slightly decreases, but the revenue and order do not follow the trend of new customers.
* The order and revenue increase sharply after Sep 2011 maybe because it was the holiday season and this e-commerce mainly sells gifts; their business is seasonal.
* The area chart shows that the retention rates increase for the first 4 months after new customers place their first order and decrease a little after 4 months. Gifts are not necessities, so those who have purchased from this business may not need to come back in a short time.

#### Manipulating the Dashboard

Steps to switch the dashboard to another country (e.g. France):
1. Use MySQL to run: 
~~~~sql
CALL country_series("France");
CALL country_retention("France");
~~~~
2. Refresh the data in Power BI and we get:

![image-3.png](attachment:image-3.png)

The data in France has a somewhat similar pattern with the data in the United Kingdom; however, the pattern is not obvious. If we look at the "New User Trend" chart, we can see that there are no more than 20 users placing orders each month. Therefore, the data in France are just too small to be random and to capture the patterns.

Switching to all countries
<br>
Running:
~~~~sql
CALL all_series();
CALL all_retention();
~~~~

![image-3.png](attachment:image-3.png)

The patterns of the whole data set are very similar to the patterns of the United Kingdom; it is very likely that the company has more businesses in the United Kingdom.

[Go back to the top](#top)

<a id="summary1"></a>
# 7. Summary I

* With the above 4 stored procedures I created, it is very fast and easy to update a 1-year cohort and trending analysis dashboard for a company. The data cleaning processes can also be stored in procedures as long as the data sets of the company are alway dirty in the same way, which is not hard to achieve if the company improves its data gathering methods. I chose not to do that because I used a third-party data set.
* The limitation of these MySQL procedures is that if I want to do a 2-year cohort analysis, I need to edit the procedures or create new ones because MySQL does not have PIVOT commands. It is easier to use pandas in Python to achieve that.
* <u>Using MySQL and Power BI together to do cohort analysis is redundant because we can just use the power query editor in Power BI to get retention rate tables. In that case, all we need to do is to refresh the data source. I will demonstrate this theory in the following analysis.</u>

<a id="rfm"></a>
# 8. RFM Analysis
https://clevertap.com/blog/rfm-analysis/
Creating another clean report table that is suitable for RFM and other analyses
~~~~sql
DROP VIEW IF EXISTS report_rfm;
CREATE VIEW report_rfm
AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    IF(Quantity > 70000, 10, Quantity) AS Quantity,
    DATE_FORMAT(STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i'), '%Y-%m-%d') AS InvoiceDate,
    UnitPrice,
    ROUND(IF(Quantity > 70000, 10, Quantity)*UnitPrice, 2) AS TotalRevenue,
    CustomerID,
    LEFT(Country, CHAR_LENGTH(Country) - 1) AS Country
FROM report_positive
~~~~
The only difference between report_rfm and report_clean tables is that the 'InvoiceDate' in report_rfm table has the specific day for recency calculation in RFM analysis.  

#### 1. RFM Table

~~~~sql
DROP VIEW IF EXISTS rfm_table;
CREATE VIEW rfm_table AS
WITH cte AS
(
SELECT
	*,
	MAX(InvoiceDate) OVER() AS max_date
FROM report_rfm
)

SELECT
	CustomerID,
    DATEDIFF(max_date, MAX(InvoiceDate)) AS Recency,
    COUNT(*) AS Frequency,
    ROUND(SUM(TotalRevenue),2) AS Monetary
FROM cte
GROUP BY 1
HAVING Frequency < 100000 # DELETING NULL CustomerID
~~~~
![image.png](attachment:image.png)

#### 2. RFM Table Ranked
<br>
Ranking RFM columns based on their values

~~~~sql
SELECT
	CustomerID,
    DENSE_RANK() OVER(ORDER BY Recency) AS RecencyRank,
    DENSE_RANK() OVER(ORDER BY Frequency DESC) AS FrequencyRank,
    DENSE_RANK() OVER(ORDER BY Monetary DESC) AS MonetaryRank
FROM rfm_table
~~~~
![image.png](attachment:image.png)

#### 3. RFM Score Table
<br>
Assigning RFM scores from 1 to 5 to customers based on their RFM ranks

~~~~sql
DROP VIEW IF EXISTS rfm_scores;
CREATE VIEW rfm_scores AS
WITH cte AS
(
SELECT
	CustomerID,
    DENSE_RANK() OVER(ORDER BY Recency) AS RecencyRank,
    DENSE_RANK() OVER(ORDER BY Frequency DESC) AS FrequencyRank,
    DENSE_RANK() OVER(ORDER BY Monetary DESC) AS MonetaryRank
FROM rfm_table
),
cte2 AS
(
SELECT
	*,
    MAX(RecencyRank) OVER() AS MaxR,
    MAX(FrequencyRank) OVER() AS MaxF,
    MAX(MonetaryRank) OVER() AS MaxM
FROM cte
),
cte3 AS
(
SELECT
	CustomerID,
	(CASE
		WHEN RecencyRank < 0.2*MaxR THEN 5
		WHEN RecencyRank >= 0.2*MaxR AND RecencyRank < 0.4*MaxR THEN 4
        WHEN RecencyRank >= 0.4*MaxR AND RecencyRank < 0.6*MaxR THEN 3
        WHEN RecencyRank >= 0.8*MaxR THEN 1
        ELSE 2 END) AS RScore,
	(CASE 
		WHEN FrequencyRank < 0.2*MaxF THEN 5
		WHEN FrequencyRank >= 0.2*MaxF AND FrequencyRank < 0.4*MaxF THEN 4
        WHEN FrequencyRank >= 0.4*MaxF AND FrequencyRank < 0.6*MaxF THEN 3
        WHEN FrequencyRank >= 0.8*MaxF THEN 1
        ELSE 2 END) AS FScore,
	(CASE 
		WHEN MonetaryRank < 0.2*MaxF THEN 5
		WHEN MonetaryRank >= 0.2*MaxF AND MonetaryRank < 0.4*MaxF THEN 4
        WHEN MonetaryRank >= 0.4*MaxF AND MonetaryRank < 0.6*MaxF THEN 3
        WHEN MonetaryRank >= 0.8*MaxF THEN 1
        ELSE 2 END) AS MScore
FROM cte2
)
SELECT
	*,
    CONCAT(RScore, FScore, MScore) AS RFMCell,
    Round((RScore + FScore + MScore)/3,1) AS RFMScore
FROM cte3
~~~~
![image-3.png](attachment:image-3.png)

#### 4. Checking the RFM Cell distribution
~~~~sql
SELECT 
	RFMCell,
    COUNT(RFMCell)
FROM project.rfm_scores
GROUP BY RFMCell
ORDER BY 2 DESC
~~~~
![image.png](attachment:image.png)

The top RFM cell is 511, those who place orders recently but have only placed a few orders and generated small revenues. They may be new customers or inactive customers who come back recently. For now, I call them recent customers.

#### 5. Setting up segmentation based on "RFMCell"
<br> Depending on the individual situation of each business. An example:

|RFMCell|Segment|Description|
|-------|-------|-----------|
|555|Core Customers|Best of the best|
|55[1-4]|Loyal Customers|Ordering frequently|
|5[2-4]5|Value Customers|large amounts and more frequent|
|54[2-4]|Promising Customers|More active than the average|
|5[1-2][1-3]|Recent Customers|Ordering recently|
|5[3-4][1-4]|Active Customers|Ordering recently and more frequently|
|4[2-3]1, 52[3-4]|Less Active Customers|Less recent and Less frequent|
|[2-3][1-2]1, 41[1-2]|Inactive Customers|Average orders with small amounts|
|[1-2][1-2]1|Hybernating Customers|Neither recent nor frequent|
|[4-5]1[4-5]|Large-Order Customers|Only few orders but large amounts|


~~~~sql
DROP VIEW IF EXISTS customer_segment;
CREATE VIEW customer_segment AS
SELECT
	*,
    (CASE 
        WHEN RFMCell LIKE '555' THEN 'Core Customer'
        WHEN RFMCell IN (551, 554, 553, 552) THEN 'Loyal Customer'
        WHEN RFMCell IN (545, 535, 525) THEN 'Value Customer'
        WHEN RFMCell IN (544, 543, 542) THEN 'Promising Customer'
        WHEN RFMCell IN (421, 431, 331, 524, 523) THEN 'Less Active Customer'
        WHEN RFMCell IN (511, 521, 522, 512, 513) THEN 'Recent Customer'
        WHEN RFMCell IN (531, 541, 532, 533, 534) THEN 'Active Customer'
        WHEN RFMCell IN (311, 321, 221, 412, 411) THEN 'Inactive Customer'
        WHEN RFMCell IN (211, 111, 121) THEN 'Hybernating Customer'
        WHEN RFMCell IN (514, 515, 414) THEN 'Large-Order Customer'
        ELSE 'Other Customers' END) AS Segment
	FROM rfm_scores
~~~~
![image-3.png](attachment:image-3.png)

#### 5. Adding customer segmentation columns back to the report
~~~~sql
DROP VIEW IF EXISTS report_segment;
CREATE VIEW report_segment AS
SELECT 
    r.* ,
    RFMCell,
    Segment
FROM report_clean r
LEFT JOIN customer_segment
USING(CustomerID)
~~~~
![image-2.png](attachment:image-2.png)

Now, we can combine all queries in the RFM analysis to create another stored procedure called "update_segmentation()." Whenever we have new transactions, we can CALL this procedure to update those customers' segments. I will skip this step because this data set will never update.

[Go back to the top](#top)

<a id="additional"></a>
# 9. Additional Analyses

* #### In which country does the company have more businesses?
~~~~sql
SELECT
    Country,
    COUNT(*) AS TotalOrders,
    SUM(TotalRevenue) AS TotalRevenues,
    COUNT(DISTINCT CustomerID) AS TotalCustomers,
    COUNT(DISTINCT StockCode) AS TotalProducts,
    COUNT(DISTINCT InvoiceDate) AS SalesPeriod,
    SUM(Segment = 'Core Customers') AS CoreCustomers
FROM report_segment
GROUP BY country
ORDER BY 3 DESC
~~~~
![image-3.png](attachment:image-3.png)

* #### Top 10 customers
~~~~sql
SELECT
    CustomerID,
    COUNT(*) AS TotalOrders,
    ROUND(SUM(TotalRevenue),2) AS TotalRevenues,
    COUNT(DISTINCT StockCode) AS TotalProducts,
    COUNT(DISTINCT InvoiceDate) AS RSDuration,
    Country,
    Segment
FROM report_segment
GROUP BY CustomerID
ORDER BY 3 DESC
LIMIT 1, 10 # Skipping the first row with NULL CustomerID
~~~~
![image-4.png](attachment:image-4.png)

* Although Netherlands is not the country that does the most business with the company, the customer who contributes the most revenue is located in Netherlands.
* Although value customers place fewer orders from the business, they still contribute many revenues.

* #### Top 10 ordered produts
~~~~sql
SELECT
	StockCode,
    COUNT(StockCode) AS OrderTimes,
    Description
FROM report_segment
GROUP BY StockCode
ORDER BY 2 DESC
LIMIT 10
~~~~
![image.png](attachment:image.png)

The champion is "White Hanging Heart T-Light Holder". Love is in the air!

* #### Which segment has the most customers and revenues?
~~~~sql
SELECT
    Segment,
    COUNT(DISTINCT CustomerID) AS TotalCustomers,
    COUNT(*) AS TotalOrders,
    ROUND(SUM(TotalRevenue),2) AS TotalRevenues,
    COUNT(DISTINCT StockCode) AS TotalProducts,
    COUNT(DISTINCT InvoiceDate) AS SalesPeriod,
    COUNT(DISTINCT Country) AS TotalRegion
FROM report_segment
WHERE Segment IS NOT NULL
GROUP BY segment
ORDER BY 2 DESC
~~~~
![image-3.png](attachment:image-3.png)

[Go back to the top](#top)

<a id="sharing2"></a>
# 10. Data Sharing Part II

<a id="dashboard2"></a>
### Dashboard 2
NOTE: compared to dashboard 1, I only imported the report with segmentation for dashboard 2 and used Power Query Editor and DAX language to manipulate the table for visualization. 
![image-4.png](attachment:image-4.png)
![image-3.png](attachment:image-3.png)
* The second dashboard reports both geographical segmentation and customer segmentation.
* The geographical segmentation table points out that the company has much more businesses in the United Kingdom than in other countries.
* The "customer segmentation vs revenue" chart shows that although there are only a few core and value customers, they contribute many revenues to the company. Therefore, the company should try its best not to lose these customers.
* Other than that, those recent customers are also very valuable, but this segmentation is vague; we don't know whether they are new customers or those who just happen to place an order recently. We need techniques beyond RFM analysis to solve this problem.

### Interaction with the dashboard
![image-3.png](attachment:image-3.png)
* By clicking the countries in the geographical map or the rows, we could view the customer segmentation based on countries. 
* As the dashboard shows, the largest customer segment of the United Kingdom is "value customer" and they contribute the most revenues.
* The geography map in this dashboard is more aesthetic than practical. I am ready to replace it with other charts as needed by the stakeholders.

[Go back to the top](#top)

<a id="summary2"></a>
# 11. Summary II 
* With MySQL and Power BI, it is easy to refresh the data source and update the dashboard with new e-commerce transactions.
* Updating dashboard 2 is easier than updating dashboard 1 because the query and visualization were both performed in Power BI for dashboard 2; meanwhile, the query was performed in MySQL for dashboard 1. 
* For the same reason, dashboard 2 has more interactions on the charts and maps.
* For automation purpose, it is easier to use Python than MySQL or Power BI. The libraries in Python have already had many "stored procedures"(functions) to speed the coding process. For example, MySQL does not even have a PIVOT command.
* RFM segmentation has its limitation. We still need techniques like K-mean Clustering to improve our segmentation. That would be another Python project.

Thank you for reading!
