@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '프로젝트 상태 Value Help'

define view entity Z8PS_VH_STATUS
  as select from I_DomainFixedValueText
{
  key DomainValue as ProjectStatus,
      DomainText as ProjectStatusName
}
where SAPDataDictionaryDomain = 'Z8D_PROJ_STATUS'
