{{ config(
    materialized = 'view',
    
) }}

SELECT

    /*
       CAMPAIGN TYPE

       Use the target audience segment from the
       marketing campaign dimension as the campaign type.
    */

    dmc.target_audience_segment AS campaign_type,

    /*
       CAMPAIGN COUNT

       Count the number of unique campaigns
       represented within each campaign type.
    */

    COUNT(
        DISTINCT fmp.campaign_key
    ) AS campaign_count,

    /*
       TOTAL SALES INFLUENCED

       Calculate the combined sales amount
       attributed to campaigns within each type.
    */

    SUM(
        fmp.total_sales_influenced
    ) AS total_sales_influenced,

    /*
       TOTAL CAMPAIGN COST

       Calculate the total campaign expenditure
       for each campaign type.
    */

    SUM(
        fmp.total_campaign_cost
    ) AS total_campaign_cost,

    /*
       AVERAGE ROI

       Calculate the average ROI value recorded
       across the campaigns in each campaign type.
    */

    AVG(
        fmp.roi
    ) AS average_roi,

    /*
       CALCULATED ROI

       Recalculate ROI using the total sales
       influenced and total campaign cost.

       Formula:

           (Total Sales Influenced - Total Campaign Cost)
           ------------------------------------------------
                    Total Campaign Cost

           multiplied by 100.
    */

    CASE

        WHEN SUM(
            fmp.total_campaign_cost
        ) > 0

        THEN
            (
                SUM(
                    fmp.total_sales_influenced
                )
                -
                SUM(
                    fmp.total_campaign_cost
                )
            )
            /
            SUM(
                fmp.total_campaign_cost
            )
            * 100

        ELSE NULL

    END AS calculated_roi

FROM {{ ref('fact_marketing_performance') }} fmp

/*
   CAMPAIGN DIMENSION JOIN

   Match marketing performance records with
   their corresponding campaign dimension records.
*/

LEFT JOIN {{ ref('dim_marketing_campaign') }} dmc

    ON fmp.campaign_key =
       dmc.campaign_key

/*
   GROUPING

   Summarize campaign performance by
   target audience segment.
*/

GROUP BY

    dmc.target_audience_segment