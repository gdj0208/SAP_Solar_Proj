@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '전기기사 Object Page 조회용 CDS'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z8PS_R_AVAILABLE_ELEC_OP 
as 
select from Z8PS_R_AVAILABLE_TECH_OP //이미 작성한 가용성 판단로직을 다시 만들지 않고 재사용
{
    key ProjectId,
    key PersonalNumber,
    Ename,
    BranchName,
    Stell,
    Grade,
    @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
    Capacity,
    CapacityUnit,
    Telnr
   
}
where Stell = '전기기사'
