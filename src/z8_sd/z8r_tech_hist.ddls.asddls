// 1. 새로 생성할 Data Definition: z8r_tech_hist
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '배정 인력 및 투입 내역 View'
@Metadata.ignorePropagatedAnnotations: true
define view entity z8r_tech_hist
  as select from z8ps_tech_hist as t
  left outer join z8employee_m  as e  on t.pernr = e.pernr
  left outer join z8plant_m     as pl on e.bupla = pl.bupla
  association to parent z8r_projects as _Project on $projection.pro_id = _Project.pro_id
{
  key t.pro_id  as pro_id,
  key t.pernr   as pernr,
  key t.sdate as sdate,
      
      // z8plant_m에서 가져온 업장(부서) 명칭
      pl.name1  as branch_name, 
      
      e.ename   as emp_name,    // 직원 이름 
      e.grade   as emp_grade,   // 직원 등급 
      e.telnr   as emp_tel,     // 직원 연락처 
      t.edate as edate,
      t.sdate_a   as work_sdate,  // 실제 투입 시작일
      t.edate_a   as work_edate,  // 실제 투입 종료일 

      // 부모 뷰(프로젝트)로의 연결 고리 노출
      _Project
}
