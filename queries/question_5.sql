SELECT l.l_shipmode AS ship_mode,
AVG(DATEDIFF('day', o.o_orderdate, l.l_shipdate)) AS avg_dispatch_days,
SUM(l.l_quantity) AS total_units_shipped
FROM DIMLINEITEM l
INNER JOIN FACTORDER o
ON l.l_orderkey = o.o_orderkey
GROUP BY l.l_shipmode
ORDER BY total_units_shipped DESC;