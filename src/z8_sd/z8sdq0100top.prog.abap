*&---------------------------------------------------------------------*
*& Include Z8SDQ0100TOP                             - Report Z8SDQ0100
*&---------------------------------------------------------------------*
REPORT z8sdq0100.

DATA: gs_variant  TYPE disvariant,
      gv_req_mode TYPE c LENGTH 1,
      gv_answer   TYPE c.

DATA: go_custom1301 TYPE REF TO cl_gui_custom_container.

DATA: gv_subscreen TYPE sy-dynnr.

DATA: gv_audat_from    TYPE z8sd_quotation_h-audat,
      gv_audat_to      TYPE z8sd_quotation_h-audat,
      gv_customer      TYPE z8customer_m-kunnr,
      gv_init_flag     TYPE abap_bool,
      gv_search_status TYPE z8sd_quotation_h-status,
      gv_vbeln_q       TYPE z8sd_quotation_h-vbeln_q,
      gv_bupla_search  TYPE z8branch_m-branch.



DATA: ok_code      TYPE sy-ucomm,
      go_container TYPE REF TO cl_gui_custom_container,
      go_alv       TYPE REF TO cl_gui_alv_grid,
      gt_fcat      TYPE lvc_t_fcat,
      gw_fcat      TYPE lvc_s_fcat,
      gs_layout    TYPE lvc_s_layo.

DATA: gs_quot_detail    TYPE z8v_quotation,
      gv_status         TYPE char30,
      gv_region_txt     TYPE z8region_m-region_text,
      gv_mat_total      TYPE char30,
      gv_trans          TYPE char30,
      gv_inst           TYPE char30,
      gv_tot            TYPE char30,
      gv_reject_message TYPE char50,
      gv_reason         TYPE char30.

DATA: go_container1200 TYPE REF TO cl_gui_custom_container,
      go_alv1200       TYPE REF TO cl_gui_alv_grid,
      gt_fcat1200      TYPE lvc_t_fcat,
      gw_fcat1200      TYPE lvc_s_fcat,
      gs_layout1200    TYPE lvc_s_layo,
      gs_stable1200    TYPE lvc_s_stbl.

DATA: go_container1300     TYPE REF TO cl_gui_custom_container,
      go_container1300_h   TYPE REF TO cl_gui_container,
      go_container1300_i   TYPE REF TO cl_gui_container,
      go_alv1300_h         TYPE REF TO cl_gui_alv_grid,
      go_alv1300_i         TYPE REF TO cl_gui_alv_grid,
      gt_fcat1300          TYPE lvc_t_fcat,
      gw_fcat1300          TYPE lvc_s_fcat,
      gt_fcat1300_i        TYPE lvc_t_fcat,
      gw_fcat1300_i        TYPE lvc_s_fcat,
      gs_layout1300        TYPE lvc_s_layo,
      gs_layout1300_i      TYPE lvc_s_layo,
      gt_sort1300_i        TYPE lvc_t_sort,
      gw_sort1300_i        LIKE LINE OF gt_sort1300_i,
      gs_stable1300        TYPE lvc_s_stbl,
      go_docking_container TYPE REF TO cl_gui_docking_container,
      go_split             TYPE REF TO cl_gui_splitter_container.

DATA: BEGIN OF gw_quot_list.
        INCLUDE TYPE z8sd_quotation_h.
DATA vkorg_txt TYPE char60.
DATA vtweg_txt  TYPE char60.
DATA kunnr_txt TYPE char60.
DATA bupla_txt TYPE char60.
DATA werks_txt TYPE char60.
DATA status_txt TYPE char60.
DATA reject_reason_txt TYPE char60.
DATA zzpayst TYPE z8sd_billing_h-zzpayst.
DATA pay_status_txt TYPE char60.
DATA request_date TYPE z8sd_quot_req-request_date.
DATA light(1) TYPE c.
DATA region_txt TYPE z8region_m-region_text.
DATA email TYPE z8sd_quot_req-email.
DATA send_btn TYPE char10.
DATA mail_sent TYPE abap_bool.
DATA ct TYPE lvc_t_styl.
DATA END OF gw_quot_list.
DATA: gt_quot_list LIKE TABLE OF gw_quot_list.

DATA: BEGIN OF gw_quot_item.
        INCLUDE TYPE z8sd_quotation_i.
DATA waers1 TYPE z8sd_quotation_i-waers.
DATA: END OF gw_quot_item.
DATA gt_quot_item LIKE TABLE OF gw_quot_item.


