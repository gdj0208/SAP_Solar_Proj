*&---------------------------------------------------------------------*
*& Include          ZMMGR020I01
*&---------------------------------------------------------------------*


MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CONF'.
  ENDCASE.
ENDMODULE.
