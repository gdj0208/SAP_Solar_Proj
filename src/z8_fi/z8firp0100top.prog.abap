*&---------------------------------------------------------------------*
*& Include Z8FIRP0100TOP                            - Report Z8FIRP0100
*&---------------------------------------------------------------------*
REPORT z8firp0100.

TABLES: z8fi_customer, z8fi_vendor.
TABLES: sscrfields.

DATA ok_code TYPE sy-ucomm.

CONSTANTS gc_bukrs TYPE z8company_m-bukrs VALUE '1000'.

"원천 데이터
DATA:
  gt_ar_detail TYPE STANDARD TABLE OF z8fi_c_aritem,
  gs_ar_detail TYPE z8fi_c_aritem.

"100번 화면
TYPES: BEGIN OF ty_ar_100,
         light(1) TYPE c,                            "신호등
         statt    TYPE c LENGTH 10,
         bukrs    TYPE z8fi_customer-bukrs,
         bupla    TYPE z8fi_customer-bupla,
         bname    TYPE c LENGTH 40,
         kunnr    TYPE z8fi_customer-kunnr,
         cname    TYPE c LENGTH 40,

         tot_amt  TYPE z8fi_customer-wrbtr, "전체
         col_amt  TYPE z8fi_customer-wrbtr, "반제
         bal_amt  TYPE z8fi_customer-wrbtr, "미결

         tot_cnt  TYPE i, "전체
         col_cnt  TYPE i, "반제
         open_cnt TYPE i, "미결

         waers    TYPE z8fi_customer-waers,
       END OF ty_ar_100.

DATA:
  gt_ar_100 TYPE STANDARD TABLE OF ty_ar_100,
  gs_ar_100 TYPE ty_ar_100.

"선택한 행
DATA gs_ar_sel TYPE ty_ar_100.

"200번 화면
TYPES: BEGIN OF ty_ar_200,
         light(1) TYPE c,
         statt    TYPE c LENGTH 10,
         bukrs    TYPE z8fi_customer-bukrs,
         bupla    TYPE z8fi_customer-bupla,
         bname    TYPE c LENGTH 40,

         pro_id   TYPE z8fi_customer-xblnr,
         belnr    TYPE z8fi_customer-belnr,
         gjahr    TYPE z8fi_customer-gjahr,
         budat    TYPE z8fi_customer-budat,
         ar_amt   TYPE z8fi_customer-wrbtr,

         augdt    TYPE z8fi_customer-augdt,
         augbl    TYPE z8fi_customer-augbl,
         auggj    TYPE z8fi_customer-auggj,

         col_amt  TYPE z8fi_customer-wrbtr,
         bal_amt  TYPE z8fi_customer-wrbtr,

         waers    TYPE z8fi_customer-waers,
         ct       TYPE lvc_t_styl,
       END OF ty_ar_200.

DATA:
  gt_ar_200 TYPE STANDARD TABLE OF ty_ar_200,
  gs_ar_200 TYPE ty_ar_200.

"스크린 페인터
TYPES: BEGIN OF ty_ar_sp,
         bukrs    TYPE z8fi_customer-bukrs,
         kunnr    TYPE z8fi_customer-kunnr,
         cname    TYPE c LENGTH 40,

         bupla TYPE z8branch_m-branch,
         buplat TYPE z8branch_m-name,

         stcd2    TYPE z8customer_m-stcd2,
         ort01    TYPE z8customer_m-ort01,
         stras    TYPE z8customer_m-stras,
         telf1    TYPE z8customer_m-telf1,
         gv_add   TYPE c LENGTH 80,


         tot_amt  TYPE z8fi_customer-wrbtr,
         col_amt  TYPE z8fi_customer-wrbtr,
         bal_amt  TYPE z8fi_customer-wrbtr,

         tot_cnt  TYPE i,
         col_cnt  TYPE i,
         open_cnt TYPE i,

         waers    TYPE z8fi_customer-waers,
       END OF ty_ar_sp.

DATA gs_ar_sp TYPE ty_ar_sp.

DATA:
  gv_waers1  TYPE waers,
  gv_waers2  TYPE waers,
  gv_waers3  TYPE waers,

  gv_tot_amt TYPE char20,
  gv_col_amt TYPE char20,
  gv_bal_amt TYPE char20.

****공급업체*******************************************************************
"원천 데이터
DATA:
  gt_ap_detail TYPE STANDARD TABLE OF z8fi_vendor,
  gs_ap_detail TYPE z8fi_vendor.

"300번 화면
TYPES: BEGIN OF ty_ap_300,
         light(1) TYPE c,                            "신호등
         statt    TYPE c LENGTH 10,
         bukrs    TYPE z8fi_vendor-bukrs,
         bupla    TYPE z8fi_vendor-bupla,
         bname    TYPE c LENGTH 40,
         lifnr    TYPE z8fi_vendor-lifnr,
         vname    TYPE c LENGTH 40,

         tot_amt  TYPE z8fi_vendor-wrbtr, "전체
         pay_amt  TYPE z8fi_vendor-wrbtr, "반제
         bal_amt  TYPE z8fi_vendor-wrbtr, "미결

         tot_cnt  TYPE i, "전체
         clr_cnt  TYPE i, "반제
         open_cnt TYPE i, "미결

         waers    TYPE z8fi_vendor-waers,
       END OF ty_ap_300.

