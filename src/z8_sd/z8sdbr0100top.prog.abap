*&---------------------------------------------------------------------*
*& Include Z8SDBR0100TOP                            - Report Z8SDBR0100
*&---------------------------------------------------------------------*
REPORT Z8SDBR0100.
TABLES: z8sd_quotation_h,  z8sd_so_h..
"계약 목록
TYPES: BEGIN OF ty_contract,
        icon TYPE icon-id,
         light      TYPE c LENGTH 1,                    " 1 미진행 2 진행중 3 진행완료 4 폐기
         status_tx  TYPE c LENGTH 8,                    " 진행 상태
         vbeln_q    TYPE z8sd_quotation_h-vbeln_q,      " 견적번호
         audat      TYPE z8sd_quotation_h-audat,        " 견적일
         kunnr      TYPE z8sd_quotation_h-kunnr,
         name1      TYPE z8customer_m-name1,
         bupla      TYPE z8sd_quotation_h-bupla,
         branch_nm  TYPE z8branch_m-name,
         step1      TYPE icon-id,                       " 견적
         step2      TYPE icon-id,                       " 선수금 청구
         step3      TYPE icon-id,                       " 선수금 입금
         step4      TYPE icon-id,                       " 시공
         step5      TYPE icon-id,                       " 검수
         step6      TYPE icon-id,                       " 잔금 청구
         step7      TYPE icon-id,                       " 잔금 입금
         stage_tx   TYPE c LENGTH 30,                   " 현재 단계
         dept_tx    TYPE c LENGTH 10,                   " 담당 부서
         due_date   TYPE sy-datum,                      " 마감일
         sort_due   TYPE sy-datum,                      " 정렬용
         netwr      TYPE z8sd_quotation_h-netwr,        " 계약금액
         paid_amt   TYPE z8sd_quotation_h-netwr,        " 입금액
         open_amt   TYPE z8sd_quotation_h-netwr,        " 미수금
         waerk      TYPE z8sd_quotation_h-waerk,
         vbeln_s    TYPE z8sd_so_h-vbeln_s,             " SO번호
         status_p   TYPE z8ps_project-status_p,         " 프로젝트 상태
         dp_vbeln   TYPE z8sd_billing_h-vbeln,          " 선수금 청구번호
         dp_amt     TYPE z8sd_billing_h-netwr,
         dp_payst   TYPE z8sd_billing_h-zzpayst,
         dp_duedat  TYPE z8sd_billing_h-zduedat,
         bal_vbeln  TYPE z8sd_billing_h-vbeln,          " 잔금 청구번호
         bal_amt    TYPE z8sd_billing_h-netwr,
         bal_payst  TYPE z8sd_billing_h-zzpayst,
         bal_duedat TYPE z8sd_billing_h-zduedat,
         bill_due   TYPE sy-datum,                      " 청구 기한
         pay_due    TYPE sy-datum,                      " 입금 기한
  "── 상세 화면용 ──
         so_audat   TYPE z8sd_so_h-audat,                " SO일
         transit    TYPE z8sd_quotation_h-transit_cost,  " 운송비
         install    TYPE z8sd_quotation_h-install_cost,  " 설치비
         dp_fkdat   TYPE z8sd_billing_h-fkdat,           " 선수금 청구일
         dp_paydat  TYPE z8sd_billing_h-zpaydat,         " 선수금 입금일
         dp_belnr   TYPE z8sd_billing_h-belnr,           " 선수금 전표번호
         bal_fkdat  TYPE z8sd_billing_h-fkdat,           " 잔금 청구일
         bal_paydat TYPE z8sd_billing_h-zpaydat,         " 잔금 입금일
         bal_belnr  TYPE z8sd_billing_h-belnr,
         dp_gjahr   TYPE z8sd_billing_h-gjahr,          " 선수금 전표 회계연도
         bal_gjahr  TYPE z8sd_billing_h-gjahr,          " 잔금 전표 회계연도
         overdue    TYPE c LENGTH 1,                    " 입금기한 경과 X (4번에서 사용)

       END OF ty_contract.

