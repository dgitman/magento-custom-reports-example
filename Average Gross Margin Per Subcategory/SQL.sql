select
  c.`category` as 'Category',
  c.`subcategory` as 'SubCategory',
  #date_format(o.`created_at`, '%m/%Y') as 'Month/Year',
  100 * round(avg((( i.`qty_ordered` * (o.`shipping_amt`+i.`base_price`) - i.`qty_ordered` * (o.`freight`+i.`base_cost`*0.9))) / (i.`qty_ordered` * (o.`shipping_amt`+i.`base_price`))), 4) as 'MarginPct',
  round(sum((o.`shipping_amt` + i.`base_price`)), 2) as `TotalSales`
from (
  select
    o.`entity_id`,
    o.`created_at`,
    ifnull(o.`shipping_amount` / (select sum(`qty_ordered`) from sales_flat_order_item where `order_id` = o.`entity_id`), 0) as 'shipping_amt',
    ifnull(o.`pa_shipping_invoiced` / (select sum(`qty_ordered`) from sales_flat_order_item where `order_id` = o.`entity_id`), 0) as 'freight'
  from sales_flat_order o
) as o
join sales_flat_order_item i on o.`entity_id` = i.`order_id`
join catalog_category_product cp on cp.`product_id` = i.`product_id`
join (
  select
    cat.`category_id`,
    cat.`category`,
    subcat.`subcategory_id`,
    subcat.`subcategory`
  from (
    select
      c.`entity_id` as 'category_id',
      cv.`value` as 'category'
    from catalog_category_entity c
    join catalog_category_entity_varchar cv on c.`entity_id` = cv.`entity_id`
    and c.`level` = 2
    and cv.`value` != 'Brands'
    and cv.`attribute_id` = (
     select
      `attribute_id`
     from eav_attribute
     where `entity_type_id` = 3
     and `attribute_code` = 'name'
    )
  ) as cat
  left join (
    select
      c.`parent_id` as 'category_id',
      c.`entity_id` as 'subcategory_id',
      cv.`value` as 'subcategory'
    from catalog_category_entity c
    join catalog_category_entity_varchar cv on c.`entity_id` = cv.`entity_id`
    and c.`level` = 3
    and cv.`attribute_id` = (
     select
      `attribute_id`
     from eav_attribute
     where `entity_type_id` = 3
     and `attribute_code` = 'name'
    )
  ) as subcat on subcat.`category_id` = cat.`category_id`
) c on c.`subcategory_id` = cp.`category_id`
where (o.`shipping_amt` + i.`base_price`) >= (o.`freight` + i.`base_cost` * 0.9)
group by c.`category`, c.`subcategory`#, year(o.`created_at`), month(o.`created_at`)
order by c.`category`, c.`subcategory`#, year(o.`created_at`), month(o.`created_at`)