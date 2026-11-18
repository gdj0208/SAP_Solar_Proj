@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SO Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8SD_R_SO 
as 
select from z8sd_so_h

association [1..1] to Z8_R_CUSTOMER as _Customer // 관계 정의
    on $projection.CustomerId = _Customer.CustomerId
{
    key vbeln_s as SalesOrderId,
    vbeln_q as QuotationId,
    kunnr as CustomerId,
    _Customer.CustomerName,
    vkorg as SalesOrganization,
    vtweg as DistributionChannel,
    bupla as Branch,
    werks as Plant,
    audat as Audat,
    vdatu as Vdatu,
    @Semantics.amount.currencyCode: 'Waerk'
    netwr as Netwr,
    waerk as Waerk,
    status_s as StatusS,
    ernam_so as ErnamSo,
    
    
    _Customer // 이 관계를 이 CDS 밖에서 사용할 수 있도록 공개 (expose, 즉 노출 시켜주는 작업)
}
