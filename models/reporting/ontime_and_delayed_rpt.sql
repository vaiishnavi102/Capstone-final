{{ config(
    materialized = 'view'
 
) }}

WITH inventory AS (

    /*
       INVENTORY FACT DATA

       Select the inventory measures and snapshot
       quality fields required for supplier and
       store-level supply analysis.
    */

    SELECT

        inventory_key,
        product_key,
        date_key,
        store_key,
        supplier_key,

        beginning_stock,
        purchased_quantity,
        sold_quantity,
        ending_stock,

        inventory_value,

        snapshot_gap_flag,
        snapshot_gap_days

    FROM {{ ref('fact_inventory') }}

),

suppliers AS (

    /*
       SUPPLIER DIMENSION

       Retrieve supplier identifiers and descriptive
       attributes for reporting and classification.
    */

    SELECT

        supplier_key,
        supplier_id,
        supplier_name,
        supplier_type

    FROM {{ ref('dim_supplier') }}

),

stores AS (

    /*
       STORE DIMENSION

       Retrieve store identifiers and location
       attributes required for supply analysis.
    */

    SELECT

        store_key,
        store_id,
        store_name,
        region,
        store_type

    FROM {{ ref('dim_store') }}

),

dates AS (

    /*
       DATE DIMENSION

       Bring calendar attributes into the inventory
       reporting dataset.
    */

    SELECT

        date_key,
        full_date,
        year,
        month,
        quarter

    FROM {{ ref('dim_date') }}

),

classified AS (

    /*
       CLASSIFY INVENTORY SNAPSHOTS

       Combine inventory facts with supplier, store,
       and date dimensions. The snapshot quality flag
       is converted into a readable supply status.
    */

    SELECT

        i.inventory_key,

        i.product_key,
        i.date_key,
        i.store_key,
        i.supplier_key,

        d.full_date,

        d.year,
        d.month,
        d.quarter,

        s.supplier_id,
        s.supplier_name,
        s.supplier_type,

        st.store_id,
        st.store_name,
        st.region,
        st.store_type,

        i.beginning_stock,
        i.purchased_quantity,
        i.sold_quantity,
        i.ending_stock,
        i.inventory_value,

        i.snapshot_gap_flag,
        i.snapshot_gap_days,

        /*
           SUPPLY STATUS

           Mark the inventory snapshot as Delayed
           when a snapshot gap is detected. All
           remaining records are classified as On Time.
        */

        CASE

            WHEN COALESCE(
                i.snapshot_gap_flag,
                FALSE
            ) = TRUE

                THEN 'Delayed'

            ELSE 'On Time'

        END AS supply_status

    FROM inventory i

    /*
       SUPPLIER JOIN

       Connect inventory records to the supplier
       dimension through supplier_key.
    */

    LEFT JOIN suppliers s

        ON i.supplier_key = s.supplier_key

    /*
       STORE JOIN

       Connect inventory records to the store
       dimension through store_key.
    */

    LEFT JOIN stores st

        ON i.store_key = st.store_key

    /*
       DATE JOIN

       Connect inventory records to the date
       dimension through date_key.
    */

    LEFT JOIN dates d

        ON i.date_key = d.date_key

)

/*
   FINAL SUPPLY ANALYSIS

   Aggregate inventory activity by supplier, store,
   date, and supply status for reporting purposes.
*/

SELECT

    supplier_key,
    supplier_id,
    supplier_name,
    supplier_type,

    store_key,
    store_id,
    store_name,
    region,
    store_type,

    date_key,
    full_date,
    year,
    month,
    quarter,

    supply_status,

    /*
       INVENTORY SNAPSHOT COUNT

       Count the distinct inventory snapshots
       represented in each reporting group.
    */

    COUNT(
        DISTINCT inventory_key
    ) AS inventory_snapshot_count,

    /*
       PURCHASED QUANTITY

       Total quantity purchased within the
       selected supplier, store, and date group.
    */

    SUM(
        purchased_quantity
    ) AS total_purchased_quantity,

    /*
       SOLD QUANTITY

       Total quantity sold within the
       selected reporting group.
    */

    SUM(
        sold_quantity
    ) AS total_sold_quantity,

    /*
       ENDING INVENTORY

       Total ending stock across the
       inventory snapshots in the group.
    */

    SUM(
        ending_stock
    ) AS total_ending_inventory,

    /*
       INVENTORY VALUE

       Total monetary value represented by
       the ending inventory records.
    */

    SUM(
        inventory_value
    ) AS total_inventory_value,

    /*
       AVERAGE SNAPSHOT GAP

       Average number of days associated with
       inventory snapshot gaps.
    */

    AVG(
        snapshot_gap_days
    ) AS average_snapshot_gap_days,

    /*
       ON-TIME SNAPSHOT COUNT

       Count inventory snapshots classified
       as On Time.
    */

    COUNT(
        DISTINCT CASE

            WHEN supply_status = 'On Time'
                THEN inventory_key

        END
    ) AS on_time_snapshot_count,

    /*
       DELAYED SNAPSHOT COUNT

       Count inventory snapshots classified
       as Delayed.
    */

    COUNT(
        DISTINCT CASE

            WHEN supply_status = 'Delayed'
                THEN inventory_key

        END
    ) AS delayed_snapshot_count,

    /*
       ON-TIME PERCENTAGE

       Calculate the percentage of inventory
       snapshots that were received on time.
    */

    ROUND(
        100.0
        * COUNT(
            DISTINCT CASE

                WHEN supply_status = 'On Time'
                    THEN inventory_key

            END
        )
        / NULLIF(
            COUNT(DISTINCT inventory_key),
            0
        ),
        2
    ) AS on_time_percentage,

    /*
       DELAYED PERCENTAGE

       Calculate the percentage of inventory
       snapshots that were classified as delayed.
    */

    ROUND(
        100.0
        * COUNT(
            DISTINCT CASE

                WHEN supply_status = 'Delayed'
                    THEN inventory_key

            END
        )
        / NULLIF(
            COUNT(DISTINCT inventory_key),
            0
        ),
        2
    ) AS delayed_percentage

FROM classified

/*
   GROUPING LEVEL

   Generate the final results at supplier, store,
   date, and supply-status grain.
*/

GROUP BY

    supplier_key,
    supplier_id,
    supplier_name,
    supplier_type,

    store_key,
    store_id,
    store_name,
    region,
    store_type,

    date_key,
    full_date,
    year,
    month,
    quarter,

    supply_status