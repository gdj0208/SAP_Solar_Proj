@EndUserText.label: '고객 검수 서명 팝업'
define abstract entity z8a_inspect_param
{
  @EndUserText.label: '담당자 서명'
  InspectorName : abap.char( 20 );

  @EndUserText.label: '검수자 서명'
  CustomerName  : abap.char( 20 );
}