DATA gs_req TYPE z8sd_quot_req.
DATA gv_region_text TYPE z8region_m-region_text.
DATA gv_bupla TYPE z8branch_m-branch.
DATA gv_plant TYPE z8plant_m-werks.
DATA gv_netwr_disp TYPE char20.
DATA gv_transit_cost_disp TYPE char20.
DATA gv_install_cost_disp TYPE char20.
DATA gv_mat_total_disp TYPE char20.
DATA gv_1300_reqid TYPE z8sd_quotation_h-request_id.
DATA: tab1 TYPE c LENGTH 40,
      tab2 TYPE c LENGTH 40.
DATA gv_selected_id TYPE z8sd_quotation_h-vbeln_q.
DATA: BEGIN OF gs_reject,
        code TYPE z8sd_quotation_h-reject_reason,
        text TYPE dd07t-ddtext,
      END OF gs_reject.
DATA gt_reject LIKE TABLE OF gs_reject.

CONTROLS: tabstrip1300 TYPE TABSTRIP.


*엑셀에서 읽어온 데이터를 담을 내부 구조/인터널 테이블
DATA: BEGIN OF gs_excel_head,
        request_id TYPE z8sd_quot_req-request_id,
        total_area TYPE z8sd_quotation_h-total_area,
      END OF gs_excel_head.

DATA: BEGIN OF gs_excel_item,
        posnr      TYPE z8sd_quotation_i-posnr,
        matnr      TYPE z8sd_quotation_i-matnr,
        kwmeng     TYPE z8sd_quotation_i-kwmeng,
        vrkme      TYPE z8sd_quotation_i-vrkme,
        place_type TYPE z8sd_quotation_i-place_type,
        light(1)   TYPE c, "Trreshold 값 (1 - 빨, 2- 노, 3- 초),
*        light      TYPE icons-text,
        result     TYPE char10,
        message    TYPE char100,
        arktx      TYPE z8sd_quotation_i-arktx,
      END OF gs_excel_item.
DATA gt_excel_item LIKE TABLE OF gs_excel_item.


DATA: BEGIN OF gw_quot_i,
        vbeln_q    TYPE z8sd_quotation_i-vbeln_q,
        posnr      TYPE z8sd_quotation_i-posnr, "항목
        place_type TYPE z8sd_quotation_i-place_type, "설치 장소
        matnr      TYPE z8sd_quotation_i-matnr, "자재
        arktx      TYPE z8material_txt_m-maktx,
        kwmeng     TYPE z8sd_quotation_i-kwmeng, "수량
        vrkme      TYPE z8sd_quotation_i-vrkme, "단위
        netpr      TYPE z8sd_quotation_i-netpr, "자재 별 단가
        waers      TYPE z8sd_quotation_i-waers,
        netwr      TYPE z8sd_quotation_i-netwr, "자재 당 총 금액
        stock      TYPE menge_d, "1200에서만 보여줄 참고값 - 배정 된 플랜트의 가용재고
        meins      TYPE z8material_stk_m-meins,
        message    TYPE c LENGTH 50,
        waers1     TYPE z8sd_quotation_i-waers,
      END OF gw_quot_i.
DATA gt_quot_i LIKE TABLE OF gw_quot_i.

DATA BEGIN OF gs_quot_h.
INCLUDE TYPE z8sd_quotation_h.
DATA bupla_txt TYPE char30.
DATA plant_txt TYPE char30.
DATA END OF gs_quot_h.


DATA: BEGIN OF gw_plant,
        werks        TYPE z8plant_m-werks,
        region_code  TYPE z8plant_m-region_code,
        bupla        TYPE z8plant_m-bupla,
        transit_days TYPE z8route_m-est_transit_days,
        trans_cost   TYPE z8distance_m-kbetr,
        waers        TYPE z8distance_m-waers,
      END OF gw_plant.
DATA: gt_plant LIKE TABLE OF gw_plant.


TABLES:     sscrfields.

SELECTION-SCREEN FUNCTION KEY: 1, 2, 3.

*
*TABLES z8sd_quotation_h.
*
*SELECTION-SCREEN BEGIN OF SCREEN 1330 AS SUBSCREEN.
*  SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-003.
*    SELECT-OPTIONS:
*      so_date FOR z8sd_quotation_h-audat, "견적 작성일
*      so_qid FOR z8sd_quotation_h-vbeln_q.
*    PARAMETERS:
*      pa_stat TYPE z8sd_quotation_h-status,
*      pa_bupla TYPE z8sd_quotation_h-bupla.
*  SELECTION-SCREEN END OF BLOCK b1.
*SELECTION-SCREEN END OF SCREEN 1330.
