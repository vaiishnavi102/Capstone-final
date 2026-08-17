{{ config(
    materialized = 'view',
   
) }}

SELECT

    /* 
       CAMPAIGN IDENTIFIER

       Retain the surrogate campaign key from the
       Marketing Performance fact table.
    */

    fmp.campaign_key,

    /*
       NATURAL CAMPAIGN ID

       Retrieve the business campaign identifier
       from the Marketing Campaign dimension.
    */

    dmc.campaign_id,

    /*
       CAMPAIGN TYPE

       Use the target audience segment from the
       campaign dimension as the campaign type.
    */

    dmc.target_audience_segment AS campaign_type,

    /*
       CAMPAIGN START DATE KEY

       Identify the earliest performance date
       recorded for each campaign.
    */

    MIN(
        fmp.date_key
    ) AS campaign_start_date_key,

    /*
       CAMPAIGN END DATE KEY

       Identify the latest performance date
       recorded for each campaign.
    */

    MAX(
        fmp.date_key
    ) AS campaign_end_date_key,

    /*
       NEW CUSTOMERS ACQUIRED

       Aggregate the total number of new customers
       attributed to each marketing campaign.
    */

    SUM(
        fmp.new_customers_acquired
    ) AS new_customers_acquired,

    /*
       REPEAT PURCHASE RATE

       Calculate the average repeat purchase rate
       across the campaign performance dates.
    */

    AVG(
        fmp.repeat_purchase_rate
    ) AS repeat_purchase_rate,

    /*
       AVERAGE DAILY SALES INFLUENCED

       Calculate the average daily sales value
       influenced by the campaign.
    */

    AVG(
        fmp.total_sales_influenced
    ) AS average_daily_sales_influenced,

    /*
       TOTAL SALES INFLUENCED

       Calculate the cumulative sales amount
       attributed to the campaign.
    */

    SUM(
        fmp.total_sales_influenced
    ) AS total_sales_influenced

FROM {{ ref('fact_marketing_performance') }} fmp

/*
   CAMPAIGN DIMENSION JOIN

   Match the Marketing Performance fact with
   the Marketing Campaign dimension using the
   campaign surrogate key.
*/

LEFT JOIN {{ ref('dim_marketing_campaign') }} dmc

    ON fmp.campaign_key =
       dmc.campaign_key

/*
   GROUPING LEVEL

   Produce one summarized record for each
   campaign and campaign type combination.
*/

GROUP BY

    fmp.campaign_key,
    dmc.campaign_id,
    dmc.target_audience_segment