# Customer Cohort and RFM Automation with MySQL and Power BI
Aaron Xie
___

# The Problem
Customer retention and churn rates are important for businesses to have sustainable revenues, especially for e-commerce businesses. The retention rate of e-commerce is not as obvious as those businesses that rely on subscriptions. Subscription businesses can easily find those who unsubscribe, but e-commerce businesses only have sales reports with a large amount of transactions. This difference raises the questions: 
* How can the e-commerce business keep track of customer retention easily? 
* How can they create the customer segmentation of the business for improving the retention rate?
* Can they use MySQL and/or Power BI to automate these processes?

# The Goal
* Use SQL language to extract tables from the database to conduct cohort, trending, and RFM analysis.
* Connect Power BI to MySQL database and visualize the data analyses results on dashboards.
* Use the stored procedure function of MySQL and Power BI to automate the cohort and trending analyses.
* Use the Power Query Editor and DAX language in Power BI to automate RFM analysis.
* This project is for exploring the probability of MySQL and Power BI, so don't use Python!

# The Data Set
This project uses a Online Retail [Data Set](https://archive.ics.uci.edu/ml/datasets/online+retail) from the UCI Machine Learning Repository
___
# Files
* [Main_File.ipynb](https://github.com/aaronxxie/Cohort-RFM-MySQL/blob/main/Main_File.ipynb) The main project file in a notebook
* [MySQL_Codes.md](https://github.com/aaronxxie/Cohort-RFM-MySQL/blob/main/MySQL_Codes.md) Markdown file for easier code reading
* [Dashboard_File.pbix](https://github.com/aaronxxie/Cohort-RFM-MySQL/blob/main/Dashboard_File.pbix) Power BI file
* [Dashboard_1.jpg](https://github.com/aaronxxie/Cohort-RFM-MySQL/blob/main/Dashboard_1.jpg)
* [Dashboard_2.jpg](https://github.com/aaronxxie/Cohort-RFM-MySQL/blob/main/Dashboard_2.jpg)
* [MySQL_Procedures](https://github.com/aaronxxie/Cohort-RFM-MySQL/tree/main/MySQL_Procedures)
___
# Table of Contents
1. The Problem
    1. The Goal
2. Data Preparation
3. Data Processing
    1. Dataset Basic Info
    2. Removing Duplicate Rows
    3. Dealing with missing values
    4. Detecting Anormal Values/Outliers

#### Data Analysis Part I
4. Cohort Analysis
    1. Cohort Analysis by Countries
5. Trending Analysis
6. Data Sharing I
    1. Dashboard 1
7. Summary I

#### Data Analysis Part II
8. RFM Analysis
9. Additional Analysis
10. Data Sharing II
    1. Dashboard 2
11. Summary II
___
# Dashboards
![Dashboard 1](https://github.com/aaronxxie/cohort-RFM-MySQL/blob/main/Dashboard_1.jpg?raw=true)
![Dashboard 2](https://github.com/aaronxxie/Cohort-RFM-MySQL/blob/main/Dashboard_2.jpg?raw=true)
___
All files are my original work; sharing is not permitted.
