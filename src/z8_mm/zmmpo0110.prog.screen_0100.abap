" SE51 흐름 로직입니다. 일반 INCLUDE로 생성하지 않습니다.
" BEFORE OUTPUT은 PBO, AFTER INPUT은 PAI입니다.
" PAI에서 서브스크린 값을 먼저 받은 뒤 버튼 명령을 처리합니다.

PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  CALL SUBSCREEN sub_filter INCLUDING sy-repid '1100'.
  MODULE display_0100.
PROCESS AFTER INPUT.
  CALL SUBSCREEN sub_filter.
  MODULE command_0100.
