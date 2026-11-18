*&---------------------------------------------------------------------*
*& Include ZMMGR000TOP                              - Report ZMMGR000
*&---------------------------------------------------------------------*
REPORT z8mmgr100.

TABLES :
  z8plant_m,
  z8vendor_m,
  z8mm_po_hist,
  z8mm_po_h,
  z8mm_po_i,
  z8v_poh,
  z8mm_matdoc_h,
  z8mm_matdoc_i,
  z8fi_accdoc_h,
  z8fi_accdoc_i,
  z8v_matdoc,
  sscrfields.


TYPES : BEGIN OF ty_po_h.
          INCLUDE STRUCTURE z8v_poh.
TYPES :
          light type c LENGTH 1,
          bsart_txt  TYPE char20,
          status_txt TYPE char20,
        END OF ty_po_h.

TYPES : BEGIN OF ty_po_i.
          INCLUDE STRUCTURE z8mm_po_i.
TYPES :
          light type c LENGTH 1,
          status_txt TYPE char20,
          in_amt  TYPE z8mm_po_i-menge,
          prog_amt TYPE z8mm_po_i-menge,
          yet_amt TYPE z8mm_po_i-menge,
        END OF ty_po_i.


TYPES : BEGIN OF ty_matdoc_i.
          INCLUDE STRUCTURE z8v_matdoc.
TYPES :
        sup_name TYPE z8vendor_m-name1,
        plant_name type z8plant_m-name1,
        po_amt TYPE z8mm_po_i-menge,
        inv_ret TYPE char20,
        END OF ty_matdoc_i.

TYPES : BEGIN OF ty_stk_lock,
          matnr TYPE z8mm_po_i-matnr,
          werks TYPE z8mm_po_i-werks,
          lgort TYPE z8mm_po_i-lgort,
        END OF ty_stk_lock.

DATA :
  " 내가 잡고 있는 PO Lock 목록
  gt_locked_po TYPE SORTED TABLE OF z8mm_po_h-ebeln
               WITH UNIQUE KEY table_line,
  " INVO 중 잡은 재고/평가 Lock 목록
  gt_stk_lock  TYPE SORTED TABLE OF ty_stk_lock
               WITH UNIQUE KEY matnr werks lgort.

DATA : gv_err TYPE c LENGTH 1.     " INVO 오류 플래그

DATA :
  ok_code  TYPE sy-ucomm,
  save_ok  TYPE sy-ucomm,
  gv_ucomm TYPE sy-ucomm,

  "gv_pname type z8plant_m-name1,
  p_meins     TYPE z8mm_po_i-meins,
  gv_ebeln    TYPE z8mm_po_i-ebeln,
  gv_ebelp    TYPE z8mm_po_i-ebelp,

  gv_new_doc_mblnr TYPE z8mm_matdoc_h-mblnr ,
  gv_new_doc_no TYPE z8mm_matdoc_i-zeile,
  gv_ord_date TYPE ty_po_h-bedat,

*  gt_matdoc_i TYPE table of z8mm_matdoc_i,
*  gs_matdoc_i TYPE z8mm_matdoc_i,

  gv_werks TYPE z8plant_m-werks,
  gv_sup TYPE z8mm_po_h-lifnr,
  gv_date  TYPE datum.

DATA: gt_dynp   TYPE STANDARD TABLE OF dynpread,
      gs_dynp   TYPE dynpread.

*RANGES:
*  s_date FOR sy-datum.

" 1000, 100, 200
DATA :
  " alv
  gt_po_h          TYPE TABLE OF ty_po_h,
  gs_po_h          TYPE ty_po_h,
  gt_po_i          TYPE TABLE OF ty_po_i,
  gs_po_i          TYPE ty_po_i,

  go_dock_cont1    TYPE REF TO cl_gui_docking_container,
  go_split         TYPE REF TO cl_gui_splitter_container,

  go_cont01        TYPE REF TO cl_gui_container,
  go_cont02        TYPE REF TO cl_gui_container,

  go_header_alv    TYPE REF TO cl_gui_alv_grid,
  go_item_alv      TYPE REF TO cl_gui_alv_grid,

  gt_header_fcat_h TYPE lvc_t_fcat,
  gs_header_fcat_h TYPE lvc_s_fcat,

  gt_item_fcat_h   TYPE lvc_t_fcat,
  gs_item_fcat_h   TYPE lvc_s_fcat,

  gs_header_layout TYPE lvc_s_layo,
  gs_item_layout   TYPE lvc_s_layo,

  gt_header_sort type lvc_t_sort,
  gs_header_sort type lvc_s_sort,

  gt_item_sort type lvc_t_sort,
  gs_item_sort type lvc_s_sort
  .

" 300
DATA :
  " PO_HIST
  gt_po_hist    TYPE TABLE OF z8mm_po_hist,
  gs_po_hist    TYPE z8mm_po_hist,

  " ALV
  go_conf_cont       TYPE REF TO cl_gui_docking_container,
  go_conf_alv        TYPE REF TO cl_gui_alv_grid,

  gt_conf_fcat_h     TYPE lvc_t_fcat,
  gs_conf_fcat_h     TYPE lvc_s_fcat,

  gs_conf_layout     TYPE lvc_s_layo,

  gt_filter TYPE lvc_t_filt,
  gs_filter TYPE lvc_s_filt,

  tmpt_matdoc_i TYPE TABLE OF z8mm_matdoc_i,
  tmps_matdoc_i TYPE z8mm_matdoc_i,

  gt_matdoc_h   TYPE TABLE OF z8mm_matdoc_h,
  gs_matdoc_h   TYPE  z8mm_matdoc_h,

