*&---------------------------------------------------------------------*
*& Include          Z8SDQ0100K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.

    CLASS-METHODS on_hotspot
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id.

    CLASS-METHODS on_row_select
        FOR EVENT delayed_changed_sel_callback OF cl_gui_alv_grid.

    CLASS-METHODS on_button_click
      FOR EVENT button_click OF cl_gui_alv_grid
      IMPORTING es_row_no es_col_id.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_button_click.

    IF es_col_id-fieldname <> 'SEND_BTN'.
      RETURN.
    ENDIF.

    CLEAR gw_quot_list.

    READ TABLE gt_quot_list INTO gw_quot_list INDEX es_row_no-row_id.

    gv_selected_id = gw_quot_list-vbeln_q.

    IF sy-subrc <> 0.
      MESSAGE s004(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    PERFORM get_quot_item USING gw_quot_list-vbeln_q.

    PERFORM get_quot_detail USING es_row_no-row_id.

    CALL SCREEN 1320 STARTING AT 5 5.

  ENDMETHOD.

  METHOD on_row_select.
    DATA: ls_quot TYPE z8sd_quotation_h.

    CLEAR: gv_selected_id, ls_quot.

    PERFORM get_selected_quot USING abap_false
                              CHANGING ls_quot.

    gv_selected_id = ls_quot-vbeln_q.

    PERFORM get_quot_item USING gv_selected_id.

  ENDMETHOD.

  METHOD on_double_click.

    READ TABLE gt_quot_list INTO gw_quot_list INDEX e_row-index.

    IF sy-subrc = 0.
      gv_selected_id = gw_quot_list-vbeln_q.
    ENDIF.

    PERFORM get_quot_item USING gw_quot_list-vbeln_q.

    go_alv1300_i->refresh_table_display( ).
  ENDMETHOD.

  METHOD on_hotspot.

    PERFORM get_quot_detail USING e_row_id-index.

    CALL SCREEN 1310 STARTING AT 5 5.
  ENDMETHOD.

ENDCLASS.
