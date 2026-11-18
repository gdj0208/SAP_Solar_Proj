*&---------------------------------------------------------------------*
*& Include          Z8SDBI0100K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_hotspot_quot FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id,
      on_hotspot_so   FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_hotspot_quot.
    READ TABLE gt_quot INTO gs_quot INDEX e_row_id-index.
    IF sy-subrc = 0 AND gs_quot-vbeln IS NOT INITIAL.
      gv_detail_vbeln = gs_quot-vbeln.
      PERFORM show_billing.
    ENDIF.
  ENDMETHOD.

  METHOD on_hotspot_so.
    READ TABLE gt_so INTO gs_so INDEX e_row_id-index.
    IF sy-subrc = 0 AND gs_so-vbeln IS NOT INITIAL.
      gv_detail_vbeln = gs_so-vbeln.
      PERFORM show_billing.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
