@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '고객 Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity Z8_R_CUSTOMER 
as 
select from z8customer_m

{
    key kunnr as CustomerId,
    name1 as CustomerName,
    stcd2 as BusinessRegistrationNumber,
    land1 as Land,
    regio as Regio,
    ort01 as Ort01,
    pstlz as Pstlz,
    stras as Stras,
    telf1 as Telf1
    
}
