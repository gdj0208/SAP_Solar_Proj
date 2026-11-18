*&---------------------------------------------------------------------*
*& Include ZMMSTO0100_I01
*&---------------------------------------------------------------------*
*& PAI - 버튼 명령 처리
*&   MODULE 안의 DATA는 전역 선언이라 0100/0200에서 이름을 다르게 둔다.
*& 담당: MM(이규빈) / 프로그램: ZMMSTO0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: 지사 간 자재이동(STO) 목록·입력·취소 (개발 10/17~10/23)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: STO 1건 품목 N줄 구조, 목록 카드·이력 ALV
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: STO 예약 추가, 취소 메시지 202·134 구분, 수량 소수점·카드 크기 수정
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 화면 0100: [조회]·Enter / STO 생성 / STO 취소 / 카드 클릭
MODULE command_0100 INPUT.
  gv_saved = ok_code.
  IF gv_saved IS INITIAL.
    gv_saved = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  CASE gv_saved.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'SCARD'.
      " 카드 클릭은 HTML 이벤트가 보낸 내부 코드이다. SE41 버튼이 아니다.
      PERFORM apply_summary.
    WHEN 'NEW'.
      PERFORM start_entry.
    WHEN 'VOIDSTO'.
      " [STO 취소] (SE41 S0100에 기능코드 VOIDSTO 버튼 추가 필요). 예약중 STO만 취소된다.
      PERFORM cancel_selected_sto.
    WHEN 'QUERY' OR 'REFR'.
      CLEAR: gt_new_sto, gv_mark_new.   " [조회] = 파란 줄 정리 후 일반 목록
      PERFORM query_list.
    WHEN 'ENTR' OR 'ENTER' OR space.
      " Enter: 조회조건이 바뀌었을 때만 다시 조회한다(F4로 값만 고른 것은 조회하지 않음).
      DATA lv_sto_chg TYPE abap_bool.
      PERFORM list_filter_changed CHANGING lv_sto_chg.
      IF lv_sto_chg = abap_true.
        PERFORM query_list.
      ENDIF.
  ENDCASE.
ENDMODULE.

" 화면 0200: 초기화 / 재고·일정 확인 / 자재 추가·삭제 / 저장·출고 / STO 목록
MODULE command_0200 INPUT.
  gv_saved = ok_code.
  IF gv_saved IS INITIAL.
    gv_saved = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  IF gv_saved = 'EXIT'.
    LEAVE PROGRAM.
  ENDIF.
  IF gv_saved = 'BACK' OR gv_saved = 'CANC'.
    PERFORM leave_entry.
    LEAVE TO SCREEN 0.
  ENDIF.
  IF gv_saved = 'STOLIST'.
    " [STO 목록] : 생성한 STO를 목록에서 바로 확인한다(방금 만든 STO는 선택된 채로 보인다).
    PERFORM goto_list.
  ENDIF.
  IF gv_saved = 'NEWIN'.
    " [초기화] : 입력 값 검사 없이 처음 상태로 돌린다(셀에 막 입력한 값도 받아와 미저장 여부를 판단).
    IF go_items IS BOUND.
      go_items->check_changed_data( ).
    ENDIF.
    PERFORM new_input.
    RETURN.
  ENDIF.
  DATA lv_valid TYPE abap_bool.
  lv_valid = abap_true.               " ALV가 없으면 검사 없이 버튼을 처리한다.
  IF go_items IS BOUND.
    " ALV 셀에 마지막으로 입력한 값까지 내부테이블로 받아온 뒤 처리한다.
    go_items->check_changed_data( IMPORTING e_valid = lv_valid ).
    IF lv_valid <> abap_true.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '정확한 데이터'.   " 정확한 데이터를 입력해주세요
      RETURN.
    ENDIF.
  ENDIF.
  PERFORM invalidate_if_changed.
  CASE gv_saved.
    WHEN 'QCHG' OR 'ECHG' OR 'ENTR' OR 'ENTER' OR space.
      PERFORM auto_entry.
    WHEN 'CHECK'.
      PERFORM preview_entries.
    WHEN 'SAVE'.
      PERFORM auto_entry.
      PERFORM save_entries.
    WHEN 'ADDI'.
      " 플랜트 미입력·동일·미등록이면 행을 추가하지 않는다.
      PERFORM add_entry_row.
    WHEN 'DELI'.
      PERFORM delete_entries.
  ENDCASE.
ENDMODULE.
