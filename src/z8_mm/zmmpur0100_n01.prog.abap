*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_N01
*&---------------------------------------------------------------------*
*& PR·PO·STO 프로그램 호출(SUBMIT ... AND RETURN)과 복귀 후 새 문서 표시
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" SUBMIT ... AND RETURN으로 PUR의 지사·선택 업무가 유지된다.

FORM check_program USING program TYPE clike CHANGING ready TYPE abap_bool.
  ready = abap_false.
  SELECT SINGLE name FROM trdir WHERE name = @program AND subc = '1'
    INTO @DATA(found).
  IF sy-subrc = 0.
    ready = abap_true.
  ELSE.
    MESSAGE s022(z8_msg) DISPLAY LIKE 'E'.   " 데이터를 불러올 수 없습니다(실행할 프로그램 없음)
  ENDIF.
ENDFORM.

" new_pr : [+ PR 생성]. PR 입력 화면을 열고, 돌아오면 새로 생긴 PR을 미발주 PR 목록에 파란 줄로 표시한다.
FORM new_pr.
  DATA ready TYPE abap_bool.
  DATA plant TYPE z8mm_pr-werks.
  PERFORM check_program USING 'ZMMPR0110' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  PERFORM site_plant CHANGING plant.    " 담당 지사(B001) → 넘길 입고플랜트(P100)
  CLEAR: gt_pur_new, gv_pur_sel.
  SELECT MAX( banfn ) FROM z8mm_pr INTO @DATA(lv_pr_before).
  SUBMIT zmmpr0110 WITH p_new = abap_true WITH p_werks = plant AND RETURN.
  " 방금 만든 PR을 찾아 미발주 PR 목록에 파란 줄·선택으로 표시
  SELECT DISTINCT banfn FROM z8mm_pr WHERE banfn > @lv_pr_before INTO TABLE @gt_pur_new.
  PERFORM after_pur_new USING 'R'.
  gv_refresh = abap_true.
ENDFORM.

" new_po : [+ PO 생성]. PO 생성 화면을 열고(미발주 PR에서 고른 행은 선택된 채로), 돌아오면 새 PO를 진행 중 PO 목록에 파란 줄로 표시한다.
FORM new_po.
  DATA ready TYPE abap_bool.
  DATA plant TYPE z8mm_pr-werks.
  PERFORM check_program USING 'ZMMPO0110' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  PERFORM site_plant CHANGING plant.    " 담당 지사(B001) → 넘길 입고플랜트(P100)
  " 미발주 PR 목록에서 고른 행이 있으면 그 PR을 메모리(Z8MM_PO_SELECTED)로 넘겨
  "   PO 생성 화면에서 선택된 채로 보이게 한다(PR 목록 [선택 PR 발주]와 같은 방식).
  "   고른 행이 없으면 P_PURNEW로 PO 생성 화면(0200)에 바로 들어간다.
  " 지사는 PUR 전용 전달값 P_PURWK로 넘긴다(P_WERKS는 PO 서브스크린 칸이라 SUBMIT로 안 넘어감).
  DATA lt_keys TYPE STANDARD TABLE OF z8mm_pr WITH EMPTY KEY.
  IF gv_view = 'R' AND go_grid IS BOUND.
    DATA lt_rows TYPE lvc_t_row.
    go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
    " 고른 행을 모은 뒤 그 PR을 한 번에 읽는다(루프 안 SELECT 없음).
    DATA lt_picks TYPE ty_rows.
    LOOP AT lt_rows INTO DATA(ls_row).
      READ TABLE gt_out INDEX ls_row-index INTO DATA(ls_pick).
      IF sy-subrc = 0.
        APPEND ls_pick TO lt_picks.
      ENDIF.
    ENDLOOP.
    IF lt_picks IS NOT INITIAL.
      SELECT * FROM z8mm_pr FOR ALL ENTRIES IN @lt_picks
        WHERE banfn = @lt_picks-docno AND bnfpo = @lt_picks-item
        INTO TABLE @lt_keys.
      SORT lt_keys BY banfn bnfpo.
    ENDIF.
  ENDIF.
  CLEAR: gt_pur_new, gv_pur_sel.
  SELECT MAX( ebeln ) FROM z8mm_po_h WHERE bsart = 'NB' INTO @DATA(lv_po_before).
  IF lt_keys IS NOT INITIAL.
    EXPORT keys = lt_keys TO MEMORY ID 'Z8MM_PO_SELECTED'.
    SUBMIT zmmpo0110 WITH p_purwk = plant AND RETURN.
    FREE MEMORY ID 'Z8MM_PO_SELECTED'.
  ELSE.
    SUBMIT zmmpo0110 WITH p_purnew = abap_true WITH p_purwk = plant AND RETURN.
  ENDIF.
  SELECT ebeln FROM z8mm_po_h WHERE bsart = 'NB' AND ebeln > @lv_po_before INTO TABLE @gt_pur_new.
  PERFORM after_pur_new USING 'O'.
  gv_refresh = abap_true.
