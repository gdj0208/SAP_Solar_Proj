*&---------------------------------------------------------------------*
*& Include Z8SDBI0100TOP                            - Report Z8SDBI0100
*&---------------------------------------------------------------------*
REPORT Z8SDBI0100.

TABLES: z8sd_billing_h, z8sd_quotation_h, z8sd_so_h.
"선수금 목록 조회
TYPES: BEGIN OF ty_quot,
         light(1)     TYPE c,                 " 신호등
        icon TYPE icon-id,
         bill_tx    TYPE c LENGTH 10,                " 청구상태 텍스트
         vbeln_q    TYPE z8sd_quotation_h-vbeln_q,   " 견적번호
         audat      TYPE z8sd_quotation_h-audat,     " 견적일
         bill_limit TYPE sy-datum,   " 청구가능기한
         kunnr      TYPE z8sd_quotation_h-kunnr,     " 고객번호
         name1      TYPE z8customer_m-name1,        " 고객명
         bupla      TYPE z8sd_quotation_h-bupla,     " 종사업장
         branch_nm  TYPE z8branch_m-name,            " 종사업장명
         netwr      TYPE z8sd_quotation_h-netwr,     " 견적금액
         dp_amt     TYPE z8sd_billing_h-netwr,       " 선수금 예정액
         waerk      TYPE z8sd_quotation_h-waerk,     " 통화
         vbeln      TYPE z8sd_billing_h-vbeln,       " 청구번호
         fkdat      TYPE z8sd_billing_h-fkdat,       " 청구일
         zduedat    TYPE z8sd_billing_h-zduedat,     " 입금기한
         zzpayst    TYPE z8sd_billing_h-zzpayst,     " 입금상태 코드
        bill_amt TYPE z8sd_billing_h-netwr,
         pay_tx     TYPE c LENGTH 12,                " 입금상태 텍스트
         ct            TYPE lvc_t_styl,                               " 셀 스타일 (핫스팟)
       END OF ty_quot.

DATA: gt_quot TYPE TABLE OF ty_quot,
          gs_quot TYPE ty_quot.
DATA: ok_code TYPE sy-ucomm.

DATA: go_cont_quot   TYPE REF TO cl_gui_custom_container,
           go_alv_quot    TYPE REF TO cl_gui_alv_grid,
           gt_fcat_quot   TYPE lvc_t_fcat,
           gw_fcat_quot   TYPE lvc_s_fcat,
           gs_layout_quot TYPE lvc_s_layo.

"청구헤더
DATA: gs_bill_h     TYPE z8sd_billing_h,   " 생성 예정 청구 헤더
          gv_name1      TYPE z8customer_m-name1,
          gv_branch_nm  TYPE z8branch_m-name,
          gv_quot_netwr TYPE z8sd_quotation_h-netwr,
          gv_quot_waerk TYPE z8sd_quotation_h-waerk.

"청구문서 생성.
TYPES: BEGIN OF ty_prev,
         posnr      TYPE z8sd_billing_i-posnr,
         matnr      TYPE z8sd_billing_i-matnr,
         arktx      TYPE z8sd_billing_i-arktx,
         place_type TYPE z8sd_quotation_i-place_type,
         fkimg      TYPE z8sd_billing_i-fkimg,
         vrkme      TYPE z8sd_billing_i-vrkme,
         quot_amt   TYPE z8sd_quotation_i-netwr,   " 견적금액
         netwr      TYPE z8sd_billing_i-netwr,     " 청구금액
         rest_amt   TYPE z8sd_billing_i-netwr,     " 잔여금액
         waerk      TYPE z8sd_billing_i-waerk,
       END OF ty_prev.

DATA: gt_prev TYPE TABLE OF ty_prev,
      gs_prev TYPE ty_prev.
