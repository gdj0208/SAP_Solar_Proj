*&---------------------------------------------------------------------*
*& Include          Z8FIAP0100O01
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
    PERFORM set_evt_handler.
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
*& Module ALV_CL_PROCESS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE alv_cl_process_0200 OUTPUT.

  IF go_cont_org IS NOT BOUND OR go_cont_pre IS NOT BOUND..

    PERFORM create_objects_200. "컨테이너 + alv 생성
**    PERFORM set_evt_handler.
    PERFORM set_alv_layout_200.
    PERFORM set_field_catalog_200. "ALV에 예외 컬럼 정보 제공
    PERFORM display_alv_200.    " alv 출력

  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module REFRESH_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE refresh_0100 OUTPUT.

  IF gv_refresh_100 = 'X'.

    PERFORM get_data_100.
    PERFORM set_cell_style_100.

  ENDIF.

ENDMODULE.
