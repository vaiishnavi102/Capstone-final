{{ config(
    materialized = 'view',
   
) }}

/*
   ============================================================
   INVENTORY TURNOVER DETAIL
   ============================================================

   This view presents product-level inventory turnover
   information by store and date. It combines inventory
   measures with product, store, and date attributes
   for reporting and analysis.
*/

SELECT

    /*
       PRODUCT INFORMATION

       Retrieve product identifiers and descriptive
       attributes from the product dimension.
    */

    fi.product_key,

    dp.product_id,
    dp.product_name,
    dp.category,
    dp.subcategory,


    /*
       STORE INFORMATION

       Include the store associated with the inventory
       snapshot.
    */

    fi.store_key,

    ds.store_id,
    ds.store_name,


    /*
       DATE INFORMATION

       Connect the inventory record with the
       corresponding calendar date.
    */

    fi.date_key,

    dd.full_date,


    /*
       INVENTORY MOVEMENT MEASURES

       These fields represent sales movement and
       stock levels for the product at the store.
    */

    fi.sold_quantity,

    fi.beginning_stock,

    fi.ending_stock,


    /*
       STOCK TURNOVER

       Represents the calculated inventory turnover
       ratio for the product and store.
    */

    fi.stock_turnover_ratio,


    /*
       TURNOVER CATEGORY

       Classify each inventory record according to
       the available stock turnover ratio.

       NULL values indicate that turnover data
       is unavailable.

       A zero ratio represents no inventory movement.

       Ratios of one or greater indicate high turnover.

       Remaining positive ratios are classified
       as low turnover.
    */

    CASE

        WHEN fi.stock_turnover_ratio IS NULL
            THEN 'No Turnover Data'

        WHEN fi.stock_turnover_ratio = 0
            THEN 'No Movement'

        WHEN fi.stock_turnover_ratio >= 1
            THEN 'High Turnover'

        ELSE 'Low Turnover'

    END AS turnover_category


/*
   INVENTORY FACT TABLE

   Fact_Inventory provides the inventory snapshot
   measures used in this reporting view.
*/

FROM {{ ref('fact_inventory') }} fi


/*
   PRODUCT DIMENSION

   Match inventory records with their corresponding
   product details using product_key.
*/

LEFT JOIN {{ ref('dim_product') }} dp

    ON fi.product_key =
       dp.product_key


/*
   STORE DIMENSION

   Match each inventory record to the appropriate
   store using store_key.
*/

LEFT JOIN {{ ref('dim_store') }} ds

    ON fi.store_key =
       ds.store_key


/*
   DATE DIMENSION

   Add the calendar date associated with each
   inventory snapshot.
*/

LEFT JOIN {{ ref('dim_date') }} dd

    ON fi.date_key =
       dd.date_key