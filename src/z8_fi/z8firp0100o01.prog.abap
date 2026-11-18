*&---------------------------------------------------------------------*
*& Include          Z8FIRP0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'G0100'.
  SET TITLEBAR 'T0100'.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module ALV_CL_PROCESS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE alv_cl_process_0100 OUTPUT.

  IF go_cont_100 IS NOT BOUND.

    PERFORM create_objects_100. "컨테이너 + alv 생성
    PERFORM set_evt_handler_100.
    PERFORM set_alv_layout_100.
    PERFORM set_field_catalog_100. "ALV에 예외 컬럼 정보 제공
    PERFORM display_alv_100.    " alv 출력

  ELSE.

    IF gv_refresh_100 = 'X'.

      PERFORM refresh_alv_100.

    ENDIF.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  DATA lt_ar_exclude TYPE TABLE OF sy-ucomm.

  CLEAR lt_ar_exclude.

  IF gv_ar_all_branch = 'X'.
    APPEND 'ALLB' TO lt_ar_exclude.
  ELSE.
    APPEND 'SELB' TO lt_ar_exclude.
  ENDIF.

  SET PF-STATUS 'G0200' EXCLUDING lt_ar_exclude.
  SET TITLEBAR 'T0200' WITH gs_ar_sp-cname.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module ALV_CL_PROCESS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE alv_cl_process_0200 OUTPUT.

  IF go_cont_200 IS NOT BOUND.

    PERFORM create_objects_200. "컨테이너 + alv 생성
    PERFORM set_evt_handler_200.
    PERFORM set_alv_layout_200.
    PERFORM set_field_catalog_200. "ALV에 예외 컬럼 정보 제공
    PERFORM display_alv_200.    " alv 출력

  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'G0300'.
  SET TITLEBAR 'T0300'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module ALV_CL_PROCESS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE alv_cl_process_0300 OUTPUT.

  IF go_cont_300 IS NOT BOUND.

    PERFORM create_objects_300. "컨테이너 + alv 생성
    PERFORM set_evt_handler_300.
    PERFORM set_alv_layout_300.
    PERFORM set_field_catalog_300. "ALV에 예외 컬럼 정보 제공
    PERFORM display_alv_300.    " alv 출력

  ELSE.

    IF gv_refresh_300 = 'X'.

      PERFORM refresh_alv_300.

    ENDIF.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0400 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0400 OUTPUT.

  DATA lt_exclude TYPE TABLE OF sy-ucomm.

  CLEAR lt_exclude.

  IF gv_ap_all_branch = 'X'.
    APPEND 'ALLB' TO lt_exclude.
  ELSE.
    APPEND 'SELB' TO lt_exclude.
  ENDIF.

 SET PF-STATUS 'G0400' EXCLUDING lt_exclude.
 SET TITLEBAR 'T0400' WITH gs_ap_sp-vname.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module ALV_CL_PROCESS_0400 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE alv_cl_process_0400 OUTPUT.

  IF go_cont_400 IS NOT BOUND.

    PERFORM create_objects_400. "컨테이너 + alv 생성
    PERFORM set_evt_handler_400.
    PERFORM set_alv_layout_400.
    PERFORM set_field_catalog_400. "ALV에 예외 컬럼 정보 제공
    PERFORM display_alv_400.    " alv 출력

  ENDIF.

ENDMODULE.
