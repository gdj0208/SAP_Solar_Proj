@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '테스트용 직원 테이블 프로젝션 뷰'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity z8_c_emp_test as select from z8_emp_test
{
    key Pernr,
    Bukrs,
    Ename
}
