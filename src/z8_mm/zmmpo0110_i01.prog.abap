*&---------------------------------------------------------------------*
*& Include ZMMPO0110_I01
*&---------------------------------------------------------------------*
*& PAI - 버튼 명령 처리
*&   0100: [PO 생성]·[PO 취소]·[새로고침]·카드·[조회]·Enter / 0200: [PO 생성]·[새로고침]·[조회]·Enter
*&   MODULE 안의 DATA는 전역 선언이라 0100/0200에서 이름을 다르게 둔다.
*& 담당: MM(이규빈) / 프로그램: ZMMPO0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-07  이규빈  최초 개발   최초 작성: PR 묶음 발주(PR N건 → PO 1건), PO 목록·취소 (개발 10/07~10/13)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등, 후보 ALV에서 골라 바로 PO 생성
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 생성 확인 메시지 축약, '납기 충족 / N일 지연', 취소 메시지 202·134 구분
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 화면 0100: 조회 / PO 생성(화면 0200으로) / PO 취소 / 상태카드 클릭
MODULE command_0100 INPUT.
  gv_cmd = ok_code.
  IF gv_cmd IS INITIAL.
    gv_cmd = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  CASE gv_cmd.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      PERFORM free_po_grid.
      LEAVE TO SCREEN 0.
    WHEN 'GOCRT'.
      " [PO 생성] → 화면 0200. 돌아오면 새 PO를 파란 줄·선택으로 보여주고 'PO번호 생성 완료'를 띄운다.
      "   파란 줄은 [조회]를 누르거나 다시 PO를 만들 때까지 유지한다(Enter·카드 클릭에도 유지).
      PERFORM free_po_grid.
      PERFORM open_create.
      CLEAR: gt_new_po, gv_sel_new.
      CALL SCREEN 0200.
      IF gt_new_po IS NOT INITIAL.
        p_state = 'A'.                     " 새 PO가 카드 필터에 가려지지 않게 [전체]로
        gv_sel_new = abap_true.
      ENDIF.
      PERFORM query_po.
      IF gt_new_po IS NOT INITIAL.
        DATA lt_new_docs TYPE string_table.
        CLEAR lt_new_docs.                 " MODULE 안 DATA는 전역이라 매번 비운다
        LOOP AT gt_new_po INTO DATA(lv_new_po).
          APPEND CONV string( lv_new_po ) TO lt_new_docs.
        ENDLOOP.
        DATA(lv_new_txt) = lcl_mm_f4=>doc_text( lt_new_docs ).
        MESSAGE s133(z8_msg) WITH lv_new_txt '생성'.   " &1 &2 완료
      ENDIF.
    WHEN 'VOID'.
      PERFORM cancel_selected.
    WHEN 'SCARD'.
      " 카드 클릭은 HTML 이벤트가 보낸 내부 코드이다. SE41 버튼이 아니다.
      PERFORM apply_card.
    WHEN 'QUERY' OR 'REFR'.
      " [조회]·[새로고침] : DB를 다시 읽는다. 파란 줄은 정리하고 일반 목록으로 본다(STO 목록과 같음).
      CLEAR: gt_new_po, gv_sel_new.
      PERFORM query_po.
    WHEN 'ENTR' OR 'ENTER' OR space.
      " Enter: 조회조건이 바뀌었을 때만 다시 조회한다(F4로 값만 고른 것은 조회하지 않음).
      DATA lv_chg1 TYPE abap_bool.
      PERFORM po_filter_changed CHANGING lv_chg1.
      IF lv_chg1 = abap_true.
        PERFORM query_po.
      ENDIF.
  ENDCASE.
ENDMODULE.

" 화면 0200: 조회 / PO 생성
MODULE command_0200 INPUT.
  gv_cmd = ok_code.
  IF gv_cmd IS INITIAL.
    gv_cmd = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  CASE gv_cmd.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      PERFORM free_cand_grid.
      LEAVE TO SCREEN 0.
    WHEN 'CREATE'.
      PERFORM create_po_selected.
    WHEN 'QUERY' OR 'REFR'.
      " [조회]·[새로고침] : 발주 후보 PR을 DB에서 다시 읽는다(가격·예상입고일·신호등 다시 계산).
      PERFORM load_cand.
    WHEN 'ENTR' OR 'ENTER' OR space.
      " Enter: 후보조건이 바뀌었을 때만 다시 조회한다.
      DATA lv_chg2 TYPE abap_bool.
      PERFORM cand_filter_changed CHANGING lv_chg2.
      IF lv_chg2 = abap_true.
        PERFORM load_cand.
      ENDIF.
  ENDCASE.
ENDMODULE.
