@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Object Page용 조회 CDS'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity Z8PS_R_AVAILABLE_TECH_OP
  as select from    z8ps_project   as Project
    cross join      Z8_R_EMPLOYEE  as Employee
    left outer join z8ps_tech_hist as Hist on Hist.pernr        =  Employee.PersonalNumber
                                           and(
                                             (
                                               Hist.sdate_a     is initial
                                               and Hist.edate_a is initial
                                               and Hist.sdate   <= Project.edate
                                               and Hist.edate   >= Project.sdate
                                             )

                                             or(
                                               Hist.sdate_a     is not initial
                                               and Hist.edate_a is initial
                                             )

                                             or(
                                               Hist.sdate_a     is not initial
                                               and Hist.edate_a is not initial
                                               and Hist.sdate_a <= Project.edate
                                               and Hist.edate_a >= Project.sdate
                                             )
                                           )

{
  key Project.pro_id          as ProjectId,
  key Employee.PersonalNumber as PersonalNumber,
      Employee.Ename,
      Employee.Grade,
      Employee.Stell,
      @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
      Employee.Capacity,
      Employee.CapacityUnit,
      Employee.Telnr,
      Employee.BranchName
}
where
      Project.status_p = '20'
  and Employee.Stat2   = '1'
  and Employee.IsEng   = 'X'
  and Hist.pernr       is null
  and Employee.BranchCode = Project.branch
