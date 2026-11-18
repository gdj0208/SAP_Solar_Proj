@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Z8CUSTOMER_M View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8V_CUSOMER as select from z8customer_m
{
        @EndUserText.label: '고객 번호'
    key kunnr as Kunnr,
        @EndUserText.label: '계정 과목'
        saknr as Saknr,
        @EndUserText.label: '고객'
        name1 as Name1,
        @EndUserText.label: '사업자 번호'
        stcd2 as Stcd2,
        @EndUserText.label: '국가'
        land1 as Land1,
        @EndUserText.label: '지역'
        regio as Regio,
        @EndUserText.label: '근무지'
        ort01 as Ort01,
        @EndUserText.label: '우편번호'
        pstlz as Pstlz,
        @EndUserText.label: '도로 주소'
        stras as Stras,
        @EndUserText.label: '연락처'
        telf1 as Telf1
}