ENDFORM.

" new_sto : [+ STO 생성]. STO 입력 화면을 열고, 돌아오면 새 STO를 이동 중 STO 목록에 파란 줄로 표시한다.
FORM new_sto.
  DATA ready TYPE abap_bool.
  DATA plant TYPE z8mm_pr-werks.
  PERFORM check_program USING 'ZMMSTO0100' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  PERFORM site_plant CHANGING plant.    " 담당 지사(B001) → 넘길 입고플랜트(P100)
  " 담당 지사는 신규 STO의 출발지사 기본값이다. 도착지사는 직접 지정한다.
  " STO 조회칸(p_sfrom)은 서브스크린 안이라 SUBMIT WITH로 채워지지 않는다 → 숨은 칸 p_purwk로 넘긴다.
  CLEAR: gt_pur_new, gv_pur_sel.
  SELECT MAX( ebeln ) FROM z8mm_po_h WHERE bsart = 'UB' INTO @DATA(lv_sto_before).
  SUBMIT zmmsto0100 WITH p_new = abap_true WITH p_purwk = plant AND RETURN.
  SELECT ebeln FROM z8mm_po_h WHERE bsart = 'UB' AND ebeln > @lv_sto_before INTO TABLE @gt_pur_new.
  PERFORM after_pur_new USING 'S'.
  gv_refresh = abap_true.
ENDFORM.

" open_document : 더블클릭한 문서를 해당 프로그램(PR/PO/STO 목록)에서 그 문서만 보이게 연다.
FORM open_document.
  READ TABLE gt_out INDEX gv_row INTO DATA(row).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  DATA ready TYPE abap_bool.
  CASE gv_view.
    WHEN 'R'.
      PERFORM check_program USING 'ZMMPR0100' CHANGING ready.
      IF ready = abap_false.
        RETURN.
      ENDIF.
      " PR0100의 화면 칸은 서브스크린 안이라 전용 숨김 칸(p_pur*)으로 넘긴다.
      SUBMIT zmmpr0100 WITH p_purdoc = row-docno
        WITH p_purwk = row-werks WITH p_pursta = 'A' AND RETURN.
    WHEN 'O'.
      PERFORM check_program USING 'ZMMPO0110' CHANGING ready.
      IF ready = abap_false.
        RETURN.
      ENDIF.
      " PO 번호는 P_PURDOC로 넘긴다. PO는 이때 발주일 기간을 비우고 그 PO만 보여준다.
      SUBMIT zmmpo0110 WITH p_purlst = abap_true
        WITH p_purdoc = row-docno WITH p_state = 'A' AND RETURN.
    WHEN 'S'.
      PERFORM check_program USING 'ZMMSTO0100' CHANGING ready.
      IF ready = abap_false.
        RETURN.
      ENDIF.
      " STO 번호는 숨은 칸 p_purdoc로 넘긴다(STO가 받아서 조회칸 p_doc에 옮기고 기간을 비운다).
      SUBMIT zmmsto0100 WITH p_list = abap_true WITH p_purdoc = row-docno AND RETURN.
  ENDCASE.
  CLEAR gv_row.
  gv_refresh = abap_true.
