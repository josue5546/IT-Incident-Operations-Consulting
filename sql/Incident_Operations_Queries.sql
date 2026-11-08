
-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- Q01: Create and Verify Incident Event Database
-- =====================================================

-- Create database
CREATE DATABASE IF NOT EXISTS incident_event
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Select database
USE incident_event;

-- Verify active database
SELECT DATABASE() AS active_database;


-- Q04: Validate Incident-Level Import

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,
    COUNT(DISTINCT number) AS unique_incidents,
    SUM(Event_Count) AS total_events,

    SUM(Resolved_At IS NULL)
        AS missing_resolution_dates,

    SUM(Resolution_Duration_Minutes IS NULL)
        AS missing_resolution_durations

FROM incident_event.clean_incidents_sql;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- Q05A: Validate Event Staging Table
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_events,

    COUNT(DISTINCT number) AS unique_incidents,

    COUNT(DISTINCT CSV_Row) AS unique_source_rows,

    SUM(
        CASE
            WHEN sys_created_at IS NULL
              OR sys_created_at = 'NULL'
            THEN 1 ELSE 0
        END
    ) AS missing_creation_dates

FROM incident_event.clean_events_stage;



-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- Q10: Final Event-Level Data Integrity Validation
-- Database: incident_event
-- Table: clean_events_ready
-- =====================================================

USE incident_event;

SELECT
    -- Dataset structure
    COUNT(*) AS total_events,

    COUNT(DISTINCT number) AS unique_incidents,

    COUNT(DISTINCT CSV_Row) AS unique_source_rows,

    COUNT(DISTINCT Event_Order) AS unique_event_orders,

    -- Timestamp completeness
    SUM(opened_at IS NULL)
        AS missing_opening_dates,

    SUM(sys_created_at IS NULL)
        AS missing_creation_dates,

    SUM(sys_updated_at IS NULL)
        AS missing_update_dates,

    SUM(resolved_at IS NULL)
        AS missing_resolution_dates,

    SUM(closed_at IS NULL)
        AS missing_closure_dates,

    -- Organisational data completeness
    SUM(assignment_group IS NULL)
        AS missing_assignment_groups,

    SUM(cmdb_ci IS NULL)
        AS missing_configuration_items,

    -- Data-quality exceptions
    SUM(DQ_State_Flag IS NOT NULL)
        AS unknown_state_events,

    SUM(DQ_Update_Before_Open = 1)
        AS early_update_events,

    SUM(DQ_Mod_Sequence_Conflict = 1)
        AS modification_conflict_events

FROM incident_event.clean_events_ready;



-- =====================================================
-- Q11: Verify Event Table Column Count
-- =====================================================

SELECT
    COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'incident_event'
  AND table_name = 'clean_events_ready';


-- =====================================================
-- Q12: Verify Event-to-Incident Relationships
-- =====================================================

USE incident_event;

-- Check events without a matching incident
SELECT
    COUNT(*) AS unmatched_event_records

FROM clean_events_ready e

LEFT JOIN clean_incidents_sql i
    ON e.number = i.number

WHERE i.number IS NULL;


-- =====================================================
-- Q12A: Verify Incident-Level Event Counts
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS incidents_checked,

    SUM(
        CASE
            WHEN e.number IS NULL
              OR i.Event_Count <> e.actual_events
            THEN 1 ELSE 0
        END
    ) AS mismatched_incidents

FROM clean_incidents_sql i

LEFT JOIN (
    SELECT
        number,
        COUNT(*) AS actual_events
    FROM clean_events_ready
    GROUP BY number
) e
    ON i.number = e.number;
    
    
-- =====================================================
-- Q13A: Check Existing Event Tables
-- =====================================================

SHOW TABLES FROM incident_event
LIKE 'clean_events%';


-- =====================================================
-- Q13B: Finalise Clean Event Table
-- Run only after all integrity checks pass
-- =====================================================

USE incident_event;

-- Preserve the incomplete import under a backup name
-- Promote the validated table to the final name

RENAME TABLE
    incident_event.clean_events_sql
        TO incident_event.clean_events_incomplete_backup,

    incident_event.clean_events_ready
        TO incident_event.clean_events_sql;


-- =====================================================
-- Q13C: Verify Final Event Table
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT number) AS unique_incidents,
    COUNT(DISTINCT CSV_Row) AS unique_source_rows

FROM clean_events_sql;


-- =====================================================
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q14: Overall Incident Volume and
--      Resolution Data Coverage
--
-- Business objective:
-- Establish the incident-volume baseline and assess
-- availability of resolution timestamps.
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,

    COUNT(DISTINCT number) AS unique_incidents,

    SUM(
        CASE
            WHEN Resolved_At IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS incidents_with_resolution_date,

    SUM(
        CASE
            WHEN Resolved_At IS NULL
            THEN 1 ELSE 0
        END
    ) AS incidents_missing_resolution_date,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Resolved_At IS NOT NULL
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS resolution_date_coverage_pct,

    SUM(Event_Count) AS total_handling_events

FROM incident_event.clean_incidents_sql;


-- =====================================================
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q15: Monthly Incident Volume Trend
--
-- Business objective:
-- Identify monthly incident demand and its share
-- of the total recorded incident workload.
-- =====================================================

USE incident_event;

SELECT
    DATE_FORMAT(Opened_At, '%Y-%m')
        AS opening_month,

    COUNT(*) AS incidents_opened,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM incident_event.clean_incidents_sql),
        2
    ) AS share_of_total_pct

