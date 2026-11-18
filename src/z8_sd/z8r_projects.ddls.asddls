@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK  
@EndUserText.label: 'PROJECT - SO_H - CUSTOMER view'
@Metadata.ignorePropagatedAnnotations: true

define root view entity z8r_projects 
    as select from z8ps_project as p
    inner join z8sd_so_h as h on p.vbeln = h.vbeln_s
    left outer join z8sd_deliv_h as dh on p.vbeln = dh.vbeln_s
                                  and h.vbeln_s = dh.vbeln_s
    association [1..1] to z8customer_m as cus 
        on cus.kunnr = h.kunnr
    association [0..*] to z8r_Materials as _Materials 
        on $projection.vbeln = _Materials.Vbeln
    composition [0..*] of z8r_tech_hist as _TechHist
    association [0..1] to z8i_status_text as _StatusText 
        on $projection.status = _StatusText.StatusCode
    association [0..1] to z8i_deliv_text as _DelivText 
        on $projection.del_status = _DelivText.StatusCode
    association [0..1] to z8R_plant_text as _PLANT_TXT
        on $projection.branch = _PLANT_TXT.Bupla
    
{
        @EndUserText.label: '프로젝트 번호'
    key p.pro_id as pro_id,
    
        @EndUserText.label: 'SO 번호'
        p.vbeln as vbeln,
        
        @EndUserText.label: '진행 상태'
        p.status_p as status,
        _StatusText.StatusText as status_text,
        
        @EndUserText.label: '자재 준비 상태'
        dh.status_d as del_status,
        _DelivText.StatusText as del_stat_text,
        
        @EndUserText.label: '고객'
        cus.name1 as name,
        
        @EndUserText.label: '지사 코드'
        p.branch as branch,
        
        @EndUserText.label: '지사명'
        _PLANT_TXT.Name1 as branch_name,
        
        @EndUserText.label: '설치 주소'
        p.install_address as address,
        
        @EndUserText.label: '예정 시작일'
        p.sdate as sdate,
        
        @EndUserText.label: '예정 종료일'
        p.edate as edate,
        
        @EndUserText.label: '실제 시작일'
        p.sdate_a as real_sdate,
        
        @EndUserText.label: '실제 종료일'
        p.edate_a as real_edate,
        
    // 상태값에 따라 버튼을 숨기는 제어용 필드 ('' = 보임, 'X' = 숨김)
    cast( case when p.status_p = '30' then '' else 'X' end as abap_boolean ) as hide_start_btn,
    cast( case when p.status_p = '40' then '' else 'X' end as abap_boolean ) as hide_comp_btn,
    cast( case when p.status_p = '50' then '' else 'X' end as abap_boolean ) as hide_insp_btn,
    cast( case when p.status_p = '50' then '' else 'X' end as abap_boolean ) as hide_rej_btn,

    // Association 노출
    _TechHist,
    _StatusText,
    _PLANT_TXT,
    _Materials
}
