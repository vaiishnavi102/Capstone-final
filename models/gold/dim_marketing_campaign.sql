{{ config(
    materialized='table'
) }}

WITH campaigns AS (

    SELECT
        campaign_id,
        target_audience_segmentation,
        budget,
        campaign_duration_days,
        roi_calculation,
        start_date,
        end_date

    FROM {{ ref('si_campaign') }}

),

final AS (

    SELECT

        /*
           SURROGATE KEY

           Create the surrogate key using the
           natural Campaign ID with dbt_utils.
        */

        {{ dbt_utils.generate_surrogate_key([
            'campaign_id'
        ]) }} AS campaign_key,


        /*
           NATURAL KEY
        */

        campaign_id,


        /*
           TARGET AUDIENCE
        */

        target_audience_segmentation
            AS target_audience_segment,


        /*
           CAMPAIGN BUDGET
        */

        budget,


        /*
           CAMPAIGN DURATION

           Calculate the campaign duration using
           the number of days between the start
           and end dates.
        */

        campaign_duration_days
            AS duration,


        /*
           SOURCE ROI

           This represents the normalized
           roi_calculation value from Silver.

           The final ROI based on attributed sales
           is calculated and validated in the
           Gold Marketing Performance fact.
        */

        roi_calculation
            AS roi,


        /*
           CAMPAIGN DATES
        */

        start_date,
        end_date

    FROM campaigns

)

/*
   FINAL CAMPAIGN DIMENSION
*/

SELECT
    *

FROM final