FROM incident_event.clean_incidents_sql

GROUP BY
    DATE_FORMAT(Opened_At, '%Y-%m')

ORDER BY opening_month ASC;


-- =====================================================
-- Q15A: Validate Monthly Incident Volume Totals
-- =====================================================

USE incident_event;

SELECT
    SUM(monthly_incidents)
        AS total_incidents,

    COUNT(*)
        AS months_observed,

    MIN(opening_month)
        AS first_month,

    MAX(opening_month)
        AS last_month

FROM (
    SELECT
        DATE_FORMAT(Opened_At, '%Y-%m')
            AS opening_month,

        COUNT(*) AS monthly_incidents

    FROM incident_event.clean_incidents_sql

    GROUP BY
        DATE_FORMAT(Opened_At, '%Y-%m')
) AS monthly_summary;


-- =====================================================
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q15B: Monthly Incident Demand and
--       Month-on-Month Changes
--
-- Business objective:
-- Identify demand peaks, low-volume months,
-- and monthly fluctuations.
-- Excludes partial months from comparisons.
-- =====================================================

USE incident_event;

WITH monthly_volume AS (
    SELECT
        DATE_FORMAT(Opened_At, '%Y-%m')
            AS opening_month,

        COUNT(*) AS incidents_opened

    FROM clean_incidents_sql

    GROUP BY DATE_FORMAT(Opened_At, '%Y-%m')
),

full_months AS (
    SELECT
        opening_month,
        incidents_opened,

        LAG(incidents_opened)
        OVER (ORDER BY opening_month)
            AS previous_month_incidents

    FROM monthly_volume

    WHERE opening_month
        BETWEEN '2016-03' AND '2017-01'
)

SELECT
    opening_month,

    incidents_opened,

    previous_month_incidents,

    incidents_opened - previous_month_incidents
        AS monthly_change,

    ROUND(
        100.0 *
        (incidents_opened - previous_month_incidents)
        / NULLIF(previous_month_incidents, 0),
        2
    ) AS monthly_change_pct

FROM full_months

ORDER BY opening_month;


-- =====================================================
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q16: Median and P90 Incident Resolution Time
--
-- Business objective:
-- Measure typical resolution time and long-duration
-- incident performance.
--
-- Method:
-- Inclusive percentile with linear interpolation.
-- Excludes NULL and negative resolution durations.
-- =====================================================

USE incident_event;

WITH ranked_durations AS (

    SELECT
        Resolution_Duration_Minutes
            AS resolution_minutes,

        ROW_NUMBER() OVER (
            ORDER BY Resolution_Duration_Minutes
        ) AS rn,

        COUNT(*) OVER () AS n

    FROM clean_incidents_sql

    WHERE Resolution_Duration_Minutes IS NOT NULL
      AND Resolution_Duration_Minutes >= 0
),

percentile_bounds AS (

    SELECT
        MAX(n) AS valid_incidents,

        -- Two positions surrounding the median
        MAX(
            CASE
                WHEN rn = FLOOR((n + 1) / 2)
                THEN resolution_minutes
            END
        ) AS median_lower,

        MAX(
            CASE
                WHEN rn = CEIL((n + 1) / 2)
                THEN resolution_minutes
            END
        ) AS median_upper,

        -- Two positions surrounding P90
        MAX(
            CASE
                WHEN rn = FLOOR(1 + 0.90 * (n - 1))
                THEN resolution_minutes
            END
        ) AS p90_lower,

        MAX(
            CASE
                WHEN rn = CEIL(1 + 0.90 * (n - 1))
                THEN resolution_minutes
            END
        ) AS p90_upper

    FROM ranked_durations
)

SELECT
    valid_incidents,

    ROUND(
        (median_lower + median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        p90_lower
        + (p90_upper - p90_lower)
        * (
            1 + 0.90 * (valid_incidents - 1)
            - FLOOR(
                1 + 0.90 * (valid_incidents - 1)
              )
          ),
        2
    ) AS p90_resolution_minutes

FROM percentile_bounds;


-- =====================================================
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q17: Resolution Time by Initial Incident Priority
--
-- Objective:
-- Compare incident volumes, resolution-data
-- coverage, median duration and P90 duration
-- across initial priority groups.
--
-- Method:
-- Continuous percentiles with linear interpolation.
-- =====================================================

USE incident_event;

WITH base AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(Initial_Priority), ''),
            'Unknown'
        ) AS priority_group,

        Resolution_Duration_Minutes
            AS resolution_minutes

    FROM clean_incidents_sql
),

coverage AS (
    SELECT
        priority_group,
        COUNT(*) AS total_incidents,

        SUM(
            CASE WHEN resolution_minutes IS NOT NULL
                   AND resolution_minutes >= 0
                 THEN 1 ELSE 0 END
        ) AS valid_durations,

        SUM(resolution_minutes IS NULL)
            AS missing_durations,

        SUM(resolution_minutes < 0)
            AS negative_durations

    FROM base
    GROUP BY priority_group
),

ranked AS (
    SELECT
        priority_group,
        resolution_minutes,

        ROW_NUMBER() OVER (
            PARTITION BY priority_group
            ORDER BY resolution_minutes
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY priority_group
        ) AS n

    FROM base
    WHERE resolution_minutes IS NOT NULL
      AND resolution_minutes >= 0
),

