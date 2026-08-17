{{ config(
    materialized = 'view',
    
) }}

/*
   ============================================================
   SUPPLIER PURCHASE SHARE ANALYSIS
   ============================================================

   This view calculates the purchase volume contributed by
   each supplier and determines the supplier's percentage
   share of the overall purchased quantity.
*/

WITH supplier_purchase AS (

    /*
       ========================================================
       SUPPLIER PURCHASE SUMMARY
       ========================================================

       Aggregate purchased quantities at supplier level
       and attach supplier descriptive information.
    */

    SELECT

        fi.supplier_key,

        dsp.supplier_id,
        dsp.supplier_name,

        SUM(
            fi.purchased_quantity
        ) AS total_purchased_quantity

    FROM {{ ref('fact_inventory') }} fi


    /*
       SUPPLIER DIMENSION

       Link inventory records with the corresponding
       supplier details.
    */

    LEFT JOIN {{ ref('dim_supplier') }} dsp

        ON fi.supplier_key =
           dsp.supplier_key


    /*
       SUPPLIER-LEVEL AGGREGATION
    */

    GROUP BY

        fi.supplier_key,
        dsp.supplier_id,
        dsp.supplier_name

),


/*
   ============================================================
   TOTAL PURCHASE QUANTITY
   ============================================================

   Calculate the combined purchased quantity across
   all suppliers.
*/

total_purchase AS (

    SELECT

        SUM(
            total_purchased_quantity
        ) AS total_purchased_quantity

    FROM supplier_purchase

),


/*
   ============================================================
   SUPPLIER PURCHASE SHARE
   ============================================================

   Compare each supplier's purchased quantity with the
   overall supplier purchase quantity.
*/

supplier_share AS (

    SELECT

        sp.supplier_key,
        sp.supplier_id,
        sp.supplier_name,

        sp.total_purchased_quantity,

        /*
           TOTAL PURCHASED QUANTITY FROM ALL SUPPLIERS
        */

        tp.total_purchased_quantity
            AS all_supplier_purchased_quantity,


        /*
           SUPPLIER PURCHASE SHARE

           Calculates the percentage contribution of
           each supplier to the overall purchase volume.
        */

        CASE

            WHEN tp.total_purchased_quantity > 0

            THEN
                100.0
                * sp.total_purchased_quantity
                /
                NULLIF(
                    tp.total_purchased_quantity,
                    0
                )

            ELSE NULL

        END AS supplier_purchase_share_percentage


    FROM supplier_purchase sp


    /*
       CROSS JOIN

       Add the overall purchase total to every
       supplier record for percentage calculation.
    */

    CROSS JOIN total_purchase tp

)


/*
   ============================================================
   FINAL SUPPLIER CONCENTRATION OUTPUT
   ============================================================

   Classify suppliers according to their individual
   contribution to total purchase volume.
*/

SELECT

    supplier_key,
    supplier_id,
    supplier_name,

    total_purchased_quantity,

    all_supplier_purchased_quantity,

    supplier_purchase_share_percentage,


    /*
       SUPPLIER CONCENTRATION RISK

       Categorizes the supplier's purchase concentration
       based on its percentage share.

       50% or more  = Very High
       30% or more  = High
       15% or more  = Medium
       Below 15%    = Low
    */

    CASE

        WHEN supplier_purchase_share_percentage >= 50
            THEN 'Very High'

        WHEN supplier_purchase_share_percentage >= 30
            THEN 'High'

        WHEN supplier_purchase_share_percentage >= 15
            THEN 'Medium'

        ELSE 'Low'

    END AS supplier_concentration_risk


FROM supplier_share