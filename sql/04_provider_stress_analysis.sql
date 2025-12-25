
/* ============================================================
   QUERY PURPOSE: EXTRACT PROVIDER-LEVEL WORKLOAD FOR BOTTLENECK DRGs
   ============================================================ */
SELECT
    p.DRG_Desc,
    p.provider_id,
    p.provider_discharges
INTO #provider_bottleneck_load
FROM #drg_providersummary p
JOIN #top_bottleneckdrgs b
  ON p.DRG_Desc = b.DRG_Desc;

  /* ============================================================
   QUERY PURPOSE: COMPUTE STATISTICAL LOAD THRESHOLDS
   ============================================================ */
SELECT
    DRG_Desc,
    provider_id,
    provider_discharges,
    PERCENTILE_CONT(0.90) 
        WITHIN GROUP (ORDER BY provider_discharges)
        OVER (PARTITION BY DRG_Desc) AS p90_threshold,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY provider_discharges)
        OVER (PARTITION BY DRG_Desc) AS median_load
INTO #provider_with_percentiles
FROM #provider_bottleneck_load;

