" SE51 0100 흐름 로직
" 담당 지사(GV_WERKS)는 일반 입력칸이다. F4는 POV의 help_werks(choose_plant)가 띄운다.
"   SE51 레이아웃에서 GV_WERKS 속성: 드롭다운 = 없음(공백), FctCode = 공백.

PROCESS BEFORE OUTPUT.
  MODULE status_0100.
PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  MODULE command_0100.

PROCESS ON VALUE-REQUEST.
  FIELD gv_werks MODULE help_werks.
