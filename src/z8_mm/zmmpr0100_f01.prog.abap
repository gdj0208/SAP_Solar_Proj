*&---------------------------------------------------------------------*
*& Include ZMMPR0100_F01
*&---------------------------------------------------------------------*
*& 업무 처리 FORM - 조회·카드·PR 취소·PR 생성/변경/발주 화면 호출
*&   처리 결과는 하단 상태줄, 방금 처리한 PR은 파란 줄로 강조한다.
*& 담당: MM(이규빈) / 프로그램: ZMMPR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-14  이규빈  최초 개발   최초 작성: PR 목록 조회·취소, PR 생성/변경·PO 생성 화면 연결 (개발 10/14~10/16)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등 화면 통일, 조회조건·버튼 동작 보완
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 조회 결과 없음 오류 표시, 취소 메시지 정리
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" enrich_list : PR 한 줄에 자재명·업체명·구매지사명·요청구분 글자·상태/신호등·안내를 채운다. DB 변경 없음.
FORM enrich_list CHANGING row TYPE ty_list.
  SELECT SINGLE maktx FROM z8material_txt_m WHERE matnr = @row-matnr AND spras = @sy-langu INTO @row-maktx.
  IF row-lifnr IS NOT INITIAL.
    SELECT SINGLE name1 FROM z8vendor_m WHERE lifnr = @row-lifnr INTO @row-vendor_name.
    IF sy-subrc <> 0.
      row-vendor_name = row-lifnr.
    ENDIF.
  ENDIF.
  " 구매지사는 이름만(예: 충청지사), 플랜트 코드는 '입고플랜트' 열(WERKS)에 따로 보인다.
  PERFORM plant_name USING row-werks CHANGING row-site_text.
  IF row-site_text IS INITIAL.
    row-site_text = row-werks.
  ENDIF.
  PERFORM source_text USING row-source_type CHANGING row-src_text.
  IF row-loekz IS NOT INITIAL.
    row-state = '취소'.
    row-signal = icon_led_red.
  ELSEIF row-ebeln IS NOT INITIAL.
    row-state = '발주완료'.
    row-signal = icon_led_green.
  ELSE.
    row-state = '발주대기'.
    row-signal = icon_led_yellow.
    IF row-lifnr IS INITIAL.
      row-signal = icon_led_red.
      row-detail = 'PO 생성 전 공급업체를 지정하세요.'.
    ELSEIF row-lfdat IS NOT INITIAL AND row-lfdat < sy-datum.
      " 희망납기일이 지난 발주대기 PR도 신호등은 노랑(발주대기) 그대로 두고 처리 안내로만 알린다.
      "   빨강은 취소·공급업체 없음(발주 불가)에만 쓴다.
      row-detail = '희망납기일이 지났습니다. 발주를 서둘러 주세요.'.
    ENDIF.
  ENDIF.
ENDFORM.

" query_list : 조회조건(기간 필수·지사·자재·업체·PR번호)으로 PR을 읽어 목록·카드 건수를 만든다.
"   방금 처리한 PR(gt_mark)은 조건과 관계없이 맨 위 파란 줄로 함께 보여준다.
FORM query_list.
  " 조회 기간: 시작일 필수(문서번호로 찾을 때도), 종료일이 비면 시작일 하루.
  "   - 시작일 비면 Z8_MSG 046 / 종료일 비면 시작일 하루 / 시작일 > 종료일이면 결과 없음(BETWEEN과 동일)
  IF p_dfrom IS INITIAL.
    " 팀 공통 메시지 Z8_MSG 046 '조회 기간을 입력해주세요'
    MESSAGE s046(z8_msg) DISPLAY LIKE 'E'.
    SET CURSOR FIELD 'P_DFROM'.          " 시작일 칸에 커서
    RETURN.
  ENDIF.
  DATA(lv_dto) = COND sy-datum( WHEN p_dto IS INITIAL THEN p_dfrom ELSE p_dto ).
  " 구매지사(B001) → 그 지사에 속한 입고플랜트(P100...) 목록
  DATA lr_site TYPE RANGE OF z8mm_pr-werks.
  IF p_bupla IS NOT INITIAL.
    SELECT werks FROM z8plant_m WHERE bupla = @p_bupla INTO TABLE @DATA(lt_site).
    DATA ls_range LIKE LINE OF lr_site.
    LOOP AT lt_site INTO DATA(ls_site).
      CLEAR ls_range.
      ls_range-sign = 'I'.
      ls_range-option = 'EQ'.
      ls_range-low = ls_site-werks.
      APPEND ls_range TO lr_site.
    ENDLOOP.
    IF lr_site IS INITIAL.
      lr_site = VALUE #( ( sign = 'I' option = 'EQ' low = '####' ) ).   " 플랜트 없는 지사 → 결과 없음
    ENDIF.
  ENDIF.
  " 전체 PR을 다 읽지 않고 희망납기 기간으로 DB에서 거른다(나머지 조건은 아래 LOOP).
  "   방금 처리한 PR(gt_mark)은 기간 밖이어도 보여야 하므로 따로 읽어 붙이고 중복을 지운다.
  SELECT * FROM z8mm_pr WHERE lfdat BETWEEN @p_dfrom AND @lv_dto INTO TABLE @gt_original.
  IF gt_mark IS NOT INITIAL.
    SELECT * FROM z8mm_pr FOR ALL ENTRIES IN @gt_mark
      WHERE banfn = @gt_mark-banfn AND bnfpo = @gt_mark-bnfpo
      APPENDING TABLE @gt_original.
    SORT gt_original BY banfn bnfpo.
    DELETE ADJACENT DUPLICATES FROM gt_original COMPARING banfn bnfpo.
  ENDIF.
  CLEAR gt_list.
  LOOP AT gt_original INTO DATA(pr).
    " 방금 처리한 PR은 조회조건·카드와 관계없이 맨 위에 파란 줄로 한 번 보여준다.
    READ TABLE gt_mark TRANSPORTING NO FIELDS WITH TABLE KEY banfn = pr-banfn bnfpo = pr-bnfpo.
    DATA(lv_marked) = xsdbool( sy-subrc = 0 ).
    IF lv_marked = abap_false.
      IF ( p_doc IS NOT INITIAL AND pr-banfn <> p_doc ) OR ( p_bupla IS NOT INITIAL AND pr-werks NOT IN lr_site )
        OR ( p_matnr IS NOT INITIAL AND pr-matnr <> p_matnr ) OR ( p_lifnr IS NOT INITIAL AND pr-lifnr <> p_lifnr ).
        CONTINUE.
      ENDIF.
      " 희망납기일 기간시작일~종료일(종료일 없으면 시작일 하루)
      IF pr-lfdat < p_dfrom OR pr-lfdat > lv_dto.
        CONTINUE.
      ENDIF.
    ENDIF.
    DATA(row) = CORRESPONDING ty_list( pr ).
    PERFORM enrich_list CHANGING row.
    IF lv_marked = abap_true.
      row-is_mark = abap_true.
      row-rowclr = 'C410'.
    ENDIF.
    APPEND row TO gt_list.
  ENDLOOP.
  " 기본정렬: 처리할 것(발주대기) 먼저, 그 안에서 희망납기일 빠른 순. 완료·취소는 아래로.
  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<rank_pr>).
    <rank_pr>-sort_rank = SWITCH #( <rank_pr>-state WHEN '발주대기' THEN 1 WHEN '발주완료' THEN 2 ELSE 3 ).
  ENDLOOP.
  SORT gt_list BY is_mark DESCENDING sort_rank lfdat banfn bnfpo.
  gt_summary = gt_list.
  PERFORM filter_list.
  PERFORM remember_query.
  IF gt_summary IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.   " 조회 조건에 해당하는 데이터가 없습니다
  ENDIF.
