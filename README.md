# Clinical-Operations-Bottleneck-Analysis
End-to-end analysis of U.S. inpatient healthcare data to identify high-impact clinical bottlenecks using discharge volume, hospital load, and cost metrics. Demonstrates structured SQL analytics, healthcare domain understanding, and operational insight generation.

Project Overview
This project analyzes U.S. inpatient clinical operations data to identify Diagnosis Related Groups (DRGs) that create operational bottlenecks across hospitals. The analysis focuses on patient volume pressure, hospital load imbalance, and cost intensity using SQL-based analytics.

Business Problem
Healthcare systems often face operational strain not only from high costs but from uneven patient volume distribution across hospitals. Identifying DRGs that consistently overload hospitals helps administrators prioritize process optimization, staffing, and care redesign.

Analytical Approach
Cleaned and standardized raw CMS inpatient data
Aggregated DRG-level discharge volumes per hospital
Identified bottleneck DRGs using average discharges per hospital
Analyzed provider-level and state-level stress patterns
Built a composite bottleneck index combining volume and cost pressure

Key Insights
Certain DRGs (e.g., Sepsis, Heart Failure) consistently create high operational load
Bottlenecks are volume-driven rather than cost-driven alone
Provider stress is unevenly distributed even within the same DRG
State-level aggregation reveals regional concentration of bottleneck pressure

Skills Demonstrated
SQL aggregation and window functions
Analytical metric design
Healthcare domain understanding (DRGs)
Problem framing and structured analysis
