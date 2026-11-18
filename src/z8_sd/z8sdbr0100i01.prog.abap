*&---------------------------------------------------------------------*
*& Include          Z8SDBR0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      CLEAR ok_code.
      PERFORM free_control_contract.
      LEAVE TO SCREEN 0.
    WHEN 'REFR'.
      PERFORM refresh_alv_contract.
      MESSAGE '최신 데이터로 새로고침했습니다.' TYPE 'S'.
    WHEN 'BILL'.
      PERFORM call_billing_contract.
*      gv_view = '0'.
*      PERFORM change_view_contract.
*    WHEN 'VREQ'.
*      gv_view = '1'.
*      PERFORM change_view_contract.
*    WHEN 'VPRG'.
*      gv_view = '2'.
*      PERFORM change_view_contract.
*    WHEN 'VDON'.
*      gv_view = '3'.
*      PERFORM change_view_contract.
  ENDCASE.
  CLEAR ok_code.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      PERFORM free_control_detail.
      LEAVE TO SCREEN 0.
    WHEN 'BILL'.
      PERFORM call_billing_detail.
   ENDCASE.

ENDMODULE.