ENDFORM.

" filter_list : 마지막 조회 결과(gt_summary)에서 카드로 고른 상태(p_state)만 ALV에 남긴다. DB를 읽지 않는다.
"   방금 처리한 PR(파란 줄)은 카드와 관계없이 보인다.
FORM filter_list.
  gt_list = gt_summary.
  CASE p_state.
    WHEN 'W'. DELETE gt_list WHERE state <> '발주대기' AND is_mark = abap_false.
    WHEN 'C'. DELETE gt_list WHERE state <> '발주완료' AND is_mark = abap_false.
    WHEN 'X'. DELETE gt_list WHERE state <> '취소' AND is_mark = abap_false.
  ENDCASE.
  IF go_list IS BOUND.
    DATA catalog TYPE lvc_t_fcat.
    go_list->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = catalog ).
    PERFORM quantity_catalog USING gt_list CHANGING catalog.
    go_list->set_frontend_fieldcatalog( it_fieldcatalog = catalog ).
    DATA lv_title TYPE lvc_title.
    PERFORM list_title CHANGING lv_title.
    go_list->set_gridtitle( i_gridtitle = lv_title ).
    go_list->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  ENDIF.
ENDFORM.

" column : ALV 열 하나(필드명·제목·폭·단위/통화 참조)를 필드카탈로그에 추가한다. 열별 폭은 CASE에서 조정.
FORM column USING name TYPE clike title TYPE clike edit TYPE abap_bool CHANGING catalog TYPE lvc_t_fcat.
  DATA fc TYPE lvc_s_fcat.
  fc = VALUE #( fieldname = name coltext = title scrtext_l = title scrtext_m = title scrtext_s = title
    outputlen = 10 edit = edit ).
  CASE name.
    WHEN 'SIGNAL'.
      fc-icon = abap_true.
      fc-outputlen = 4.
    WHEN 'MATNR'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'MATNR'.
      fc-f4availabl = edit.
      fc-outputlen = 12.
    WHEN 'LIFNR'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'LIFNR'.
      fc-f4availabl = edit.
    WHEN 'MENGE'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'MENGE'.
      fc-qfieldname = 'MEINS'.
      fc-decimals_o = 0.
      fc-outputlen = 9.
    WHEN 'MEINS'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'MEINS'.
      fc-outputlen = 5.
    WHEN 'PREIS'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'PREIS'.
      fc-cfieldname = 'WAERS'.
    WHEN 'LFDAT'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'LFDAT'.
      fc-outputlen = 10.
    WHEN 'MAKTX'.
      fc-outputlen = 16.
    WHEN 'VENDOR_NAME'.
      fc-outputlen = 12.
    WHEN 'SITE_TEXT'.
      fc-outputlen = 12.
    WHEN 'WERKS'.
      fc-outputlen = 7.
    WHEN 'SRC_TEXT'.
      fc-outputlen = 8.
    WHEN 'STATE'.
      fc-outputlen = 9.
    WHEN 'DETAIL'.
      fc-outputlen = 28.
    WHEN 'BANFN' OR 'EBELN'.
      fc-outputlen = 10.
    WHEN 'WAERS'.
      fc-outputlen = 5.
  ENDCASE.
  APPEND fc TO catalog.
