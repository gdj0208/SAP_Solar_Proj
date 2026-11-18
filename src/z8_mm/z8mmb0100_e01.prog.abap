*&---------------------------------------------------------------------*
*& Include Z8MMB0100_E01
*&---------------------------------------------------------------------*
*& STO 번호 F4, 실행 시작 - 기준일 검사 후 배치 실행·결과 표시
*& 담당: MM(이규빈) / 프로그램: Z8MMB0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-22  이규빈  최초 개발   최초 작성: 예상도착일이 된 이동중 STO 자동 101 입고 배치 (개발 10/22~10/26)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 예약 STO 351 출고 단계 추가, 모의 실행·결과 표시 보완
*& 2026-11-04  이규빈  수정사항    STO 번호 F4(STO 화면과 같은 공통 검색) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

INITIALIZATION.
  " 실행 권한: MM 프로그램 권한(Z8MM_ADMIN)의 실행(16)이 없으면 시작하지 않는다(팀 MM 프로그램 공통).
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
    ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.   " MM 관리자 전용 프로그램입니다. 권한을 요청하세요.
  ENDIF.

" STO 번호 F4: STO 화면과 같은 공통 검색(lcl_mm_f4, kind = 'STO')이다.
"   칸에 일부만 적고 F4를 누르면 그 글자로 걸러 보여 주고, 취소하면 입력값을 그대로 둔다.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sto.
  DATA(lv_sto_pick) = lcl_mm_f4=>pick( kind = 'STO' typed = lcl_mm_f4=>screen_value( 'P_STO' ) ).
  IF lv_sto_pick IS NOT INITIAL.
    p_sto = lv_sto_pick.
  ENDIF.

START-OF-SELECTION.
" 기준일: 이 날짜까지 출고일·예상도착일이 된 STO를 처리한다. 자재문서 전기일은 항상 오늘이다.
"   JOB(배치)으로 돌면 화면 값과 관계없이 실행한 날(오늘)을 기준일로 쓴다.
gv_asof = p_asof.
IF sy-batch = abap_true.
  gv_asof = sy-datum.
ENDIF.
IF gv_asof IS INITIAL.
  MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '처리 기준일자'.   " 처리 기준일자를 입력해주세요
  RETURN.
ENDIF.
" 직접 실행에서 모의 실행을 끄고 미래 기준일을 넣으면, 그날까지 출고·도착 예정인 STO를
"   오늘 날짜로 앞당겨 출고·입고한다. 실수로 앞당기지 않도록 확인창에서 [진행]을 눌러야 처리한다.
IF p_sim = abap_false AND gv_asof > sy-datum.
  DATA: lv_answer   TYPE c LENGTH 1,
        lv_question TYPE c LENGTH 200.
  lv_question = |기준일 { gv_asof DATE = USER }까지 출고·도착 예정인 STO를 오늘 날짜로 앞당겨 출고·입고합니다. 진행할까요?|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'STO 앞당겨 처리' text_question = lv_question
      text_button_1 = '진행' text_button_2 = '취소'
      default_button = '2' display_cancel_button = space
    IMPORTING answer = lv_answer
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    RETURN.
  ENDIF.
ENDIF.
PERFORM execute_batch.
PERFORM display_results.
