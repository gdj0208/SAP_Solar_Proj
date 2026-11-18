*&---------------------------------------------------------------------*
*& Include          Z8SDBR0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0100 OUTPUT.
  IF go_cont_contract IS INITIAL.
    PERFORM create_objects_contract.
    PERFORM set_layout_contract.
    PERFORM set_field_catalog_contract.
    PERFORM set_exclude_contract.
    PERFORM set_event_handler_contract.
*    PERFORM set_filter_contract.
    PERFORM display_alv_contract.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
 SET PF-STATUS 'S0200'.
IF gs_detail-stage_tx = '선수금 청구 대기'
  OR gs_detail-stage_tx = '잔금 청구 대기'.
    SET PF-STATUS 'S0200'.
  ELSE.
    SET PF-STATUS 'S0200' EXCLUDING 'BILL'.
  ENDIF.
  SET TITLEBAR 'T0200' WITH gs_detail-vbeln_q.
LOOP AT SCREEN.
    IF screen-group1 = 'DUE' AND gs_detail-due_date IS INITIAL.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0200 OUTPUT.
  IF go_cont_payment IS INITIAL.
    PERFORM create_objects_detail.
    PERFORM set_layout_detail.
    PERFORM set_field_catalog_payment.
    PERFORM set_field_catalog_item.
    PERFORM set_event_handler_detail.
    PERFORM display_alv_detail.
  ENDIF.
ENDMODULE.
