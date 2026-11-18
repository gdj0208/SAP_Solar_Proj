@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TECH_HIST Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

define view entity Z8PS_C_TECH_HIST 
as 
projection on Z8PS_R_TECH_HIST
{
    key ProjectId,
    key PersonalNumber,
    key StartDate,
    EndDate,
    Stell,
    Grade,
    ActualStartDate,
    ActualEndDate,
    DailyCost,
    Waers,
    Ename,
    Capacity,
    CapacityUnit,
    Telnr,
    BranchName,
    /* Associations */
    _Project : redirected to parent Z8PS_C_PROJECT,
    _Employee
}
