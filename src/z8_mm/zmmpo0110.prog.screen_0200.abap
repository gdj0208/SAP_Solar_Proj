" SE51 흐름 로직입니다. 일반 INCLUDE로 생성하지 않습니다.
" BEFORE OUTPUT은 PBO, AFTER INPUT은 PAI입니다.
" PAI에서 서브스크린 값을 먼저 받은 뒤 버튼 명령을 처리합니다.

PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  CALL SUBSCREEN sub_entry INCLUDING sy-repid '1200'.
  MODULE display_0200.
PROCESS AFTER INPUT.
  CALL SUBSCREEN sub_entry.
  MODULE command_0200.