ENDFORM.

" display_list : PR 목록 ALV를 처음 한 번 만든다(열 순서 = 아래 PERFORM column 순서).
FORM display_list.
  IF go_list IS BOUND.
    RETURN.
  ENDIF.
  CREATE OBJECT go_listc EXPORTING container_name = 'CC_MAIN'.
  CREATE OBJECT go_list EXPORTING i_parent = go_listc.
  DATA catalog TYPE lvc_t_fcat.
  PERFORM column USING 'SIGNAL' `상태` abap_false CHANGING catalog.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM column USING 'STATE' `발주 여부` abap_false CHANGING catalog.
  PERFORM column USING 'BANFN' `PR 번호` abap_false CHANGING catalog.
  PERFORM column USING 'SRC_TEXT' `요청구분` abap_false CHANGING catalog.
  PERFORM column USING 'MATNR' `자재번호` abap_false CHANGING catalog.
  PERFORM column USING 'MAKTX' `자재명` abap_false CHANGING catalog.
  PERFORM column USING 'MENGE' `요청수량` abap_false CHANGING catalog.
  PERFORM column USING 'MEINS' `단위` abap_false CHANGING catalog.
  PERFORM column USING 'VENDOR_NAME' `공급업체` abap_false CHANGING catalog.
  PERFORM column USING 'SITE_TEXT' `구매지사` abap_false CHANGING catalog.
  PERFORM column USING 'WERKS' `입고플랜트` abap_false CHANGING catalog.
  PERFORM column USING 'LFDAT' `희망납기일` abap_false CHANGING catalog.
  PERFORM column USING 'EBELN' `연결 PO번호` abap_false CHANGING catalog.
  PERFORM column USING 'DETAIL' `처리 안내` abap_false CHANGING catalog.
  PERFORM quantity_catalog USING gt_list CHANGING catalog.
  DATA lv_first_title TYPE lvc_title.
  PERFORM list_title CHANGING lv_first_title.
  DATA lt_excl TYPE ui_functions.
  PERFORM sort_only_toolbar CHANGING lt_excl.
  go_list->set_table_for_first_display(
    EXPORTING is_layout = VALUE lvc_s_layo( no_toolbar = abap_false zebra = abap_true sel_mode = 'A' info_fname = 'ROWCLR' smalltitle = abap_true grid_title = lv_first_title )
      it_toolbar_excluding = lt_excl
    CHANGING it_outtab = gt_list it_fieldcatalog = catalog ).
  PERFORM select_marked.
ENDFORM.

" selected : ALV에서 사용자가 고른 행들을 목록 내부테이블 기준으로 돌려준다.
FORM selected CHANGING rows TYPE ty_rows.
  CLEAR rows.
  IF go_list IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA indices TYPE lvc_t_row.
  go_list->get_selected_rows( IMPORTING et_index_rows = indices ).
  LOOP AT indices INTO DATA(idx).
    READ TABLE gt_list INDEX idx-index INTO DATA(row).
    IF sy-subrc = 0.
      APPEND row TO rows.
    ENDIF.
  ENDLOOP.
ENDFORM.

" begin_new : 입력 프로그램을 호출하고 복귀 후 현재 목록을 갱신한다.
FORM begin_new.
  " 돌아오면 새로 생긴 PR을 파란 줄로 표시한다.
  PERFORM clear_mark.
  SELECT MAX( banfn ) FROM z8mm_pr INTO @DATA(lv_last_pr).
  " 입력 화면은 입고플랜트로 받는다 → 구매지사의 첫 플랜트를 넘긴다.
  DATA lv_plant TYPE z8mm_pr-werks.
  IF p_bupla IS NOT INITIAL.
    SELECT werks FROM z8plant_m WHERE bupla = @p_bupla ORDER BY werks INTO @lv_plant UP TO 1 ROWS.
    ENDSELECT.
  ENDIF.
  SUBMIT zmmpr0110 WITH p_new = abap_true WITH p_werks = lv_plant AND RETURN.
  SELECT banfn, bnfpo FROM z8mm_pr WHERE banfn > @lv_last_pr
    INTO CORRESPONDING FIELDS OF TABLE @gt_mark.
  PERFORM query_list.
  PERFORM after_mark USING '생성'.
ENDFORM.

"" after_mark : 방금 처리한 PR이 있으면 상태줄에 'PR번호 생성/변경/발주 완료'를 띄운다.
" 파란 줄(gt_mark)은 [조회] 버튼·카드·새 처리 전까지 유지하고, 그 행들을 한 번 선택해 둔다.
FORM after_mark USING iv_action TYPE clike.
  IF gt_mark IS NOT INITIAL.
    DATA lt_mark_docs TYPE string_table.
    LOOP AT gt_mark INTO DATA(ls_mark).
      APPEND CONV string( ls_mark-banfn ) TO lt_mark_docs.
    ENDLOOP.
    DATA(lv_mark_txt) = lcl_mm_f4=>doc_text( lt_mark_docs ).
    MESSAGE s133(z8_msg) WITH lv_mark_txt iv_action.   " &1 &2 완료
    gv_sel_mark = abap_true.
    PERFORM select_marked.
  ENDIF.
ENDFORM.

