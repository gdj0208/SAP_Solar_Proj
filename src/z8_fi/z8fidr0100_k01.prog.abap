*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_K01
*&---------------------------------------------------------------------*

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_hotspot
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING es_row_no e_column_id.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_hotspot.
    DATA lv_result TYPE abap_bool.

    CHECK e_column_id-fieldname = 'BELNR' OR e_column_id-fieldname = 'XBLNR'.

    READ TABLE gt_accdoc_h INTO gw_accdoc_h INDEX es_row_no-row_id.


    IF sy-subrc <> 0.
      MESSAGE s110(z8_msg) DISPLAY LIKE 'E' WITH gw_accdoc_h-belnr.
      RETURN.
    ENDIF.

    PERFORM get_detail USING gw_accdoc_h-bukrs
                             gw_accdoc_h-belnr
                             gw_accdoc_h-gjahr
                        CHANGING lv_result.

    IF lv_result = abap_false.
      MESSAGE S111(z8_msg) WITH gw_accdoc_h-belnr DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CALL SCREEN 1200.

  ENDMETHOD.

ENDCLASS.
