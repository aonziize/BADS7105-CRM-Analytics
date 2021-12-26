WITH data_ AS (SELECT CUST_CODE,
DATE_TRUNC(SHOP_DATE2,month) AS MONTH_
FROM
(SELECT 
PARSE_DATE('%Y%m%d', CAST(SHOP_DATE AS STRING)) AS SHOP_DATE2,
CUST_CODE
 FROM `aonz_data.SuperMarket.data`
 WHERE CUST_CODE IS NOT NULL) 
 GROUP BY 1,2) 

,data_2 AS (SELECT 
MONTH_M,
MONTH_,
REGISTER_DATE,
CUST_CODE
FROM
(SELECT 
DISTINCT MONTH_ AS MONTH_M
FROM
data_) A
 LEFT JOIN
(SELECT 
*
FROM
data_ A1
 RIGHT JOIN 
--  REGISTER
(SELECT 
CUST_CODE AS CUST_CODE_RE ,MIN(MONTH_) as REGISTER_DATE
FROM
-- MAIN
data_
 GROUP BY 1) A2
 ON A1.CUST_CODE = A2.CUST_CODE_RE) B 
 ON A.MONTH_M = B.MONTH_)


SELECT 
    MONTH_M,
    F_CUST,
    CASE WHEN F_CUST = 'CHURN' THEN (-1)*cust ELSE cust END AS CUST
FROM
(
    
    SELECT
    MONTH_M,
    F_CUST,
    count(distinct CUST_CODE) as cust
FROM
(
SELECT * FROM
  -- NEW,REPEAT,REACTIVATE  
  (SELECT
    MONTH_M,
    CUST_CODE,
    REGISTER_DATE,
    DATE_DIFF(MONTH_, PRE_M, MONTH) AS R,
    CASE    
         WHEN MONTH_ = REGISTER_DATE THEN 'NEW'
         WHEN DATE_DIFF(MONTH_,PRE_M, MONTH) =1 THEN 'REPEAT'
         WHEN DATE_DIFF(MONTH_,PRE_M, MONTH) >1 THEN 'REACTIVATE'
     END AS F_CUST
FROM
(SELECT
    CUST_CODE,
    MONTH_M,
    MONTH_,
    REGISTER_DATE,
 LAG(MONTH_) OVER (PARTITION BY CUST_CODE ORDER BY MONTH_) AS PRE_M
FROM
data_2))
UNION ALL 
-- CHURN
(SELECT 
    MONTH_M,
    CUST_CODE,
    REGISTER_DATE,
    R,
    F_CUST
FROM
(SELECT 
    CUST_CODE,
    F_CUST,
    REGISTER_DATE,
    NULL as R,
    MIN(CASE WHEN F_CUST = 'CHURN' THEN MONTH_M END) AS MONTH_M
FROM 
(SELECT *,
CASE WHEN MONTH_M > LAST_DATE THEN 'CHURN' END AS F_CUST
FROM
(SELECT 
1 AS KEY, MONTH_ AS MONTH_M
FROM
data_ 
GROUP BY 1,2) A
 LEFT JOIN
(SELECT 
1 AS KEY,*
FROM
data_ A1
 RIGHT JOIN 
(SELECT 
CUST_CODE AS CUST_CODE_RE ,MIN(MONTH_) as REGISTER_DATE,MAX(MONTH_) as LAST_DATE
FROM
data_
 GROUP BY 1) A2
 ON A1.CUST_CODE = A2.CUST_CODE_RE) B 
 ON A.KEY = B.KEY)
GROUP BY 1,2,3)
WHERE F_CUST IS NOT NULL)
)
GROUP BY 1,2 )
order by 1 asc
