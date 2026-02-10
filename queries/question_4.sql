SELECT c.r_name AS region,
AVG(l.l_discount) AS avg_discount,
SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
FROM DIMLINEITEM l
INNER JOIN FACTORDER o
ON l.l_orderkey = o.o_orderkey
INNER JOIN DIMCUSTOMER c
ON o.o_custkey = c.c_custkey
GROUP BY c.r_name
ORDER BY avg_discount DESC;