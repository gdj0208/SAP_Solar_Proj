*&---------------------------------------------------------------------*
*& Include ZMMGR030TOP                              - 모듈풀              ZMMGR030
*&---------------------------------------------------------------------*
PROGRAM zmmgr030.

TABLES :
  z8plant_m,
  z8vendor_m,
  z8mm_po_i,
  z8mm_po_hist,
  z8mm_inv_h,
  z8mm_inv_i,
  z8fi_vendor,
  z8v_3comp
  .

TYPES : BEGIN OF ty_3comp.
          INCLUDE STRUCTURE z8v_3comp.
TYPES :
          inv_no     TYPE inv_no,
          qunt_light TYPE char1,
          amnt_light TYPE char1,
          uneq       TYPE char10,
          "qunt_color type c length 4,
          "amnt_color type c length 4,
        END OF ty_3comp.


TYPES : BEGIN OF ty_inv_i.
          INCLUDE STRUCTURE z8mm_inv_i.
TYPES :
          maktx TYPE z8material_txt_m-maktx,
        END OF ty_inv_i.


TYPES: BEGIN OF ty_party,
         id          TYPE char10,  " 사업자번호
         type_code   TYPE char50,  " 업태
         name_text   TYPE char50,  " 상호
         class_code  TYPE char50,  " 종목 (분류코드)
         tax_reg_id  TYPE char4,   " 종사업장번호
         person_name TYPE char50,  " 대표자 성명
         email       TYPE char50,  " 담당자 이메일
         address     TYPE char100, " 주소
       END OF ty_party.

TYPES: BEGIN OF ty_xml_item,
         seq       TYPE char6,          " 일련번호
         item_text TYPE char40,         " 품목명
         menge     TYPE p LENGTH 7 DECIMALS 3, " 청구 수량
         uprice    TYPE p LENGTH 7 DECIMALS 2, " 청구 단가
         wrbtr     TYPE p LENGTH 7 DECIMALS 2, " 품목 공급가액
       END OF ty_xml_item.

TYPES: BEGIN OF ty_xml_doc,
         issue_id TYPE char24,
         bldat    TYPE char8,

         invoicer TYPE ty_party,  " ★ 공급자 전체 정보
         invoicee TYPE ty_party,  " ★ 공급받는자 전체 정보

         netwr    TYPE p LENGTH 7 DECIMALS 2,
         wmwst1   TYPE p LENGTH 7 DECIMALS 2,
         rmwwr    TYPE p LENGTH 7 DECIMALS 2,
         items    TYPE STANDARD TABLE OF ty_xml_item WITH DEFAULT KEY,
       END OF ty_xml_doc.

DATA:
  ok_code     TYPE sy-ucomm,
  gv_werks    TYPE z8plant_m-werks,
  gv_ebeln    TYPE z8mm_po_i-ebeln,
  gv_ebelp    TYPE z8mm_po_i-ebelp,
  gv_belnr    TYPE z8fi_accdoc_h-belnr,
  gv_invno    TYPE z8mm_inv_h-inv_no,
  gv_3cof     TYPE c VALUE 'X',
  gv_amnt     TYPE ty_3comp,
  gv_qunt     TYPE ty_3comp,

  gv_menge_un TYPE c LENGTH 1 VALUE 'X',
  gv_wrbtr_un TYPE c LENGTH 1 VALUE 'X'.

DATA: gv_inv_err TYPE c LENGTH 1.

DATA: gv_po_locked  TYPE c LENGTH 1,        " 이 세션이 PO 락을 보유 중인지
      gv_save_err   TYPE c LENGTH 1,        " 저장 단계 오류 플래그
      gv_lock_ebeln TYPE z8mm_po_i-ebeln,   " 락을 잡은 PO (UNLOCK_PO 가 이 값으로 해제)
      gv_lock_rc    TYPE sy-subrc,
      gv_lock_user  TYPE sy-uname,
      gv_state_ok   TYPE c LENGTH 1.

DATA :
  " ALV
  go_dock_cont1  TYPE REF TO cl_gui_docking_container,
  go_split       TYPE REF TO cl_gui_splitter_container,

  go_amnt_cont   TYPE REF TO cl_gui_container,
  go_qunt_cont   TYPE REF TO cl_gui_container,

  go_amnt_alv    TYPE REF TO cl_gui_alv_grid,
  go_qunt_alv    TYPE REF TO cl_gui_alv_grid,

  gt_amnt_fcat   TYPE lvc_t_fcat,
  gs_amnt_fcat   TYPE lvc_s_fcat,

  gt_qunt_fcat   TYPE lvc_t_fcat,
  gs_qunt_fcat   TYPE lvc_s_fcat,

  gs_amnt_layout TYPE lvc_s_layo,
  gs_qunt_layout TYPE lvc_s_layo,

  gt_inv_h       TYPE TABLE OF z8mm_inv_h,
  gs_inv_h       TYPE z8mm_inv_h,

  gt_inv_i       TYPE TABLE OF ty_inv_i,
  gs_inv_i       TYPE ty_inv_i,

  gt_accdoc_h    TYPE TABLE OF z8fi_accdoc_h,
  gs_accdoc_h    TYPE z8fi_accdoc_h,

  gt_accdoc_i    TYPE TABLE OF z8fi_accdoc_i,
  gs_accdoc_i    TYPE z8fi_accdoc_i,


  gt_amnt_3comp  TYPE TABLE OF ty_3comp,
  gs_amnt_3comp  TYPE ty_3comp,

  gt_qunt_3comp  TYPE TABLE OF ty_3comp,
  gs_qunt_3comp  TYPE ty_3comp,


  gt_vendor      TYPE TABLE OF z8fi_vendor,
  gs_vendor      TYPE z8fi_vendor.


* --------------------
DATA:
  gs_xml_doc   TYPE ty_xml_doc,
  gs_po_h      TYPE z8mm_po_h,
  gv_inv_saved TYPE c VALUE ''.
