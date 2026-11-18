//@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '배정 인력 Projection View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity Z8C_tech_hist as projection on z8r_tech_hist
{
    key pro_id,
    key pernr,
    key sdate,
    
    branch_name,
    emp_name,
    emp_grade,
    emp_tel,
    edate,
    work_sdate,
    work_edate,
    
    /* Associations */
    _Project: redirected to parent z8c_projects
}
