@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Z8_PS_PROJECT View'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8V_PROJECT as select from z8ps_project
{
        @EndUserText.label: '프로젝트 ID'
    key pro_id as ProId,
        @EndUserText.label: 'SO 번호'
        vbeln as Vbeln,
        @EndUserText.label: '예정 시작일'
        sdate as Sdate,
        @EndUserText.label: '예정 종료일'
        edate as Edate,
        @EndUserText.label: '실제 시작일'
        sdate_a as SdateA,
        @EndUserText.label: '예정 종료일'
        edate_a as EdateA,
        @EndUserText.label: '작업 일수'
        work_days as WorkDays,
        @EndUserText.label: '작업 부서'
        branch as Branch,
        @EndUserText.label: '진행 상태'
        status_p as StatusP,
        @EndUserText.label: '설치 주소'
        install_address as InstallAddress,
        total_area as TotalArea,
        capacity_kwp as CapacityKwp,
        ess_yn as EssYn,
        request_date as RequestDate,
        erdat as Erdat
}
