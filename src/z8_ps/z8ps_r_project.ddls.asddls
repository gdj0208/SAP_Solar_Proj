@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project Interface View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define root view entity Z8PS_R_PROJECT
  as select from z8ps_project as Project

  composition [0..*] of Z8PS_R_TECH_HIST         as _Tech

  association [0..1] to Z8_R_BRANCH              as _Branch        on  $projection.BranchCode = _Branch.BranchCode

  association [0..1] to I_DomainFixedValueText   as _ProjectStatusText //텍스트가 없을 수도 있고(0), 있으면 하나(1)
                                                                   on  _ProjectStatusText.SAPDataDictionaryDomain = 'Z8D_PROJ_STATUS'
                                                                   and _ProjectStatusText.DomainValue             = $projection.ProjectStatus
                                                                   and _ProjectStatusText.Language                = $session.system_language



  association [1]    to Z8SD_R_SO                   as _SalesOrder on  $projection.SalesOrderId = _SalesOrder.SalesOrderId

  // association [0..*] to Z8PS_R_AVAILABLE_TECH_OP as _AvailableTech on  $projection.ProjectId = _AvailableTech.ProjectId

  association [0..*] to Z8PS_R_AVAILABLE_INSTALL_OP as _AvailableInstall on $projection.ProjectId = _AvailableInstall.ProjectId
  association [0..*] to Z8PS_R_AVAILABLE_ELEC_OP as _AvailableElec on $projection.ProjectId = _AvailableElec.ProjectId 
{
  key pro_id                        as ProjectId,
      vbeln                         as SalesOrderId,
      sdate                         as StartDate,
      edate                         as EndDate,
      sdate_a                       as ActualStartDate,
      edate_a                       as ActualEndDate,
      work_days                     as WorkDays,
      branch                        as BranchCode,
      _Branch.BranchName            as BranchName,
      status_p                      as ProjectStatus,
      _ProjectStatusText.DomainText as ProjectStatusName,
      install_address               as InstallAddress,
      total_area                    as TotalArea,
      capacity_kwp                  as CapacityKwp,
      ess_yn                        as EssYn,
      request_date                  as RequestDate,
      erdat                         as Erdat,
      ernam                         as Ernam,


      _SalesOrder.CustomerId        as CustomerId,
      _SalesOrder.CustomerName      as CustomerName,



      _Tech,
      _Branch,
      _ProjectStatusText,
      _SalesOrder,
      //_AvailableTech,
      _AvailableInstall,
      _AvailableElec
      
}