" select_marked : 방금 처리한 행(is_mark)을 ALV 선택 상태로 한 번 걸어 둔다. 사용자가 다른 행을 고르면 그 선택이 우선이다.
FORM select_marked.
  IF go_list IS NOT BOUND OR gv_sel_mark = abap_false.
    RETURN.
  ENDIF.
  DATA lt_rows TYPE lvc_t_row.
  LOOP AT gt_list TRANSPORTING NO FIELDS WHERE is_mark = abap_true.
    APPEND VALUE #( index = sy-tabix ) TO lt_rows.
  ENDLOOP.
  go_list->set_selected_rows( it_index_rows = lt_rows ).
  CLEAR gv_sel_mark.
ENDFORM.

" clear_mark : 새 처리·[조회] 전에 이전 파란 줄을 지운다.
FORM clear_mark.
  CLEAR: gt_mark, gv_sel_mark.
ENDFORM.

" begin_change : [PR변경]. 한 건만 골랐는지 확인하고 PR 입력 프로그램을 변경 모드로 연다.
FORM begin_change.
  DATA rows TYPE ty_rows.
  PERFORM selected CHANGING rows.
  IF lines( rows ) <> 1.
    MESSAGE s032(z8_msg) DISPLAY LIKE 'E'.   " 한 건만 선택해주세요
    RETURN.
  ENDIF.
  DATA(chosen) = rows[ 1 ].
  PERFORM open_change USING chosen.
ENDFORM.

" open_change : 선택 PR 번호를 입력 프로그램에 전달한다.
FORM open_change USING chosen TYPE ty_list.
  " 실제로 값이 바뀌었을 때만 파란 줄로 표시한다.
  PERFORM clear_mark.
  SELECT SINGLE * FROM z8mm_pr WHERE banfn = @chosen-banfn AND bnfpo = @chosen-bnfpo INTO @DATA(ls_before).
  SUBMIT zmmpr0110 WITH p_chg = abap_true
    WITH p_pr = chosen-banfn WITH p_item = chosen-bnfpo AND RETURN.
  SELECT SINGLE * FROM z8mm_pr WHERE banfn = @chosen-banfn AND bnfpo = @chosen-bnfpo INTO @DATA(ls_after).
  IF ls_after <> ls_before.
    INSERT VALUE #( banfn = chosen-banfn bnfpo = chosen-bnfpo ) INTO TABLE gt_mark.
  ENDIF.
  PERFORM query_list.
  PERFORM after_mark USING '변경'.
ENDFORM.

" cancel_selected : [PR취소]. 발주완료·취소 PR이 섞이면 막고(202), 확인 후 고른 미발주 PR을 한 건씩 잠금→취소(LOEKZ)→COMMIT→잠금해제 한다.
"   취소한 행은 그 자리에서 '취소' + 파란 줄로 바뀌고 선택 상태로 남는다.
FORM cancel_selected.
  DATA rows TYPE ty_rows.
  PERFORM selected CHANGING rows.
  IF rows IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  " 발주완료·취소 PR이 하나라도 섞이면 아무것도 바꾸지 않고 그 PR 번호를 알린다(목록 신호등·상태 그대로).
  LOOP AT rows INTO DATA(ls_chk) WHERE ebeln IS NOT INITIAL OR loekz IS NOT INITIAL.
    DATA(lv_done_pr) = |{ ls_chk-banfn ALPHA = OUT }|.
    MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH lv_done_pr.   " &1번은 이미 처리 완료된 품목입니다
    RETURN.
  ENDLOOP.
  " 확인창에 취소할 PR 번호를 보여준다(여러 건이면 첫 PR 번호 외 N건).
  DATA lv_first_pr TYPE string.
  lv_first_pr = |{ rows[ 1 ]-banfn ALPHA = OUT }|.
  DATA lv_question TYPE c LENGTH 120.
  IF lines( rows ) = 1.
    lv_question = |미발주 PR { lv_first_pr }을(를) 취소할까요?|.
  ELSE.
    lv_question = |미발주 PR { lv_first_pr } 외 { lines( rows ) - 1 }건을 취소할까요?|.
  ENDIF.
  DATA answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'PR 취소' text_question = lv_question
    default_button = '2' display_cancel_button = space
    IMPORTING answer = answer EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR answer <> '1'.
    RETURN.
  ENDIF.
  DATA failed TYPE i.
  DATA lt_cancelled TYPE string_table.      " 취소한 PR 번호(완료 메시지용)
  PERFORM clear_mark.
  LOOP AT rows INTO DATA(row).
    READ TABLE gt_original WITH KEY banfn = row-banfn bnfpo = row-bnfpo INTO DATA(original).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    TRY.
      " 저장 직전에 잠금을 확보한다. 성공·실패 모두 unlock으로 해제해야 한다.
      lcl_mm_common=>lock_doc( ).          " 재고 잠금 없이 문서 잠금만(재고 처리 중에도 저장 가능)
      lcl_mm_purchase=>change_pr( original = original quantity = original-menge vendor = original-lifnr cancel = abap_true ).
      " 이 행/문서의 DB 변경을 확정한다. 이전에 성공한 건은 다음 건 오류로 취소되지 않는다.
      COMMIT WORK AND WAIT.
      lcl_mm_common=>unlock( ).
      " 취소한 행은 목록에서 빼지 않고 그 자리에서 '취소' + 파란 줄로 바꿔 보여준다(다음 조회 때 정리).
      LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<list_cancel>)
        WHERE banfn = row-banfn AND bnfpo = row-bnfpo.
        <list_cancel>-loekz = 'X'.
        <list_cancel>-state = '취소'.
        <list_cancel>-signal = icon_led_red.
        <list_cancel>-rowclr = 'C410'.
        <list_cancel>-is_mark = abap_true.
      ENDLOOP.
      LOOP AT gt_summary ASSIGNING FIELD-SYMBOL(<summary_cancel>)
        WHERE banfn = row-banfn AND bnfpo = row-bnfpo.
        <summary_cancel>-loekz = 'X'.
        <summary_cancel>-state = '취소'.
        <summary_cancel>-signal = icon_led_red.
        CLEAR <summary_cancel>-detail.
      ENDLOOP.
      INSERT VALUE #( banfn = row-banfn bnfpo = row-bnfpo ) INTO TABLE gt_mark.
      APPEND CONV string( row-banfn ) TO lt_cancelled.
    " 검사/저장 중 fail로 전달된 업무 오류를 여기서 받아 해당 행에 표시한다.
    CATCH lcx_mm INTO DATA(error).
      " 현재 미확정 DB 변경을 되돌린다. 번호범위에서 받은 번호는 건너뛸 수 있다.
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      failed = failed + 1.
      " 실패 행은 신호등·상태를 바꾸지 않고 처리 안내에 사유만 남긴다(취소된 것처럼 보이지 않게).
      LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<bad>) WHERE banfn = row-banfn AND bnfpo = row-bnfpo.
        <bad>-detail = error->detail.
      ENDLOOP.
    CATCH cx_root INTO DATA(unexpected).
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      failed = failed + 1.
      LOOP AT gt_list ASSIGNING <bad> WHERE banfn = row-banfn AND bnfpo = row-bnfpo.
        <bad>-detail = unexpected->get_text( ).
      ENDLOOP.
    ENDTRY.
  ENDLOOP.
  " 실패가 있으면 실패 메시지(사유는 행의 처리 안내), 모두 성공이면 'PR번호 취소 완료'.
  IF failed > 0.
    MESSAGE s105(z8_msg) DISPLAY LIKE 'E'.   " 상태 변경에 실패했습니다
  ELSE.
    DATA(lv_cancel_txt) = lcl_mm_f4=>doc_text( lt_cancelled ).
    MESSAGE s133(z8_msg) WITH lv_cancel_txt '취소'.   " &1 &2 완료
  ENDIF.
  IF go_list IS BOUND.
    DATA cancel_title TYPE lvc_title.
    PERFORM list_title CHANGING cancel_title.
    go_list->set_gridtitle( i_gridtitle = cancel_title ).
    go_list->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
    " 방금 취소한 행을 선택 상태로 걸어 둔다(선택 해제하지 않음).
    gv_sel_mark = abap_true.
    PERFORM select_marked.
  ENDIF.
