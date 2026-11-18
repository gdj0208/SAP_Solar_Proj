@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '가용 기술 인력 Interface View'
@Metadata.ignorePropagatedAnnotations: true


define view entity Z8PS_R_AVAILABLE_TECH
  with parameters
    p_project_id : z8e_pro_id //프로젝트 아이디의 Data Element

  as select from    Z8_R_EMPLOYEE    as Employee

  //넘겨받은 projectId 파라미터로 프로젝트 테이블 조회
    inner join      Z8PS_R_PROJECT   as Project on Project.ProjectId = $parameters.p_project_id

    left outer join Z8PS_R_TECH_HIST as Hist    on Hist.PersonalNumber       =  Employee.PersonalNumber

                                                and(
                                                  (
                                                    Hist.ActualStartDate     is initial
                                                    and Hist.ActualEndDate   is initial
                                                    and Hist.StartDate       <= Project.EndDate
                                                    and Hist.EndDate         >= Project.StartDate
                                                  )
                                                  or( // 실제 시작했지만 아직 종료되지 않은 경우 (프로젝트 진행중이므로 배정 불가)
                                                    Hist.ActualStartDate     is not initial
                                                    and Hist.ActualEndDate   is initial
                                                  )
                                                  or( // 실제 종료까지 완료된 경우
                                                    Hist.ActualStartDate     is not initial
                                                    and Hist.ActualEndDate   is not initial
                                                    and Hist.ActualStartDate <= Project.EndDate
                                                    and Hist.ActualEndDate   >= Project.StartDate
                                                  )
                                                )


{
  key Project.ProjectId,
  key Employee.PersonalNumber,
      Employee.Ename,
      Employee.Grade,
      Employee.Stell,
      @Semantics.quantity.unitOfMeasure: 'CapacityUnit'
      Employee.Capacity,
      Employee.CapacityUnit,
      Employee.Telnr,
      Project.SalesOrderId,
      Project.StartDate,
      Project.EndDate,
      Project.ActualStartDate,
      Project.ActualEndDate,
      Project.WorkDays,
      Project.BranchCode,
      Project.BranchName,
      Project.ProjectStatus,
      Project.ProjectStatusName,
      Project.InstallAddress,
      Project.TotalArea,
      Project.CapacityKwp,
      Project.EssYn,
      Project.RequestDate,
      Project.Erdat,
      Project.Ernam

}

// 신규 프로젝트의 기간과 Proj_Hist의 배정 기간이 겹치지 않는 직원 번호로 조회
where
      Hist.PersonalNumber is null
  and Employee.Stat2      = '1'
  and Employee.IsEng = 'X'
  and Project.BranchCode = Employee.BranchCode
