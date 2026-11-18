@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '기술등급별 생산성 마스터'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8PS_R_YIELDRATE 
as 
select from z8yeildrate_m
{
    key grade as Grade,
    
    @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
    capacity as Capacity,
    capacity_unit as CapacityUnit
}
