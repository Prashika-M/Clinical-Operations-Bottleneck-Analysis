/* ============================================================
   QUERY PURPOSE: CATEGORIZE HOSPITALS BY BOTTLENECKS STRESS LEVELS
   ============================================================ */
SELECT
    DRG_Desc,
    provider_id,
    provider_discharges,
    median_load,
    p90_threshold,
    CASE
        WHEN provider_discharges >= p90_threshold
            THEN 'HIGH-STRESS OUTLIER'
        WHEN provider_discharges >= median_load
            THEN 'ABOVE AVERAGE'
        ELSE 'NORMAL'
    END AS load_category
FROM #provider_with_percentiles
ORDER BY DRG_Desc, provider_discharges DESC;

/* ============================================================
   QUERY PURPOSE: IDENTIFY LOW-COVERAGE DRGs
   ============================================================ */
SELECT
    DRG_Desc,
    hospital_count,
    avg_discharges_per_hospital,
    bottleneck_rank
FROM drg_bottleneck_summary
WHERE hospital_count < 50
ORDER BY bottleneck_rank;

/* ============================================================
   QUERY PURPOSE: VALIDATE BOTTLENECKS WITH BROAD HOSPITAL COVERAGE
   ============================================================ */
SELECT
    DRG_Desc,
    hospital_count,
    total_discharges,
    avg_discharges_per_hospital,
    bottleneck_rank
FROM drg_bottleneck_summary
WHERE hospital_count >= 500
ORDER BY bottleneck_rank;


/* ============================================================
   QUERY PURPOSE: IDENTIFY EXTREME WORKLOAD DRG
   ============================================================ */
SELECT
    DRG_Desc,
    hospital_count,
    avg_discharges_per_hospital,
    avg_payment
FROM drg_bottleneck_summary
WHERE avg_discharges_per_hospital > 150
ORDER BY avg_discharges_per_hospital DESC;


/* ============================================================
   QUERY PURPOSE: IDENTIFY COST-INTENSIVE DRG
   ============================================================ */
SELECT
    DRG_Desc,
    avg_discharges_per_hospital,
    avg_payment
FROM drg_bottleneck_summary
WHERE avg_discharges_per_hospital > 50
ORDER BY avg_payment DESC;


/* ============================================================
   QUERY PURPOSE: COMPUTE VOLUME PRESSURE SCORE
   ============================================================ */
SELECT
    DRG_Desc,
    avg_discharges_per_hospital,
    avg_payment,
    hospital_count,
    CAST(avg_discharges_per_hospital AS FLOAT)
    / MAX(avg_discharges_per_hospital) OVER () AS volume_pressure_score
FROM drg_bottleneck_summary;


/* ============================================================
   QUERY PURPOSE: COMPUTE VOLUME AND COST PRESSURE SCORE
   ============================================================ */
SELECT
    DRG_Desc,
    avg_discharges_per_hospital,
    avg_payment,
    hospital_count,
    CAST(avg_discharges_per_hospital AS FLOAT)
        / MAX(avg_discharges_per_hospital) OVER () AS volume_pressure_score,
    CAST(avg_payment AS FLOAT)
        / MAX(avg_payment) OVER () AS cost_pressure_score
FROM drg_bottleneck_summary;


/* ============================================================
   QUERY PURPOSE: COMPUTE COMPOSITE BOTTLENECK INDEX
   ============================================================ */
SELECT
    DRG_Desc,
    hospital_count,
    total_discharges,
    avg_discharges_per_hospital,
    avg_payment,

    CAST(avg_discharges_per_hospital AS FLOAT)
        / MAX(avg_discharges_per_hospital) OVER () AS volume_pressure_score,

    CAST(avg_payment AS FLOAT)
        / MAX(avg_payment) OVER () AS cost_pressure_score,

    (
        0.6 * CAST(avg_discharges_per_hospital AS FLOAT)
            / MAX(avg_discharges_per_hospital) OVER ()
      + 0.4 * CAST(avg_payment AS FLOAT)
            / MAX(avg_payment) OVER ()
    ) AS bottleneck_index