ENDFORM.

" forward_to_po : [선택 PR 발주]. 고른 발주대기 PR을 메모리로 넘겨 PO 생성 화면을 열고,
"   돌아오면 실제로 PO가 생긴 PR만 파란 줄로 표시한다.
FORM forward_to_po.
  DATA rows TYPE ty_rows.
  PERFORM selected CHANGING rows.
  IF rows IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  DATA requests TYPE lcl_mm_common=>ty_prs.
  LOOP AT rows INTO DATA(row).
    IF row-ebeln IS NOT INITIAL OR row-loekz IS NOT INITIAL.
      DATA(lv_done_pr) = |{ row-banfn ALPHA = OUT }|.
      MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH lv_done_pr.   " &1번은 이미 처리 완료된 품목입니다(발주대기 PR만 발주)
      RETURN.
    ENDIF.
    READ TABLE gt_original WITH KEY banfn = row-banfn bnfpo = row-bnfpo INTO DATA(pr).
    IF sy-subrc = 0.
      APPEND pr TO requests.
    ENDIF.
  ENDLOOP.
  IF requests IS INITIAL.
    RETURN.
  ENDIF.
  PERFORM clear_mark.
  EXPORT keys = requests TO MEMORY ID 'Z8MM_PO_SELECTED'.
  SUBMIT zmmpo0110 AND RETURN.
  FREE MEMORY ID 'Z8MM_PO_SELECTED'.
  " PO가 실제로 만들어진 PR만 파란 줄로 표시한다(발주완료로 바뀐 행). 넘긴 PR을 한 번에 다시 읽는다.
  TYPES: BEGIN OF ty_po_now,
           banfn TYPE z8mm_pr-banfn,
           bnfpo TYPE z8mm_pr-bnfpo,
         END OF ty_po_now.
  DATA lt_po_now TYPE STANDARD TABLE OF ty_po_now WITH EMPTY KEY.
  SELECT banfn, bnfpo FROM z8mm_pr FOR ALL ENTRIES IN @requests
    WHERE banfn = @requests-banfn AND bnfpo = @requests-bnfpo AND ebeln <> @space
    INTO CORRESPONDING FIELDS OF TABLE @lt_po_now.
  LOOP AT lt_po_now INTO DATA(ls_po_now).
    INSERT VALUE #( banfn = ls_po_now-banfn bnfpo = ls_po_now-bnfpo ) INTO TABLE gt_mark.
  ENDLOOP.
  PERFORM query_list.
  PERFORM after_mark USING '발주'.
ENDFORM.

