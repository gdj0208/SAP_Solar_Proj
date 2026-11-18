@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Project Projection'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true



define root view entity Z8PS_C_PROJECT
  provider contract transactional_query
  as projection on Z8PS_R_PROJECT
{

  key     ProjectId,
          SalesOrderId,
          StartDate,
          EndDate,
          CustomerId,
          CustomerName,
          ActualStartDate,
          ActualEndDate,
          WorkDays,
          BranchCode,
          BranchName,
          ProjectStatus,
          ProjectStatusName,
          InstallAddress,
          TotalArea,
          CapacityKwp,
          EssYn,
          RequestDate,
          Erdat,
          Ernam,
          /* Associations */
          _Branch,
          _ProjectStatusText,
          _Tech : redirected to composition child Z8PS_C_TECH_HIST,
          _SalesOrder,
          //_AvailableTech,
          _AvailableInstall,
          _AvailableElec,

// HideAssignedTech와 HideAvailableTech는 DB에 저장된 필드가 아니므로 이 필드들의 값이 필요하면 ZCL_8PS_RACET_VIS 클래스로 계산
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_8PS_FACET_VIS'
          virtual HideAssignedTech  : abap_boolean,

          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_8PS_FACET_VIS'
          virtual HideAvailableTech : abap_boolean




}

