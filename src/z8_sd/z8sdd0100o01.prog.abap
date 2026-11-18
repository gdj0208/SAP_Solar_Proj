*&---------------------------------------------------------------------*
*& Include          Z8SDD0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_1000 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1000 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing OUTPUT.
  IF go_container IS NOT BOUND.
    PERFORM set_default_date.
    PERFORM create_object.
    PERFORM set_evt_handler.
    PERFORM set_alv_layout.
    PERFORM set_fcat.
    PERFORM set_fcat_i.
    PERFORM display_alv.
    PERFORM get_data.
  ENDIF.
ENDMODULE.