" screen_help : F4. 칸에 글자 일부(예: CAB, 케이블, P2)가 있으면 그 글자로 걸러서 보여준다.
" 1건뿐이면 목록 없이 바로 넣는다. 고른 값·이름만 화면에 반영하고, 목록 조회는 [조회]·Enter 때 한다. (공통: Z8MM_F4_C01)
FORM screen_help USING iv_kind TYPE clike iv_dyn TYPE clike.
  DATA(lv_typed) = lcl_mm_f4=>screen_value( iv_dyn ).
  DATA(lv_value) = lcl_mm_f4=>pick( kind = iv_kind typed = lv_typed ).
  IF lv_value IS INITIAL.
    RETURN.
  ENDIF.
  ASSIGN (iv_dyn) TO FIELD-SYMBOL(<parameter>).
  IF sy-subrc = 0.
    <parameter> = lv_value.
  ENDIF.
  lcl_mm_f4=>put_screen( field = iv_dyn value = lv_value ).
  IF sy-batch = abap_false.
    CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
      EXPORTING functioncode = 'F4SET'      " 이름 표시만 갱신하는 PAI(조회 안 함)
      EXCEPTIONS function_not_supported = 1 OTHERS = 2.
  ENDIF.
ENDFORM.
" 정수 열은 .000을 숨기고 실제 소수가 있는 열은 3자리로 표시한다.
FORM quantity_catalog USING rows TYPE STANDARD TABLE CHANGING catalog TYPE lvc_t_fcat.
  LOOP AT catalog ASSIGNING FIELD-SYMBOL(<qty_fc>) WHERE qfieldname = 'MEINS'.
    <qty_fc>-decimals_o = 0.
    LOOP AT rows ASSIGNING FIELD-SYMBOL(<qty_row>).
      ASSIGN COMPONENT <qty_fc>-fieldname OF STRUCTURE <qty_row> TO FIELD-SYMBOL(<qty_value>).
      IF sy-subrc = 0.
        DATA amount TYPE decfloat34.
        amount = CONV decfloat34( <qty_value> ).
        IF amount <> trunc( amount ).
          <qty_fc>-decimals_o = 3.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

" remember_query : 마지막으로 조회한 조건을 기억한다(조건이 바뀌었는지 비교용).
FORM remember_query.
  gs_query_filter = VALUE #( document = p_doc bupla = p_bupla matnr = p_matnr
    lifnr = p_lifnr state = p_state dfrom = p_dfrom dto = p_dto ).
ENDFORM.

" query_changed : 화면 조건이 마지막 조회 때와 다른지 확인한다(다르면 처리 전에 재조회 요구).
FORM query_changed CHANGING changed TYPE abap_bool.
  DATA(current) = VALUE ty_query_filter( document = p_doc bupla = p_bupla
    matnr = p_matnr lifnr = p_lifnr state = p_state dfrom = p_dfrom dto = p_dto ).
  changed = xsdbool( current <> gs_query_filter ).
ENDFORM.

