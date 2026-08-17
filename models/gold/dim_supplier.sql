{{ config(
    materialized='table'
) }}

WITH suppliers AS (

    SELECT
        supplier_id,
        supplier_name,
        contact_name,
        email,
        phone,
        standardized_address,
        payment_terms,
        supplier_type

    FROM {{ ref('si_supplier') }}

),

final AS (

    SELECT

        /*
           SURROGATE KEY

           Generate the surrogate key using the
           natural supplier_id through dbt_utils.
        */

        {{ dbt_utils.generate_surrogate_key([
            'supplier_id'
        ]) }} AS supplier_key,


        /*
           NATURAL KEY
        */

        supplier_id,


        /*
           SUPPLIER NAME
        */

        supplier_name,


        /*
           CONTACT INFORMATION

           Combine the cleaned contact fields
           into a single reporting-friendly value.
        */

        CONCAT_WS(
            ' | ',

            NULLIF(
                TRIM(contact_name),
                ''
            ),

            NULLIF(
                TRIM(email),
                ''
            ),

            NULLIF(
                TRIM(phone),
                ''
            )

        ) AS contact_information,


        /*
           PAYMENT TERMS
        */

        payment_terms,


        /*
           SUPPLIER TYPE
        */

        supplier_type

    FROM suppliers

)

/*
   FINAL SUPPLIER DIMENSION
*/

SELECT
    *

FROM final