FROM drg_bottleneck_summary;


/* ============================================================
   QUERY PURPOSE: FINAL BOTTLENECK PRIORITIZATION
   ============================================================ */
SELECT
    *,
    RANK() OVER (ORDER BY bottleneck_index DESC) AS final_bottleneck_rank
FROM (
    SELECT
        DRG_Desc,
        hospital_count,
        total_discharges,
        avg_discharges_per_hospital,
        avg_payment,

        0.6 * CAST(avg_discharges_per_hospital AS FLOAT)
            / MAX(avg_discharges_per_hospital) OVER ()
      + 0.4 * CAST(avg_payment AS FLOAT)
            / MAX(avg_payment) OVER () AS bottleneck_index
    FROM drg_bottleneck_summary
) t
ORDER BY final_bottleneck_rank;

/* ============================================================
   QUERY PURPOSE: ISOLATE TOP BOTTLENECK DRGS
   ============================================================ */
SELECT
    DRG_Desc
INTO #topbottleneckdrgs
FROM drg_bottleneck_summary
ORDER BY bottleneck_rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

/* ============================================================
   QUERY PURPOSE: HOSPITAL LEVEL BOTTLENECK LOAD
   ============================================================ */
SELECT
    Rndrng_Prvdr_Org_Name AS hospital_name,
    COUNT(DISTINCT DRG_Desc) AS bottleneck_drg_count,
    SUM(Tot_Dschrgs) AS bottleneck_discharges
INTO #hospital_bottleneck_load
FROM cms_raw_inpatient
WHERE DRG_Desc IN (SELECT DRG_Desc FROM #topbottleneckdrgs)
GROUP BY Rndrng_Prvdr_Org_Name;


/* ============================================================
   QUERY PURPOSE: NORMALIZE HOSPITAL BOTTLENECK STRESS
   ============================================================ */
SELECT
    hospital_name,
    bottleneck_drg_count,
    bottleneck_discharges,
    CAST(bottleneck_discharges AS FLOAT) 
        / NULLIF(bottleneck_drg_count, 0) AS avg_discharges_per_bottleneck_drg
INTO hospital_bottleneck_stress
FROM #hospital_bottleneck_load;

/* ============================================================
   QUERY PURPOSE: RANK HOSPITAL BY BOTTLENECK STRESS
   ============================================================ */
SELECT
    *,
    RANK() OVER (
        ORDER BY avg_discharges_per_bottleneck_drg DESC
    ) AS hospital_stress_rank
FROM hospital_bottleneck_stress
ORDER BY hospital_stress_rank;

/* ============================================================
   QUERY PURPOSE: AGGREGATE BOTTLENECK LOAST AT STATE LEVEL
   ============================================================ */
SELECT
    Rndrng_Prvdr_State_Abrvtn AS state,
    COUNT(DISTINCT Rndrng_Prvdr_Org_Name) AS hospital_count,
    SUM(Tot_Dschrgs) AS bottleneck_discharges
INTO #state_bottleneck_load
FROM cms_raw_inpatient
WHERE DRG_Desc IN (SELECT DRG_Desc FROM #topbottleneckdrgs)
GROUP BY Rndrng_Prvdr_State_Abrvtn;


/* ============================================================
   QUERY PURPOSE: NORMALIZE STATE-LEVEL BOTTLENECK PRESSURE
   ============================================================ */
SELECT
    state,
    hospital_count,
    bottleneck_discharges,
    CAST(bottleneck_discharges AS FLOAT)
        / NULLIF(hospital_count, 0) AS avg_bottleneck_discharges_per_hospital
INTO state_bottleneck_pressure
FROM #state_bottleneck_load;


/* ============================================================
   QUERY PURPOSE: RANK STATES BY BOTTLENECK PRESSURE
   ============================================================ */
SELECT
    *,
    RANK() OVER (
        ORDER BY avg_bottleneck_discharges_per_hospital DESC
    ) AS state_bottleneck_rank
FROM state_bottleneck_pressure
ORDER BY state_bottleneck_rank;

