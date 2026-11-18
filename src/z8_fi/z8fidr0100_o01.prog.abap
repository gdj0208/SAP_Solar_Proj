*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing OUTPUT.
  DATA lv_init_result TYPE abap_bool.

  IF go_container IS NOT BOUND.
*    CLEAR lv_init_result.
*
*    PERFORM set_default_date.
*    PERFORM get_data CHANGING lv_init_result. "최초 1회 데이터 조회

    PERFORM create_object.
    PERFORM set_evt_handler.
    PERFORM set_alv_layout.
    PERFORM set_fcat.

    PERFORM display_alv.
    PERFORM display_summary.

    PERFORM refresh_alv.
  ELSE.
    PERFORM refresh_alv.
  ENDIF.
ENDMODULE.


*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING1200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing1200 OUTPUT.
  IF go_container200 IS NOT BOUND.
    PERFORM create_object200.
    PERFORM set_alv_layout200.
    PERFORM set_fcat200.
    PERFORM display_alv200.
  ELSE.
    PERFORM refresh_alv200.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module LOAD_EXTERNAL_DETAIL1200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE load_external_detail1200 OUTPUT.
  DATA lv_result TYPE abap_bool.

  "외부 프로그램에서 전달한 전표 키 읽기
  CLEAR: gv_ext_bukrs,
         gv_ext_belnr,
         gv_ext_gjahr.

  IF gs_detail_h-belnr IS NOT INITIAL.
    RETURN.
  ENDIF.

  IMPORT bukrs = gv_ext_bukrs
         belnr = gv_ext_belnr
         gjahr = gv_ext_gjahr
    FROM MEMORY ID 'Z8FI_DETAIL_1200'.

  IF sy-subrc <> 0 OR gv_ext_belnr IS INITIAL.
    MESSAGE s113(z8_msg) DISPLAY LIKE 'E'.
    LEAVE TO SCREEN 0.
  ENDIF.

  FREE MEMORY ID 'Z8FI_DETAIL_1200'.

  "기존 GET_DETAIL 재사용
  PERFORM get_detail USING    gv_ext_bukrs
                              gv_ext_belnr
                              gv_ext_gjahr
                     CHANGING lv_result.

  IF lv_result = abap_false.
    MESSAGE s111(z8_msg) DISPLAY LIKE 'E' WITH gv_ext_belnr.
    LEAVE TO SCREEN 0.
  ENDIF.

  PERFORM refresh_alv200.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1200 OUTPUT.
  SET PF-STATUS 'G1200'.
  SET TITLEBAR 'T1200'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1100 OUTPUT.
 SET PF-STATUS 'G1100'.
 SET TITLEBAR 'T1100'.
ENDMODULE.