percentile_bounds AS (
    SELECT
        priority_group,
        MAX(n) AS n,

        MAX(CASE
            WHEN rn = FLOOR((n + 1) / 2)
            THEN resolution_minutes
        END) AS median_lower,

        MAX(CASE
            WHEN rn = CEIL((n + 1) / 2)
            THEN resolution_minutes
        END) AS median_upper,

        MAX(CASE
            WHEN rn = FLOOR(1 + 0.90 * (n - 1))
            THEN resolution_minutes
        END) AS p90_lower,

        MAX(CASE
            WHEN rn = CEIL(1 + 0.90 * (n - 1))
            THEN resolution_minutes
        END) AS p90_upper

    FROM ranked
    GROUP BY priority_group
)

SELECT
    c.priority_group,
    c.total_incidents,
    c.valid_durations,
    c.missing_durations,
    c.negative_durations,

    ROUND(
        100.0 * c.valid_durations
        / NULLIF(c.total_incidents, 0),
        2
    ) AS duration_coverage_pct,

    ROUND(
        (p.median_lower + p.median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        p.p90_lower
        + (p.p90_upper - p.p90_lower)
        * (
            1 + 0.90 * (p.n - 1)
            - FLOOR(1 + 0.90 * (p.n - 1))
          ),
        2
    ) AS p90_resolution_minutes

FROM coverage c
LEFT JOIN percentile_bounds p
    ON c.priority_group = p.priority_group

ORDER BY c.priority_group;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q18: Resolution Time by Reassignment Frequency
--
-- Business objective:
-- Assess the association between recorded incident
-- reassignments and resolution duration.
--
-- Method:
-- Group incidents by reassignment frequency.
-- Calculate median and P90 using interpolation.
-- =====================================================

USE incident_event;

WITH base AS (
    SELECT
        CASE
            WHEN Reassignment_Count = 0
                THEN '0 - None'
            WHEN Reassignment_Count = 1
                THEN '1 - One'
            WHEN Reassignment_Count = 2
                THEN '2 - Two'
            WHEN Reassignment_Count >= 3
                THEN '3+ - Three or more'
            ELSE 'Unknown'
        END AS reassignment_group,

        CASE
            WHEN Reassignment_Count = 0 THEN 0
            WHEN Reassignment_Count = 1 THEN 1
            WHEN Reassignment_Count = 2 THEN 2
            WHEN Reassignment_Count >= 3 THEN 3
            ELSE 4
        END AS group_order,

        Resolution_Duration_Minutes
            AS resolution_minutes

    FROM clean_incidents_sql
),

coverage AS (
    SELECT
        reassignment_group,
        group_order,

        COUNT(*) AS total_incidents,

        SUM(
            CASE
                WHEN resolution_minutes IS NOT NULL
                 AND resolution_minutes >= 0
                THEN 1 ELSE 0
            END
        ) AS valid_durations,

        SUM(
            CASE
                WHEN resolution_minutes IS NULL
                THEN 1 ELSE 0
            END
        ) AS missing_durations

    FROM base
    GROUP BY reassignment_group, group_order
),

ranked AS (
    SELECT
        reassignment_group,
        resolution_minutes,

        ROW_NUMBER() OVER (
            PARTITION BY reassignment_group
            ORDER BY resolution_minutes
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY reassignment_group
        ) AS n

    FROM base
    WHERE resolution_minutes IS NOT NULL
      AND resolution_minutes >= 0
),

bounds AS (
    SELECT
        reassignment_group,

        MAX(n) AS n,

        MAX(CASE
            WHEN rn = FLOOR((n + 1) / 2)
            THEN resolution_minutes
        END) AS median_lower,

        MAX(CASE
            WHEN rn = CEIL((n + 1) / 2)
            THEN resolution_minutes
        END) AS median_upper,

        MAX(CASE
            WHEN rn = FLOOR(1 + 0.90 * (n - 1))
            THEN resolution_minutes
        END) AS p90_lower,

        MAX(CASE
            WHEN rn = CEIL(1 + 0.90 * (n - 1))
            THEN resolution_minutes
        END) AS p90_upper

    FROM ranked
    GROUP BY reassignment_group
)

SELECT
    c.reassignment_group,

    c.total_incidents,

    c.valid_durations,

    c.missing_durations,

    ROUND(
        100.0 * c.total_incidents / 24918,
        2
    ) AS share_of_incidents_pct,

    ROUND(
        (b.median_lower + b.median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        b.p90_lower
        + (b.p90_upper - b.p90_lower)
        * (
            1 + 0.90 * (b.n - 1)
            - FLOOR(1 + 0.90 * (b.n - 1))
          ),
        2
    ) AS p90_resolution_minutes

FROM coverage c

LEFT JOIN bounds b
    ON c.reassignment_group = b.reassignment_group

ORDER BY c.group_order;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
--
-- Q18A: Validate Reassignment Baseline
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,

    SUM(Reassignment_Count > 0)
        AS incidents_with_reassignment,

    SUM(Reassignment_Count)
        AS total_recorded_reassignments,

    SUM(Reassignment_Count IS NULL)
        AS missing_reassignment_counts,

    SUM(
        Resolution_Duration_Minutes IS NOT NULL
        AND Resolution_Duration_Minutes >= 0
    ) AS valid_durations,

    SUM(Resolution_Duration_Minutes IS NULL)
        AS missing_durations

FROM clean_incidents_sql;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q19: Resolution Time by Handling Event Count
--
-- Business objective:
-- Investigate whether incidents with more recorded
-- handling events have longer resolution durations.
--
-- Method:
-- Group by Event_Count and calculate median and P90.
-- =====================================================

USE incident_event;

WITH base AS (
    SELECT
        CASE
            WHEN Event_Count = 1 THEN '1 event'
            WHEN Event_Count BETWEEN 2 AND 3
                THEN '2-3 events'
            WHEN Event_Count BETWEEN 4 AND 6
                THEN '4-6 events'
            WHEN Event_Count BETWEEN 7 AND 10
                THEN '7-10 events'
            WHEN Event_Count >= 11
                THEN '11+ events'
            ELSE 'Unknown / invalid'
        END AS event_group,

        CASE
            WHEN Event_Count = 1 THEN 1
            WHEN Event_Count BETWEEN 2 AND 3 THEN 2
            WHEN Event_Count BETWEEN 4 AND 6 THEN 3
            WHEN Event_Count BETWEEN 7 AND 10 THEN 4
            WHEN Event_Count >= 11 THEN 5
            ELSE 6
        END AS group_order,

        Resolution_Duration_Minutes AS duration_minutes

    FROM clean_incidents_sql
),

coverage AS (
    SELECT
        event_group,
        group_order,

        COUNT(*) AS total_incidents,

        SUM(duration_minutes IS NOT NULL
            AND duration_minutes >= 0)
            AS valid_durations,

        SUM(duration_minutes IS NULL)
            AS missing_durations

    FROM base
    GROUP BY event_group, group_order
),

ranked AS (
    SELECT
        event_group,
        duration_minutes,

        ROW_NUMBER() OVER (
            PARTITION BY event_group
            ORDER BY duration_minutes
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY event_group
        ) AS n

    FROM base

    WHERE duration_minutes IS NOT NULL
      AND duration_minutes >= 0
),

bounds AS (
    SELECT
        event_group,
        MAX(n) AS n,

        MAX(CASE
            WHEN rn = FLOOR((n + 1) / 2)
            THEN duration_minutes
        END) AS median_lower,

        MAX(CASE
            WHEN rn = CEIL((n + 1) / 2)
            THEN duration_minutes
        END) AS median_upper,

        MAX(CASE
            WHEN rn = FLOOR(1 + 0.90 * (n - 1))
            THEN duration_minutes
        END) AS p90_lower,

        MAX(CASE
            WHEN rn = CEIL(1 + 0.90 * (n - 1))
            THEN duration_minutes
        END) AS p90_upper

    FROM ranked
    GROUP BY event_group
)

SELECT
    c.event_group,
    c.total_incidents,
    c.valid_durations,
    c.missing_durations,

    ROUND(
        100.0 * c.valid_durations
        / NULLIF(c.total_incidents, 0),
        2
    ) AS duration_coverage_pct,

    ROUND(
        (b.median_lower + b.median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        b.p90_lower
        + (b.p90_upper - b.p90_lower)
        * (
            1 + 0.90 * (b.n - 1)
            - FLOOR(1 + 0.90 * (b.n - 1))
        ),
        2
    ) AS p90_resolution_minutes

FROM coverage c

LEFT JOIN bounds b
    ON c.event_group = b.event_group

ORDER BY c.group_order;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
--
-- Q19A: Validate Handling Event Baseline
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,

    SUM(Event_Count) AS total_events,

    ROUND(AVG(Event_Count), 2)
        AS average_events_per_incident,

    SUM(Event_Count IS NULL OR Event_Count < 1)
        AS invalid_event_counts,

    SUM(Resolution_Duration_Minutes IS NOT NULL
        AND Resolution_Duration_Minutes >= 0)
        AS valid_durations,

    SUM(Resolution_Duration_Minutes IS NULL)
        AS missing_durations

FROM clean_incidents_sql;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q20: Reassignment Frequency by Initial Priority
--
-- Business objective:
-- Compare resolution durations across reassignment
-- groups while separating incidents by initial priority.
--
-- Method:
-- Calculate group counts, duration coverage,
-- median and P90 using linear interpolation.
-- =====================================================

USE incident_event;

WITH base AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(Initial_Priority), ''),
            'Unknown'
        ) AS priority_group,

        CASE
            WHEN Reassignment_Count = 0
                THEN '0 - None'
            WHEN Reassignment_Count = 1
                THEN '1 - One'
            WHEN Reassignment_Count = 2
                THEN '2 - Two'
            WHEN Reassignment_Count >= 3
                THEN '3+ - Three or more'
            ELSE 'Unknown'
        END AS reassignment_group,

        CASE
            WHEN Reassignment_Count = 0 THEN 0
            WHEN Reassignment_Count = 1 THEN 1
            WHEN Reassignment_Count = 2 THEN 2
            WHEN Reassignment_Count >= 3 THEN 3
            ELSE 4
        END AS group_order,

        Resolution_Duration_Minutes
            AS duration_minutes

    FROM clean_incidents_sql
),