ENDFORM.

" open_pr_list : [PR 전체목록]. PR 조회 프로그램(ZMMPR0100)을 열고, PUR에서 고른·방금 만든 PR은 그쪽에서도 파란 줄·선택으로 보인다.
FORM open_pr_list.
  DATA ready TYPE abap_bool.
  DATA plant TYPE z8mm_pr-werks.
  PERFORM check_program USING 'ZMMPR0100' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  PERFORM site_plant CHANGING plant.    " 담당 지사(B001) → 넘길 입고플랜트(P100)
  " 미발주 PR 목록에서 고른 행(없으면 방금 만든 PR)을 메모리(Z8MM_PR_MARK)로 넘겨
  "   PR 목록에서도 파란 줄·선택으로 이어서 보이게 한다.
  DATA lt_marks TYPE STANDARD TABLE OF z8mm_pr WITH EMPTY KEY.
  IF gv_view = 'R' AND go_grid IS BOUND.
    DATA lt_rows TYPE lvc_t_row.
    go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
    LOOP AT lt_rows INTO DATA(ls_row).
      READ TABLE gt_out INDEX ls_row-index INTO DATA(ls_pick).
      IF sy-subrc = 0.
        APPEND VALUE #( banfn = ls_pick-docno bnfpo = ls_pick-item ) TO lt_marks.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lt_marks IS INITIAL AND gt_pur_new IS NOT INITIAL.
    SELECT * FROM z8mm_pr FOR ALL ENTRIES IN @gt_pur_new
      WHERE banfn = @gt_pur_new-table_line INTO TABLE @lt_marks.
  ENDIF.
  IF lt_marks IS NOT INITIAL.
    EXPORT marks = lt_marks TO MEMORY ID 'Z8MM_PR_MARK'.
  ENDIF.
  SUBMIT zmmpr0100 WITH p_purwk = plant WITH p_pursta = 'A' AND RETURN.
  FREE MEMORY ID 'Z8MM_PR_MARK'.
  gv_refresh = abap_true.
ENDFORM.

" open_po_list : [PO 전체목록]. PO 조회 프로그램(ZMMPO0110)을 열고, PUR에서 고른·방금 만든 PO는 그쪽에서도 파란 줄·선택으로 보인다.
FORM open_po_list.
  DATA ready TYPE abap_bool.
  DATA plant TYPE z8mm_pr-werks.
  PERFORM check_program USING 'ZMMPO0110' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  PERFORM site_plant CHANGING plant.    " 담당 지사(B001) → 넘길 입고플랜트(P100)
  " 진행 중 PO 목록에서 고른 행(없으면 방금 만든 PO)을 메모리(Z8MM_PO_MARK)로 넘겨
  "   PO 목록에서도 파란 줄·선택으로 이어서 보이게 한다.
  DATA lt_marks TYPE STANDARD TABLE OF z8mm_po_h-ebeln WITH EMPTY KEY.
  IF gv_view = 'O' AND go_grid IS BOUND.
    DATA lt_rows TYPE lvc_t_row.
    go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
    LOOP AT lt_rows INTO DATA(ls_row).
      READ TABLE gt_out INDEX ls_row-index INTO DATA(ls_pick).
      IF sy-subrc = 0.
        APPEND ls_pick-docno TO lt_marks.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lt_marks IS INITIAL.
    LOOP AT gt_pur_new INTO DATA(lv_new).
      APPEND lv_new TO lt_marks.
    ENDLOOP.
  ENDIF.
  SORT lt_marks BY table_line.
  DELETE ADJACENT DUPLICATES FROM lt_marks COMPARING table_line.
  IF lt_marks IS NOT INITIAL.
    EXPORT marks = lt_marks TO MEMORY ID 'Z8MM_PO_MARK'.
  ENDIF.
  SUBMIT zmmpo0110 WITH p_purlst = abap_true
    WITH p_purwk = plant WITH p_state = 'A' AND RETURN.
  FREE MEMORY ID 'Z8MM_PO_MARK'.
  gv_refresh = abap_true.
