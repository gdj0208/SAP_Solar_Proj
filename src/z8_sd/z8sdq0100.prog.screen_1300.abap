PROCESS BEFORE OUTPUT.
  MODULE status_1300.
  MODULE modify_screen1300.
  MODULE set_tabscreen1300.

  CALL SUBSCREEN sub_quot INCLUDING sy-repid gv_subscreen.

*  CALL SUBSCREEN sub1 INCLUDING sy-repid '1330'.

PROCESS AFTER INPUT.

  CALL SUBSCREEN sub_quot.

*  CALL SUBSCREEN sub1.

  MODULE user_command_1300.

*PROCESS ON VALUE-REQUEST.
*  FIELD gv_customer MODULE f4_kunnr.
