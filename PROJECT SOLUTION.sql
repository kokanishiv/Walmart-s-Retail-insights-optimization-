/*Task 1:Identifying the Top Branch by Sales Growth Rate.*/
WITH MonthlySales AS (
    SELECT Branch, DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m') AS Month,
        SUM(Total) AS TotalSales
    FROM walmartsales
    GROUP BY Branch, Month
),
SalesGrowth AS (
    SELECT Branch, Month, TotalSales, 
    LAG(TotalSales) OVER (PARTITION BY Branch ORDER BY Month) AS PrevMonthSales,
        ROUND(
            (TotalSales - LAG(TotalSales) OVER (PARTITION BY Branch ORDER BY Month)) 
            / LAG(TotalSales) OVER (PARTITION BY Branch ORDER BY Month) * 100, 2
        ) AS GrowthRate
    FROM MonthlySales
)
SELECT Branch, ROUND(AVG(GrowthRate), 2) AS AvgMonthlyGrowthRate
FROM SalesGrowth
WHERE GrowthRate IS NOT NULL
GROUP BY Branch
ORDER BY AvgMonthlyGrowthRate DESC
LIMIT 1;

/*TASK 2: Finding the Most Profitable Product Line for Each Branch*/
WITH ProductProfit AS (
    SELECT Branch, `Product line`, SUM(`gross income`) AS TotalProfit
    FROM walmartsales
    GROUP BY Branch, `Product line`
),
RankedProfit AS (
    SELECT *, RANK() OVER (PARTITION BY Branch ORDER BY TotalProfit DESC) AS rnk
    FROM ProductProfit
)
SELECT
    Branch, `Product line`, ROUND(TotalProfit, 2) AS TotalProfit
FROM RankedProfit
WHERE rnk = 1;

/*TASK 3: Analyzing Customer Segmentation Based on Spending*/
WITH CustomerSpending AS (
    SELECT `Customer ID`, SUM(Total) AS TotalSpent
    FROM walmartsales
    GROUP BY `Customer ID`
),
RankedSpenders AS (
    SELECT `Customer ID`, TotalSpent, NTILE(4) OVER (ORDER BY TotalSpent DESC) AS SpendQuartile
    FROM CustomerSpending
)
SELECT `Customer ID`, TotalSpent,
    CASE 
        WHEN SpendQuartile = 1 THEN 'High Spender'
        WHEN SpendQuartile IN (2, 3) THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS CustomerSegment
FROM RankedSpenders;

/*TASK 4: Detecting Anomalies in Sales Transactions*/
WITH AvgSales AS (
    SELECT `Product line`, AVG(Total) AS AvgTotal
    FROM walmartsales
    GROUP BY `Product line`
)
SELECT w.*, ROUND(a.AvgTotal, 2) AS AvgSale,
    CASE
        WHEN w.Total > 2 * a.AvgTotal THEN 'High Anomaly'
        WHEN w.Total < 0.5 * a.AvgTotal THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS AnomalyFlag
FROM walmartsales w
JOIN AvgSales a ON w.`Product line` = a.`Product line`
WHERE w.Total > 2 * a.AvgTotal OR w.Total < 0.5 * a.AvgTotal;

/*Task 5: Most Popular Payment Method by City */
WITH Payment_Counts AS (
  SELECT City, Payment, COUNT(*) AS Count,
         RANK() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) AS rnk
  FROM walmartsales
  GROUP BY City, Payment
)
SELECT City, Payment, Count
FROM Payment_Counts
WHERE rnk = 1;

/*Task 6: Monthly Sales Distribution by Gender*/
SELECT 
    EXTRACT(MONTH FROM STR_TO_DATE(`Date`, '%d-%m-%Y')) AS Month,
    Gender,
    ROUND(SUM(Total),2) AS MonthlySales
FROM walmartsales
GROUP BY Month, Gender
ORDER BY  Month, Gender;


/*Task 7: Best Product Line by Customer Type*/
WITH ProductSales AS (
  SELECT  `Customer type`, `Product line`, SUM(Total) AS TotalSpent
  FROM walmartsales
  GROUP BY `Customer type`, `Product line`
),
ProductPreference AS (
  SELECT `Customer type`, `Product line`, TotalSpent,
    RANK() OVER (PARTITION BY `Customer type` ORDER BY TotalSpent DESC) AS rnk
  FROM ProductSales
)
SELECT * 
FROM ProductPreference 
WHERE rnk = 1;

/*Task 8: Identifying Repeat Customers (within 30 days)*/
SELECT DISTINCT 
    s1.`Customer ID`, 
    STR_TO_DATE(s1.`Date`, '%d-%m-%Y') AS FirstPurchaseDate,
    STR_TO_DATE(s2.`Date`, '%d-%m-%Y') AS RepeatPurchaseDate,
    DATEDIFF(STR_TO_DATE(s2.`Date`, '%d-%m-%Y'), STR_TO_DATE(s1.`Date`, '%d-%m-%Y')) AS DaysBetween
FROM walmartsales s1
JOIN walmartsales s2 
    ON s1.`Customer ID` = s2.`Customer ID`
WHERE 
    STR_TO_DATE(s1.`Date`, '%d-%m-%Y') < STR_TO_DATE(s2.`Date`, '%d-%m-%Y')
    AND DATEDIFF(
        STR_TO_DATE(s2.`Date`, '%d-%m-%Y'),
        STR_TO_DATE(s1.`Date`, '%d-%m-%Y')
    ) <= 30
ORDER BY s1.`Customer ID`, FirstPurchaseDate;

/*Task 9: Finding Top 5 Customers by Sales Volume*/
SELECT 
    `Customer ID`,
    ROUND(SUM(Total),2) AS TotalSales
FROM walmartsales
GROUP BY `Customer ID`
ORDER BY TotalSales DESC
LIMIT 5;

/*Task 10: Analyzing Sales Trends by Day of the Week*/
SELECT 
    DAYNAME(STR_TO_DATE(`Date`, '%d-%m-%Y')) AS DayOfWeek,
   ROUND(SUM(Total),2) AS TotalSales
FROM walmartsales
GROUP BY DayOfWeek
ORDER BY TotalSales DESC;




