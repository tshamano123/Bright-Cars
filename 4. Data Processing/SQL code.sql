WITH base_data AS (
  SELECT
    vin,
    state,
    make,
    odometer,
    model,

    -- Correct parsing for your format
    TRY_TO_TIMESTAMP(sale_date, 'dd MMMM yyyy') AS sale_timestamp,

    YEAR(TRY_TO_TIMESTAMP(sale_date, 'dd MMMM yyyy')) AS sale_year,
    QUARTER(TRY_TO_TIMESTAMP(sale_date, 'dd MMMM yyyy')) AS sale_quarter,
    MONTH(TRY_TO_TIMESTAMP(sale_date, 'dd MMMM yyyy')) AS sale_month,

    TRY_CAST(
      REGEXP_REPLACE(sellingprice, '[^0-9.]', '') AS DOUBLE
    ) AS sellingprice_numeric,

    mmr
  FROM workspace.default.car_sales_Clean_table
  WHERE mmr > 0
),

aggregated_data AS (
  SELECT
    sale_year,
    sale_quarter,
    sale_month,
    state,
    make,
    model,
    
   COUNT(DISTINCT vin) AS units_sold,
    SUM(sellingprice_numeric) AS total_revenue,
    Round(AVG(sellingprice_numeric), 2) AS Avg_price,
    ROUND(AVG(odometer), 0) AS avg_odometer, 
    SUM(mmr) AS total_mmr

  FROM base_data
  WHERE sellingprice_numeric > 0

  GROUP BY
    sale_year,
    sale_quarter,
    sale_month,
    state,
    make,
    model
)

SELECT
  sale_year AS manufacturing_year,
  sale_quarter,
  sale_month,
  state,
  make,
  model,
  units_sold,
  total_revenue,
  avg_price,
  avg_odometer,

  ROUND(
    CASE 
      WHEN total_revenue = 0 THEN 0
      ELSE (total_revenue - total_mmr) / total_revenue * 100
    END,
    2
  ) AS profit_margin_pct,

  CASE
    WHEN total_revenue = 0 THEN 'No Revenue'
    WHEN (total_revenue - total_mmr) / total_revenue >= 0.20 THEN 'High Margin'
    WHEN (total_revenue - total_mmr) / total_revenue >= 0.10 THEN 'Medium Margin'
    ELSE 'Low Margin'
  END AS performance_tier

FROM aggregated_data

ORDER BY
  sale_year,
  sale_quarter,
  sale_month,
  total_revenue DESC;
