@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '전기기사 가용인력'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8PS_R_AVAILABLE_ELEC
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
      CapacityUnit,
      Telnr
}

// 신규 프로젝트의 기간과 Proj_Hist의 배정 기간이 겹치지 않는 직원 번호로 조회
where Stell      = '전기기사'
