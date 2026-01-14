
create view GlobalExportAnalysis_view as
with GlobalExportAnalysis as(
select 
HSCode,
FT.[Commodity Code],
DCM.Commodity,        
FT.[State Code],
DST.[STATE DESCRIPTION],
FT.[Supplier Code],
DSU.[SUPPLIER DESCRIPTION],
FT.[Region Code],

--Build a new hierarchy

Case
	when FT.[Country Code] in ('NM','MO') then 'EAST AFRICA'
	else DR.[REGION DESCRIPTION] end as [Region_Description],

DR.[REGION DESCRIPTION],
FT.[Country Code],
DCO.[COUNTRY DESCRIPTION],
FT.[Exported To Code],
DET.[EXPORTED TO DESCRIPTION],
FT.Year as Year,
FT.[Exported Month],
DCA.Month as Month,
DCA.Quarter as Quarter,
DCA.[Year-Month] as Year_Month,
FT.[Export Mode],
DTP.[Export Mode Description],
FT.[Material Type Code],
DMT.[Material Type],
FT.[Unit of Measure (UoM)],
Round(FT.Price,2) as Price,
FT.Quantity,
FT.[Freight Charges In %],

--Calculations
--Total Sales
Round(FT.Price * FT.Quantity,2) as [Total Sales],

--Freight Charges
Round(FT.Price * FT.Quantity * (FT.[Freight Charges In %]/100),2) as [Freight Charges], 

--Duty Charges
Round(FT.Price * FT.Quantity *
Case
	when FT.Quantity between 1 and 25 then 0.005
	when FT.Quantity between 26 and 50 then 0.01
	when FT.Quantity between 51 and 100 then 0.015
	when FT.Quantity between 101 and 200 then 0.02
	when FT.Quantity > 200 then 0.025
	else 0
	end,2) as [Duty Charges]

from [dbo].[EXPO-FCT-EXPORTS ANALYSIS] FT

--Commodity Table
Left Join [dbo].[DIM-COMMODITY] DCM
on FT.[Commodity Code] = DCM.[Commodity Code]

--State Table
Left Join [dbo].[DIM-STATE] DST
on FT.[State Code] = DST.[STATE CODE]

-- Supplier Table
Left Join [dbo].[DIM-SUPPLIER] DSU
on FT.[Supplier Code] = DSU.[Supplier Code]

--Region Table
Left Join [dbo].[DIM-REGION] DR
on FT.[Region Code] = DR.[Region Code]

--Country Table
Left Join [dbo].[DIM-COUNTRY] DCO
on FT.[Country Code] = DCO.[Country Code]

--Exported To Table
Left Join [dbo].[DIM-EXPORTED TO] DET
on FT.[Exported To Code] = DET.[Exported To Code]

--Calendar Table
Left Join [dbo].[DIM_CALENDAR] DCA
on FT.[Exported Month] = DCA.[Exported Month]

--Transportation Table
Left Join [dbo].[DIM-TRANSPORTATION] DTP
on FT.[Export Mode] = DTP.[Export Mode]

--Material Type Table
Left Join [dbo].[DIM-MATERIAL TYPE] DMT
on FT.[Material Type Code] = DMT.[MATERIAL CODE]

--Exclude Gold, Iron and Steel
where DCM.Commodity not in ('Gold','Iron and Steel') and DCO.[Country Code] <> 'nm'
)
select 
GEA.*,
--Total Cost To Company
GEA.[Total Sales]+GEA.[Freight Charges]+GEA.[Duty Charges] as [Total Cost To Company],

--Net Sales
GEA.[Total Sales]-GEA.[Freight Charges]-GEA.[Duty Charges] as [Net Sales]

from GlobalExportAnalysis GEA

--select * from GlobalExportAnalysis_view