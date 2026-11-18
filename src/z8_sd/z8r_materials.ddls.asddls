@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '구매오더 내 모든 자재 목록'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8r_Materials as select from z8sd_so_i as soi
    left outer join z8material_txt_m as mat on soi.matnr = mat.matnr
                                       and mat.spras = $session.system_language
{
    @UI.hidden: true // 키 값은 굳이 화면에 안 보여줘도 됩니다
    key soi.vbeln_s as Vbeln,
    
    @EndUserText.label: '항목 번호'
    key soi.posnr as Posnr,
    
    @UI.lineItem: [{ position: 10 }]
    @EndUserText.label: '자재 코드'
    //@UI.hidden: true
    soi.matnr,
    
    @UI.lineItem: [{ position: 20 }]
    @EndUserText.label: '자재명'
    mat.maktx as Maktx,
    
    @UI.lineItem: [{ position: 30 }]
    @EndUserText.label: '설치 위치'
    soi.place_type as PlaceType,
    
    @UI.lineItem: [{ position: 40 }]
    @EndUserText.label: '수량'
    @Semantics.quantity.unitOfMeasure: 'Vrkme'
    soi.kwmeng as Qunt,
    
    //@UI.lineItem: [{ position: 50 }]
    //@EndUserText.label: '단위'
    soi.vrkme as Vrkme,
    
    @UI.hidden: true
    mat.spras
}

