*&---------------------------------------------------------------------*
*& Include MZ8SDSO0700TOP                           - 모듈풀              SAPMZ8SDSO0700
*&---------------------------------------------------------------------*
PROGRAM sapmz8sdso0700.

DATA ok_code TYPE sy-ucomm.

DATA: gv_audat_from       TYPE z8sd_so_h-audat,
      gv_audat_to         TYPE z8sd_so_h-audat,
      gv_customer         TYPE z8customer_m-kunnr,
      gv_status           TYPE z8ps_project-status_p,
      gv_init_flag        TYPE abap_bool,
      gv_sel_line_flag    TYPE abap_bool,
      gv_selected_vbeln_q TYPE z8sd_so_h-vbeln_q.



DATA: BEGIN OF gw_so_h.
        INCLUDE TYPE z8sd_so_h.
DATA:   branch_txt         TYPE char60,
        plant_txt          TYPE char60,
        customer_txt       TYPE char60,
        so_txt             TYPE char60,
        dc_txt             TYPE char60,
        status_txt         TYPE dd07t-ddtext,
        sdate              TYPE z8ps_project-sdate,
        ct                 TYPE lvc_t_styl,
        btn_txt(10)        TYPE c,
        name1              TYPE z8customer_m-name1,
        pro_id             TYPE z8ps_project-pro_id,
        status_p           TYPE z8ps_project-status_p,
        project_status_txt TYPE char60,
        req_start_date     TYPE z8sd_quot_req-req_start_date,
        work_days          TYPE z8sd_quotation_h-work_days.
DATA: END OF gw_so_h.
DATA gt_so_h LIKE TABLE OF gw_so_h.

DATA: BEGIN OF gw_so_i.
         INCLUDE TYPE z8sd_so_i.
         DATA vbeln_q TYPE z8sd_so_h-vbeln_q.
         DATA waers1 TYPE z8sd_so_i-waers.
         DATA zzrtkpz TYPE z8material_m-zzrtkpz.
DATA: END OF gw_so_i.

DATA: gt_so_i LIKE TABLE OF gw_so_i.
*      gw_so_i LIKE LINE OF gt_so_i.

DATA: go_container   TYPE REF TO cl_gui_custom_container,
      go_container_h TYPE REF TO cl_gui_container,
      go_container_i TYPE REF TO cl_gui_container,
      go_alv_h       TYPE REF TO cl_gui_alv_grid,
      go_alv_i       TYPE REF TO cl_gui_alv_grid,
      gt_fcat_h      TYPE lvc_t_fcat,
      gw_fcat_h      TYPE lvc_s_fcat,
      gt_fcat_i      TYPE lvc_t_fcat,
      gw_fcat_i      TYPE lvc_s_fcat,
      gs_layout_h    TYPE lvc_s_layo,
      gs_layout_i    TYPE lvc_s_layo,
      gt_sort_i      TYPE lvc_t_sort,
      gs_sort_i      TYPE lvc_s_sort,
      gs_stable_h    TYPE lvc_s_stbl,
      gs_stable_i    TYPE lvc_s_stbl,
      go_split       TYPE REF TO cl_gui_splitter_container.

*설치일정 데이터
DATA: BEGIN OF gw_date.
 DATA sdate TYPE sy-datum."z8ps_project-sdate.
 DATA edate TYPE z8ps_project-edate.
DATA: END OF gw_date.

DATA: gv_search_so TYPE z8sd_deliv_h-vbeln_s,
      gv_bupla     TYPE z8branch_m-branch.

DATA: gw_proj_hist TYPE z8ps_proj_hist.
