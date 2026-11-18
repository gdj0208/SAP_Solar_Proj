*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_O01
*&---------------------------------------------------------------------*
*& PBO - 필요할 때만 다시 조회하고 카드·ALV를 그린다
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회, 조회 기간(시작·종료일) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
  PERFORM show_site_name.
  " 날짜 변경·하위 프로그램 복귀·[새로고침]·Enter 때만 DB를 다시 읽는다.
  IF gv_date <> sy-datum.
    gv_refresh = abap_true.
  ENDIF.
  IF gv_refresh = abap_true.
    PERFORM read_data.
    PERFORM select_view.
    gv_previous = gv_werks.
    gv_prev_dfrom = gv_dfrom.
    gv_prev_dto = gv_dto.
  ELSEIF gv_reselect = abap_true.
    PERFORM select_view.                 " 카드 전환: DB를 다시 읽지 않고 보여줄 목록만 바꾼다
  ENDIF.
  CLEAR: gv_refresh, gv_reselect.
  PERFORM show_cards.
  PERFORM display_grid.
ENDMODULE.
