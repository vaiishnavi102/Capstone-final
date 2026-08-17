{{ config(
    materialized='table'
) }}

WITH products AS (

    SELECT
        product_id,
        product_name,
        category,
        subcategory,
        brand,
        color,
        size,
        unit_price,
        cost_price,
        supplier_id

    FROM {{ ref('si_product') }}

),

suppliers AS (

    SELECT
        supplier_id,
        supplier_name

    FROM {{ ref('si_supplier') }}

),

final AS (

    SELECT

        /*
           SURROGATE KEY

           Create the surrogate key using the
           natural Product ID through dbt_utils.
        */

        {{ dbt_utils.generate_surrogate_key([
            'p.product_id'
        ]) }} AS product_key,


        /*
           NATURAL KEY
        */

        p.product_id,


        /*
           PRODUCT ATTRIBUTES
        */

        p.product_name,
        p.category,
        p.subcategory,
        p.brand,
        p.color,
        p.size,


        /*
           FINANCIAL ATTRIBUTES
        */

        p.unit_price,
        p.cost_price,


        /*
           SUPPLIER INFORMATION
        */

        p.supplier_id,
        s.supplier_name

    FROM products p

    /*
       Match products with their corresponding
       supplier information.
    */

    LEFT JOIN suppliers s
        ON p.supplier_id = s.supplier_id

)

/*
   FINAL PRODUCT DIMENSION
*/

SELECT
    *

FROM final