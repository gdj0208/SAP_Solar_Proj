*&---------------------------------------------------------------------*
*& Include          Z8SDBI0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  IF p_st2 = 'X'.
    SET PF-STATUS 'S0100' EXCLUDING 'CREA'.
  ELSE.
    SET PF-STATUS 'S0100'.
  ENDIF.
SET TITLEBAR 'T0100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0100 OUTPUT.
  IF go_cont_quot IS INITIAL.
    PERFORM create_objects_quot.
    PERFORM set_layout_quot.
    PERFORM set_field_catalog_quot.
    PERFORM set_event_handler_quot.
    PERFORM display_alv_quot.
 ELSEIF gv_refresh_100 = 'X'.
    PERFORM refresh_alv_quot.
    CLEAR gv_refresh_100.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
SET PF-STATUS 'S0200'.
SET TITLEBAR 'T0200'.   "선수금 청구생성.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0210 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0210 OUTPUT.
SET PF-STATUS 'S0200'.
SET TITLEBAR 'T0210'.  "잔금 청구생성
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_ALV_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0200 OUTPUT.
  IF go_cont_prev IS INITIAL.
    PERFORM create_objects_prev.
    PERFORM set_layout_prev.
    PERFORM set_field_catalog_prev.
    PERFORM display_alv_prev.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0110 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0110 OUTPUT.
  IF p_st2 = 'X'.
    SET PF-STATUS 'S0100' EXCLUDING 'CREA'.
  ELSE.
    SET PF-STATUS 'S0100'.
  ENDIF.
  SET TITLEBAR 'T0110'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0110 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0110 OUTPUT.
  IF go_cont_so IS INITIAL.
    PERFORM create_objects_so.
    PERFORM set_layout_so.
    PERFORM set_field_catalog_so.
    PERFORM set_event_handler_so.
    PERFORM display_alv_so.
  ELSEIF gv_refresh_100 = 'X'.
    PERFORM refresh_alv_so.
    CLEAR gv_refresh_100.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'S0300'.
  SET TITLEBAR 'T0300'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0300 OUTPUT.
  IF go_cont_detail IS INITIAL.
    PERFORM create_objects_detail.
    PERFORM set_layout_detail.
    PERFORM set_field_catalog_detail.
    PERFORM display_alv_detail.
  ENDIF.
ENDMODULE.
