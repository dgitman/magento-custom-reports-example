SELECT
	city,
	count(city) AS Orders
FROM
	sales_flat_order_address
INNER JOIN sales_flat_order ON sales_flat_order_address.parent_id = sales_flat_order.entity_id
INNER JOIN directory_country_region ON directory_country_region.region_id = sales_flat_order_address.region_id
WHERE
	address_type = 'billing'
AND sales_flat_order_address.country_id = 'US'
GROUP BY
	city
HAVING
	count(city) > 100
ORDER BY
	Orders DESC