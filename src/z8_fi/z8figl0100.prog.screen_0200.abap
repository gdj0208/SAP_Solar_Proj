PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  MODULE alv_cl_process_0200.


PROCESS AFTER INPUT.
*  FIELD gv_blart MODULE get_blartt_0200.
  FIELD gv_blart MODULE clear_blart_0200.
  FIELD gv_bupla MODULE clear_bupla_0200.
  MODULE user_command_0200.

PROCESS ON VALUE-REQUEST.
  FIELD gv_blart MODULE f4_blart_0200.
  FIELD gv_bupla MODULE f4_bupla_0200.
