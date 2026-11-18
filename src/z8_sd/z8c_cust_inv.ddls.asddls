@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '고객 검수 내역 view'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8c_cust_inv as select from z8r_cust_inv
{
    key ProId,
    key InvNo,
    InspName,
    InspRes,
    InspectDate,
    RejReason
}