"품목 미리보기.
DATA: gt_bill_i TYPE TABLE OF z8sd_billing_i,   " 생성 예정 청구 품목
            gs_bill_i TYPE z8sd_billing_i,
            gv_err TYPE c LENGTH 1,
            gv_last_vbeln TYPE z8sd_billing_h-vbeln,
            gv_refresh_100 TYPE c LENGTH 1. "저장후 목록다시 읽기.

DATA: go_cont_prev   TYPE REF TO cl_gui_custom_container,
          go_alv_prev    TYPE REF TO cl_gui_alv_grid,
          gt_fcat_prev   TYPE lvc_t_fcat,
          gw_fcat_prev   TYPE lvc_s_fcat,
          gs_layout_prev TYPE lvc_s_layo.

"""""""""""""""""""잔금""""""""""""""""""""""""""
"잔금 목록 + 선수금 목록
TYPES: BEGIN OF ty_so,
         light     TYPE c LENGTH 1,
         icon      TYPE icon-id,
         bill_tx   TYPE c LENGTH 14,                " 청구상태
         vbeln     TYPE z8sd_billing_h-vbeln,       " 잔금 청구번호
         vbeln_s   TYPE z8sd_so_h-vbeln_s,          " SO번호
         audat     TYPE z8sd_so_h-audat,            " SO일
         kunnr     TYPE z8sd_so_h-kunnr,
         name1     TYPE z8customer_m-name1,
         bupla     TYPE z8sd_so_h-bupla,
         branch_nm TYPE z8branch_m-name,
         netwr     TYPE z8sd_so_h-netwr,            " SO금액
         dp_vbeln  TYPE z8sd_billing_h-vbeln,       " 선수금 청구번호
         dp_amt    TYPE z8sd_billing_h-netwr,       " 선수금
         dp_payst  TYPE z8sd_billing_h-zzpayst,     " 선수금 입금상태
         bal_amt   TYPE z8sd_billing_h-netwr,       " 잔금
         waerk     TYPE z8sd_so_h-waerk,
         vbeln_q   TYPE z8sd_so_h-vbeln_q,          " 견적번호 (운송·설치비 조회용)
         fkdat     TYPE z8sd_billing_h-fkdat,
         zduedat   TYPE z8sd_billing_h-zduedat,
         zzpayst   TYPE z8sd_billing_h-zzpayst,
          ct            TYPE lvc_t_styl,                               " 셀 스타일 (핫스팟
         pay_tx    TYPE c LENGTH 14,
       END OF ty_so.

DATA: gt_so TYPE TABLE OF ty_so,
      gs_so TYPE ty_so.

DATA: go_cont_so   TYPE REF TO cl_gui_custom_container,
      go_alv_so    TYPE REF TO cl_gui_alv_grid,
      gt_fcat_so   TYPE lvc_t_fcat,
      gw_fcat_so   TYPE lvc_s_fcat,
      gs_layout_so TYPE lvc_s_layo.

DATA: gv_fkart     TYPE z8sd_billing_h-fkart,   " ALV컬럼제목- 선수금/잔금
      gv_so_netwr  TYPE z8sd_so_h-netwr,
      gv_so_waerk  TYPE z8sd_so_h-waerk,
      gv_dp_vbeln  TYPE z8sd_billing_h-vbeln,
      gv_dp_amt    TYPE z8sd_billing_h-netwr,
      gv_dp_waerk TYPE z8sd_billing_h-waerk.

""""""""""""""""""""청구문서 상세 조회 + 청구 취소"""""""""""""""""""""""""""
DATA: gv_detail_vbeln TYPE z8sd_billing_h-vbeln,
          gv_fkart_tx   TYPE c LENGTH 10,
          gv_pay_tx     TYPE c LENGTH 14.

DATA: go_cont_detail   TYPE REF TO cl_gui_custom_container,
      go_alv_detail    TYPE REF TO cl_gui_alv_grid,
      gt_fcat_detail  TYPE lvc_t_fcat,
      gw_fcat_detail TYPE lvc_s_fcat,
      gs_layout_detail TYPE lvc_s_layo.
