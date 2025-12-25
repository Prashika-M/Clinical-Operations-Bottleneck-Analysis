/* ============================================================
   SCRIPT 1: Raw Data Table Creation & Validation
   PURPOSE:
   This script sets up the foundational raw table to store
   CMS inpatient DRG-level hospital data. The goal is to create
   a clean, well-typed base table that mirrors the source data
   while enabling reliable downstream analytical queries.
   DESIGN PHILOSOPHY:
   - Keep this table as a "raw but structured" layer
   - No aggregations or business logic here
   - Data types are chosen to support later numeric analysis
   ============================================================ */

/* ============================================================
   STEP 1: Create Raw Inpatient Table
   ============================================================ */

CREATE TABLE cms_raw_inpatient (
    Rndrng_Prvdr_CCN NVARCHAR(20),
    Rndrng_Prvdr_Org_Name NVARCHAR(255),
    Rndrng_Prvdr_City NVARCHAR(100),
    Rndrng_Prvdr_St NVARCHAR(10),
    Rndrng_Prvdr_State_FIPS NVARCHAR(10),
    Rndrng_Prvdr_Zip5 NVARCHAR(10),
    Rndrng_Prvdr_State_Abrvtn NVARCHAR(10),
    Rndrng_Prvdr_RUCA NVARCHAR(20),
    Rndrng_Prvdr_RUCA_Desc NVARCHAR(255),
    DRG_Cd NVARCHAR(10),
    DRG_Desc NVARCHAR(255),
    Tot_Dschrgs INT,
    Avg_Submtd_Cvrd_Chrg DECIMAL(18,2),
    Avg_Tot_Pymt_Amt DECIMAL(18,2),
    Avg_Mdcr_Pymt_Amt DECIMAL(18,2)
);

INSERT INTO cms_raw_inpatient (
    Rndrng_Prvdr_CCN,
    Rndrng_Prvdr_Org_Name,
    Rndrng_Prvdr_City,
    Rndrng_Prvdr_St,
    Rndrng_Prvdr_State_FIPS,
    Rndrng_Prvdr_Zip5,
    Rndrng_Prvdr_State_Abrvtn,
    Rndrng_Prvdr_RUCA,
    Rndrng_Prvdr_RUCA_Desc,
    DRG_Cd,
    DRG_Desc,
    Tot_Dschrgs,
    Avg_Submtd_Cvrd_Chrg,
    Avg_Tot_Pymt_Amt,
    Avg_Mdcr_Pymt_Amt
)
SELECT
    CAST(Rndrng_Prvdr_CCN AS NVARCHAR(20)),
    CAST(Rndrng_Prvdr_Org_Name AS NVARCHAR(255)),
    CAST(Rndrng_Prvdr_City AS NVARCHAR(100)),
    CAST(Rndrng_Prvdr_St AS NVARCHAR(10)),
    CAST(Rndrng_Prvdr_State_FIPS AS NVARCHAR(10)),
    CAST(Rndrng_Prvdr_Zip5 AS NVARCHAR(10)),
    CAST(Rndrng_Prvdr_State_Abrvtn AS NVARCHAR(10)),
    CAST(Rndrng_Prvdr_RUCA AS NVARCHAR(20)),
    CAST(Rndrng_Prvdr_RUCA_Desc AS NVARCHAR(255)),
    CAST(DRG_Cd AS NVARCHAR(10)),
    CAST(DRG_Desc AS NVARCHAR(255)),
    CAST(Tot_Dschrgs AS INT),
    CAST(Avg_Submtd_Cvrd_Chrg AS DECIMAL(18,2)),
    CAST(Avg_Tot_Pymt_Amt AS DECIMAL(18,2)),
    CAST(Avg_Mdcr_Pymt_Amt AS DECIMAL(18,2))
FROM imported_table;

