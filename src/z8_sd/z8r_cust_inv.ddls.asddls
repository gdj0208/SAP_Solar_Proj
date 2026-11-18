@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '고객 검수 내역 테이블'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8r_cust_inv as select from z8ps_custom_inv
{
    key pro_id as ProId,
    key inv_no as InvNo,
        insp_name as InspName,
        insp_res as InspRes,
        inspect_date as InspectDate,
        rej_reason as RejReason
}
