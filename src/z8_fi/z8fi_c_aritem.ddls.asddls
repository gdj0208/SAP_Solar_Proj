@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '고객 채권 상세 조회'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8FI_C_ARItem 
as select from z8fi_customer as c

inner join z8ps_project as p
on p.pro_id = c.xblnr

left outer join z8sd_billing_h as b
on b.vgbel = p.vbeln
and b.fkart = 'F2'
and b.bukrs = c.bukrs
and b.bupla = c.bupla
and b.kunnr = c.kunnr

left outer join z8customer_m as cm
on cm.kunnr = c.kunnr

left outer join z8branch_m as bm
on bm.bukrs = c.bukrs
and bm.branch = c.bupla

{

 key c.bukrs as CompanyCode,
 key c.gjahr as FiscalYear,
 key c.belnr as AccountingDocument,
 
    c.bupla as Branch,
    bm.name as BranchName,
    c.kunnr as Customer,
    cm.name1 as CustomerName,
    
    c.budat as ReceivableDate,
    @Semantics.amount.currencyCode: 'Currency'
    c.wrbtr as ReceivableAmount,
    c.waers as Currency,
    
    c.xblnr as ProjectId,
    
    c.augbl as CollectionDocument,
    c.augdt as CollectionDate,
    c.auggj as CollectionFiscalYear,
    
    p.vbeln as SalesOrder,
    
    b.vbeln as BillingDocument,
    b.fkdat as BillingDate,
    b.zduedat as DueDate,
    b.zpaydat as PaymemtDate,
    b.zzpayst as PaymentStatus
    
}
