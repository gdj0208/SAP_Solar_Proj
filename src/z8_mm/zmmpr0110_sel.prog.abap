*&---------------------------------------------------------------------*
*& Include ZMMPR0110_SEL
*&---------------------------------------------------------------------*
*& 호출 파라미터와 입력 서브스크린 1200
*& 담당: MM(이규빈) / 프로그램: ZMMPR0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 구매지사 기준 PR 신규 입력·변경·삭제 (개발 10/01~10/06)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 입력 화면 개편(신호등·입력 열 색), 공급업체·희망납기일 자동 채움
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 저장·삭제 메시지 정리, ALV 행 버튼 제거, PR 변경은 수량·희망납기일만
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 호출값은 NO-DISPLAY이다. 실행 시 입력화면 0100으로 바로 진입한다.
PARAMETERS: p_new TYPE abap_bool NO-DISPLAY,
  p_chg TYPE abap_bool NO-DISPLAY,
  p_cancel TYPE abap_bool NO-DISPLAY,
  p_view TYPE abap_bool NO-DISPLAY,
  p_pr TYPE z8mm_pr-banfn NO-DISPLAY,
  p_item TYPE z8mm_pr-bnfpo DEFAULT '00010' NO-DISPLAY,
  p_so TYPE z8mm_pr-kdauf NO-DISPLAY,
  p_pos TYPE z8mm_pr-kdpos NO-DISPLAY.

PARAMETERS p_werks TYPE z8mm_pr-werks NO-DISPLAY.

" 저장위치는 화면에 표시하지 않는다. 신규 PR은 0001 고정이다.
PARAMETERS n_lgort TYPE z8mm_pr-lgort DEFAULT '0001' NO-DISPLAY.
" 입고플랜트는 화면에 안 보이고 구매지사(n_bupla)에서 자동으로 정해진다(지사 B001 → 플랜트 P100).
"   저장·검사는 지금처럼 이 플랜트(n_werks)로 한다.
PARAMETERS n_werks TYPE z8mm_pr-werks NO-DISPLAY.

SELECTION-SCREEN BEGIN OF SCREEN 1200 AS SUBSCREEN.
" 업무 정보는 프레임으로 묶고, 제목은 메인 텍스트 요소에서 관리한다.
SELECTION-SCREEN BEGIN OF BLOCK b_entry WITH FRAME TITLE text-e01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_esite FOR FIELD n_bupla.
SELECTION-SCREEN POSITION 14.
" 다른 화면과 같이 구매지사(지사코드 B001)로 입력. F4는 팀 서치헬프 Z8SH_BRANCH
PARAMETERS n_bupla TYPE z8plant_m-bupla VISIBLE LENGTH 4 MODIF ID hdr.
SELECTION-SCREEN COMMENT 20(30) gv_sname.
" 기본 희망납기일: 새 행에 자동으로 들어가는 날짜. 바꾸면 아직 손대지 않은 행의 날짜도 같이 바뀐다.
SELECTION-SCREEN COMMENT 52(11) gv_ldate FOR FIELD n_lfdat.
SELECTION-SCREEN POSITION 64.
PARAMETERS n_lfdat TYPE z8mm_pr-lfdat MODIF ID dft.
SELECTION-SCREEN END OF LINE.
" 입력 현황 요약 한 줄: 값은 FORM update_summary가 PBO마다 채운다.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(60) gv_ssum.
" 기본 납기일 바로 아래: 왜 이 날짜인지(오늘 + 3영업일, 공장달력 KR). 선택화면 한 줄은 83열까지
SELECTION-SCREEN COMMENT 64(18) gv_lhint.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b_entry.
SELECTION-SCREEN END OF SCREEN 1200.