ENDFORM.

" open_stock : [지사 재고 조회] → 지사재고 통합현황(Z8MMDS0100).
"   Z8MMDS0100은 START-OF-SELECTION에서 바로 CALL SCREEN 0100을 하므로,
"   SUBMIT(VIA SELECTION-SCREEN 없이)하면 조회조건 화면을 건너뛰고 0100으로 바로 열린다.
"   담당 지사를 골라 둔 경우 그 지사만, '전체 지사'면 전체를 조회한다. 뒤로 가면 PUR로 돌아온다.
FORM open_stock.
  DATA ready TYPE abap_bool.
  PERFORM check_program USING 'Z8MMDS0100' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  IF gv_werks IS NOT INITIAL AND gv_werks <> '*'.
    DATA lr_stock_plants TYPE RANGE OF z8mm_pr-werks.
    PERFORM site_plants CHANGING lr_stock_plants.   " 지사 재고 조회는 플랜트로 받는다
    SUBMIT z8mmds0100 WITH s_werks IN lr_stock_plants AND RETURN.
  ELSE.
    SUBMIT z8mmds0100 AND RETURN.
  ENDIF.
  gv_refresh = abap_true.
ENDFORM.

" 전체 STO 목록은 STO 프로그램(ZMMSTO0100) 0100 화면에서 확인한다(카드: 전체·이동중·입고완료).
FORM open_sto_list.
  DATA ready TYPE abap_bool.
  PERFORM check_program USING 'ZMMSTO0100' CHANGING ready.
  IF ready = abap_false.
    RETURN.
  ENDIF.
  " 예약·이동 STO 목록에서 고른 행(없으면 방금 만든 STO)을 메모리(Z8MM_STO_MARK)로 넘겨
  "   STO 목록에서도 파란 줄·선택으로 이어서 보이게 한다.
  DATA lt_marks TYPE STANDARD TABLE OF z8mm_po_h-ebeln WITH EMPTY KEY.
  IF gv_view = 'S' AND go_grid IS BOUND.
    DATA lt_rows TYPE lvc_t_row.
    go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
    LOOP AT lt_rows INTO DATA(ls_row).
      READ TABLE gt_out INDEX ls_row-index INTO DATA(ls_pick).
      IF sy-subrc = 0.
        APPEND ls_pick-docno TO lt_marks.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF lt_marks IS INITIAL.
    LOOP AT gt_pur_new INTO DATA(lv_new).
      APPEND lv_new TO lt_marks.
    ENDLOOP.
  ENDIF.
  SORT lt_marks BY table_line.
  DELETE ADJACENT DUPLICATES FROM lt_marks COMPARING table_line.
  IF lt_marks IS NOT INITIAL.
    EXPORT marks = lt_marks TO MEMORY ID 'Z8MM_STO_MARK'.
  ENDIF.
  SUBMIT zmmsto0100 WITH p_list = abap_true AND RETURN.
  FREE MEMORY ID 'Z8MM_STO_MARK'.
  gv_refresh = abap_true.
ENDFORM.

" after_pur_new : 방금 만든 문서가 있으면 그 업무 목록으로 바꾸고 한 번 선택하게 표시한다.
FORM after_pur_new USING iv_view TYPE clike.
  IF gt_pur_new IS INITIAL.
    RETURN.                              " 만든 문서가 없으면(그냥 뒤로) 메시지 없이 현황만 다시 조회
  ENDIF.
  gv_view = iv_view.
  gv_pur_sel = abap_true.
  DATA lt_new_docs TYPE string_table.
  LOOP AT gt_pur_new INTO DATA(lv_new_doc).
    APPEND CONV string( lv_new_doc ) TO lt_new_docs.
  ENDLOOP.
  DATA(lv_new_txt) = lcl_mm_f4=>doc_text( lt_new_docs ).
  MESSAGE s133(z8_msg) WITH lv_new_txt '생성'.   " &1 &2 완료 (새 문서 행은 파란 줄)
ENDFORM.
