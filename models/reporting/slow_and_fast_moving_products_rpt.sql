{{ config(
    materialized = 'view',
   
) }}

/*
   ============================================================
   PRODUCT TURNOVER ANALYSIS
   ============================================================

   This view summarizes product sales movement, stock turnover,
   and inventory value. Products are later classified into
   movement categories based on their turnover quartile.
*/

WITH product_turnover AS (

    /*
       ========================================================
       PRODUCT TURNOVER SUMMARY
       ========================================================

       Calculate total quantity sold, average stock turnover,
       and total inventory value for each product.
    */

    SELECT

        fi.product_key,

        dp.product_id,
        dp.product_name,
        dp.category,
        dp.subcategory,


        /*
           TOTAL QUANTITY SOLD

           Represents the total number of units sold
           for the product across all inventory records.
        */

        SUM(
            fi.sold_quantity
        ) AS total_sold_quantity,


        /*
           AVERAGE STOCK TURNOVER

           Measures how efficiently inventory is being
           converted through product sales.
        */

        AVG(
            fi.stock_turnover_ratio
        ) AS average_stock_turnover_ratio,


        /*
           TOTAL INVENTORY VALUE

           Represents the combined inventory value
           recorded for the product.
        */

        SUM(
            fi.inventory_value
        ) AS total_inventory_value


    FROM {{ ref('fact_inventory') }} fi


    /*
       PRODUCT DIMENSION

       Connect inventory records with product attributes
       using the product surrogate key.
    */

    LEFT JOIN {{ ref('dim_product') }} dp

        ON fi.product_key =
           dp.product_key


    /*
       PRODUCT-LEVEL AGGREGATION
    */

    GROUP BY

        fi.product_key,
        dp.product_id,
        dp.product_name,
        dp.category,
        dp.subcategory

),


/*
   ============================================================
   TURNOVER CLASSIFICATION
   ============================================================

   Divide products into four groups based on their
   average stock turnover ratio.
*/

classified AS (

    SELECT

        *,


        /*
           TURNOVER QUARTILE

           NTILE(4) divides products into four equally
           distributed turnover groups.
        */

        NTILE(4) OVER (
            ORDER BY
                average_stock_turnover_ratio
        ) AS turnover_quartile


    FROM product_turnover

)


/*
   ============================================================
   FINAL PRODUCT MOVEMENT OUTPUT
   ============================================================

   Assign a business-friendly movement category to
   each product based on its turnover performance.
*/

SELECT

    product_key,
    product_id,
    product_name,
    category,
    subcategory,

    total_sold_quantity,
    average_stock_turnover_ratio,
    total_inventory_value,


    /*
       PRODUCT MOVEMENT CATEGORY

       Products without turnover are marked as
       'No Movement'.

       The lowest turnover quartile is classified
       as 'Slow-Moving'.

       The highest turnover quartile is classified
       as 'Fast-Moving'.

       Remaining products are classified as
       'Medium-Moving'.
    */

    CASE

        WHEN average_stock_turnover_ratio IS NULL
            THEN 'No Movement'

        WHEN turnover_quartile = 1
            THEN 'Slow-Moving'

        WHEN turnover_quartile = 4
            THEN 'Fast-Moving'

        ELSE 'Medium-Moving'

    END AS product_movement_category


FROM classified