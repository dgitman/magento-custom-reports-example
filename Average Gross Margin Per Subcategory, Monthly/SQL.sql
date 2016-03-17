select
  `category` as 'Category',
  `subcategory` as 'SubCategory',
  max(if(`date`='08-2014',`MarginPct`,NULL)) as `08-2014 (Margin %)`,
  max(if(`date`='08-2014',`TotalSales`,NULL)) as `08-2014 (Total Sales)`,
  max(if(`date`='09-2014',`MarginPct`,NULL)) as `09-2014 (Margin %)`,
  max(if(`date`='09-2014',`TotalSales`,NULL)) as `09-2014 (Total Sales)`,
  max(if(`date`='10-2014',`MarginPct`,NULL)) as `10-2014 (Margin %)`,
  max(if(`date`='10-2014',`TotalSales`,NULL)) as `10-2014 (Total Sales)`,
  max(if(`date`='11-2014',`MarginPct`,NULL)) as `11-2014 (Margin %)`,
  max(if(`date`='11-2014',`TotalSales`,NULL)) as `11-2014 (Total Sales)`,
  max(if(`date`='12-2014',`MarginPct`,NULL)) as `12-2014 (Margin %)`,
  max(if(`date`='12-2014',`TotalSales`,NULL)) as `12-2014 (Total Sales)`,
  max(if(`date`='01-2015',`MarginPct`,NULL)) as `01-2015 (Margin %)`,
  max(if(`date`='01-2015',`TotalSales`,NULL)) as `01-2015 (Total Sales)`,
  max(if(`date`='02-2015',`MarginPct`,NULL)) as `02-2015 (Margin %)`,
  max(if(`date`='02-2015',`TotalSales`,NULL)) as `02-2015 (Total Sales)`,
  max(if(`date`='03-2015',`MarginPct`,NULL)) as `03-2015 (Margin %)`,
  max(if(`date`='03-2015',`TotalSales`,NULL)) as `03-2015 (Total Sales)`,
  max(if(`date`='04-2015',`MarginPct`,NULL)) as `04-2015 (Margin %)`,
  max(if(`date`='04-2015',`TotalSales`,NULL)) as `04-2015 (Total Sales)`,
  max(if(`date`='05-2015',`MarginPct`,NULL)) as `05-2015 (Margin %)`,
  max(if(`date`='05-2015',`TotalSales`,NULL)) as `05-2015 (Total Sales)`,
  max(if(`date`='06-2015',`MarginPct`,NULL)) as `06-2015 (Margin %)`,
  max(if(`date`='06-2015',`TotalSales`,NULL)) as `06-2015 (Total Sales)`,
  max(if(`date`='07-2015',`MarginPct`,NULL)) as `07-2015 (Margin %)`,
  max(if(`date`='07-2015',`TotalSales`,NULL)) as `07-2015 (Total Sales)`
from (
  select
    `data`.`category`,
    `data`.`subcategory`,
    `dates`.`date`,
    sum(case when `data`.`date`=`dates`.`date` then `data`.`MarginPct` else 0 end) as `MarginPct`,
    sum(case when `data`.`date`=`dates`.`date` then `data`.`TotalSales` else 0 end) as `TotalSales`
  from (
    select
      c.`category`,
      c.`subcategory`,
      date_format(o.`created_at`, '%m-%Y') as 'date',
      100*round(avg((( i.`qty_ordered`*(o.`shipping_amt`+i.`base_price`) - i.`qty_ordered`*(o.`freight`+i.`base_cost`*0.9))) / (i.`qty_ordered`*(o.`shipping_amt`+i.`base_price`))), 4) as 'MarginPct',
      round(sum((o.`shipping_amt` + i.`base_price`)), 2) as 'TotalSales'
    from (
      select
        o.`entity_id`,
        o.`created_at`,
        ifnull(o.`shipping_amount` / (select sum(`qty_ordered`) from sales_flat_order_item where `order_id` = o.`entity_id`), 0) as 'shipping_amt',
        ifnull(o.`pa_shipping_invoiced` / (select sum(`qty_ordered`) from sales_flat_order_item where `order_id` = o.`entity_id`), 0) as 'freight'
      from sales_flat_order o
    ) as o
    left join sales_flat_order_item i on o.`entity_id` = i.`order_id`
    left join catalog_category_product cp on cp.`product_id` = i.`product_id`
    left join (
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
    group by c.`category`, c.`subcategory`, year(o.`created_at`), month(o.`created_at`)
  ) as `data`, (
    select
      @m := @m + 1 as `m`,
      date_format(timestampadd(month, @m, '2014-08-20'), '%m-%Y') as `date`
    from `sales_flat_order_item`, (
    select @m := -1
    ) as `m`
    where @m < timestampdiff(month, '2014-08-20', '2015-07-20')
  ) as `dates`
  group by `data`.`category`, `data`.`subcategory`, `dates`.`date`
) as `t`
where `category`  is not null
group by `category`, `subcategory`
order by `category`, `subcategory`