use ecommerce;



SET SQL_SAFE_UPDATES = 0;
ALTER TABLE orders ADD COLUMN NewOrderDate DATE;
UPDATE orders 
SET NewOrderDate = STR_TO_DATE(OrderDate, '%d/%m/%Y');
ALTER TABLE orders ADD COLUMN NewDeliveryDate DATE;
UPDATE orders 
SET NewDeliveryDate = STR_TO_DATE(`Delivery Date`, '%d/%m/%Y');

use ecommerce;

-- OBJECTIVE ANSWER 14



WITH CustomerMetrics AS (
    SELECT 
        c.`CustomerID`,
        SUM(o.`Sale Price`) OVER (PARTITION BY c.`CustomerID`) AS TotalRevenue,
        COUNT(o.`OrderID`) OVER (PARTITION BY c.`CustomerID`) AS OrderFrequency,
        AVG(o.`Sale Price`) OVER (PARTITION BY c.`CustomerID`) AS AverageOrderValue
    FROM customers c
    JOIN orders o ON c.`CustomerID` = o.`CustomerID`
)
SELECT DISTINCT 
    `CustomerID`,
    TotalRevenue,
    OrderFrequency,
    AverageOrderValue,
    (TotalRevenue * 0.5 + OrderFrequency * 0.3 + AverageOrderValue * 0.2) AS CompositeScore
FROM CustomerMetrics
ORDER BY CompositeScore DESC
LIMIT 5;


-- OBJECTIVE ANSWER 15

WITH MonthlyRevenue AS (
    SELECT 
        EXTRACT(YEAR FROM NewOrderDate) AS Year,
        EXTRACT(MONTH FROM NewOrderDate) AS Month,
        SUM(`Sale Price`) AS TotalRevenue
    FROM orders
    GROUP BY Year, Month
)
SELECT 
    Year, 
    Month, 
    TotalRevenue,
    (TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY Year, Month)) / 
    LAG(TotalRevenue) OVER (ORDER BY Year, Month) * 100 AS MoMGrowthRate
FROM MonthlyRevenue
ORDER BY Year, Month;

-- OBJECTIVE ANSWER 16


WITH MonthlyRevenue AS (
    SELECT 
        EXTRACT(YEAR FROM NewOrderDate) AS Year,
        EXTRACT(MONTH FROM NewOrderDate) AS Month,
        `Product Category` AS ProductCategory,
        SUM(`Sale Price`) AS TotalRevenue
    FROM orders
    GROUP BY Year, Month, `Product Category`
)
SELECT 
    Year, 
    Month, 
    ProductCategory,
    AVG(TotalRevenue) OVER (
        PARTITION BY ProductCategory 
        ORDER BY Year, Month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Rolling3MonthAvgRevenue
FROM MonthlyRevenue
ORDER BY Year, Month;

-- OBJECTIVE ANSWER 17

UPDATE orders
SET `Sale Price` = `Sale Price` * 0.85
WHERE CustomerID IN (
    SELECT CustomerID
    FROM orders
    GROUP BY CustomerID
    HAVING COUNT(OrderID) >= 10
);



-- OBJECTIVE ANSWER 18

WITH CustomerOrders AS (
    SELECT CustomerID, OrderID, `NewOrderDate`,
           LEAD(`NewOrderDate`) OVER (PARTITION BY CustomerID ORDER BY `NewOrderDate`) AS NextOrderDate
    FROM orders
)
SELECT CustomerID, AVG(DATEDIFF(NextOrderDate, `NewOrderDate`)) AS AvgDaysBetweenOrders
FROM CustomerOrders
WHERE NextOrderDate IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(OrderID) >= 5;


-- OBJECTIVE ANSWER 19
WITH TotalCustomerRevenue AS (
    SELECT CustomerID, SUM(`Sale Price`) AS TotalRevenue
    FROM orders
    GROUP BY CustomerID
),
AverageRevenue AS (
    SELECT AVG(`Sale Price`) AS AvgRevenue FROM orders
)
SELECT t.CustomerID, t.TotalRevenue
FROM TotalCustomerRevenue t, AverageRevenue a
WHERE t.TotalRevenue > a.AvgRevenue * 1.30;

-- OBJECTIVE ANSWER 20

SELECT 
    a.`Product Category`,
    a.TotalSales AS CurrentYearSales,
    b.TotalSales AS PreviousYearSales,
    a.TotalSales - b.TotalSales AS SalesIncrease
FROM 
    (SELECT `Product Category`, SUM(`Sale Price`) AS TotalSales
     FROM orders
     WHERE YEAR(`NewOrderDate`) = 2020  
     GROUP BY `Product Category`) AS a  
JOIN 
    (SELECT `Product Category`, SUM(`Sale Price`) AS TotalSales
     FROM orders
     WHERE YEAR(`NewOrderDate`) = 2019 
     GROUP BY `Product Category`) AS b  
ON a.`Product Category` = b.`Product Category`
ORDER BY SalesIncrease DESC 
LIMIT 3;









