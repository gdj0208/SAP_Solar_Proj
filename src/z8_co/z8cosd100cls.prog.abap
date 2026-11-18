*&---------------------------------------------------------------------*
*& Include          Z8COSD100CLS
*&---------------------------------------------------------------------*

CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column sender.
ENDCLASS.

CLASS lcl_event_receiver IMPLEMENTATION.
  METHOD handle_double_click.
      PERFORM GET_DETAIL_DATA USING e_row-index.
  ENDMETHOD.
ENDCLASS.
