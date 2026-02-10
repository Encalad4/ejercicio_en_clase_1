SELECT YEAR(f.o_orderdate) AS year,
MONTH(f.o_orderdate) AS month,
c.r_name AS REGION,
SUM(f.o_totalprice) AS net_revenue
FROM FACTORDER f
INNER JOIN DIMCUSTOMER c
ON f.o_custkey = c.c_custkey
GROUP BY YEAR(f.o_orderdate),
MONTH(f.o_orderdate),
REGION
ORDER BY
year,
month,
region;