coverage AS (
    SELECT
        priority_group,
        reassignment_group,
        group_order,

        COUNT(*) AS total_incidents,

        SUM(
            duration_minutes IS NOT NULL
            AND duration_minutes >= 0
        ) AS valid_durations,

        SUM(duration_minutes IS NULL)
            AS missing_durations

    FROM base

    GROUP BY
        priority_group,
        reassignment_group,
        group_order
),

ranked AS (
    SELECT
        priority_group,
        reassignment_group,
        duration_minutes,

        ROW_NUMBER() OVER (
            PARTITION BY
                priority_group,
                reassignment_group
            ORDER BY duration_minutes
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY
                priority_group,
                reassignment_group
        ) AS n

    FROM base

    WHERE duration_minutes IS NOT NULL
      AND duration_minutes >= 0
),

bounds AS (
    SELECT
        priority_group,
        reassignment_group,

        MAX(n) AS n,

        MAX(
            CASE
                WHEN rn = FLOOR((n + 1) / 2)
                THEN duration_minutes
            END
        ) AS median_lower,

        MAX(
            CASE
                WHEN rn = CEIL((n + 1) / 2)
                THEN duration_minutes
            END
        ) AS median_upper,

        MAX(
            CASE
                WHEN rn = FLOOR(
                    1 + 0.90 * (n - 1)
                )
                THEN duration_minutes
            END
        ) AS p90_lower,

        MAX(
            CASE
                WHEN rn = CEIL(
                    1 + 0.90 * (n - 1)
                )
                THEN duration_minutes
            END
        ) AS p90_upper

    FROM ranked

    GROUP BY
        priority_group,
        reassignment_group
)

