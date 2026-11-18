*&---------------------------------------------------------------------*
*& Include ZMMGR030TOP                              - 모듈풀              ZMMGR030
*&---------------------------------------------------------------------*
PROGRAM zmmgr030.

TABLES :
  z8plant_m,
  z8vendor_m,
  z8mm_inv_h,
  z8v_unb_inv
  .

TYPES : BEGIN OF ty_unb_inv.
          INCLUDE STRUCTURE z8v_unb_inv.
TYPES :
  LIGHT  type c LENGTH 1,
  STAT_TXT type c LENGTH 10,
  inv_no TYPE z8mm_inv_h-inv_no,
  END OF ty_unb_inv.

DATA:
  ok_code       TYPE sy-ucomm,

  gv_invno TYPE z8mm_inv_h-inv_no,
  gv_inv_sel type c,
  gv_werks TYPE z8plant_m-werks,
  gv_date  TYPE datum,
  gv_sup   TYPE z8vendor_m-lifnr.

RANGES:
  s_date FOR sy-datum.

DATA :
  " ALV
  go_cont       TYPE REF TO cl_gui_docking_container,
  go_alv        TYPE REF TO cl_gui_alv_grid,

  gt_fcat_h     TYPE lvc_t_fcat,
  gs_fcat_h     TYPE lvc_s_fcat,

  gs_layout     TYPE lvc_s_layo,

  gt_unb_inv   TYPE TABLE OF ty_unb_inv,
  gs_unb_inv   TYPE ty_unb_inv.

  DATA gv_done_ebeln TYPE z8mm_po_i-ebeln.   " 방금 송장 검증을 마친 PO
