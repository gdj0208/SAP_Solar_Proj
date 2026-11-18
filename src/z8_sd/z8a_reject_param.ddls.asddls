@EndUserText.label: '고객 검수 서명 팝업'
define abstract entity Z8A_REJECT_PARAM
{
  @EndUserText.label: '검수 담당자(서명)'
  InspectorName : abap.char( 20 );

  @EndUserText.label: '고객(검수자) 서명'
  CustomerName  : abap.char( 20 );
  
  @EndUserText.label: '부적격 사유'
  RejReason  : abap.char( 20 );
}
