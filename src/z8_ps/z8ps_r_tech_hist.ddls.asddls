@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '프로젝트 기술인력 배정 Interface View'
@Metadata.ignorePropagatedAnnotations: true

define view entity Z8PS_R_TECH_HIST 
as 
select from z8ps_tech_hist
association to parent Z8PS_R_PROJECT as _Project 
                on $projection.ProjectId = _Project.ProjectId

association [1..1] to Z8_R_EMPLOYEE as _Employee
                on $projection.PersonalNumber = _Employee.PersonalNumber

                

{

    key pro_id as ProjectId,
    key pernr as PersonalNumber,
    key sdate as StartDate,
    _Employee.Ename as Ename,
    _Employee.BranchCode as BranchCode,
    edate as EndDate,
    stell as Stell,
    grade as Grade,
    sdate_a as ActualStartDate,
    edate_a as ActualEndDate,
    @Semantics.amount.currencyCode: 'Waers'
    daily_cost as DailyCost,
    waers as Waers,
    @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
    _Employee.Capacity as Capacity,
    _Employee.CapacityUnit as CapacityUnit,
    _Employee.Telnr as Telnr,
    _Employee.BranchName as BranchName,
    
    _Project,
    _Employee
}
