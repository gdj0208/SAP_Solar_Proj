*&---------------------------------------------------------------------*
*& Include          ZMMGR020O01
*&---------------------------------------------------------------------*



MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE reset_meins OUTPUT.
  gv_mein1 = gv_meins.
  gv_mein2 = gv_meins.
  gv_mein3 = gv_meins.
ENDMODULE.

MODULE modify_read_only OUTPUT.
  LOOP AT SCREEN.
    IF SCREEN-GROUP1 = 'NCH'.
      SCREEN-INPUT = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