SELECT
    c.priority_group,
    c.reassignment_group,

    c.total_incidents,
    c.valid_durations,
    c.missing_durations,

    ROUND(
        100.0 * c.valid_durations
        / NULLIF(c.total_incidents, 0),
        2
    ) AS duration_coverage_pct,

    ROUND(
        (b.median_lower + b.median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        b.p90_lower
        + (b.p90_upper - b.p90_lower)
        * (
            1 + 0.90 * (b.n - 1)
            - FLOOR(
                1 + 0.90 * (b.n - 1)
              )
          ),
        2
    ) AS p90_resolution_minutes

FROM coverage c

LEFT JOIN bounds b
    ON c.priority_group = b.priority_group
   AND c.reassignment_group = b.reassignment_group

ORDER BY
    c.priority_group,
    c.group_order;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
--
-- Q20A: Validate Priority and Reassignment Baseline
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,

    COUNT(DISTINCT Initial_Priority)
        AS priority_categories,

    SUM(Reassignment_Count > 0)
        AS reassigned_incidents,

    SUM(
        Resolution_Duration_Minutes IS NOT NULL
        AND Resolution_Duration_Minutes >= 0
    ) AS valid_durations,

    SUM(Resolution_Duration_Minutes IS NULL)
        AS missing_durations

FROM clean_incidents_sql;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q21: Overall Incident Reopen Rate
--
-- Business objective:
-- Measure how often incidents are reopened
-- and quantify total recorded reopenings.
--
-- Definition:
-- Reopen rate = incidents with at least one
-- recorded reopening / total incidents * 100
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,

    SUM(
        CASE
            WHEN Reopen_Count > 0 THEN 1
            ELSE 0
        END
    ) AS incidents_reopened,

    SUM(
        CASE
            WHEN Reopen_Count = 0 THEN 1
            ELSE 0
        END
    ) AS incidents_never_reopened,

    SUM(Reopen_Count) AS total_reopening_events,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Reopen_Count > 0 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS incident_reopen_rate_pct,

    SUM(
        CASE
            WHEN Reopen_Count IS NULL
              OR Reopen_Count < 0
            THEN 1 ELSE 0
        END
    ) AS invalid_reopen_counts

FROM incident_event.clean_incidents_sql;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q22: Monthly Incident Demand vs Resolution Throughput
--
-- Business objective:
-- Compare incidents opened and incidents resolved
-- within each calendar month.
--
-- Important:
-- Monthly net difference is NOT a verified backlog.
-- Missing resolution dates are excluded from
-- recorded resolution throughput.
-- =====================================================

USE incident_event;

WITH monthly_opened AS (
    SELECT
        DATE_FORMAT(Opened_At, '%Y-%m')
            AS reporting_month,

        COUNT(*) AS incidents_opened

    FROM clean_incidents_sql

    WHERE Opened_At IS NOT NULL

    GROUP BY DATE_FORMAT(Opened_At, '%Y-%m')
),

monthly_resolved AS (
    SELECT
        DATE_FORMAT(Resolved_At, '%Y-%m')
            AS reporting_month,

        COUNT(*) AS incidents_resolved

    FROM clean_incidents_sql

    WHERE Resolved_At IS NOT NULL

    GROUP BY DATE_FORMAT(Resolved_At, '%Y-%m')
),

all_months AS (
    SELECT reporting_month FROM monthly_opened

    UNION

    SELECT reporting_month FROM monthly_resolved
)

SELECT
    m.reporting_month,

    COALESCE(o.incidents_opened, 0)
        AS incidents_opened,

    COALESCE(r.incidents_resolved, 0)
        AS incidents_resolved,

    COALESCE(r.incidents_resolved, 0)
    - COALESCE(o.incidents_opened, 0)
        AS resolved_minus_opened

FROM all_months m

LEFT JOIN monthly_opened o
    ON m.reporting_month = o.reporting_month

LEFT JOIN monthly_resolved r
    ON m.reporting_month = r.reporting_month

ORDER BY m.reporting_month;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
--
-- Q22A: Validate Monthly Throughput Data Coverage
--
-- Objective:
-- Reconcile opening and resolution totals, and
-- identify the observed date ranges.
-- =====================================================

USE incident_event;

SELECT
    COUNT(*) AS total_incidents,

    SUM(Opened_At IS NOT NULL)
        AS incidents_with_opening_date,

    SUM(Resolved_At IS NOT NULL)
        AS incidents_with_resolution_date,

    SUM(Resolved_At IS NULL)
        AS incidents_missing_resolution_date,

    MIN(Opened_At) AS earliest_opening,

    MAX(Opened_At) AS latest_opening,

    MIN(Resolved_At) AS earliest_resolution,

    MAX(Resolved_At) AS latest_resolution

FROM clean_incidents_sql;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q23: Opening Cohorts of Post-May Resolutions
--
-- Business objective:
-- Determine whether incidents resolved after May
-- were opened during earlier reporting periods.
-- =====================================================

USE incident_event;

SELECT
    DATE_FORMAT(Resolved_At, '%Y-%m')
        AS resolution_month,

    COUNT(*) AS total_resolved,

    SUM(
        CASE
            WHEN Opened_At < '2016-06-01'
            THEN 1 ELSE 0
        END
    ) AS resolved_from_earlier_incidents,

    SUM(
        CASE
            WHEN Opened_At >= '2016-06-01'
            THEN 1 ELSE 0
        END
    ) AS resolved_from_newer_incidents,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN Opened_At < '2016-06-01'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS earlier_incidents_pct

FROM incident_event.clean_incidents_sql

WHERE Resolved_At >= '2016-06-01'
  AND Resolved_At < '2017-03-01'

GROUP BY DATE_FORMAT(Resolved_At, '%Y-%m')

ORDER BY resolution_month;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q24: Resolution Data Coverage by Opening Cohort
--
-- Business objective:
-- Compare resolution-date completeness between
-- incidents opened before June 2016 and those
-- opened from June 2016 onward.
-- =====================================================

USE incident_event;

WITH opening_cohorts AS (
    SELECT
        CASE
            WHEN Opened_At < '2016-06-01'
                THEN '1 - Before June 2016'
            WHEN Opened_At >= '2016-06-01'
                THEN '2 - June 2016 onward'
            ELSE 'Unknown opening date'
        END AS opening_cohort,

        Resolved_At

    FROM clean_incidents_sql
)

SELECT
    opening_cohort,

    COUNT(*) AS total_incidents,

    SUM(
        Resolved_At IS NOT NULL
        AND Resolved_At < '2016-06-01'
    ) AS resolved_before_june,

    SUM(
        Resolved_At >= '2016-06-01'
    ) AS resolved_from_june_onward,

    SUM(Resolved_At IS NULL)
        AS missing_resolution_dates,

    ROUND(
        100.0 * SUM(Resolved_At IS NOT NULL)
        / NULLIF(COUNT(*), 0),
        2
    ) AS resolution_date_coverage_pct

FROM opening_cohorts

GROUP BY opening_cohort

ORDER BY opening_cohort;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 5: OPERATIONAL PERFORMANCE ANALYSIS
--
-- Q25: Reassignment and Handling Activity Segmentation
--
-- Business objective:
-- Identify incident groups with both repeated
-- reassignments and high recorded event activity.
--
-- Method:
-- Four segments; calculate incident volumes,
-- valid durations, median and P90.
-- =====================================================

USE incident_event;

WITH base AS (
    SELECT
        CASE
            WHEN Reassignment_Count >= 3
                THEN '3+ reassignments'
            ELSE '0-2 reassignments'
        END AS reassignment_band,

        CASE
            WHEN Event_Count >= 7
                THEN '7+ events'
            ELSE '2-6 events'
        END AS event_band,

        Resolution_Duration_Minutes
            AS duration_minutes

    FROM clean_incidents_sql
),

coverage AS (
    SELECT
        reassignment_band,
        event_band,

        COUNT(*) AS total_incidents,

        SUM(
            duration_minutes IS NOT NULL
            AND duration_minutes >= 0
        ) AS valid_durations,

        SUM(duration_minutes IS NULL)
            AS missing_durations

    FROM base
    GROUP BY reassignment_band, event_band
),

ranked AS (
    SELECT
        reassignment_band,
        event_band,
        duration_minutes,

        ROW_NUMBER() OVER (
            PARTITION BY reassignment_band, event_band
            ORDER BY duration_minutes
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY reassignment_band, event_band
        ) AS n

    FROM base

    WHERE duration_minutes IS NOT NULL
      AND duration_minutes >= 0
),

bounds AS (
    SELECT
        reassignment_band,
        event_band,
        MAX(n) AS n,

        MAX(CASE
            WHEN rn = FLOOR((n + 1) / 2)
            THEN duration_minutes
        END) AS median_lower,

        MAX(CASE
            WHEN rn = CEIL((n + 1) / 2)
            THEN duration_minutes
        END) AS median_upper,

        MAX(CASE
            WHEN rn = FLOOR(1 + 0.90 * (n - 1))
            THEN duration_minutes
        END) AS p90_lower,

        MAX(CASE
            WHEN rn = CEIL(1 + 0.90 * (n - 1))
            THEN duration_minutes
        END) AS p90_upper

    FROM ranked
    GROUP BY reassignment_band, event_band
)

SELECT
    c.reassignment_band,
    c.event_band,

    c.total_incidents,
    c.valid_durations,
    c.missing_durations,

    ROUND(
        100.0 * c.total_incidents / 24918,
        2
    ) AS share_of_incidents_pct,

    ROUND(
        (b.median_lower + b.median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        b.p90_lower
        + (b.p90_upper - b.p90_lower)
        * (
            1 + 0.90 * (b.n - 1)
            - FLOOR(1 + 0.90 * (b.n - 1))
        ),
        2
    ) AS p90_resolution_minutes

FROM coverage c

LEFT JOIN bounds b
    ON c.reassignment_band = b.reassignment_band
   AND c.event_band = b.event_band

ORDER BY
    c.reassignment_band,
    c.event_band;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 6: TARGETED ROUTING DIAGNOSTIC
--
-- Q26: Assignment Group History and Data Coverage
--
-- Business objective:
-- Assess assignment-group data completeness and
-- identify incidents involving multiple observed
-- assignment groups.
--
-- Important:
-- Multiple distinct groups indicate possible
-- routing transitions, not confirmed unnecessary
-- reassignments.
-- =====================================================

USE incident_event;

WITH assignment_coverage AS (
    SELECT
        number,

        COUNT(*) AS event_count,

        SUM(
            CASE
                WHEN NULLIF(
                    TRIM(assignment_group), ''
                ) IS NOT NULL
                THEN 1 ELSE 0
            END
        ) AS events_with_group,

        COUNT(
            DISTINCT NULLIF(
                TRIM(assignment_group), ''
            )
        ) AS distinct_observed_groups

    FROM incident_event.clean_events_sql

    GROUP BY number
)

SELECT
    COUNT(*) AS total_incidents,

    SUM(event_count) AS total_events,

    SUM(events_with_group)
        AS events_with_assignment_group,

    SUM(event_count - events_with_group)
        AS events_missing_assignment_group,

    SUM(distinct_observed_groups = 0)
        AS incidents_without_observed_group,

    SUM(distinct_observed_groups = 1)
        AS incidents_with_one_group,

    SUM(distinct_observed_groups >= 2)
        AS incidents_with_multiple_groups,

    MAX(distinct_observed_groups)
        AS maximum_distinct_groups

FROM assignment_coverage;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 6: TARGETED ROUTING DIAGNOSTIC
--
-- Q27: Most Frequent Assignment-Group Transitions
--
-- Business objective:
-- Identify recurring directional changes between
-- support groups in chronological incident histories.
--
-- Method:
-- Compare consecutive event records using LAG().
-- Count changes only when both groups are known.
-- =====================================================

USE incident_event;

WITH ordered_events AS (
    SELECT
        number,
        Event_Order,
        CSV_Row,

        NULLIF(
            TRIM(assignment_group), ''
        ) AS current_group,

        LAG(
            NULLIF(TRIM(assignment_group), '')
        ) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS previous_group

    FROM clean_events_sql
),

observed_changes AS (
    SELECT
        number,
        previous_group,
        current_group

    FROM ordered_events

    WHERE previous_group IS NOT NULL
      AND current_group IS NOT NULL
      AND previous_group <> current_group
)

SELECT
    previous_group AS from_group,

    current_group AS to_group,

    COUNT(*) AS observed_group_changes,

    COUNT(DISTINCT number)
        AS affected_incidents

FROM observed_changes

GROUP BY
    previous_group,
    current_group

ORDER BY
    observed_group_changes DESC,
    affected_incidents DESC,
    from_group,
    to_group

LIMIT 15;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
--
-- Q27A: Validate Observed Group Transitions
-- =====================================================

USE incident_event;

WITH ordered_events AS (
    SELECT
        number,

        NULLIF(
            TRIM(assignment_group), ''
        ) AS current_group,

        LAG(
            NULLIF(TRIM(assignment_group), '')
        ) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS previous_group

    FROM clean_events_sql
)

SELECT
    COUNT(*) AS total_events,

    COUNT(DISTINCT number)
        AS total_incidents,

    SUM(
        previous_group IS NOT NULL
        AND current_group IS NOT NULL
    ) AS comparable_event_pairs,

    SUM(
        previous_group IS NOT NULL
        AND current_group IS NOT NULL
        AND previous_group <> current_group
    ) AS observed_group_changes,

    COUNT(DISTINCT
        CASE
            WHEN previous_group IS NOT NULL
             AND current_group IS NOT NULL
             AND previous_group <> current_group
            THEN number
        END
    ) AS incidents_with_observed_changes

FROM ordered_events;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 6: TARGETED ROUTING DIAGNOSTIC
--
-- Q28: Identify Immediate Return-to-Group Patterns
--
-- Business objective:
-- Detect incidents that move from Group A to
-- Group B and then return directly to Group A.
--
-- Method:
-- Compress repeated known group states.
-- Preserve NULL values as barriers.
-- Identify A -> B -> A group sequences.
-- =====================================================

USE incident_event;

WITH ordered_events AS (
    SELECT
        number,
        Event_Order,
        CSV_Row,

        NULLIF(TRIM(assignment_group), '')
            AS group_id,

        LAG(
            NULLIF(TRIM(assignment_group), '')
        ) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS previous_group

    FROM clean_events_sql
),

change_points AS (
    SELECT
        number,
        Event_Order,
        CSV_Row,
        group_id

    FROM ordered_events

    WHERE previous_group IS NULL
       OR group_id IS NULL
       OR group_id <> previous_group
),

group_sequence AS (
    SELECT
        number,
        group_id,

        LAG(group_id, 1) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS intermediate_group,

        LAG(group_id, 2) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS original_group

    FROM change_points
),

return_patterns AS (
    SELECT
        number,

        original_group AS return_group,

        intermediate_group AS via_group

    FROM group_sequence

    WHERE group_id IS NOT NULL
      AND intermediate_group IS NOT NULL
      AND original_group IS NOT NULL
      AND group_id = original_group
      AND group_id <> intermediate_group
)

SELECT
    return_group,
    via_group,

    COUNT(*) AS observed_return_patterns,

    COUNT(DISTINCT number)
        AS affected_incidents

FROM return_patterns

GROUP BY return_group, via_group

ORDER BY
    observed_return_patterns DESC,
    affected_incidents DESC

LIMIT 15;


-- =====================================================
-- IT SERVICE MANAGEMENT & DIGITAL TRANSFORMATION
-- STAGE 6: TARGETED ROUTING DIAGNOSTIC
--
-- Q29: Resolution Performance by Routing-Return Status
--
-- Business objective:
-- Compare resolution durations for Moderate-priority
-- incidents with and without observed A -> B -> A
-- assignment-group returns.
--
-- Method:
-- Preserve missing groups as sequence barriers.
-- Calculate median and P90 using interpolation.
-- =====================================================

USE incident_event;

WITH ordered_events AS (
    SELECT
        number,
        Event_Order,
        CSV_Row,
        NULLIF(TRIM(assignment_group), '') AS group_id,

        LAG(
            NULLIF(TRIM(assignment_group), '')
        ) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS previous_group

    FROM clean_events_sql
),

change_points AS (
    SELECT
        number,
        Event_Order,
        CSV_Row,
        group_id
    FROM ordered_events
    WHERE previous_group IS NULL
       OR group_id IS NULL
       OR group_id <> previous_group
),

group_sequence AS (
    SELECT
        number,
        group_id,

        LAG(group_id, 1) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS via_group,

        LAG(group_id, 2) OVER (
            PARTITION BY number
            ORDER BY Event_Order, CSV_Row
        ) AS original_group

    FROM change_points
),

returns_by_incident AS (
    SELECT
        number,
        COUNT(*) AS return_pattern_count

    FROM group_sequence

    WHERE group_id IS NOT NULL
      AND via_group IS NOT NULL
      AND original_group IS NOT NULL
      AND group_id = original_group
      AND group_id <> via_group

    GROUP BY number
),

base AS (
    SELECT
        CASE
            WHEN r.number IS NOT NULL
                THEN 'Observed routing return'
            ELSE 'No observed routing return'
        END AS routing_status,

        i.Resolution_Duration_Minutes
            AS duration_minutes,

        i.Reassignment_Count,

        COALESCE(r.return_pattern_count, 0)
            AS return_pattern_count

    FROM clean_incidents_sql i

    LEFT JOIN returns_by_incident r
        ON i.number = r.number

    WHERE i.Initial_Priority = '3 - Moderate'
),

coverage AS (
    SELECT
        routing_status,

        COUNT(*) AS total_incidents,

        SUM(
            duration_minutes IS NOT NULL
            AND duration_minutes >= 0
        ) AS valid_durations,

        SUM(duration_minutes IS NULL)
            AS missing_durations,

        SUM(return_pattern_count)
            AS observed_return_patterns,

        ROUND(AVG(Reassignment_Count), 2)
            AS avg_reassignments

    FROM base
    GROUP BY routing_status
),

ranked AS (
    SELECT
        routing_status,
        duration_minutes,

        ROW_NUMBER() OVER (
            PARTITION BY routing_status
            ORDER BY duration_minutes
        ) AS rn,

        COUNT(*) OVER (
            PARTITION BY routing_status
        ) AS n

    FROM base

    WHERE duration_minutes IS NOT NULL
      AND duration_minutes >= 0
),

bounds AS (
    SELECT
        routing_status,
        MAX(n) AS n,

        MAX(CASE
            WHEN rn = FLOOR((n + 1) / 2)
            THEN duration_minutes
        END) AS median_lower,

        MAX(CASE
            WHEN rn = CEIL((n + 1) / 2)
            THEN duration_minutes
        END) AS median_upper,

        MAX(CASE
            WHEN rn = FLOOR(1 + 0.90 * (n - 1))
            THEN duration_minutes
        END) AS p90_lower,

        MAX(CASE
            WHEN rn = CEIL(1 + 0.90 * (n - 1))
            THEN duration_minutes
        END) AS p90_upper

    FROM ranked
    GROUP BY routing_status
)

SELECT
    c.routing_status,
    c.total_incidents,
    c.valid_durations,
    c.missing_durations,
    c.observed_return_patterns,
    c.avg_reassignments,

    ROUND(
        (b.median_lower + b.median_upper) / 2,
        2
    ) AS median_resolution_minutes,

    ROUND(
        b.p90_lower
        + (b.p90_upper - b.p90_lower)
        * (
            1 + 0.90 * (b.n - 1)
            - FLOOR(1 + 0.90 * (b.n - 1))
        ),
        2
    ) AS p90_resolution_minutes

FROM coverage c

LEFT JOIN bounds b
    ON c.routing_status = b.routing_status

ORDER BY c.routing_status;


