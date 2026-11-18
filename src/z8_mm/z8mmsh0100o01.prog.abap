*&---------------------------------------------------------------------*
*& Include          Z8MMSH0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
SET PF-STATUS 'S0100'.
  IF p_test = 'X'.
    gv_mode = '시험 실행'.
  ELSE.
    gv_mode = '실제 실행'.
  ENDIF.
  SET TITLEBAR 'T0100' WITH gv_mode.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0100 OUTPUT.
  IF go_alv IS NOT BOUND.
    PERFORM create_objects.
*    PERFORM set_event_handler.
    PERFORM set_alv_layout.
   PERFORM set_field_catalog.
*    PERFORM modify_field_catalog.

   PERFORM display_alv.
  ELSE.
  CALL METHOD go_alv->refresh_table_display.
  ENDIF.

ENDMODULE.
