@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Z8PS_PROJECT의 STATUS_P의 fixed value 내역 출력용'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8i_status_text as select from dd07t
{
    @UI.hidden: true
  key domname    as DomainName,
  @UI.hidden: true
  key domvalue_l as StatusCode,
  
  @EndUserText.label: '진행 상태'
  ddtext         as StatusText
}
where domname = 'Z8D_PROJ_STATUS' // 도메인 이름[cite: 13]
  and ddlanguage = $session.system_language
