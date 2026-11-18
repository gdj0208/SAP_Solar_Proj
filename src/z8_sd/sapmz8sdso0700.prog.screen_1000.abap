PROCESS BEFORE OUTPUT.
  MODULE check_authority.
  MODULE status_1000.
  MODULE init_processing.
  MODULE set_init_data.
  MODULE clear_ok_code. "다음 스크린이나 엔터 입력에 영향을 주지 않도록 CLEAR 해줌

PROCESS AFTER INPUT.
  MODULE user_command_1000.

PROCESS ON VALUE-REQUEST.
  FIELD gv_customer MODULE f4_customer.
