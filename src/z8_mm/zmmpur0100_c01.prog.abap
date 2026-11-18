*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_C01
*&---------------------------------------------------------------------*
*& ALV 더블클릭·카드(SAPEVENT) 이벤트 클래스
*&   이벤트에서는 PAI 명령만 만들고 실제 처리는 I01·N01에서 한다.
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 더블클릭 이벤트에서는 행만 기억하고 PAI에 OPEN을 전달한다.
" 실제 프로그램 호출은 N01의 open_document에서 수행한다.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
ENDCLASS.
CLASS lcl_events IMPLEMENTATION.
  " double_click : 목록 행 더블클릭 → 그 행 번호를 기억하고 PAI(OPEN)로 문서 화면을 연다.
  METHOD double_click.
    IF e_row-index <= 0.
      RETURN.
    ENDIF.
    gv_row = e_row-index.
    cl_gui_cfw=>set_new_ok_code( new_code = 'OPEN' ).
  ENDMETHOD.
ENDCLASS.

" 카드 클릭: HTML의 SAPEVENT 이름을 그대로 기능코드로 PAI에 넘긴다.
" 카드 본문 = 목록 전환(PRLIST/POLIST/STLIST/DUE), 카드 안 버튼 = 프로그램 이동.
CLASS lcl_card_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_click FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action.
ENDCLASS.
CLASS lcl_card_events IMPLEMENTATION.
  " on_click : 위쪽 카드(SAPEVENT) 클릭을 PAI 명령(PRLIST/PONEW 등)으로 바꾼다.
  METHOD on_click.
    DATA lv_code TYPE sy-ucomm.
    CASE action.
      WHEN 'PRLIST' OR 'POLIST' OR 'STLIST'
        OR 'PRNEW' OR 'PRALL' OR 'PONEW' OR 'POALL' OR 'STNEW' OR 'STALL'.
        lv_code = action.
        cl_gui_cfw=>set_new_ok_code( new_code = lv_code ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
