/* ============================================================
   PROJECT: Clinical Operations Bottleneck Analysis
  
   PURPOSE OF THIS SCRIPT:
   This script performs multi-level analytical aggregation on
   CMS inpatient data to identify clinical bottlenecks based on
   workload intensity, hospital participation, and cost impact.

   ANALYTICAL STRATEGY:
   - Start with system-level context
   - Aggregate at DRG level to identify pressure points
   - Normalize workload to remove scale bias
   - Rank DRGs based on operational stress
   - Extend analysis to hospital and geographic levels
   ============================================================ */

/* ============================================================
   QUERY PURPOSE: SYSTEM-LEVEL CONTEXT METRICS
   ============================================================ */
SELECT 
    COUNT(DISTINCT Rndrng_Prvdr_CCN) AS total_hospitals,
    COUNT(DISTINCT DRG_Cd) AS total_drgs
FROM cms_raw_inpatient;


SELECT
    DRG_Desc,
    SUM(Tot_Dschrgs) AS total_discharges
FROM cms_raw_inpatient
GROUP BY DRG_Desc
ORDER BY total_discharges DESC;


SELECT 
    DRG_Desc,
    SUM(Tot_Dschrgs) AS total_discharges,
    AVG(Avg_Tot_Pymt_Amt) AS avg_payment
FROM cms_raw_inpatient
GROUP BY DRG_Desc
ORDER BY avg_payment DESC;


SELECT
    DRG_Desc,
    Rndrng_Prvdr_CCN,
    SUM(Tot_Dschrgs) AS provider_discharges
FROM cms_raw_inpatient
GROUP BY DRG_Desc, Rndrng_Prvdr_CCN;


SELECT
    DRG_Desc,
    Rndrng_Prvdr_CCN AS provider_id,
    SUM(Tot_Dschrgs) AS provider_discharges
INTO #drg_providersummary
FROM cms_raw_inpatient
GROUP BY
    DRG_Desc,
    Rndrng_Prvdr_CCN;


/* ============================================================
   QUERY PURPOSE: DRG-LEVEL WORKLOAD AGGREGATION
   ============================================================ */
SELECT
    DRG_Desc,
    COUNT(provider_id) AS hospital_count,
    SUM(provider_discharges) AS total_discharges,
    CAST(
        SUM(provider_discharges) * 1.0 / COUNT(provider_id)
        AS DECIMAL(10,2)
    ) AS avg_discharges_per_hospital
FROM #drg_providersummary
GROUP BY DRG_Desc
ORDER BY avg_discharges_per_hospital DESC;

SELECT
    DRG_Desc,
    AVG(Avg_Tot_Pymt_Amt) AS avg_payment
INTO #drg_payment
FROM cms_raw_inpatient
GROUP BY DRG_Desc;


/* ============================================================
   QUERY PURPOSE: ADD COST DIMENSION TO DRG METRICS
   ============================================================ */
SELECT
    p.DRG_Desc,
    COUNT(p.provider_id) AS hospital_count,
    SUM(p.provider_discharges) AS total_discharges,
    CAST(
        SUM(p.provider_discharges) * 1.0 / COUNT(p.provider_id)
        AS DECIMAL(10,2)
    ) AS avg_discharges_per_hospital,
    pay.avg_payment,
    RANK() OVER (
        ORDER BY
            SUM(p.provider_discharges) * 1.0 / COUNT(p.provider_id) DESC
    ) AS bottleneck_rank
FROM #drg_providersummary p
JOIN #drg_payment pay
    ON p.DRG_Desc = pay.DRG_Desc
GROUP BY
    p.DRG_Desc,
    pay.avg_payment
HAVING COUNT(p.provider_id) >= 500
ORDER BY bottleneck_rank;


SELECT
    DRG_Desc,
    hospital_count,
    total_discharges,
    avg_discharges_per_hospital,
    avg_payment,
    bottleneck_rank
INTO drg_bottleneck_summary
FROM (SELECT
    p.DRG_Desc,
    COUNT(p.provider_id) AS hospital_count,
    SUM(p.provider_discharges) AS total_discharges,
    CAST(
        SUM(p.provider_discharges) * 1.0 / COUNT(p.provider_id)
        AS DECIMAL(10,2)
    ) AS avg_discharges_per_hospital,
    pay.avg_payment,
    RANK() OVER (
        ORDER BY
            SUM(p.provider_discharges) * 1.0 / COUNT(p.provider_id) DESC
    ) AS bottleneck_rank
FROM #drg_providersummary p
JOIN #drg_payment pay
    ON p.DRG_Desc = pay.DRG_Desc
GROUP BY
    p.DRG_Desc,
    pay.avg_payment
HAVING COUNT(p.provider_id) >= 500) t;
