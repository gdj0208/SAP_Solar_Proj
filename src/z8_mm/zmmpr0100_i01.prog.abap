*&---------------------------------------------------------------------*
*& Include ZMMPR0100_I01
*&---------------------------------------------------------------------*
*& PAI - 목록 버튼 명령 처리
*& 담당: MM(이규빈) / 프로그램: ZMMPR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-14  이규빈  최초 개발   최초 작성: PR 목록 조회·취소, PR 생성/변경·PO 생성 화면 연결 (개발 10/14~10/16)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등 화면 통일, 조회조건·버튼 동작 보완
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 조회 결과 없음 오류 표시, 취소 메시지 정리
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

MODULE command_0100 INPUT.
  gv_cmd = ok_code.
  IF gv_cmd IS INITIAL.
    gv_cmd = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  IF gv_cmd <> 'BACK' AND gv_cmd <> 'EXIT' AND gv_cmd <> 'CANC'.
    DATA changed TYPE abap_bool.
    PERFORM query_changed CHANGING changed.
    IF changed = abap_true
      AND ( gv_cmd = 'CHANGE' OR gv_cmd = 'VOID' OR gv_cmd = 'POGEN' ).
      MESSAGE s126(z8_msg) DISPLAY LIKE 'W'.   " 조회 범위를 확인해주세요(조건이 바뀌었으니 다시 조회)
      RETURN.
    ENDIF.
  ENDIF.
  CASE gv_cmd.
    WHEN 'SCARD'.
      PERFORM apply_summary.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'QUERY' OR 'REFR'.
      " [조회]를 누르면 방금 처리한 파란 줄을 정리하고 일반 목록으로 본다.
      PERFORM clear_mark.
      PERFORM query_list.
    WHEN 'ENTR' OR 'ENTER' OR space.
      PERFORM query_list.            " Enter는 파란 줄 유지
    WHEN 'NEW'.
      PERFORM begin_new.
    WHEN 'CHANGE'.
      PERFORM begin_change.
    WHEN 'VOID'.
      PERFORM cancel_selected.
    WHEN 'POGEN'.
      PERFORM forward_to_po.
  ENDCASE.
ENDMODULE.