" 상태·도착일정 선택 전 품목 원본으로 전체 현황을 집계한다.
" 재조회·취소·생성화면 복귀 뒤 0100 PBO에서 함께 갱신한다.
FORM display_summary.
  DATA: n1 TYPE i, n2 TYPE i, n3 TYPE i, n4 TYPE i, n5 TYPE i,
        stamp TYPE string, html TYPE STANDARD TABLE OF w3html WITH EMPTY KEY,
        url TYPE c LENGTH 255,
        active TYPE string.
  n1 = lines( gt_summary ).
  LOOP AT gt_summary INTO DATA(summary_row).
    CASE summary_row-state.
      WHEN '발주대기'.
        n2 = n2 + 1.
      WHEN '발주완료'.
        n3 = n3 + 1.
      WHEN '취소'.
        n4 = n4 + 1.
    ENDCASE.
  ENDLOOP.
  CASE p_state.
    WHEN 'A'. active = 'ALL'.
    WHEN 'W'. active = 'WAIT'.
    WHEN 'C'. active = 'DONE'.
    WHEN 'X'. active = 'VOID'.
    WHEN space. active = 'ALL'.
  ENDCASE.
  stamp = |{ n1 }/{ n2 }/{ n3 }/{ n4 }/{ n5 }/{ active }|.
  IF go_summary IS BOUND AND stamp = gv_summary_stamp.
    RETURN.
  ENDIF.
  IF go_summary_box IS NOT BOUND.
    CREATE OBJECT go_summary_box
      EXPORTING container_name = 'CC_SUM'
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_summary IS NOT BOUND.
    CREATE OBJECT go_summary EXPORTING parent = go_summary_box
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_summary_events IS NOT BOUND.
    CREATE OBJECT go_summary_events.
    SET HANDLER go_summary_events->on_click FOR go_summary.
    DATA events TYPE cntl_simple_events.
    events = VALUE #( ( eventid = cl_gui_html_viewer=>m_id_sapevent
                        appl_event = abap_false ) ).
    go_summary->set_registered_events( EXPORTING events = events
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      SET HANDLER go_summary_events->on_click FOR go_summary ACTIVATION abap_false.
      FREE go_summary_events.
      RETURN.
    ENDIF.
  ENDIF.
  " 카드 모양은 PO·PUR과 같다(색 점 + 이름 + 건수, 선택 카드는 파란 테두리).
  APPEND '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' TO html.
  " 카드 세로 가운데: html·body·table을 영역(CC_SUM) 높이 100%로 채우고 칸 안에서 가운데 정렬
  APPEND 'html,body{height:100%;margin:0;overflow:hidden}' TO html.
  " 바깥(body)은 GUI 화면 배경색(#f2f2f2), 카드는 흰 판(.p) 안에 둔다.
  "   흰 판 테두리는 왼쪽 조회조건 틀과 같은 색이고, 아래 여백 8px로 틀의 아래 끝과 높이를 맞춘다.
  APPEND 'body{padding:0 0 8px;box-sizing:border-box;background:#f2f2f2;font:12px Arial,sans-serif;color:#243b53}' TO html.
  APPEND '.p{height:100%;box-sizing:border-box;padding:0 8px;background:#fff;border:1px solid #e5e5e5}' TO html.
  APPEND 'table{width:100%;height:100%;table-layout:fixed;border-spacing:6px 0}' TO html.
  APPEND 'td{text-align:center;vertical-align:middle}' TO html.
  APPEND 'a.c{display:block;text-decoration:none;color:#607ca2;border:1px solid #d6e0ee;' TO html.
  APPEND 'border-radius:8px;padding:8px 2px}a.c:hover{border-color:#1684bf;background:#f3f9ff}' TO html.
  APPEND 'a.on{border:2px solid #1684bf;background:#edf6ff;padding:7px 1px}' TO html.
  APPEND '.v{font-size:22px;font-weight:bold;color:#243b53;padding-top:3px}' TO html.
  APPEND '.d{display:inline-block;width:8px;height:8px;border-radius:4px;margin-right:4px}' TO html.
  APPEND '.g{background:#2e9d4f}.y{background:#e3b100}.r{background:#d34343}.n{background:#9aa9bb}' TO html.
  APPEND '.t{font-size:11px;color:#8090a0;padding:6px 6px 0}</style></head><body><div class="p"><table><tr>' TO html.
  PERFORM card_cell USING 'ALL' active 'n' '&#51204;&#52404;' n1 CHANGING html.
  PERFORM card_cell USING 'WAIT' active 'y' '&#48156;&#51452;&#45824;&#44592;' n2 CHANGING html.
  PERFORM card_cell USING 'DONE' active 'g' '&#48156;&#51452;&#50756;&#47308;' n3 CHANGING html.
  PERFORM card_cell USING 'VOID' active 'r' '&#52712;&#49548;' n4 CHANGING html.
  APPEND '</tr></table></div></body></html>' TO html.
  go_summary->load_data(
    EXPORTING type = 'text' subtype = 'html'
    IMPORTING assigned_url = url
    CHANGING data_table = html
    EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  go_summary->show_url( EXPORTING url = url in_place = abap_true
    EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    gv_summary_stamp = stamp.
  ENDIF.
ENDFORM.

" 서브스크린 입력을 먼저 받은 PAI에서만 상태조건을 바꾸고 재조회한다.
FORM apply_summary.
  CASE gv_summary_action.
    WHEN 'ALL'.
      p_state = 'A'.
    WHEN 'WAIT'.
      p_state = 'W'.
    WHEN 'DONE'.
      p_state = 'C'.
    WHEN 'VOID'.
      p_state = 'X'.
    WHEN OTHERS.
      CLEAR gv_summary_action.
      RETURN.
  ENDCASE.
  CLEAR gv_summary_action.
  " 카드는 마지막 조회 결과 안에서만 거른다(DB 재조회 없음). 조회조건 변경은 [조회]·Enter로 반영한다.
  PERFORM filter_list.
  gs_query_filter-state = p_state.
  IF go_list IS BOUND.
    go_list->set_selected_rows( it_index_rows = VALUE lvc_t_row( ) ).
  ENDIF.
ENDFORM.

CLASS lcl_summary_events IMPLEMENTATION.
  " on_click : 오른쪽 카드의 SAPEVENT를 받아 PAI(SCARD)를 일으킨다. 여기서는 조회하지 않는다.
  METHOD on_click.
    CASE action.
      WHEN 'ALL' OR 'WAIT' OR 'DONE' OR 'VOID'.
        gv_summary_action = action.
        DATA rc TYPE i.
        cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'SCARD'
          IMPORTING rc = rc ).
        IF rc <> cl_gui_cfw=>rc_posted.
          CLEAR gv_summary_action.
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

" ------------------------------------------------------------
" 보조 FORM
" ------------------------------------------------------------

" list_title : ALV 제목에 건수와 신호등 뜻을 함께 보여준다.
FORM list_title CHANGING cv_title TYPE lvc_title.
  cv_title = |구매요청 · { lines( gt_list ) }건|.   " 상태 글자가 신호등 옆 열에 있어 범례는 넣지 않음
ENDFORM.

" plant_name : 플랜트 코드로 지사명을 찾는다. 지사(z8branch_m) 이름이 하나면 그것, 아니면 플랜트명이다.
FORM plant_name USING iv_werks TYPE clike CHANGING ev_name TYPE clike.
  CLEAR ev_name.
  IF iv_werks IS INITIAL.
    RETURN.
  ENDIF.
  SELECT SINGLE bupla, name1 FROM z8plant_m WHERE werks = @iv_werks INTO @DATA(ls_plant).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  SELECT name FROM z8branch_m WHERE branch = @ls_plant-bupla INTO TABLE @DATA(lt_branches).
  IF lines( lt_branches ) = 1.
    ev_name = lt_branches[ 1 ]-name.
  ELSE.
    ev_name = ls_plant-name1.
  ENDIF.
ENDFORM.

" source_text : PR 요청구분 코드(SOURCE_TYPE)를 도메인 고정값 내역으로 바꾼다. DB 값은 그대로이다.
FORM source_text USING iv_type TYPE clike CHANGING ev_text TYPE clike.
  " 요청구분 = Z8MM_PR-SOURCE_TYPE. 화면 글자는 도메인 Z8D_SOURCE_TYPE 고정값 내역을 그대로 쓴다.
  ev_text = lcl_mm_f4=>domain_text( domain = 'Z8D_SOURCE_TYPE' value = iv_type ).
ENDFORM.

" fill_names : 조회조건 코드 칸 옆에 이름을 보여준다. 없는 코드는 '등록되지 않은 코드'.
FORM fill_names.
  DATA lv_mat TYPE z8material_txt_m-maktx.
  DATA lv_ven TYPE z8vendor_m-name1.
  CLEAR: gv_nplt, gv_nven, gv_nmat.
  IF p_bupla IS NOT INITIAL.
    DATA lv_brname TYPE z8branch_m-name.
    SELECT name FROM z8branch_m WHERE branch = @p_bupla INTO @lv_brname UP TO 1 ROWS.
    ENDSELECT.
    gv_nplt = lv_brname.
    IF gv_nplt IS INITIAL.
      gv_nplt = '등록되지 않은 코드'.
    ENDIF.
  ENDIF.
  IF p_lifnr IS NOT INITIAL.
    SELECT SINGLE name1 FROM z8vendor_m WHERE lifnr = @p_lifnr INTO @lv_ven.
    gv_nven = COND #( WHEN sy-subrc = 0 THEN lv_ven ELSE '등록되지 않은 코드' ).
  ENDIF.
  IF p_matnr IS NOT INITIAL.
    SELECT SINGLE maktx FROM z8material_txt_m WHERE matnr = @p_matnr AND spras = @sy-langu INTO @lv_mat.
    gv_nmat = COND #( WHEN sy-subrc = 0 THEN lv_mat ELSE '등록되지 않은 코드' ).
  ENDIF.
ENDFORM.

" card_cell : 카드 한 칸의 HTML을 만든다. 선택된 카드는 파란 테두리이다.
FORM card_cell USING iv_action TYPE clike iv_active TYPE clike iv_dot TYPE clike
                     iv_label TYPE clike iv_count TYPE i
               CHANGING ct_html TYPE STANDARD TABLE.
  DATA lv_class TYPE string.
  lv_class = 'c'.
  IF iv_action = iv_active.
    lv_class = 'c on'.
  ENDIF.
  DATA lv_line TYPE w3html.
  lv_line-line = |<td><a class="{ lv_class }" href="SAPEVENT:{ iv_action }"><span class="d { iv_dot }"></span>|.
  APPEND lv_line TO ct_html.
  lv_line-line = |{ iv_label }<div class="v">{ iv_count NUMBER = RAW }</div></a></td>|.
  APPEND lv_line TO ct_html.
ENDFORM.

" sort_only_toolbar : ALV 위쪽 버튼줄에서 정렬·찾기·필터만 남기고 나머지 버튼(엑셀·인쇄·레이아웃 등)을 숨기는 제외 목록을 만든다.
FORM sort_only_toolbar CHANGING et_excl TYPE ui_functions.
  " ALV 위쪽 버튼은 [오름차순 정렬]·[내림차순 정렬] 두 개만 남긴다.
  " 열 머리글을 한 번 눌러 열을 고른 뒤 정렬 버튼을 누르면 그 열 기준으로 정렬된다.
  et_excl = VALUE #(
    ( cl_gui_alv_grid=>mc_fc_detail ) ( cl_gui_alv_grid=>mc_fc_refresh ) ( cl_gui_alv_grid=>mc_fc_check )
    ( cl_gui_alv_grid=>mc_fc_loc_cut ) ( cl_gui_alv_grid=>mc_fc_loc_copy ) ( cl_gui_alv_grid=>mc_mb_paste )
    ( cl_gui_alv_grid=>mc_fc_loc_paste ) ( cl_gui_alv_grid=>mc_fc_loc_paste_new_row ) ( cl_gui_alv_grid=>mc_fc_loc_undo )
    ( cl_gui_alv_grid=>mc_fc_loc_append_row ) ( cl_gui_alv_grid=>mc_fc_loc_insert_row )
    ( cl_gui_alv_grid=>mc_fc_loc_delete_row ) ( cl_gui_alv_grid=>mc_fc_loc_copy_row )
    " 찾기·필터는 쓸 수 있는 기능이라 버튼줄에 남긴다(엑셀·인쇄·레이아웃 등만 숨김).
    ( cl_gui_alv_grid=>mc_mb_sum ) ( cl_gui_alv_grid=>mc_fc_sum ) ( cl_gui_alv_grid=>mc_fc_average )
    ( cl_gui_alv_grid=>mc_fc_maximum ) ( cl_gui_alv_grid=>mc_fc_minimum )
    ( cl_gui_alv_grid=>mc_mb_subtot ) ( cl_gui_alv_grid=>mc_fc_subtot )
    ( cl_gui_alv_grid=>mc_fc_print ) ( cl_gui_alv_grid=>mc_fc_print_back ) ( cl_gui_alv_grid=>mc_fc_print_prev )
    ( cl_gui_alv_grid=>mc_mb_export ) ( cl_gui_alv_grid=>mc_mb_view ) ( cl_gui_alv_grid=>mc_fc_views )
    ( cl_gui_alv_grid=>mc_mb_variant ) ( cl_gui_alv_grid=>mc_fc_current_variant )
    ( cl_gui_alv_grid=>mc_fc_load_variant ) ( cl_gui_alv_grid=>mc_fc_save_variant )
    ( cl_gui_alv_grid=>mc_fc_maintain_variant )
    ( cl_gui_alv_grid=>mc_fc_graph ) ( cl_gui_alv_grid=>mc_fc_info ) ).
ENDFORM.
