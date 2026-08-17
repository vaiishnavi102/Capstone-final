{{ config(
    materialized = 'view',
   
) }}

/*
   ============================================================
   CAMPAIGN PERFORMANCE DETAIL
   ============================================================

   This view provides campaign-level performance by date.
   It combines marketing performance facts with campaign
   and calendar dimension attributes for reporting.
*/

SELECT

    /* 
       CAMPAIGN IDENTIFIERS
    */

    fmp.campaign_key,

    dmc.campaign_id,


    /*
       CAMPAIGN TYPE

       Uses the target audience segment from the
       Marketing Campaign dimension.
    */

    dmc.target_audience_segment AS campaign_type,


    /*
       DATE ATTRIBUTES
    */

    fmp.date_key,

    dd.full_date,


    /*
       MARKETING PERFORMANCE METRICS
    */

    fmp.total_sales_influenced,

    fmp.total_campaign_cost,

    fmp.roi


/*
   SOURCE FACT TABLE

   Fact_MarketingPerformance contains the campaign
   performance measures at campaign and date grain.
*/

FROM {{ ref('fact_marketing_performance') }} fmp


/*
   CAMPAIGN DIMENSION

   Links the marketing performance record to the
   corresponding campaign information.
*/

LEFT JOIN {{ ref('dim_marketing_campaign') }} dmc

    ON fmp.campaign_key =
       dmc.campaign_key


/*
   DATE DIMENSION

   Adds the calendar date associated with each
   marketing performance record.
*/

LEFT JOIN {{ ref('dim_date') }} dd

    ON fmp.date_key =
       dd.date_key