DATA:
  gt_ap_300 TYPE STANDARD TABLE OF ty_ap_300,
  gs_ap_300 TYPE ty_ap_300.

"선택한 행
DATA gs_ap_sel TYPE ty_ap_300.

"400번 화면
TYPES: BEGIN OF ty_ap_400,
         light(1) TYPE c,
         statt    TYPE c LENGTH 10,
         bukrs    TYPE z8fi_vendor-bukrs,
         bupla    TYPE z8fi_vendor-bupla,
         bname    TYPE c LENGTH 40,

         inv_no   TYPE z8fi_vendor-xblnr,
         belnr    TYPE z8fi_vendor-belnr,
         gjahr    TYPE z8fi_vendor-gjahr,
         budat    TYPE z8fi_vendor-budat,
         ap_amt   TYPE z8fi_vendor-wrbtr,

         augdt    TYPE z8fi_vendor-augdt,
         augbl    TYPE z8fi_vendor-augbl,
         auggj    TYPE z8fi_vendor-auggj,

         pay_amt  TYPE z8fi_vendor-wrbtr,
         bal_amt  TYPE z8fi_vendor-wrbtr,

         waers    TYPE z8fi_vendor-waers,
         ct       TYPE lvc_t_styl,
       END OF ty_ap_400.

DATA:
  gt_ap_400 TYPE STANDARD TABLE OF ty_ap_400,
  gs_ap_400 TYPE ty_ap_400.

"스크린 페인터
TYPES: BEGIN OF ty_ap_sp,
         bukrs    TYPE z8fi_vendor-bukrs,
         lifnr    TYPE z8fi_vendor-lifnr,
         vname    TYPE c LENGTH 40,

         bupla TYPE z8branch_m-branch,
         buplat TYPE z8branch_m-name,

         stcd2    TYPE z8vendor_m-stcd2,
         ort01    TYPE z8vendor_m-ort01,
         stras    TYPE z8vendor_m-stras,
         telf1    TYPE z8vendor_m-telf1,
         gv_add   TYPE c LENGTH 80,


         tot_amt  TYPE z8fi_vendor-wrbtr,
         pay_amt  TYPE z8fi_vendor-wrbtr,
         bal_amt  TYPE z8fi_vendor-wrbtr,

         tot_cnt  TYPE i,
         clr_cnt  TYPE i,
         open_cnt TYPE i,

         waers    TYPE z8fi_vendor-waers,
       END OF ty_ap_sp.

DATA gs_ap_sp TYPE ty_ap_sp.

"ALV
DATA:
  go_cont_100 TYPE REF TO cl_gui_custom_container,
  go_alv_100  TYPE REF TO cl_gui_alv_grid.

DATA:
  go_cont_200 TYPE REF TO cl_gui_custom_container,
  go_alv_200  TYPE REF TO cl_gui_alv_grid.

DATA:
  go_cont_300 TYPE REF TO cl_gui_custom_container,
  go_alv_300  TYPE REF TO cl_gui_alv_grid.

DATA:
  go_cont_400 TYPE REF TO cl_gui_custom_container,
  go_alv_400  TYPE REF TO cl_gui_alv_grid.


"필드 카탈로그
DATA:
  gt_fcat_100 TYPE lvc_t_fcat,
  gs_fcat_100 TYPE lvc_s_fcat.

DATA:
  gt_fcat_200 TYPE lvc_t_fcat,
  gs_fcat_200 TYPE lvc_s_fcat.

DATA:
  gt_fcat_300 TYPE lvc_t_fcat,
  gs_fcat_300 TYPE lvc_s_fcat.

DATA:
  gt_fcat_400 TYPE lvc_t_fcat,
  gs_fcat_400 TYPE lvc_s_fcat.


"레이아웃
DATA gs_layout_100 TYPE lvc_s_layo.
DATA gs_layout_200 TYPE lvc_s_layo.
DATA gs_layout_300 TYPE lvc_s_layo.
DATA gs_layout_400 TYPE lvc_s_layo.


"alv 타이틀
DATA: gv_tot_cnt TYPE i,
      gv_op_cnt  TYPE i,
      gv_cl_cnt  TYPE i.

DATA:
  gt_sort_100 TYPE lvc_t_sort,
  gs_sort_100 TYPE lvc_s_sort,
  gt_sort_300 TYPE lvc_t_sort,
  gs_sort_300 TYPE lvc_s_sort.

"화면 갱신
DATA gv_refresh_100(1) TYPE c.
DATA gv_refresh_300(1) TYPE c.
DATA gs_stable TYPE lvc_s_stbl.

DATA:
      gv_ap_all_branch TYPE c LENGTH 1,
      gv_ar_all_branch TYPE c LENGTH 1,
      gv_other_branch TYPE c LENGTH 1.
