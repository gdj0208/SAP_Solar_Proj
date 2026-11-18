*&---------------------------------------------------------------------*
*& Include ZMMPR0110_I01
*&---------------------------------------------------------------------*
*& PAI - 입력 버튼 명령 처리 (BACK은 호출한 화면으로 복귀)
*& 담당: MM(이규빈) / 프로그램: ZMMPR0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 구매지사 기준 PR 신규 입력·변경·삭제 (개발 10/01~10/06)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 입력 화면 개편(신호등·입력 열 색), 공급업체·희망납기일 자동 채움
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 저장·삭제 메시지 정리, ALV 행 버튼 제거, PR 변경은 수량·희망납기일만
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

MODULE command_0100 INPUT.
  gv_cmd = ok_code.
  IF gv_cmd IS INITIAL.
    gv_cmd = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  IF gv_cmd = 'BACK' OR gv_cmd = 'EXIT' OR gv_cmd = 'CANC'.
    PERFORM leave_entry.
    LEAVE TO SCREEN 0.
  ENDIF.
  DATA valid TYPE abap_bool.
  IF go_entry IS BOUND.
    " ALV 셀에 마지막으로 입력한 값까지 내부테이블로 받아온 뒤 처리한다.
    go_entry->check_changed_data( IMPORTING e_valid = valid ).
    IF valid <> abap_true.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '정확한 데이터'.   " 정확한 데이터를 입력해주세요
      RETURN.
    ENDIF.
  ENDIF.
  PERFORM sync_site.
  PERFORM sync_default_date.
  PERFORM fill_pasted_rows.
  CASE gv_cmd.
    WHEN 'NEWIN'.
      PERFORM new_input.
    WHEN 'CHECK'.
      PERFORM preview_rows.
    WHEN 'STOGO'.
      PERFORM goto_sto.          " 처리 안내의 STO 링크 클릭 → 확인 → STO 생성 화면(값 채움)
    WHEN 'SAVE'.
      PERFORM save_rows.
    WHEN 'ADDI'.
      " 빈 줄 1개 추가(마지막 줄을 채우면 자동으로도 생긴다). 변경 화면은 PR 한 건만 다루므로 추가하지 않는다.
      IF gv_mode <> 'C'.
        APPEND INITIAL LINE TO gt_entry.
        PERFORM refresh_entry.
      ENDIF.
    WHEN 'DELI'.
      " 선택한 미저장 행 삭제. 변경 화면의 PR은 입력행 삭제로 취소하지 않는다(취소는 ZMMPR0100 [PR취소]).
      IF gv_mode = 'N'.
        PERFORM delete_rows.
      ENDIF.
  ENDCASE.
  " 마지막 빈 행까지 다 채웠으면 빈 행을 하나 더 붙여 둔다(신규 작성만).
  PERFORM ensure_blank_row.
ENDMODULE.
