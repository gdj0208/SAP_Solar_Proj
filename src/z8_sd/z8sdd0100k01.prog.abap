*&---------------------------------------------------------------------*
*& Include          Z8SDD0100K01
*&---------------------------------------------------------------------*

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_doublc_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_row_select
        FOR EVENT delayed_changed_sel_callback OF cl_gui_alv_grid.

    CLASS-METHODS on_hotspot
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING es_row_no e_column_id.

ENDCLASS.


CLASS lcl_handler IMPLEMENTATION.
  METHOD on_hotspot.
    CHECK e_column_id-fieldname = 'BELNR'.

    READ TABLE gt_deliv_h INTO gw_deliv_h INDEX es_row_no-row_id.


    SELECT SINGLE bukrs, belnr, gjahr
      FROM z8fi_accdoc_h
      WHERE xblnr = @gw_deliv_h-vbeln_d AND blart = 'WL'
      INTO @DATA(ls_fi_key).

    IF sy-subrc <> 0.
      MESSAGE s112(z8_msg) DISPLAY LIKE 'E'. "해당 자재문서의 회계전표가 없습니다'
      RETURN.
    ENDIF.

    "FI 상세조회 프로그램에 전표 키 전달
    EXPORT bukrs = ls_fi_key-bukrs
           belnr = ls_fi_key-belnr
           gjahr = ls_fi_key-gjahr
      TO MEMORY ID 'Z8FI_DETAIL_1200'.

    "FI 회계전표 상세조회
    CALL TRANSACTION 'Z8FIDR1200'.

    FREE MEMORY ID 'Z8FI_DETAIL_1200'. "이전에 전달한 전표번호가 남지 않게 하는 정리 작업

  ENDMETHOD.

  METHOD on_row_select.

    PERFORM remember_selected_row.

  ENDMETHOD.

  METHOD on_doublc_click.
    READ TABLE gt_deliv_h INTO gw_deliv_h INDEX es_row_no-row_id.
    IF sy-subrc = 0.
      PERFORM get_item USING gw_deliv_h-vbeln_s.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
