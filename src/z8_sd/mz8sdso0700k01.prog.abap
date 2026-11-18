*&---------------------------------------------------------------------*
*& Include          MZ8SDSO0700K01
*&---------------------------------------------------------------------*

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_button_click
      FOR EVENT button_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_row_select
        FOR EVENT delayed_changed_sel_callback OF cl_gui_alv_grid.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_row_select.
    DATA: lv_line_val TYPE abap_bool.

    PERFORM get_selected_line CHANGING lv_line_val.

  ENDMETHOD.


  METHOD on_button_click.

    READ TABLE gt_so_h INTO gw_so_h INDEX es_row_no-row_id.

    PERFORM open_fiori_project USING gw_so_h-pro_id.

  ENDMETHOD.

  METHOD on_hotspot_click.

    READ TABLE gt_so_h INTO gw_so_h INDEX es_row_no-row_id.

    PERFORM open_fiori_project USING gw_so_h-pro_id.

  ENDMETHOD.

  METHOD on_double_click.
    CLEAR gv_sel_line_flag.

    gv_sel_line_flag = abap_false.

    READ TABLE gt_so_h INTO gw_so_h INDEX es_row_no-row_id. "e_row는 구형 파라미터로 표시하고, es_row_no를 행 식별에 사용

    IF sy-subrc = 0.

      PERFORM get_data_item USING gw_so_h-vbeln_q gw_so_h-werks gw_so_h-vbeln_s.

      go_alv_i->refresh_table_display( ).

    ENDIF.

  ENDMETHOD.


ENDCLASS.
