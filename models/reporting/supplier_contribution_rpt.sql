{{ config(
    materialized = 'view',
    
) }}

/*
   ============================================================
   SUPPLIER CATEGORY CONTRIBUTION
   ============================================================

   This view measures the quantity purchased from each supplier
   within every product category. It also calculates the supplier's
   percentage contribution to the total purchased quantity of
   that category.
*/

WITH supplier_category AS (

    /*
       ========================================================
       SUPPLIER AND CATEGORY PURCHASE SUMMARY
       ========================================================

       Aggregate purchased quantities by supplier, product,
       and product category while retaining the related
       descriptive attributes.
    */

    SELECT

        fi.supplier_key,

        dsp.supplier_id,
        dsp.supplier_name,

        fi.product_key,

        dp.product_id,
        dp.product_name,
        dp.category,


        /*
           SUPPLIER PURCHASED QUANTITY

           Total quantity purchased from the supplier
           for the associated product.
        */

        SUM(
            fi.purchased_quantity
        ) AS supplier_purchased_quantity


    FROM {{ ref('fact_inventory') }} fi


    /*
       PRODUCT DIMENSION

       Connect inventory records to the corresponding
       product details using the product surrogate key.
    */

    LEFT JOIN {{ ref('dim_product') }} dp

        ON fi.product_key =
           dp.product_key


    /*
       SUPPLIER DIMENSION

       Add supplier identification and descriptive
       information to the inventory records.
    */

    LEFT JOIN {{ ref('dim_supplier') }} dsp

        ON fi.supplier_key =
           dsp.supplier_key


    /*
       AGGREGATION GRAIN

       Maintain one aggregated record for each
       supplier and product combination.
    */

    GROUP BY

        fi.supplier_key,
        dsp.supplier_id,
        dsp.supplier_name,

        fi.product_key,
        dp.product_id,
        dp.product_name,
        dp.category

),


/*
   ============================================================
   CATEGORY PURCHASE TOTALS
   ============================================================

   Calculate the total purchased quantity for every
   product category across all suppliers and products.
*/

category_totals AS (

    SELECT

        category,


        /*
           TOTAL CATEGORY PURCHASED QUANTITY

           Represents the complete purchase volume
           recorded within each category.
        */

        SUM(
            supplier_purchased_quantity
        ) AS total_category_purchased_quantity


    FROM supplier_category


    GROUP BY

        category

)


/*
   ============================================================
   FINAL SUPPLIER CONTRIBUTION OUTPUT
   ============================================================

   Compare each supplier's purchased quantity with the
   total purchased quantity for its product category.
*/

SELECT

    sc.supplier_key,
    sc.supplier_id,
    sc.supplier_name,

    sc.category,

    sc.supplier_purchased_quantity,

    ct.total_category_purchased_quantity,


    /*
       SUPPLIER CONTRIBUTION PERCENTAGE

       Calculates the percentage of category purchases
       contributed by the supplier.

       Division is protected against zero category
       purchase totals.
    */

    CASE

        WHEN ct.total_category_purchased_quantity > 0

        THEN
            100.0
            * sc.supplier_purchased_quantity
            /
            NULLIF(
                ct.total_category_purchased_quantity,
                0
            )

        ELSE NULL

    END AS supplier_contribution_percentage


FROM supplier_category sc


/*
   CATEGORY TOTAL JOIN

   Match each supplier-category record with the
   corresponding overall category purchase total.
*/

LEFT JOIN category_totals ct

    ON sc.category =
       ct.category