*  gt_matdoc_i   TYPE TABLE OF z8mm_matdoc_i,
*  gs_matdoc_i   TYPE z8mm_matdoc_i,

*  gt_matdoc_d   TYPE TABLE OF ty_matdoc_i,
*  gs_matdoc_d   TYPE ty_matdoc_i,

  gt_matdoc_i   TYPE TABLE OF ty_matdoc_i,
  gs_matdoc_i   TYPE ty_matdoc_i,

  gt_accdoc_h type TABLE OF z8fi_accdoc_h,
  gs_accdoc_h type z8fi_accdoc_h,

  gt_accdoc_i TYPE TABLE OF z8fi_accdoc_i,
  gs_accdoc_i TYPE z8fi_accdoc_i,

  gv_belnr type z8fi_accdoc_h-belnr.


SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME
  TITLE TEXT-bl1.
  " 지사 입력란
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(13) TEXT-s01 FOR FIELD p_werks.
    PARAMETERS p_werks TYPE z8plant_m-werks." MATCHCODE OBJECT z8sh_plant.
    SELECTION-SCREEN COMMENT 20(10) gv_pname.
  SELECTION-SCREEN END OF LINE.

  " 입고 예정 일자 입력란
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(13) TEXT-s03 FOR FIELD s_date.
    SELECTION-SCREEN POSITION 12.
    SELECT-OPTIONS : s_date FOR gv_date.
  SELECTION-SCREEN END OF LINE.

  " 공급사 입력란
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(13) TEXT-s02 FOR FIELD p_sup.
    SELECTION-SCREEN POSITION 15.
    PARAMETERS : p_sup TYPE z8vendor_m-lifnr
      "MATCHCODE OBJECT z8sh_vendor
      VISIBLE LENGTH 30.
    SELECTION-SCREEN COMMENT 26(10) gv_sup_t.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK blk1.


* ----------------------------
* 200번 스크린 영역 선언 시작
* ----------------------------
SELECTION-SCREEN BEGIN OF SCREEN 200. " 서브스크린으로 쓸 경우 AS SUBSCREEN 추가

  SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME
    TITLE TEXT-bl1.
    " 공급사
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s04 FOR FIELD p_sup2.
      PARAMETERS p_sup2    TYPE z8mm_po_h-lifnr MODIF ID nch.
      SELECTION-SCREEN COMMENT 30(15) gv_name.
    SELECTION-SCREEN END OF LINE.

    " 구매 오더 일자
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s05 FOR FIELD p_ordat.
      PARAMETERS p_ordat  TYPE z8mm_po_h-bedat MODIF ID nch.
    SELECTION-SCREEN END OF LINE.

    " 입고 일자
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s06 FOR FIELD p_date.
      PARAMETERS p_date   TYPE datum ."MODIF ID nch.
    SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK blk2.


  SELECTION-SCREEN BEGIN OF BLOCK blk3 WITH FRAME
    TITLE TEXT-bl2.
    " 플랜트
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s07 FOR FIELD p_plant.
      PARAMETERS p_plant  TYPE z8mm_po_i-werks MODIF ID nch.
    SELECTION-SCREEN END OF LINE.

    " 입고 일자
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s08 FOR FIELD p_strloc.
      PARAMETERS p_strloc TYPE z8mm_po_i-lgort MODIF ID nch.
    SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK blk3.

  SELECTION-SCREEN BEGIN OF BLOCK blk4 WITH FRAME
    TITLE TEXT-bl3.
    " 자재명
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s09 FOR FIELD p_matnam.
      PARAMETERS p_matnam TYPE z8mm_po_i-txz01 MODIF ID nch.
    SELECTION-SCREEN END OF LINE.

    " 자재 코드
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s10 FOR FIELD p_matcod.
      PARAMETERS p_matcod TYPE z8mm_po_i-matnr MODIF ID nch.
    SELECTION-SCREEN END OF LINE.

    " 재자 단가
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s11 FOR FIELD p_netpr.
      PARAMETERS p_netpr  TYPE p DECIMALS 0 MODIF ID nch. " 단가 수량
      SELECTION-SCREEN COMMENT 40(15) gv_peinh.  "화폐 단위
    SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK blk4.

  SELECTION-SCREEN BEGIN OF BLOCK blk5 WITH FRAME
    TITLE TEXT-bl4.
    " 구매 오더 총 구매 수량
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s12 FOR FIELD p_menge.
      PARAMETERS p_menge  TYPE p DECIMALS 0 MODIF ID nch.
      SELECTION-SCREEN COMMENT 40(15) gv_mein0. " 수량 단위
    SELECTION-SCREEN END OF LINE.


    "  검증 완료 자재 수량
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s13 FOR FIELD p_inv.
      PARAMETERS p_inv  TYPE p DECIMALS 0 MODIF ID nch.
      SELECTION-SCREEN COMMENT 40(15) gv_mein1. " 수량 단위
    SELECTION-SCREEN END OF LINE.

    " 입고 자재 수량
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s14 FOR FIELD p_in.
      "PARAMETER p_in     TYPE z8mm_po_i-menge.
      PARAMETERS p_in TYPE p DECIMALS 0.
      SELECTION-SCREEN COMMENT 40(15) gv_mein2. " 수량 단위
    SELECTION-SCREEN END OF LINE.

    " 반품 자재 수량
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-s15 FOR FIELD p_ret.
      PARAMETERS p_ret TYPE p DECIMALS 0.
      "PARAMETER p_ret    TYPE z8mm_po_i-menge.
      SELECTION-SCREEN COMMENT 40(15) gv_mein3. " 수량 단위
    SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK blk5.

SELECTION-SCREEN END OF SCREEN 200.
* ----------------------------
* 200번 스크린 영역 선언 종료
* ----------------------------
