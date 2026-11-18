@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '테스트용 직원 테이블'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity z8_emp_test as select from z8employee_m
{
    key pernr as Pernr,
    bukrs as Bukrs,
    ename as Ename
}
