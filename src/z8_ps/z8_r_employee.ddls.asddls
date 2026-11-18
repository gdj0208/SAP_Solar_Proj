@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '직원 Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8_R_EMPLOYEE 
as 
select from z8employee_m

association [0..1] to Z8_R_BRANCH as _Branch 
on 
$projection.Bupla = _Branch.BranchCode

association [0..1] to Z8PS_R_YIELDRATE as _Grade
on 
$projection.Grade = _Grade.Grade 

{
    key pernr as PersonalNumber,
    bukrs as CompanyCode,
    bupla as Bupla,
    _Branch.BranchCode as BranchCode,
    _Branch.BranchName as BranchName,
    ename as Ename,
    stell as Stell,
    @Semantics.amount.currencyCode: 'Waers'
    salary as Salary,
    waers as Waers,
    begda as Begda,
    endda as Endda,
    stat2 as Stat2,
    grade as Grade,
    @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
    _Grade.Capacity as Capacity,
    _Grade.CapacityUnit as CapacityUnit,
    is_eng as IsEng,
    telnr as Telnr,
    
    _Branch,
    _Grade
}