DATA: gt_contract_all TYPE TABLE OF ty_contract, "조회한 전체 (보관용)
            gt_contract TYPE TABLE OF ty_contract,    "ALV 용.
            gs_contract TYPE ty_contract,
            gv_view TYPE c LENGTH 1 VALUE '0'.           " 0 전체 1 미진행 2 진행중 3 진행완료
DATA: gt_filter_contract TYPE lvc_t_filt,
      gs_filter_contract TYPE lvc_s_filt.

"상태- 건수 보관용
DATA: gv_cnt_all  TYPE i,
      gv_cnt_req  TYPE i,
      gv_cnt_prg  TYPE i,
      gv_cnt_done TYPE i.
DATA: ok_code TYPE sy-ucomm,
            gt_exclude_contract TYPE ui_functions.

DATA: go_cont_contract   TYPE REF TO cl_gui_custom_container,
      go_alv_contract    TYPE REF TO cl_gui_alv_grid,
      gt_fcat_contract   TYPE lvc_t_fcat,
      gw_fcat_contract   TYPE lvc_s_fcat,
      gs_layout_contract TYPE lvc_s_layo.

"""""""""""""""""""""""""""""상세화면"(200)"""""""""""""""""""""""""""""""""""""""
DATA: gs_detail   TYPE ty_contract,          " 선택한 계약
      gs_customer TYPE z8customer_m,        " 고객 정보
      gv_address    TYPE text100,
      gv_stage_disp TYPE text60,
      gv_due_label TYPE text20.

"입금 내역
TYPES: BEGIN OF ty_payment,
         kind_tx  TYPE c LENGTH 6,                   " 선수금 / 잔금
         vbeln    TYPE z8sd_billing_h-vbeln,         " 청구번호
         fkdat    TYPE z8sd_billing_h-fkdat,         " 청구일
         zduedat  TYPE z8sd_billing_h-zduedat,       " 입금기한
         pay_tx   TYPE c LENGTH 10,                  " 입금상태
         zpaydat  TYPE z8sd_billing_h-zpaydat,       " 입금일
         belnr    TYPE z8sd_billing_h-belnr,         " 전표번호
         bill_amt TYPE z8sd_billing_h-netwr,         " 청구금액
         paid_amt TYPE z8sd_billing_h-netwr,         " 입금액
         rest_amt TYPE z8sd_billing_h-netwr,         " 잔액
         waerk    TYPE z8sd_billing_h-waerk,
        gjahr       TYPE z8sd_billing_h-gjahr,             "회계연도
        ct            TYPE lvc_t_styl,                               " 셀 스타일 (핫스팟)
       END OF ty_payment.

DATA: gt_payment TYPE TABLE OF ty_payment,
      gs_payment TYPE ty_payment.

"계약 품목
TYPES: BEGIN OF ty_item,
         posnr      TYPE z8sd_quotation_i-posnr,
         matnr      TYPE z8sd_quotation_i-matnr,
         arktx      TYPE z8sd_quotation_i-arktx,
         place_type TYPE z8sd_quotation_i-place_type,
         kwmeng     TYPE z8sd_quotation_i-kwmeng,
         vrkme      TYPE z8sd_quotation_i-vrkme,
         netwr      TYPE z8sd_quotation_i-netwr,
         netpr      TYPE z8sd_quotation_i-netpr,      " 단가
         waerk      TYPE z8sd_quotation_h-waerk,
       END OF ty_item.

DATA: gt_item TYPE TABLE OF ty_item,
      gs_item TYPE ty_item.

DATA: go_cont_payment   TYPE REF TO cl_gui_custom_container,
      go_alv_payment    TYPE REF TO cl_gui_alv_grid,
      gt_fcat_payment   TYPE lvc_t_fcat,
      gw_fcat_payment   TYPE lvc_s_fcat,
      gs_layout_payment TYPE lvc_s_layo.

DATA: go_cont_item   TYPE REF TO cl_gui_custom_container,
      go_alv_item    TYPE REF TO cl_gui_alv_grid,
      gt_fcat_item   TYPE lvc_t_fcat,
      gw_fcat_item   TYPE lvc_s_fcat,
      gs_layout_item TYPE lvc_s_layo.
