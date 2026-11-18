@AbapCatalog.sqlViewName: 'Z8VPRPO01'
@EndUserText.label: 'PR-PO 연결 현황 조회'
@AccessControl.authorizationCheck: #NOT_REQUIRED

define view Z8MM_C_PRPO
  as select from z8mm_pr as pr

    left outer join z8mm_po_i as poi
      on  pr.ebeln = poi.ebeln
      and pr.ebelp = poi.ebelp
      and pr.ebeln <> ''

    left outer join z8mm_po_h as poh
      on poi.ebeln = poh.ebeln

{
      /* PR 번호 및 품목 */
  key pr.banfn  as PrNumber,
  key pr.bnfpo  as PrItem,

      /* PR 자재 및 수량 */
      pr.matnr  as Material,

      @Semantics.quantity.unitOfMeasure: 'PrUnit'
      pr.menge  as PrQuantity,

      @Semantics.unitOfMeasure: true
      pr.meins  as PrUnit,

      pr.werks  as ReceivingPlant,
      pr.lgort  as StorageLocation,
      pr.lfdat  as PrDeliveryDate,
      pr.lifnr  as PrVendor,

      /* PR에 저장된 연결 PO 번호 */
      pr.ebeln  as LinkedPoNumber,
      pr.ebelp  as LinkedPoItem,

      /* 실제 연결된 PO 품목 */
      poi.ebeln as PoNumber,
      poi.ebelp as PoItem,

      @Semantics.quantity.unitOfMeasure: 'PoUnit'
      poi.menge as PoQuantity,

      @Semantics.unitOfMeasure: true
      poi.meins as PoUnit,

      poi.lfdat as PoDeliveryDate,
      poi.elikz as DeliveryCompleted,
      poi.loekz as PoDeletionIndicator,

      /* PO 헤더 */
      poh.lifnr as PoVendor,
      poh.bedat as PoDate,
      poh.ekorg as PurchasingOrganization,
      poh.ekgrp as PurchasingGroup
}
