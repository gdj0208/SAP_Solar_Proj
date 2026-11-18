*&---------------------------------------------------------------------*
*& Include          Z8FIRP0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'REFR'.
      PERFORM refresh_alv_100.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code.
    WHEN 'BACK' OR 'CANCEL'.
      PERFORM free_control_200.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'ALLB'.
      CLEAR gv_other_branch.

      PERFORM check_ar_branch CHANGING gv_other_branch.
      IF gv_other_branch IS INITIAL.
        MESSAGE s148(z8_msg) DISPLAY LIKE 'E' WITH '채권'.
*        MESSAGE i148(z8_msg) WITH '채권'.
      ELSE.
        gv_ar_all_branch = 'X'.
        PERFORM refresh_alv_200.
      ENDIF.
    WHEN 'SELB'.
      CLEAR gv_ar_all_branch.
      PERFORM refresh_alv_200.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.

  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'REFR'.
      PERFORM refresh_alv_300.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0400 INPUT.

  CASE ok_code.
    WHEN 'BACK' OR 'CANCEL'.
      PERFORM free_control_400.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'ALLB'.
      CLEAR gv_other_branch.

      PERFORM check_ap_branch CHANGING gv_other_branch.
      IF gv_other_branch IS INITIAL.
        MESSAGE s148(z8_msg) DISPLAY LIKE 'E' WITH '채무'.
      ELSE.
        gv_ap_all_branch = 'X'.
        PERFORM refresh_alv_400.
      ENDIF.
    WHEN 'SELB'.
      CLEAR gv_ap_all_branch.
      PERFORM refresh_alv_400.
  ENDCASE.

ENDMODULE.
