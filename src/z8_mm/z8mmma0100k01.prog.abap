*&---------------------------------------------------------------------*
*& Include          Z8MMMA0100K01
*&---------------------------------------------------------------------*
CLASS lc1_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_doubleclick
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.

    CLASS-METHODS on_doubleclick_200
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.

    CLASS-METHODS: on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id,
      on_hotspot_click_200
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id.


ENDCLASS.

CLASS lc1_handler IMPLEMENTATION.

  METHOD on_doubleclick.
    DATA: ls_mat_list TYPE ty_mat_list.

    READ TABLE gt_mat_list INTO ls_mat_list INDEX e_row-index.
    IF sy-subrc = 0.
      gv_matnr_sel = ls_mat_list-matnr.
      gv_mode        = 'D'.
      CLEAR gv_screen_init.
      CALL SCREEN 0300.
      PERFORM get_material_list.             " 돌아온 뒤 목록 다시 읽기 (신호등 처리 포함)
      CALL METHOD go_alv_100->refresh_table_display.

    ENDIF.

  ENDMETHOD.

  METHOD on_doubleclick_200.
    READ TABLE gt_vend_list INTO gw_vend_list INDEX e_row-index.
    IF sy-subrc = 0.
      gv_lifnr_sel = gw_vend_list-lifnr. "업체코드 넣기.
      gv_mode_v    = 'D'.
      CLEAR gv_screen_init_v.
      CALL SCREEN 0400.
      PERFORM get_vendor_list.
      CALL METHOD go_alv_200->refresh_table_display.
    ENDIF.
  ENDMETHOD.

  METHOD on_hotspot_click.
  CALL METHOD lc1_handler=>on_doubleclick
    EXPORTING
      e_row    = e_row_id
      e_column = e_column_id.
ENDMETHOD.

METHOD on_hotspot_click_200.
  CALL METHOD lc1_handler=>on_doubleclick_200
    EXPORTING
      e_row    = e_row_id
      e_column = e_column_id.
ENDMETHOD.
ENDCLASS.
