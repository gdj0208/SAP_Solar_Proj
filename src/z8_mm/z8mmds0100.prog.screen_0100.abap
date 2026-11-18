PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  MODULE set_subscreen.
  MODULE set_tabstrip.
  CALL SUBSCREEN tab_sub INCLUDING sy-cprog gv_dynnr.


PROCESS AFTER INPUT.
  CALL SUBSCREEN: tab_sub.
  MODULE user_command_0100.
