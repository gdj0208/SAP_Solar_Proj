*&---------------------------------------------------------------------*
*& Include Z8FIGL0100TOP                            - Report Z8FIGL0100
*&---------------------------------------------------------------------*
REPORT z8figl0100.

TABLES: z8fi_accdoc_i, z8fi_accdoc_h, z8glacc_m, z8glcompany_m, z8branch_m.
TABLES: sscrfields.

DATA ok_code TYPE sy-ucomm.


CONSTANTS gc_bukrs TYPE z8company_m-bukrs VALUE '1000'.

DATA:
  gt_glacc TYPE STANDARD TABLE OF z8glacc_m,
  gs_glacc TYPE z8glacc_m.

TYPES: BEGIN OF ty_gl_detail,
         bukrs TYPE z8fi_accdoc_i-bukrs,
         bupla TYPE z8fi_accdoc_i-bupla,
         belnr TYPE z8fi_accdoc_i-belnr,
         gjahr TYPE z8fi_accdoc_i-gjahr,
         buzei TYPE z8fi_accdoc_i-buzei,
         hkont TYPE z8fi_accdoc_i-hkont,
         budat TYPE z8fi_accdoc_h-budat,
         monat TYPE z8fi_accdoc_h-monat,
         blart TYPE z8fi_accdoc_h-blart,
         xblnr TYPE z8fi_accdoc_h-xblnr,
         shkzg TYPE z8fi_accdoc_i-shkzg,
         wrbtr TYPE z8fi_accdoc_i-wrbtr,
         waers TYPE z8fi_accdoc_i-waers,
       END OF ty_gl_detail.

DATA:
  gt_gl_detail TYPE STANDARD TABLE OF ty_gl_detail,
  gs_gl_detail TYPE ty_gl_detail.

"100번 화면
TYPES: BEGIN OF ty_alv_100,
         saknr   TYPE z8glacc_m-saknr, "계정
         txt20   TYPE z8glacc_m-txt20, "계정명
         debit   TYPE z8fi_accdoc_i-wrbtr, "차변
         credit  TYPE z8fi_accdoc_i-wrbtr, "대변
         shkzg   TYPE z8fi_accdoc_i-shkzg, "차/대 구분
         bal_txt TYPE c LENGTH 4,
         bal_amt TYPE z8fi_accdoc_i-wrbtr, "잔액
         waers   TYPE z8fi_accdoc_i-waers, "통화
       END OF ty_alv_100.

DATA:
  gt_alv_100 TYPE STANDARD TABLE OF ty_alv_100,
  gs_alv_100 TYPE ty_alv_100.

"100번에서 선택한 계정
DATA:
      gs_gl_sel TYPE ty_alv_100.

"200번
TYPES: BEGIN OF ty_alv_200,
         bukrs     TYPE z8fi_accdoc_i-bukrs,
         budat     TYPE z8fi_accdoc_h-budat,
         belnr     TYPE z8fi_accdoc_i-belnr,
         gjahr     TYPE z8fi_accdoc_i-gjahr,
         buzei     TYPE z8fi_accdoc_i-buzei,
         blart     TYPE z8fi_accdoc_h-blart,
         blart_txt TYPE t003t-ltext,
         xblnr     TYPE z8fi_accdoc_h-xblnr,
         bupla     TYPE z8fi_accdoc_i-bupla,
         bupla_txt TYPE z8branch_m-name,
         shkzg     TYPE z8fi_accdoc_i-shkzg,
         shkzg_txt TYPE c LENGTH 4,
         debit     TYPE z8fi_accdoc_i-wrbtr,
         credit    TYPE z8fi_accdoc_i-wrbtr,
         bal_txt   TYPE c LENGTH 20,
         bal_amt   TYPE z8fi_accdoc_i-wrbtr,
         waers     TYPE z8fi_accdoc_i-waers,
         ct        TYPE lvc_t_styl,
       END OF ty_alv_200.

DATA:
  gt_alv_200 TYPE STANDARD TABLE OF ty_alv_200,
  gs_alv_200 TYPE ty_alv_200.

"html
DATA:
  gv_bal_cnt  TYPE i, "전체 gl계정 수
  gv_used_cnt TYPE i, "거래 발생 계정 수
  gv_dtotal   TYPE z8fi_accdoc_i-wrbtr, "차변 누계
  gv_ctotal   TYPE z8fi_accdoc_i-wrbtr, "대변 누계
  gv_waers    TYPE z8fi_accdoc_i-waers. "통화

"200번 상단 조회 조건
DATA:
  gv_budat_fr  TYPE z8fi_accdoc_h-budat,
  gv_budat_to  TYPE z8fi_accdoc_h-budat,
  gv_bupla TYPE z8fi_accdoc_i-bupla,
  gv_buplat TYPE z8branch_m-name,
*  gv_bupla_fr  TYPE z8fi_accdoc_i-bupla,
*  gv_bupla_to  TYPE z8fi_accdoc_i-bupla,
  gv_blart     TYPE z8fi_accdoc_h-blart,
*  gv_bupla_fix TYPE c LENGTH 1,
  gv_error     TYPE c LENGTH 1,
  gv_blartt    TYPE t003t-ltext.

DATA:
      gv_org_budat_fr TYPE z8fi_accdoc_h-budat,
      gv_org_budat_to TYPE z8fi_accdoc_h-budat.
*      gv_org_bupla_fr TYPE z8fi_accdoc_i-bupla,
*      gv_org_bupla_to TYPE z8fi_accdoc_i-bupla.

DATA:
      gt_return TYPE TABLE OF ddshretval,
      gs_return TYPE ddshretval,
      gt_dynp   TYPE TABLE OF dynpread,
      gs_dynp   TYPE dynpread.

DATA:
  go_cont_100     TYPE REF TO cl_gui_custom_container,
  go_split_100    TYPE REF TO cl_gui_splitter_container,
  go_cont_html    TYPE REF TO cl_gui_container,
  go_cont_alv_100 TYPE REF TO cl_gui_container,

  go_html_viewer  TYPE REF TO cl_gui_html_viewer,
  go_alv_100      TYPE REF TO cl_gui_alv_grid.

"필드 카탈로그
DATA:
  gt_fcat_100 TYPE lvc_t_fcat,
  gs_fcat_100 TYPE lvc_s_fcat.


"레이아웃
DATA gs_layout_100 TYPE lvc_s_layo.
*DATA gs_layout_html TYPE lvc_s_layo.

"정렬
DATA gt_sort TYPE lvc_t_sort.
DATA gs_sort TYPE lvc_s_sort.

"200번 alv
DATA:
  go_cont_200   TYPE REF TO cl_gui_custom_container,
  go_alv_200    TYPE REF TO cl_gui_alv_grid,

  gt_fcat_200   TYPE lvc_t_fcat,
  gs_fcat_200   TYPE lvc_s_fcat,

  gs_layout_200 TYPE lvc_s_layo.

"화면 갱신
DATA gv_refresh_100(1) TYPE c.
DATA gs_stable TYPE lvc_s_stbl.
