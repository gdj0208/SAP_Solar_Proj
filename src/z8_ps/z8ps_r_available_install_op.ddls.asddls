@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '설치기사 Object Page 조회용 CDS'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity Z8PS_R_AVAILABLE_INSTALL_OP
  as select from Z8PS_R_AVAILABLE_TECH_OP
{
  key ProjectId,
  key PersonalNumber,
  BranchName,
      Ename,
      Stell,
      Grade,
      @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
      Capacity,
      CapacityUnit
} 
where Stell = '설치기사'
