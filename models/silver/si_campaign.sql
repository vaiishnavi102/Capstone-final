{{ config(
    materialized = "table"
) }}

with source_data as (

    select
        source_file,
        row_number,
        raw_data,
        loaded_at,
        batch_id
    from {{ ref("br_campaign") }}

),

/*
   1. FLATTEN THE CAMPAIGNS ARRAY
*/
flattened as (

    select
        sd.source_file,
        sd.row_number,
        sd.loaded_at,
        sd.batch_id,
        campaign.value as campaign_data

    from source_data as sd

    cross join lateral flatten(
        input => sd.raw_data:campaigns_data
    ) as campaign

),

/*
   2. EXTRACT + CLEAN + STANDARDIZE
*/
cleaned as (

    select
        source_file,
        row_number,
        loaded_at,
        batch_id,

        /*
           AUDIT / LINEAGE METADATA
        */

        /*
           CAMPAIGN ID
        */
        nullif(
            trim(campaign_data:campaign_id::varchar),
            ''
        ) as campaign_id,

        /*
           CAMPAIGN NAME
           Trim whitespace
           Remove unwanted characters
           Standardize capitalization
        */
        initcap(
            regexp_replace(
                trim(campaign_data:campaign_name::varchar),
                '[^A-Za-z0-9 ''&-]',
                ''
            )
        ) as campaign_name,

        /*
           TARGET AUDIENCE

           Preserve the complete demographic description.
           Example:
           "families 18-25" -> "Families 18-25"
           "suburban"       -> "Suburban"
        */
        initcap(
            regexp_replace(
                trim(campaign_data:target_audience::varchar),
                '[^A-Za-z0-9 ''&/-]',
                ''
            )
        ) as target_audience_segmentation,

        /*
           START DATE
        */
        try_to_date(
            nullif(
                trim(campaign_data:start_date::varchar),
                ''
            )
        ) as start_date,

        /*
           END DATE
        */
        try_to_date(
            nullif(
                trim(campaign_data:end_date::varchar),
                ''
            )
        ) as end_date,

        /*
           BUDGET
           Parse currency strings.
           Example:
           $24,005.75 -> 24005.75
        */
        try_to_decimal(
            nullif(
                regexp_replace(
                    trim(campaign_data:budget::varchar),
                    '[$,]',
                    ''
                ),
                ''
            ),
            18,
            2
        ) as budget,

        /*
           TOTAL COST
        */
        try_to_decimal(
            nullif(
                regexp_replace(
                    trim(campaign_data:total_cost::varchar),
                    '[$,]',
                    ''
                ),
                ''
            ),
            18,
            2
        ) as total_cost,

        /*
           TOTAL REVENUE

           Normalize to numeric.
           Not used to calculate final ROI in Silver.
        */
        try_to_decimal(
            nullif(
                regexp_replace(
                    trim(campaign_data:total_revenue::varchar),
                    '[$,]',
                    ''
                ),
                ''
            ),
            18,
            2
        ) as total_revenue,

        /*
           ROI CALCULATION

           Cast the source value to numeric.
           Do not calculate ROI here.
        */
        try_to_decimal(
            nullif(
                trim(campaign_data:roi_calculation::varchar),
                ''
            ),
            18,
            4
        ) as roi_calculation,

        /*
           LAST MODIFIED DATE
        */
        try_to_timestamp_ntz(
            nullif(
                trim(campaign_data:last_modified_date::varchar),
                ''
            )
        ) as last_modified_date

    from flattened

),

/*
   3. CAMPAIGN-SPECIFIC DERIVED ATTRIBUTES
*/
derived as (

    select
        c.*,

        /*
           CAMPAIGN DURATION

           Number of days between start and end dates.
        */
        case
            when c.start_date is not null
                and c.end_date is not null
            then datediff(
                day,
                c.start_date,
                c.end_date
            )
        end as campaign_duration_days

    from cleaned as c

),

/*
   4. DEDUPLICATION

   Natural key = campaign_id

   Keep the most recently modified record.
*/
deduplicated as (

    select
        d.*

    from derived as d

    qualify row_number() over (
        partition by
            coalesce(
                campaign_id,
                concat(
                    '_NULL_',
                    source_file,
                    '_',
                    row_number
                )
            )

        order by
            last_modified_date desc nulls last,
            loaded_at desc,
            source_file desc,
            row_number desc
    ) = 1

)

/*
   FINAL SILVER CAMPAIGN TABLE
*/

select
    *
from deduplicated

