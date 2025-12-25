/* ============================================================
   QUERY PURPOSE: REVIEW FINAL DRG BOTTLENECT RANKING
   ============================================================ */
SELECT *
FROM drg_bottleneck_summary
ORDER BY bottleneck_rank;

/* ============================================================
   QUERY PURPOSE: ISOLATE TOP BOTTLENECK DRGs
   ============================================================ */
SELECT
    DRG_Desc
INTO #top_bottleneckdrgs
FROM drg_bottleneck_summary
WHERE bottleneck_rank <= 5;
