@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Z8PLANT_M 테이블 View'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8R_plant_text as select from z8plant_m
{
        @EndUserText.label: '플랜트'
    key werks as Werks,
    
        @EndUserText.label: '지사 코드'
        bupla as Bupla,
        
        @EndUserText.label: '지사 명'
        name1 as Name1,
        
        @EndUserText.label: '지역 코드'
        region_code as RegionCode,
        bwkey as Bwkey,
        stras as Stras,
        pstlz as Pstlz,
        ort01 as Ort01,
        regio as Regio,
        land1 as Land1,
        telf1 as Telf1
}
