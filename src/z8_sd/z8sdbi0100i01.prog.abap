*&---------------------------------------------------------------------*
*& Include          Z8SDBI0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      PERFORM free_control_quot.
      LEAVE TO SCREEN 0.
    WHEN 'REFR'.
      PERFORM refresh_alv_quot.
      MESSAGE '최신 데이터로 새로고침했습니다.' TYPE 'S'.
    WHEN 'CREA'..
      PERFORM check_selected_quot.
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
      PERFORM free_control_prev.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM save_billing.
  ENDCASE.
  CLEAR ok_code.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0110 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      PERFORM free_control_so.
      LEAVE TO SCREEN 0.
    WHEN 'REFR'.
      PERFORM refresh_alv_so.
      MESSAGE '최신 데이터로 새로고침했습니다.' TYPE 'S'.
    WHEN 'CREA'.
      PERFORM check_selected_so.
  ENDCASE.
  CLEAR ok_code.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      PERFORM free_control_deatil.
      LEAVE TO SCREEN 0.
    WHEN 'CANC'.
      PERFORM cancel_billing.
  ENDCASE.
  CLEAR ok_code.

ENDMODULE.
