*&---------------------------------------------------------------------*
*& Include          Z8SDBR0100K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id,
   "계약상세- 입금내역 청구번호, 전표번호 (VBLEN, BELNR)
    on_hotspot_payment FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_hotspot_click.
    READ TABLE gt_contract INTO gs_detail INDEX e_row_id-index.
    IF sy-subrc = 0.
      PERFORM show_contract_detail.
    ENDIF.
  ENDMETHOD.

  METHOD on_hotspot_payment.
    READ TABLE gt_payment INTO gs_payment INDEX e_row_id-index.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE e_column_id-fieldname.
      WHEN 'VBELN'.  "청구번호
        PERFORM show_billing_doc.
      WHEN 'BELNR'.   "전표번호
        PERFORM show_fi_doc.
     ENDCASE.
  ENDMETHOD.

  ENDCLASS.
