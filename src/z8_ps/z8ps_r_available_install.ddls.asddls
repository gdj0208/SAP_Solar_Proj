@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '설치 기사 가용인력'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8PS_R_AVAILABLE_INSTALL 
  with parameters
    p_project_id : z8e_pro_id //프로젝트 아이디의 Data Element
  as select from Z8PS_R_AVAILABLE_TECH(
    p_project_id: $parameters.p_project_id
  )
{
  key ProjectId,
  key PersonalNumber,
      Ename,
      Stell,
      Grade,
      @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
      Capacity,
      CapacityUnit
}
where Stell = '설치기사';
