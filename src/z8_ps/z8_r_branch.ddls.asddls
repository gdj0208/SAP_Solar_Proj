@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '종사업장 Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8_R_BRANCH 
as 
select from z8branch_m
{
    key branch as BranchCode,
    key bukrs as CompanyCode,
    name as BranchName,
    kr_repres as PresidentName,
    kr_bustype as BusinessType,
    kr_indtype as IndType,
    stcd1 as Stcd1,
    ort01 as Ort01,
    stras as Stras
}
