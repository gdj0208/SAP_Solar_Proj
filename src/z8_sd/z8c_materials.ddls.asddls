@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '구매오더 내 모든 자재 목록 View'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8c_materials as select from z8r_Materials
{
    key Vbeln,
    key Posnr,
    Matnr,
    PlaceType,
    @Semantics.quantity.unitOfMeasure: 'Vrkme'
    Qunt,
    Vrkme,
    spras
}
