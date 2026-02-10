SELECT p.p_brand, p.p_mfgr AS manufacturer,
SUM(p.l_quantity) AS units_sold,
SUM(p.L_EXTENDEDPRICE * (1 - p.L_DISCOUNT) * (1 + p.l_tax )) AS net_revenue
FROM DIMLINEITEM AS p
GROUP BY p.p_brand, manufacturer
ORDER BY units_sold DESC
LIMIT 15;