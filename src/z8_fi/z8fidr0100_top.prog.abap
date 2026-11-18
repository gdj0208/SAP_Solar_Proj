*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_TOP
*&---------------------------------------------------------------------*


DATA ok_code TYPE sy-ucomm.

DATA: go_summary_container TYPE REF TO cl_gui_custom_container,
      go_html_viewer       TYPE REF TO cl_gui_html_viewer,
      gv_cnt_stock         TYPE i,  "재고 이동
      gv_cnt_invoice       TYPE i,  "매입 / 매출
      gv_cnt_payment       TYPE i,  "수금 / 지급
      gv_cnt_other         TYPE i,  "기타
      gv_cnt_mismatch      TYPE i.  "차대 불일치

DATA gs_variant TYPE disvariant.


DATA: gv_from   TYPE z8fi_accdoc_h-budat,
      gv_to     TYPE z8fi_accdoc_h-budat,
      gv_jahr   TYPE jahr,
      gv_type   TYPE z8fi_accdoc_h-blart,
      gv_belnr  TYPE z8fi_accdoc_h-belnr,
      gv_xblnr  TYPE z8fi_accdoc_h-xblnr,
      gv_status TYPE z8efi_status.




DATA: BEGIN OF gw_accdoc_h.
        INCLUDE TYPE z8fi_accdoc_h.
DATA:   kunnr      TYPE CHAR10,"z8customer_m-kunnr,
        name1      TYPE z8customer_m-name1,
        bupla      TYPE z8branch_m-branch,
        name       TYPE z8branch_m-name,
        wrbtr      TYPE z8fi_accdoc_i-wrbtr,
        ltext      TYPE t003t-ltext, "업무구분 텍스트
        light(1)   TYPE c,
        status_f   TYPE z8efi_status,
        status_txt TYPE char60.
DATA: END OF gw_accdoc_h.

DATA gt_accdoc_h LIKE TABLE OF gw_accdoc_h.

DATA: BEGIN OF gw_accdoc_i.
        INCLUDE TYPE z8fi_accdoc_i.
DATA:   name  TYPE z8branch_m-name,
        name1 TYPE z8customer_m-name1,
        vname TYPE z8vendor_m-name1,
        lfinr TYPE z8vendor_m-lifnr.
DATA: END OF gw_accdoc_i.

DATA gt_accdoc_i LIKE TABLE OF gw_accdoc_i.

DATA: go_container TYPE REF TO cl_gui_custom_container,
      go_alv       TYPE REF TO cl_gui_alv_grid,
      gt_fcat      TYPE lvc_t_fcat,
      gw_fcat      TYPE lvc_s_fcat,
      gs_layout    TYPE lvc_s_layo,
      gs_stable    TYPE lvc_s_stbl.

DATA BEGIN OF gs_detail_h.
INCLUDE TYPE z8fi_accdoc_h.
DATA: ltext TYPE t003t-ltext,
      butxt TYPE z8company_m-butxt.

DATA END OF gs_detail_h.

DATA BEGIN OF gw_detail_i.
      INCLUDE TYPE z8fi_accdoc_i.
      DATA: txt20   TYPE z8glacc_m-txt20,
            name1_v TYPE z8vendor_m-name1,
            name TYPE z8branch_m-name,
            debit TYPE z8fi_accdoc_i-wrbtr,
            credit TYPE z8fi_accdoc_i-wrbtr,
            wrbtr_txt TYPE char4,
            name1_c TYPE z8customer_m-name1.

DATA END OF gw_detail_i.

DATA:  gt_detail_i LIKE TABLE OF gw_detail_i.

DATA: go_container200 TYPE REF TO cl_gui_custom_container,
      go_alv200       TYPE REF TO cl_gui_alv_grid,
      gt_fcat200      TYPE lvc_t_fcat,
      gw_fcat200      TYPE lvc_s_fcat,
      gs_layout200    TYPE lvc_s_layo,
      gs_stable200    TYPE lvc_s_stbl.

DATA: gv_detail_debit  TYPE z8fi_accdoc_i-wrbtr,
      gv_detail_credit TYPE z8fi_accdoc_i-wrbtr,
      gv_detail_diff   TYPE z8fi_accdoc_i-wrbtr.


DATA: gv_detail_debit_txt  TYPE c LENGTH 15,
      gv_detail_credit_txt TYPE c LENGTH 15,
      gv_detail_diff_txt   TYPE c LENGTH 15,
      gv_detail_msg    TYPE c LENGTH 30,
      gv_detail_icon TYPE icons-text.

"타 프로그램으로부터 전달 받을 변수
DATA: gv_ext_bukrs TYPE z8fi_accdoc_h-bukrs,
      gv_ext_belnr TYPE z8fi_accdoc_h-belnr,
      gv_ext_gjahr TYPE z8fi_accdoc_h-gjahr.

TABLES: z8fi_accdoc_h, z8fi_accdoc_i.
