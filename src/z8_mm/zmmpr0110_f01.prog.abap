*&---------------------------------------------------------------------*
*& Include ZMMPR0110_F01
*&---------------------------------------------------------------------*
*& 업무 처리 FORM - 자동 입력·입력 확인·저장·행 추가/삭제·STO 연결
*&   신호등은 1구 LED, 줄 색은 방금 저장한 행(파란 줄)만, 처리 결과는 하단 상태줄에 표시한다.
*& 담당: MM(이규빈) / 프로그램: ZMMPR0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 구매지사 기준 PR 신규 입력·변경·삭제 (개발 10/01~10/06)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 입력 화면 개편(신호등·입력 열 색), 공급업체·희망납기일 자동 채움
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 저장·삭제 메시지 정리, ALV 행 버튼 제거, PR 변경은 수량·희망납기일만
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" column : 입력 ALV 열 하나를 필드카탈로그에 추가한다. 입력 열(edit)은 연노랑, 열별 폭은 CASE에서 조정.
FORM column USING name TYPE clike title TYPE clike edit TYPE abap_bool CHANGING catalog TYPE lvc_t_fcat.
  DATA fc TYPE lvc_s_fcat.
  fc = VALUE #( fieldname = name coltext = title scrtext_l = title scrtext_m = title scrtext_s = title
    outputlen = 10 edit = edit ).
  " 직접 입력 열은 연노랑으로 구분한다. (자동 표시 열은 기본 색)
  IF edit = abap_true.
    fc-emphasize = 'C300'.
  ENDIF.
  CASE name.
    WHEN 'ICON'.
      fc-icon = abap_true.
      fc-just = 'C'.
      fc-outputlen = 4.
      fc-fix_column = abap_true.
    WHEN 'MATNR'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'MATNR'.
      fc-f4availabl = edit.
      fc-outputlen = 12.
      fc-fix_column = abap_true.
    WHEN 'LIFNR'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'LIFNR'.
      fc-f4availabl = edit.
      fc-outputlen = 11.
    WHEN 'MENGE'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'MENGE'.
      fc-qfieldname = 'MEINS'.
      fc-decimals_o = 0.
      fc-outputlen = 9.
    WHEN 'MEINS'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'MEINS'.
      fc-outputlen = 4.
    WHEN 'PREIS'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'PREIS'.
      fc-cfieldname = 'WAERS'.
      fc-outputlen = 11.
    WHEN 'LFDAT'.
      fc-ref_table = 'Z8MM_PR'.
      fc-ref_field = 'LFDAT'.
      fc-outputlen = 10.
    WHEN 'MAKTX'.
      fc-outputlen = 18.
    WHEN 'VENDOR_NAME'.
      fc-outputlen = 14.
    WHEN 'DETAIL'.
      fc-outputlen = 48.               " STO 안내가 한 줄에 보이는 폭
    WHEN 'BANFN' OR 'EBELN'.
      fc-outputlen = 10.
    WHEN 'WAERS'.
      fc-outputlen = 4.
    WHEN 'RESULT'.
      fc-outputlen = 9.
      fc-fix_column = abap_true.        " 신호등 옆 고정(상태·자재번호와 함께)
  ENDCASE.
  APPEND fc TO catalog.
ENDFORM.

" reset_entry : 신규 입력을 처음 상태로 만든다(빈 행 1줄, 기본 납기일 = 오늘+3영업일).
FORM reset_entry.
  CLEAR: gt_entry, gs_original, gv_posted.
  gv_mode = 'N'.
  IF n_werks IS INITIAL.
    n_werks = p_werks.
    PERFORM plant_branch.
  ENDIF.
  n_lgort = '0001'.
  " 기본 납기일: 비어 있으면 오늘+3영업일.
  " 빈 행은 1줄만, 날짜도 비워 둔다(빈 줄에 날짜가 찍혀 있으면 입력된 행처럼 보여서).
  "   자재를 넣는 순간 기본 납기일이 자동으로 들어간다. 행 추가는 [자재추가]로 한다.
  " 처음 상태 = 기본 납기일도 오늘+3영업일로 되돌린다([초기화] 포함).
  PERFORM default_due CHANGING n_lfdat.
  gv_prev_lfdat = n_lfdat.
  gv_display_werks = n_werks.          " 시작 지사 기억(지사 변경 안내 기준)
  DO gc_blank_rows TIMES.
    APPEND INITIAL LINE TO gt_entry.
  ENDDO.
ENDFORM.

" load_change : DB에서 PR을 다시 읽고 변경 가능 여부를 검사한다.
FORM load_change CHANGING loaded TYPE abap_bool.
  loaded = abap_false.
  CLEAR gs_original.
  IF p_pr IS INITIAL OR p_item IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH 'PR 번호·품목번호'.   " &1를 입력해주세요
    RETURN.
  ENDIF.
  " 호출한 목록의 값이 아니라 현재 DB 값으로 읽는다.
  SELECT SINGLE * FROM z8mm_pr WHERE banfn = @p_pr AND bnfpo = @p_item INTO @gs_original.
  IF sy-subrc <> 0.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.   " 조회 조건에 해당하는 데이터가 없습니다
    RETURN.
  ENDIF.
  IF gs_original-ebeln IS NOT INITIAL OR gs_original-loekz IS NOT INITIAL.
    DATA(lv_done_pr) = |{ gs_original-banfn ALPHA = OUT }|.
    MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH lv_done_pr.   " &1번은 이미 처리 완료된 품목입니다(발주대기 PR만 변경)
    RETURN.
  ENDIF.
  IF gs_original-kdauf IS NOT INITIAL OR gs_original-kdpos IS NOT INITIAL OR gs_original-proc_seq IS NOT INITIAL.
    MESSAGE s022(z8_msg) DISPLAY LIKE 'E'.   " 데이터를 불러올 수 없습니다(SO 연계 PR은 이 화면에서 처리하지 않음)
    RETURN.
  ENDIF.
  CLEAR: gt_entry, gv_posted.
  gv_mode = 'C'.
  n_werks = gs_original-werks.
  PERFORM plant_branch.                " 화면에는 그 PR 플랜트의 구매지사
  n_lgort = gs_original-lgort.
  n_lfdat = gs_original-lfdat.
  gv_prev_lfdat = n_lfdat.
  DATA(row) = CORRESPONDING ty_entry( gs_original ).
  row-cellstyle = VALUE #( ( fieldname = 'MATNR' style = cl_gui_alv_grid=>mc_style_disabled ) ).
  PERFORM enrich_row CHANGING row.
  APPEND row TO gt_entry.
  loaded = abap_true.
ENDFORM.

" display_entry : PBO. 입력 ALV를 처음 한 번 만들고 F4·변경·링크 클릭 이벤트를 연결한다.
FORM display_entry.
  PERFORM site_text.
  PERFORM sync_site.
  IF go_entry IS BOUND.
    RETURN.
  ENDIF.
  PERFORM refresh_status.
  CREATE OBJECT go_entryc EXPORTING container_name = 'CC_ITEMS'.
  CREATE OBJECT go_entry EXPORTING i_parent = go_entryc.
  SET HANDLER go_events->entry_f4 go_events->entry_changed go_events->entry_finished
    go_events->entry_hotspot FOR go_entry.
  DATA catalog TYPE lvc_t_fcat.
  " 열 순서: 입력 열(노랑) → 결과(PR 번호) → 참고(예상단가) → 처리 안내. 한 화면에 결과까지 보이게 한다.
  PERFORM column USING 'ICON' `상태` abap_false CHANGING catalog.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM column USING 'RESULT' `처리결과` abap_false CHANGING catalog.
  " PR 변경은 수량·희망납기일만 바꾼다. 자재·공급업체는 신규 생성에서만 입력(노란색)한다.
  DATA(lv_new) = xsdbool( gv_mode = 'N' ).
  PERFORM column USING 'MATNR' `자재번호` lv_new CHANGING catalog.
  PERFORM column USING 'MAKTX' `자재명` abap_false CHANGING catalog.
  PERFORM column USING 'MENGE' `요청수량` abap_true CHANGING catalog.
  PERFORM column USING 'MEINS' `단위` abap_false CHANGING catalog.
  PERFORM column USING 'LIFNR' `공급업체` lv_new CHANGING catalog.
  PERFORM column USING 'VENDOR_NAME' `업체명` abap_false CHANGING catalog.
  PERFORM column USING 'LFDAT' `희망납기일` abap_true CHANGING catalog.
  PERFORM column USING 'BANFN' `PR 번호` abap_false CHANGING catalog.
  " 화면 이름 '예상단가'(값은 회사 평가단가 Z8MATERIAL_VAL_M, PO 단계에서 업체 구매단가로 확정)
  PERFORM column USING 'PREIS' `예상단가` abap_false CHANGING catalog.
  PERFORM column USING 'WAERS' `통화` abap_false CHANGING catalog.
  " 처리 안내는 맨 오른쪽(SAP에서 직접 옮긴 순서 반영)
  PERFORM column USING 'DETAIL' `처리 안내` abap_false CHANGING catalog.
  DATA exclude TYPE ui_functions.
  PERFORM sort_only_toolbar CHANGING exclude.
  PERFORM quantity_catalog USING gt_entry CHANGING catalog.
  go_entry->set_table_for_first_display(
    EXPORTING is_layout = VALUE lvc_s_layo( zebra = abap_true cwidth_opt = abap_false sel_mode = 'D' no_toolbar = abap_false info_fname = 'ROWCLR' stylefname = 'CELLSTYLE'
        smalltitle = abap_true grid_title = COND #( WHEN gv_mode = 'N'
          THEN '희망납기일 기본값: 오늘 + 3영업일(주말·공휴일 제외)'
          ELSE '수량과 희망납기일만 변경할 수 있습니다 (자재·공급업체는 변경 불가)' ) )
    it_toolbar_excluding = exclude
    CHANGING it_outtab = gt_entry it_fieldcatalog = catalog ).
  DATA f4 TYPE lvc_t_f4.
  f4 = VALUE #( ( fieldname = 'MATNR' register = abap_true getbefore = abap_true chngeafter = abap_true )
    ( fieldname = 'LIFNR' register = abap_true getbefore = abap_true chngeafter = abap_true ) ).
  go_entry->register_f4_for_fields( it_f4 = f4 ).
  go_entry->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
  go_entry->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
  go_entry->set_ready_for_input( i_ready_for_input = 1 ).
ENDFORM.

" refresh_entry : 신호등·줄색을 다시 정하고 입력 ALV를 새로 그린다(커서·스크롤 유지).
FORM refresh_entry.
  PERFORM refresh_status.
  IF go_entry IS BOUND.
    DATA catalog TYPE lvc_t_fcat.
    go_entry->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = catalog ).
    PERFORM quantity_catalog USING gt_entry CHANGING catalog.
    go_entry->set_frontend_fieldcatalog( it_fieldcatalog = catalog ).
    go_entry->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  ENDIF.
ENDFORM.

" preview_one : 저장 전 한 행 검사(자재·수량·납기·업체·재고위치·평가단가·구매정보). 문제가 있으면 lcx_mm.
"   DB에 쓰지 않는다. 저장(save_rows)도 이 검사를 다시 거친 뒤 저장한다.
FORM preview_one CHANGING row TYPE ty_entry RAISING lcx_mm.
  " 희망납기일을 비워 두면 기본 납기일(비어 있으면 오늘+3영업일)로 저장한다.
  IF row-lfdat IS INITIAL.
    IF n_lfdat IS INITIAL.
      PERFORM default_due CHANGING n_lfdat.
    ENDIF.
    row-lfdat = n_lfdat.
  ENDIF.
  PERFORM enrich_row CHANGING row.
  " 처리 안내는 한 가지 사유만 짧게 보여준다.
  IF row-detail IS NOT INITIAL.
    lcl_mm_common=>fail( CONV string( row-detail ) ).
  ELSEIF row-matnr IS INITIAL.
    lcl_mm_common=>fail( `자재번호를 입력하세요.` ).
  ELSEIF row-menge <= 0.
    lcl_mm_common=>fail( `요청수량을 입력하세요.` ).
  ELSEIF row-lfdat < sy-datum.
    lcl_mm_common=>fail( `희망납기일이 오늘보다 이전입니다.` ).
  ELSEIF row-lifnr IS INITIAL.
    " 공급업체 없는 PR은 PO로 만들 수 없으므로 저장 전에 막는다.
    lcl_mm_common=>fail( `공급업체를 지정하세요. 공급업체 칸 F4에서 단가를 보고 고를 수 있습니다.` ).
  ENDIF.
  DATA(key) = VALUE lcl_mm_common=>ty_key( matnr = row-matnr werks = n_werks lgort = n_lgort ).
  DATA(stock) = lcl_mm_stock=>location( key ).
  DATA(val) = lcl_mm_stock=>valuation( key ).
  row-meins = stock-meins.
  IF val-meins <> stock-meins.
    lcl_mm_common=>fail( `평가정보 단위가 자재 단위와 다릅니다.` ).
  ENDIF.
  IF val-vprsv = 'S'.
    row-preis = val-stprs / val-peinh.
  ELSE.
    row-preis = val-verpr / val-peinh.
  ENDIF.
  row-waers = val-waers.
  IF gv_mode = 'C'.
    row-preis = gs_original-preis.
    row-waers = gs_original-waers.
  ENDIF.
  IF row-lifnr IS NOT INITIAL.
    SELECT SINGLE lifnr FROM z8vendor_m WHERE lifnr = @row-lifnr INTO @DATA(vendor).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `등록되지 않은 공급업체입니다.` ).
    ENDIF.
    DATA(info) = lcl_mm_stock=>price( material = row-matnr vendor = row-lifnr ).
    IF info-meins <> row-meins.
      lcl_mm_common=>fail( `업체 구매단위가 자재 단위와 다릅니다.` ).
    ENDIF.
  ENDIF.
ENDFORM.

" preview_rows : [입력 확인]. 미저장 행 전체를 검사해 처리결과·처리 안내를 채운다. DB 변경 없음.
FORM preview_rows.
  IF n_werks IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '구매지사'.   " &1를 입력해주세요
    gv_focus_site = abap_true.          " 커서를 구매지사 칸으로(E01 AT SELECTION-SCREEN OUTPUT)
    RETURN.
  ENDIF.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<row>).
    IF ( gv_mode = 'N' AND <row>-banfn IS NOT INITIAL ) OR ( gv_mode = 'C' AND gv_posted = abap_true ).
      CONTINUE.
    ENDIF.
    IF <row>-matnr IS INITIAL AND <row>-menge = 0 AND <row>-lifnr IS INITIAL.
      CONTINUE.
    ENDIF.
    TRY.
      PERFORM preview_one CHANGING <row>.

      <row>-result = '저장 가능'.
      CLEAR <row>-detail.
      PERFORM early_hint CHANGING <row>.     " 표준 납기일(오늘+3영업일)보다 빠르면 안내(저장은 가능)
      PERFORM moq_hint CHANGING <row>.       " 업체 최소발주량 미만이면 안내(저장은 가능)
    " 검사/저장 중 fail로 전달된 업무 오류를 여기서 받아 해당 행에 표시한다.
    CATCH lcx_mm INTO DATA(error).

      <row>-result = '확인 필요'.
      PERFORM short_reason USING error->detail CHANGING <row>-detail.
    CATCH cx_root INTO DATA(unexpected).

      <row>-result = '확인 필요'.
      <row>-detail = unexpected->get_text( ).
    ENDTRY.
  ENDLOOP.
  DATA lv_bad TYPE i.
  LOOP AT gt_entry TRANSPORTING NO FIELDS WHERE result = '확인 필요'.
    lv_bad = lv_bad + 1.
  ENDLOOP.
  " 확인 필요 행이 있으면 경고한다. 정상 행은 신호등·처리 결과('저장 가능')로 보여준다.
  IF lv_bad > 0.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'W' WITH '정확한 데이터'.   " 정확한 데이터를 입력해주세요
  ENDIF.
  PERFORM refresh_entry.
ENDFORM.

" save_rows : [전체 저장]. 행마다 검사 → 잠금 → PR 생성(채번 Z8MMPRN)/변경 → COMMIT → 잠금해제.
"   한 행이 실패해도 앞서 저장된 행은 유지되고(행 단위 COMMIT), 실패 행에 사유를 남긴다.
FORM save_rows.
  " 저장 전에 화면의 구매지사와 저장할 입고플랜트를 다시 맞춘다.
  "   아직 저장한 PR이 없으면 화면 지사 기준으로 플랜트를 다시 구하고,
  "   이미 저장했으면(지사 잠김) 플랜트 기준으로 지사 칸을 되돌린다.
  IF gv_mode = 'N' AND gv_posted = abap_false.
    PERFORM branch_plant.
  ELSE.
    PERFORM plant_branch.
  ENDIF.
  IF n_werks IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '구매지사'.   " &1를 입력해주세요
    gv_focus_site = abap_true.          " 커서를 구매지사 칸으로(E01 AT SELECTION-SCREEN OUTPUT)
    RETURN.
  ENDIF.
  IF gv_mode = 'C' AND gv_posted = abap_true.
    MESSAGE s039(z8_msg).   " 변경 완료되었습니다(이미 저장한 변경)
    RETURN.
  ENDIF.
  " 아직 입력 중인 행(자재만 / 수량만)이 있으면 저장하지 않고 무엇을 넣어야 하는지 알려준다.
  "   이 경우 행을 '저장 실패'(빨강)로 바꾸지 않는다(STO 생성과 같은 방식).
  LOOP AT gt_entry INTO DATA(ls_part) WHERE banfn IS INITIAL
    AND ( ( matnr IS NOT INITIAL AND menge <= 0 ) OR ( matnr IS INITIAL AND menge > 0 ) ).
    IF ls_part-matnr IS INITIAL.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '자재번호'.   " 자재번호를 입력해주세요
    ELSE.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '요청수량'.   " 요청수량을 입력해주세요
    ENDIF.
    RETURN.
  ENDLOOP.
  DATA failed TYPE i.
  DATA lv_fail_detail TYPE string.          " 첫 번째 실패 행의 처리 안내(상태줄 메시지용)
  DATA lt_saved TYPE string_table.          " 이번에 저장한 PR 번호(완료 메시지용)
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<row>).
    IF gv_mode = 'N' AND <row>-banfn IS NOT INITIAL.
      CONTINUE.
    ENDIF.
    IF <row>-matnr IS INITIAL AND <row>-menge = 0 AND <row>-lifnr IS INITIAL.
      CONTINUE.
    ENDIF.
    TRY.
      PERFORM preview_one CHANGING <row>.
      " 저장 직전에 잠금을 확보한다. 성공·실패 모두 unlock으로 해제해야 한다.
      lcl_mm_common=>lock_doc( ).          " 재고 잠금 없이 문서 잠금만(재고 처리 중에도 저장 가능)
      IF gv_mode = 'N'.
        DATA(request) = VALUE z8mm_pr( matnr = <row>-matnr menge = <row>-menge
          werks = n_werks lgort = n_lgort lifnr = <row>-lifnr lfdat = <row>-lfdat ).
        DATA(created) = lcl_mm_purchase=>create_pr( request ).
        " 이 행/문서의 DB 변경을 확정한다. 이전에 성공한 건은 다음 건 오류로 취소되지 않는다.
        COMMIT WORK AND WAIT.
        lcl_mm_common=>unlock( ).
        <row>-banfn = created-banfn.
        <row>-meins = created-meins.
        <row>-preis = created-preis.
        <row>-waers = created-waers.
        <row>-result = '생성 완료'.
        APPEND CONV string( created-banfn ) TO lt_saved.
      ELSE.
        lcl_mm_purchase=>change_pr( original = gs_original quantity = <row>-menge
          vendor = <row>-lifnr requested_date = <row>-lfdat ).
        COMMIT WORK AND WAIT.
        lcl_mm_common=>unlock( ).
        <row>-result = '변경 완료'.
        APPEND CONV string( gs_original-banfn ) TO lt_saved.
      ENDIF.

      CLEAR <row>-detail.
      <row>-cellstyle = VALUE #( ( fieldname = 'LFDAT' style = cl_gui_alv_grid=>mc_style_disabled )
        ( fieldname = 'LIFNR' style = cl_gui_alv_grid=>mc_style_disabled )
        ( fieldname = 'MATNR' style = cl_gui_alv_grid=>mc_style_disabled )
        ( fieldname = 'MENGE' style = cl_gui_alv_grid=>mc_style_disabled ) ).
      gv_posted = abap_true.
    " 검사/저장 중 fail로 전달된 업무 오류를 여기서 받아 해당 행에 표시한다.
    CATCH lcx_mm INTO DATA(error).
      " 현재 미확정 DB 변경을 되돌린다. 번호범위에서 받은 번호는 건너뛸 수 있다.
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      failed = failed + 1.

      <row>-result = '저장 실패'.
      PERFORM short_reason USING error->detail CHANGING <row>-detail.
    CATCH cx_root INTO DATA(unexpected).
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      failed = failed + 1.

      <row>-result = '저장 실패'.
      <row>-detail = unexpected->get_text( ).
    ENDTRY.
    " 첫 번째 실패 사유를 기억한다(아래 상태줄 메시지용).
    IF <row>-result = '저장 실패' AND lv_fail_detail IS INITIAL.
      lv_fail_detail = <row>-detail.
    ENDIF.
  ENDLOOP.
  " 저장한 PR이 있으면 먼저 완료 팝업(I 133)을 띄운다. 일부만 실패해도 저장된 건은 알려준다.
  IF lt_saved IS NOT INITIAL.
    DATA(lv_saved_txt) = lcl_mm_f4=>doc_text( lt_saved ).
    DATA(lv_saved_act) = COND string( WHEN gv_mode = 'C' THEN `변경` ELSE `생성` ).
    MESSAGE i133(z8_msg) WITH lv_saved_txt lv_saved_act.   " &1 &2 완료 (저장 완료는 팝업 I)
  ENDIF.
  " 실패 행이 있으면 첫 실패 사유를 상태줄에 알려준다(처리 안내와 같은 뜻).
  IF failed > 0.
    IF lv_fail_detail CS '희망납기일'.
      MESSAGE s145(z8_msg) DISPLAY LIKE 'E' WITH '희망납기일을 오늘 이후로'.   " &1 입력해주세요
    ELSEIF lv_fail_detail CS '공급업체'.
      MESSAGE s145(z8_msg) DISPLAY LIKE 'E' WITH '등록된 공급업체를'.         " &1 입력해주세요
    ELSE.
      DATA(lv_fail_txt) = |PR { failed }건 저장|.                          " → PR 1건 저장에 실패했다
      MESSAGE s139(z8_msg) DISPLAY LIKE 'E' WITH lv_fail_txt.               " &1에 실패했습니다
    ENDIF.
  ELSEIF lt_saved IS INITIAL.
    " 저장할 행이 하나도 없다(빈 행만 있음).
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '자재번호'.   " 자재번호를 입력해주세요
  ENDIF.
  PERFORM refresh_entry.
ENDFORM.

" leave_entry : 화면을 나가기 전에 입력 ALV 컨트롤을 정리한다.
FORM leave_entry.
  IF go_entry IS BOUND.
    go_entry->free( ).
    FREE go_entry.
  ENDIF.
  IF go_entryc IS BOUND.
    go_entryc->free( ).
    FREE go_entryc.
  ENDIF.
ENDFORM.

" screen_help : F4. 칸에 글자 일부(예: CAB, 케이블, P2)가 있으면 그 글자로 걸러서 보여준다.
" 1건뿐이면 목록 없이 바로 넣고, 고른 뒤 조회를 다시 한다. (공통: Z8MM_F4_C01)
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
      EXPORTING functioncode = 'QCHG'
      EXCEPTIONS function_not_supported = 1 OTHERS = 2.
  ENDIF.
ENDFORM.
" new_input : [새로 입력/초기화]. 저장 안 된 입력이 있으면 확인 후 입력 화면을 처음 상태로 돌린다.
FORM new_input.
  DATA has_pending TYPE abap_bool.
  LOOP AT gt_entry INTO DATA(pending_row).
    IF ( gv_mode = 'N' AND pending_row-banfn IS INITIAL
         AND ( pending_row-matnr IS NOT INITIAL OR pending_row-menge <> 0 OR pending_row-lifnr IS NOT INITIAL ) )
       OR ( gv_mode = 'C' AND gv_posted = abap_false ).
      has_pending = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.
  IF has_pending = abap_true.
    DATA question TYPE c LENGTH 120.
    IF gv_mode = 'C'.
      question = '변경 입력을 버리고 처음 상태로 돌릴까요? (저장된 PR은 그대로입니다)'.
    ELSE.
      question = '저장하지 않은 입력을 지우고 처음 상태로 돌릴까요? (저장된 PR은 그대로입니다)'.
    ENDIF.
    DATA answer TYPE c LENGTH 1.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING titlebar = '초기화'
        text_question = question
        text_button_1 = '초기화' text_button_2 = '계속 작성'
        default_button = '2' display_cancel_button = space
      IMPORTING answer = answer EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0 OR answer <> '1'.
      RETURN.
    ENDIF.
  ENDIF.
  PERFORM reset_entry.
  PERFORM refresh_entry.
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

" 설명 표시 전용: 수량/필요일이 비어 있어도 자재명과 업체명은 표시한다.
" DB 저장/채번/재고 변경은 수행하지 않는다.
FORM enrich_row CHANGING row TYPE ty_entry.
  CLEAR: row-maktx, row-meins, row-vendor_name, row-preis, row-waers,
         row-result, row-detail.
  IF row-lifnr IS NOT INITIAL.
    SELECT SINGLE name1 FROM z8vendor_m WHERE lifnr = @row-lifnr INTO @row-vendor_name.
    IF sy-subrc <> 0.
      row-detail = '등록되지 않은 공급업체입니다.'.
    ENDIF.
  ENDIF.
  IF row-matnr IS NOT INITIAL.
    SELECT SINGLE meins FROM z8material_m WHERE matnr = @row-matnr INTO @row-meins.
    IF sy-subrc <> 0.
      " 자재가 틀리면 업체 사유보다 자재 사유를 먼저 보여준다(한 가지만).
      row-detail = '등록되지 않은 자재번호입니다.'.
    ELSE.
      SELECT SINGLE maktx FROM z8material_txt_m
        WHERE matnr = @row-matnr AND spras = @sy-langu INTO @row-maktx.
      IF sy-subrc <> 0.
        SELECT SINGLE maktx FROM z8material_txt_m
          WHERE matnr = @row-matnr AND spras = '3' INTO @row-maktx.
      ENDIF.
      IF gv_mode = 'C'.
        row-preis = gs_original-preis.
        row-waers = gs_original-waers.
      ELSEIF n_werks IS NOT INITIAL.
        TRY.
          DATA(val) = lcl_mm_stock=>valuation(
            VALUE #( matnr = row-matnr werks = n_werks lgort = n_lgort ) ).
          IF val-meins <> row-meins.
            lcl_mm_common=>fail( `평가정보 단위가 자재 단위와 다릅니다.` ).
          ENDIF.
          IF val-vprsv = 'S'.
            row-preis = val-stprs / val-peinh.
          ELSE.
            row-preis = val-verpr / val-peinh.
          ENDIF.
          row-waers = val-waers.
        CATCH lcx_mm INTO DATA(error).
          IF row-detail IS INITIAL.
            PERFORM short_reason USING error->detail CHANGING row-detail.
          ENDIF.
        CATCH cx_root INTO DATA(unexpected).
          row-detail = unexpected->get_text( ).
        ENDTRY.
      ENDIF.
    ENDIF.
  ENDIF.
  IF row-detail IS NOT INITIAL.
    row-result = '확인 필요'.
  ENDIF.
ENDFORM.

" 저장할 코드는 WERKS 그대로 유지하고 실제 마스터의 이름을 출력한다.
FORM site_text.
  CLEAR gv_sname.
  " 구매지사 옆에 지사명만 보여준다(예: 경기남부지사). 입고플랜트(P100)는 화면에 보이지 않고 저장에만 쓴다.
  IF n_bupla IS INITIAL.
    RETURN.
  ENDIF.
  DATA lv_branch_name TYPE z8branch_m-name.
  SELECT name FROM z8branch_m WHERE branch = @n_bupla INTO @lv_branch_name UP TO 1 ROWS.
  ENDSELECT.
  IF sy-subrc <> 0.
    gv_sname = '등록되지 않은 코드'.
  ELSEIF n_werks IS INITIAL.
    gv_sname = |{ lv_branch_name } · 입고플랜트 없음|.
  ELSE.
    gv_sname = lv_branch_name.
  ENDIF.
ENDFORM.

" 체크박스 없이 왼쪽 행 머리글로 선택한다. 정렬/필터 후에도 원본 행 ID 사용.
FORM delete_rows.
  DATA: row_ids  TYPE lvc_t_roid,
        deleted  TYPE i,
        blank    TYPE i,                    " 아무것도 입력하지 않은 빈 행
        saved    TYPE i,
        saved_pr TYPE string.               " 제외한 첫 PR 번호(메시지용)

  go_entry->get_selected_rows( IMPORTING et_row_no = row_ids ).
  IF row_ids IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.

  " 화면에 빈 행만 있고 그 빈 행을 골랐으면 지우지 않는다(지워도 빈 행 1줄이 다시 생기므로).
  DATA lv_has_input TYPE abap_bool.
  LOOP AT gt_entry INTO DATA(any_row)
    WHERE banfn IS NOT INITIAL OR matnr IS NOT INITIAL OR menge <> 0 OR lifnr IS NOT INITIAL.
    lv_has_input = abap_true.
    EXIT.
  ENDLOOP.
  IF lv_has_input = abap_false.
    MESSAGE s214(z8_msg) DISPLAY LIKE 'E' WITH '삭제할 입력'.   " &1 데이터가 없습니다.
    RETURN.
  ENDIF.

  " 아래 행부터 삭제해야 다른 선택행의 번호가 밀리지 않는다.
  SORT row_ids BY row_id DESCENDING.
  LOOP AT row_ids INTO DATA(selected).
    READ TABLE gt_entry INDEX selected-row_id INTO DATA(row).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    " 저장 완료 PR은 입력행 삭제 대상에서 제외한다(취소는 PR 목록 ZMMPR0100에서).
    IF row-banfn IS NOT INITIAL.
      saved = saved + 1.
      saved_pr = |{ row-banfn ALPHA = OUT }|.   " 아래 행부터 돌므로 마지막 값 = 화면 위쪽 첫 PR
      CONTINUE.
    ENDIF.
    IF row-matnr IS INITIAL AND row-menge = 0 AND row-lifnr IS INITIAL.
      blank = blank + 1.                    " 빈 행은 지우되 '입력행 N건'에는 세지 않는다
    ELSE.
      deleted = deleted + 1.
    ENDIF.
    DELETE gt_entry INDEX selected-row_id.
  ENDLOOP.

  PERFORM ensure_blank_row.

  " 상황별 메시지(Z8_MSG)
  "   삭제 + 제외 : 입력행 2건(생성된 PR 1건 제외) 삭제 완료
  "   삭제만      : 입력행 2건 삭제 완료
  "   빈 행만     : 빈 행 2건 삭제 완료
  "   제외만      : PR00000300번은 이미 처리 완료된 품목이다.
  IF deleted > 0 AND saved > 0.
    MESSAGE s133(z8_msg) WITH |입력행 { deleted }건(생성된 PR { saved }건 제외)| '삭제'.   " &1 &2 완료
  ELSEIF deleted > 0.
    MESSAGE s133(z8_msg) WITH |입력행 { deleted }건| '삭제'.   " &1 &2 완료
  ELSEIF blank > 0 AND saved = 0.
    MESSAGE s133(z8_msg) WITH |빈 행 { blank }건| '삭제'.      " &1 &2 완료
  ELSEIF saved > 0.
    MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH saved_pr.   " &1번은 이미 처리 완료된 품목입니다.
  ELSE.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
  ENDIF.

  PERFORM refresh_entry.
ENDFORM.

" refresh_status : 모든 입력행의 상태 아이콘과 행 색을 현재 처리결과에 맞춘다. 화면 표시용이며 DB는 건드리지 않는다.
FORM refresh_status.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<status_row>).
    PERFORM set_status CHANGING <status_row>.
  ENDLOOP.
ENDFORM.

" set_status : 처리결과 문구 → 아이콘/행 색. 입력은 했지만 아직 검사 전이면 노랑이다.
FORM set_status CHANGING row TYPE ty_entry.
  CLEAR: row-icon, row-rowclr.
  " STO 안내가 있는 행만 '처리 안내' 칸을 링크(핫스팟)로 보여준다.
  DELETE row-cellstyle WHERE fieldname = 'DETAIL'.
  "   희망납기일이 오늘보다 이전이면 STO로 갈 수 없으므로 링크를 보이지 않는다.
  IF row-sto_from IS NOT INITIAL AND row-banfn IS INITIAL AND row-lfdat >= sy-datum.
    INSERT VALUE #( fieldname = 'DETAIL' style = cl_gui_alv_grid=>mc_style_hotspot ) INTO TABLE row-cellstyle.
  ENDIF.
  CASE row-result.
    WHEN '저장 가능'.
      row-icon = icon_led_green.
    WHEN '확인 필요' OR '저장 실패'.
      row-icon = icon_led_red.
    WHEN '생성 완료' OR '변경 완료'.
      " 저장한 행: 초록 LED + 파란 줄.
      row-icon = icon_led_green.
      row-rowclr = 'C410'.
    WHEN OTHERS.
      IF row-matnr IS NOT INITIAL OR row-menge <> 0 OR row-lifnr IS NOT INITIAL.
        row-icon = icon_led_yellow.
      ENDIF.
  ENDCASE.
ENDFORM.

" update_summary : 상단 요약 한 줄(입력/저장가능/확인필요/완료/총수량). 표시 전용이다.
" 단위가 섞이면 수량을 합치지 않고 안내만 표시한다.
FORM update_summary.
  DATA: n_in TYPE i, n_ok TYPE i, n_er TYPE i, n_dn TYPE i,
        qty TYPE z8mm_pr-menge, unit TYPE z8mm_pr-meins,
        mixed TYPE abap_bool, unknown TYPE abap_bool.
  LOOP AT gt_entry INTO DATA(sum_row).
    IF sum_row-matnr IS INITIAL AND sum_row-menge = 0 AND sum_row-lifnr IS INITIAL.
      CONTINUE.
    ENDIF.
    n_in = n_in + 1.
    CASE sum_row-result.
      WHEN '저장 가능'.
        n_ok = n_ok + 1.
      WHEN '확인 필요' OR '저장 실패'.
        n_er = n_er + 1.
      WHEN '생성 완료' OR '변경 완료'.
        n_dn = n_dn + 1.
    ENDCASE.
    qty = qty + sum_row-menge.
    IF sum_row-menge <> 0 AND sum_row-meins IS INITIAL.
      unknown = abap_true.
    ENDIF.
    IF sum_row-meins IS NOT INITIAL.
      IF unit IS INITIAL.
        unit = sum_row-meins.
      ELSEIF unit <> sum_row-meins.
        mixed = abap_true.
      ENDIF.
    ENDIF.
  ENDLOOP.
  DATA lv_qt TYPE string.
  IF unknown = abap_true.
    lv_qt = '총수량: 단위 확인'.
  ELSEIF mixed = abap_true.
    lv_qt = '총수량: 단위 혼합'.
  ELSE.
    DATA lv_qty_sum TYPE string.
    PERFORM qty_text USING qty CHANGING lv_qty_sum.     " 정수면 소수점 없이, 천 단위 쉼표
    lv_qt = |총 { lv_qty_sum } { unit }|.
  ENDIF.
  " 한 줄 요약: 입력 3행 · 저장가능 2 · 확인필요 1 · 완료 0 · 총 150 EA
  gv_ssum = |입력 { n_in }행  ·  저장가능 { n_ok }  ·  확인필요 { n_er }  ·  완료 { n_dn }  ·  { lv_qt }|.
ENDFORM.

" sync_site : 구매지사(=입고플랜트)가 바뀌었으면 미저장 행의 단가·안내를 그 플랜트 기준으로 다시 계산한다.
"   입력 중인 행이 있는데 지사를 바꾼 경우에만 "구매지사 B003 변경 완료"를 알려준다(처음 지사 입력은 제외).
FORM sync_site.
  IF gv_display_werks = n_werks.
    RETURN.                                 " 지사 그대로
  ENDIF.
  DATA lv_redo TYPE i.                      " 다시 계산한 입력행 수
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<entry>).
    IF ( gv_mode = 'N' AND <entry>-banfn IS INITIAL )
      OR ( gv_mode = 'C' AND gv_posted = abap_false ).
      PERFORM enrich_row CHANGING <entry>.
      IF <entry>-matnr IS NOT INITIAL OR <entry>-menge <> 0 OR <entry>-lifnr IS NOT INITIAL.
        lv_redo = lv_redo + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF gv_display_werks IS NOT INITIAL AND n_werks IS NOT INITIAL AND lv_redo > 0.
    DATA(lv_site_txt) = |구매지사 { n_bupla }|.
    MESSAGE s133(z8_msg) WITH lv_site_txt '변경'.   " &1 &2 완료 → 구매지사 B003 변경 완료
  ENDIF.
  gv_display_werks = n_werks.
  PERFORM refresh_entry.
ENDFORM.

" auto_check : ALV에 자재·수량·희망납기일을 다 넣으면 저장 전에 바로 검사한다(저장은 하지 않음).
"   구매지사가 비어 있으면 검사하지 않고 노랑으로 둔다. 필수 안내는 상태줄로만 보여준다.
"   검사에서 나온 사유(재고 위치 없음·평가정보 없음 등)는 실제로 그 지사에 문제가 있을 때만 처리 안내에 남는다.
FORM auto_check CHANGING row TYPE ty_entry.
  PERFORM enrich_row CHANGING row.
  IF n_werks IS INITIAL.
    CLEAR: row-result, row-detail.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '구매지사'.   " &1를 입력해주세요
    gv_focus_site = abap_true.          " 커서를 구매지사 칸으로(E01 AT SELECTION-SCREEN OUTPUT)
    RETURN.
  ENDIF.
  IF row-lfdat IS NOT INITIAL AND row-lfdat < sy-datum AND row-banfn IS INITIAL.
    " 지난 희망납기일은 수량 입력 전이라도 바로 빨갛게 알려준다(저장 불가).
    row-result = '확인 필요'.
    row-detail = '희망납기일이 오늘보다 이전입니다.'.
    CLEAR row-sto_from.                 " 앞서 검사한 STO 안내(링크)도 지운다
    RETURN.
  ENDIF.
  IF row-matnr IS INITIAL OR row-menge <= 0 OR row-lfdat IS INITIAL.
    " 아직 입력 중: 이름·단위만 보여주고 판정은 하지 않는다(노란불).
    "   남은 입력만 안내 칸에 알려준다(상태줄 경고 없음, STO 생성과 같은 방식).
    IF row-detail IS INITIAL
      OR row-detail = '요청수량을 입력하세요.' OR row-detail = '자재번호를 입력하세요.'.
      CLEAR row-result.
      IF row-matnr IS NOT INITIAL AND row-menge <= 0.
        row-detail = '요청수량을 입력하세요.'.
      ELSEIF row-matnr IS INITIAL AND row-menge > 0.
        row-detail = '자재번호를 입력하세요.'.
      ELSE.
        CLEAR row-detail.
      ENDIF.
    ENDIF.
    RETURN.
  ENDIF.
  TRY.
      PERFORM preview_one CHANGING row.
      row-result = '저장 가능'.
      CLEAR row-detail.
      PERFORM early_hint CHANGING row.       " 표준 납기일(오늘+3영업일)보다 빠르면 안내(저장은 가능)
      PERFORM moq_hint CHANGING row.         " 업체 최소발주량 미만이면 안내(저장은 가능)
    CATCH lcx_mm INTO DATA(lx_auto).
      row-result = '확인 필요'.
      PERFORM short_reason USING lx_auto->detail CHANGING row-detail.
    CATCH cx_root INTO DATA(lx_auto_root).
      row-result = '확인 필요'.
      row-detail = lx_auto_root->get_text( ).
  ENDTRY.
ENDFORM.

" sort_only_toolbar : 입력 ALV 위쪽 버튼줄과 오른쪽 클릭 메뉴에서 숨길 버튼 목록을 만든다.
"   정렬·복사·붙여넣기·되돌리기만 남긴다. 행 추가·삭제는 화면 버튼([자재추가]·[선택 삭제])으로만 해서
"   ALV 자체의 행 추가·삽입·삭제·잘라내기 버튼은 숨긴다.
FORM sort_only_toolbar CHANGING et_excl TYPE ui_functions.
  " Excel에서 복사한 [자재번호 / 요청수량] 등을 Ctrl+V로 붙여넣을 수 있게
  "   복사·붙여넣기·되돌리기는 입력에 필요해서 제외하지 않는다(오른쪽 클릭 메뉴에도 보임).
  et_excl = VALUE #(
    ( cl_gui_alv_grid=>mc_fc_detail ) ( cl_gui_alv_grid=>mc_fc_refresh ) ( cl_gui_alv_grid=>mc_fc_check )
    ( cl_gui_alv_grid=>mc_fc_loc_copy_row )
    ( cl_gui_alv_grid=>mc_fc_find ) ( cl_gui_alv_grid=>mc_fc_find_more )
    ( cl_gui_alv_grid=>mc_mb_filter ) ( cl_gui_alv_grid=>mc_fc_filter )
    ( cl_gui_alv_grid=>mc_mb_sum ) ( cl_gui_alv_grid=>mc_fc_sum ) ( cl_gui_alv_grid=>mc_fc_average )
    ( cl_gui_alv_grid=>mc_fc_maximum ) ( cl_gui_alv_grid=>mc_fc_minimum )
    ( cl_gui_alv_grid=>mc_mb_subtot ) ( cl_gui_alv_grid=>mc_fc_subtot )
    ( cl_gui_alv_grid=>mc_fc_print ) ( cl_gui_alv_grid=>mc_fc_print_back ) ( cl_gui_alv_grid=>mc_fc_print_prev )
    ( cl_gui_alv_grid=>mc_mb_export ) ( cl_gui_alv_grid=>mc_mb_view ) ( cl_gui_alv_grid=>mc_fc_views )
    ( cl_gui_alv_grid=>mc_mb_variant ) ( cl_gui_alv_grid=>mc_fc_current_variant )
    ( cl_gui_alv_grid=>mc_fc_load_variant ) ( cl_gui_alv_grid=>mc_fc_save_variant )
    ( cl_gui_alv_grid=>mc_fc_maintain_variant )
    ( cl_gui_alv_grid=>mc_fc_graph ) ( cl_gui_alv_grid=>mc_fc_info )
    ( cl_gui_alv_grid=>mc_fc_loc_append_row ) ( cl_gui_alv_grid=>mc_fc_loc_insert_row )
    ( cl_gui_alv_grid=>mc_fc_loc_delete_row ) ( cl_gui_alv_grid=>mc_fc_loc_cut ) ).
ENDFORM.

" short_reason : 공통 검사의 긴 오류문을 "무엇이 문제인지" 한 줄로 바꾼다. 표시 전용이다.
"   예) 자재/플랜트/저장위치 기준정보 … 오류 → 'P200 플랜트에 등록되지 않은 자재이다.'
FORM short_reason USING iv_text TYPE clike CHANGING cv_detail TYPE clike.
  DATA(lv_text) = CONV string( iv_text ).
  IF lv_text CS '저장위치 기준정보' OR lv_text CS '평가영역'.
    cv_detail = |{ n_werks } 플랜트에 등록되지 않은 자재입니다.|.
  ELSEIF lv_text CS '평가정보' OR lv_text CS '평가가격'.
    cv_detail = |{ n_werks } 플랜트에 이 자재의 평가단가가 없습니다.|.
  ELSEIF lv_text CS '재고 수량 또는 기본단위'.
    cv_detail = '재고 단위가 자재 단위와 다릅니다.'.
  ELSEIF lv_text CS '구매정보'.
    cv_detail = '이 업체의 구매단가(구매정보)가 없습니다.'.
  ELSEIF lv_text CS '구매단위'.
    cv_detail = '업체 구매단위가 자재 단위와 다릅니다.'.
  ELSEIF lv_text CS '자재 기본단위' OR lv_text CS '자재 마스터'.
    cv_detail = '등록되지 않은 자재번호입니다.'.
  ELSE.
    cv_detail = lv_text.
  ENDIF.
ENDFORM.

" ------------------------------------------------------------
" 입력 편의 기능
" ------------------------------------------------------------

" ensure_blank_row : 신규 작성에서 빈 행이 하나도 없으면 맨 아래에 빈 행 1줄을 붙인다.
"   마지막 줄까지 채우면 [자재 추가]를 누르지 않아도 다음 줄이 생긴다. 화면용, DB 변경 없음.
FORM ensure_blank_row.
  " 행 추가는 [자재추가] 버튼으로만 한다.
  " 입력행이 하나도 없을 때(전부 삭제 등)만 빈 줄 1개를 둔다.
  IF gv_mode <> 'N' OR gt_entry IS NOT INITIAL.
    RETURN.
  ENDIF.
  APPEND INITIAL LINE TO gt_entry.       " 날짜 없는 빈 줄(자재 입력 시 기본 납기일 자동)
  PERFORM refresh_entry.
ENDFORM.

" sync_default_date : 위쪽 [희망납기일]을 바꾸면, 아직 저장 안 한 행 중
"   날짜를 직접 고치지 않은 행(= 이전 기본값과 같은 행)만 새 날짜로 바꾼다.
FORM sync_default_date.
  IF gv_mode <> 'N' OR n_lfdat = gv_prev_lfdat.
    RETURN.
  ENDIF.
  IF n_lfdat IS INITIAL.
    PERFORM default_due CHANGING n_lfdat.   " 기본 희망납기일 = 오늘 + 3영업일
  ELSEIF n_lfdat < sy-datum.
    " 지난 날짜는 희망납기일로 쓸 수 없다 → 바로 전 값으로 되돌린다.
    n_lfdat = COND #( WHEN gv_prev_lfdat >= sy-datum THEN gv_prev_lfdat ).
    IF n_lfdat IS INITIAL.
      PERFORM default_due CHANGING n_lfdat.
    ENDIF.
    MESSAGE s145(z8_msg) DISPLAY LIKE 'E' WITH '희망납기일을 오늘 이후로'.   " &1 입력해주세요 (저장 실패 메시지와 같은 문구)
    RETURN.
  ENDIF.
  " 기본 납기일을 그대로 쓰던 행(또는 빈 행)의 희망납기일을 새 기본 납기일로 바꾸고 다시 검사한다.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<date_row>)
    WHERE banfn IS INITIAL AND matnr IS NOT INITIAL AND ( lfdat = gv_prev_lfdat OR lfdat IS INITIAL ).
    <date_row>-lfdat = n_lfdat.
    PERFORM auto_check CHANGING <date_row>.
  ENDLOOP.
  gv_prev_lfdat = n_lfdat.
  PERFORM refresh_entry.
ENDFORM.

" default_vendor : 공급업체가 비어 있으면 그 자재의 구매단가(Z8PURCH_INFO_M)가 등록된 업체 중
" **가장 싼 업체**를 자동으로 넣는다. 다른 업체는 공급업체 F4에서 단가 낮은 순으로 고른다.
"   등록된 업체가 하나도 없으면 비워 두고, 입력 확인에서 '공급업체 지정 필요'로 빨갛게 알려준다. 읽기 전용.
FORM default_vendor CHANGING row TYPE ty_entry.
  IF row-matnr IS INITIAL OR row-lifnr IS NOT INITIAL.
    RETURN.
  ENDIF.
  DATA lt_vendors TYPE STANDARD TABLE OF z8purch_info_m-lifnr WITH EMPTY KEY.
  SELECT lifnr FROM z8purch_info_m
    WHERE matnr = @row-matnr AND netpr > 0
    ORDER BY netpr, lifnr
    INTO TABLE @lt_vendors UP TO 1 ROWS.
  IF lt_vendors IS NOT INITIAL.
    row-lifnr = lt_vendors[ 1 ].
  ENDIF.
ENDFORM.

" vendor_pick : 공급업체 F4. 자재가 있으면 그 자재의 구매단가가 등록된 업체만 단가·통화와 함께 보여준다.
"   등록된 업체가 없으면 전체 업체 검색(공통 Z8MM_F4_C01)으로 넘어간다.
FORM vendor_pick USING iv_matnr TYPE clike iv_typed TYPE clike CHANGING cv_value TYPE clike.
  TYPES: BEGIN OF ty_vhelp,
           lifnr TYPE z8vendor_m-lifnr,
           name1 TYPE z8vendor_m-name1,
           netpr TYPE z8purch_info_m-netpr,
           waers TYPE z8purch_info_m-waers,
         END OF ty_vhelp.
  DATA lt_help TYPE STANDARD TABLE OF ty_vhelp WITH EMPTY KEY.
  DATA lt_ret TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.
  CLEAR cv_value.
  SELECT i~lifnr, v~name1, i~netpr, i~waers
    FROM z8purch_info_m AS i LEFT OUTER JOIN z8vendor_m AS v ON v~lifnr = i~lifnr
    WHERE i~matnr = @iv_matnr AND i~netpr > 0
    ORDER BY i~netpr, i~lifnr
    INTO TABLE @lt_help.
  IF lt_help IS INITIAL.
    cv_value = lcl_mm_f4=>pick( kind = 'VEND' typed = iv_typed ).
    RETURN.
  ENDIF.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'LIFNR' value_org = 'S'
      window_title = '공급업체 선택 (이 자재의 구매단가가 있는 업체, 단가 낮은 순)'
    TABLES value_tab = lt_help return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc = 0 AND lt_ret IS NOT INITIAL.
    cv_value = lt_ret[ 1 ]-fieldval.
  ENDIF.
ENDFORM.

" fill_pasted_rows : Excel 붙여넣기로 새로 생긴 행은 ALV 변경 이벤트에서 이름이 안 채워질 수 있어
"   PAI에서 한 번 더 채운다(자재명·단위·업체 자동·기본 납기일·바로 검사). 저장은 하지 않는다.
FORM fill_pasted_rows.
  IF gv_mode <> 'N'.
    RETURN.
  ENDIF.
  DATA lv_changed TYPE abap_bool.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<paste_row>)
    WHERE banfn IS INITIAL AND matnr IS NOT INITIAL AND maktx IS INITIAL.
    TRANSLATE <paste_row>-matnr TO UPPER CASE.
    IF <paste_row>-lfdat IS INITIAL.
      <paste_row>-lfdat = n_lfdat.
    ENDIF.
    PERFORM default_vendor CHANGING <paste_row>.
    PERFORM auto_check CHANGING <paste_row>.
    lv_changed = abap_true.
  ENDLOOP.
  IF lv_changed = abap_true.
    PERFORM refresh_entry.
  ENDIF.
ENDFORM.

" default_lfdat : 위쪽 [기본 납기일] 값을 돌려준다. K01(ALV 이벤트)에서 SEL 변수를 직접 못 쓰므로 FORM으로 전달한다.
FORM default_lfdat CHANGING cv_lfdat TYPE z8mm_pr-lfdat.
  IF n_lfdat IS INITIAL.
    PERFORM default_due CHANGING n_lfdat.
  ENDIF.
  cv_lfdat = n_lfdat.
ENDFORM.

" default_due : 기본 희망납기일 = 오늘 + 3영업일
"   팀 SD 출고예정일 계산과 같은 공장달력 'KR'을 쓴다(DATE_CONVERT_TO_FACTORYDATE → +3 → FACTORYDATE_CONVERT_TO_DATE).
"   오늘이 휴무일이면 다음 영업일부터 센다. 달력이 없거나 오류면 오늘 + 3일(달력일)로 대신한다.
FORM default_due CHANGING cv_date TYPE z8mm_pr-lfdat.
  CONSTANTS lc_days TYPE i VALUE 3.
  DATA lv_factory TYPE scal-facdate.
  CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
    EXPORTING date = sy-datum factory_calendar_id = 'KR' correct_option = '+'
    IMPORTING factorydate = lv_factory
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc = 0.
    lv_factory = lv_factory + lc_days.
    CALL FUNCTION 'FACTORYDATE_CONVERT_TO_DATE'
      EXPORTING factorydate = lv_factory factory_calendar_id = 'KR'
      IMPORTING date = cv_date
      EXCEPTIONS OTHERS = 1.
  ENDIF.
  IF sy-subrc <> 0 OR cv_date IS INITIAL.
    cv_date = sy-datum + lc_days.
  ENDIF.
ENDFORM.

" std_due : 표준 납기일(오늘+3영업일). '빠른 납기·STO 안내' 판단 기준이다.
"   기본 납기일 칸(n_lfdat)은 사용자가 바꿀 수 있어 기준으로 쓰지 않는다. 실행 중 한 번만 계산한다.
FORM std_due CHANGING cv_date TYPE z8mm_pr-lfdat.
  IF gv_std_due IS INITIAL.
    PERFORM default_due CHANGING gv_std_due.
  ENDIF.
  cv_date = gv_std_due.
ENDFORM.

" ------------------------------------------------------------
" 빠른 납기 → STO 안내
"   희망납기일 < 표준 납기일(오늘+3영업일)이면 막지 않고(PR 저장 가능) 처리 안내에 알려준다.
"   다른 플랜트에 이동가능 재고가 있고 STO 도착예정일이 희망납기일 안이면
"   '…에서 STO 가능 · 클릭하면 STO 생성' 링크를 보여주고, 클릭 → 확인 [예] → STO 생성 화면(ZMMSTO0100)에 값을 채워 연다.
" ------------------------------------------------------------
FORM early_hint CHANGING row TYPE ty_entry.
  CLEAR row-sto_from.
  DATA lv_std_due TYPE z8mm_pr-lfdat.
  PERFORM std_due CHANGING lv_std_due.       " 기준 = 표준 납기일(오늘+3영업일), 기본 납기일 칸 값 아님
  IF gv_mode <> 'N' OR row-banfn IS NOT INITIAL OR row-lfdat IS INITIAL
    OR row-lfdat >= lv_std_due.
    RETURN.
  ENDIF.
  DATA: lv_from TYPE z8mm_pr-werks,
        lv_qty  TYPE z8mm_pr-menge,
        lv_eta  TYPE sy-datum.
  PERFORM find_sto_source USING row CHANGING lv_from lv_qty lv_eta.
  IF lv_from IS INITIAL.
    row-detail = '표준 납기일보다 빠름'.          " 짧게
    RETURN.
  ENDIF.
  row-sto_from = lv_from.
  row-detail = |{ lv_from }에서 STO 가능({ lv_eta DATE = USER } 도착) ▶ 클릭|.   " 짧게
ENDFORM.

" find_sto_source : 입고플랜트 말고 다른 플랜트 중 이동가능수량(현재고-예약-안전재고) >= 요청수량이고
"   오늘 출고 시 도착예정일(오늘+운송일) <= 희망납기일인 곳. 여러 곳이면 가장 빨리 도착하는 곳(같으면 재고 많은 곳).
"   읽기 전용(DB 변경 없음). 실제 재고·일정 검사는 STO 화면에서 다시 한다.
FORM find_sto_source USING is_row TYPE ty_entry CHANGING cv_from TYPE clike cv_qty TYPE z8mm_pr-menge cv_eta TYPE sy-datum.
  CLEAR: cv_from, cv_qty, cv_eta.
  SELECT SINGLE region_code FROM z8plant_m WHERE werks = @n_werks INTO @DATA(lv_dest_region).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  SELECT werks, region_code FROM z8plant_m WHERE werks <> @n_werks ORDER BY werks INTO TABLE @DATA(lt_src).
  " 후보 플랜트의 자재 기준정보(안전재고)·재고·운송경로를 한 번에 읽어 두고 플랜트마다 찾는다(루프 안 SELECT 없음).
  TYPES: BEGIN OF ty_src_mp,
           werks TYPE z8matplant_m-werks,
           eisbe TYPE z8matplant_m-eisbe,
         END OF ty_src_mp,
         BEGIN OF ty_src_stk,
           werks TYPE z8material_stk_m-werks,
           labst TYPE z8material_stk_m-labst,
           zzrsvqty TYPE z8material_stk_m-zzrsvqty,
         END OF ty_src_stk,
         BEGIN OF ty_src_route,
           from_region TYPE z8route_m-from_region,
           est_transit_days TYPE z8route_m-est_transit_days,
         END OF ty_src_route.
  DATA: lt_src_mp TYPE SORTED TABLE OF ty_src_mp WITH NON-UNIQUE KEY werks,
        lt_src_stk TYPE SORTED TABLE OF ty_src_stk WITH NON-UNIQUE KEY werks,
        lt_src_route TYPE SORTED TABLE OF ty_src_route WITH NON-UNIQUE KEY from_region.
  SELECT werks, eisbe FROM z8matplant_m
    WHERE matnr = @is_row-matnr AND werks <> @n_werks AND lgort = @n_lgort
    INTO CORRESPONDING FIELDS OF TABLE @lt_src_mp.
  SELECT werks, labst, zzrsvqty FROM z8material_stk_m
    WHERE matnr = @is_row-matnr AND werks <> @n_werks AND lgort = @n_lgort
    INTO CORRESPONDING FIELDS OF TABLE @lt_src_stk.
  SELECT from_region, est_transit_days FROM z8route_m
    WHERE to_region = @lv_dest_region AND ( use_yn = 'X' OR use_yn = 'Y' )
    INTO CORRESPONDING FIELDS OF TABLE @lt_src_route.
  LOOP AT lt_src INTO DATA(ls_src).
    " 그 플랜트에 자재 기준정보가 없으면 건너뛴다.
    READ TABLE lt_src_mp INTO DATA(ls_src_mp) WITH TABLE KEY werks = ls_src-werks.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    DATA ls_src_stk TYPE ty_src_stk.
    CLEAR ls_src_stk.                    " 재고행이 없으면 재고 0으로 본다
    READ TABLE lt_src_stk INTO ls_src_stk WITH TABLE KEY werks = ls_src-werks.
    DATA(lv_movable) = CONV z8mm_pr-menge( ls_src_stk-labst - ls_src_stk-zzrsvqty - ls_src_mp-eisbe ).
    IF lv_movable < is_row-menge.
      CONTINUE.
    ENDIF.
    " 운송일수: 같은 지역이면 0일, 다른 지역이면 활성 경로가 정확히 1건일 때만 쓴다(없거나 여러 건이면 건너뜀).
    DATA lv_days TYPE i.
    IF ls_src-region_code = lv_dest_region.
      lv_days = 0.
    ELSE.
      DATA lv_route_hits TYPE i.
      CLEAR: lv_route_hits, lv_days.
      LOOP AT lt_src_route INTO DATA(ls_src_route) WHERE from_region = ls_src-region_code.
        lv_route_hits = lv_route_hits + 1.
        lv_days = ls_src_route-est_transit_days.
      ENDLOOP.
      IF lv_route_hits <> 1 OR lv_days < 0.
        CONTINUE.
      ENDIF.
    ENDIF.
    DATA(lv_arrive) = CONV sy-datum( sy-datum + lv_days ).
    IF lv_arrive > is_row-lfdat.
      CONTINUE.
    ENDIF.
    IF cv_from IS INITIAL OR lv_arrive < cv_eta OR ( lv_arrive = cv_eta AND lv_movable > cv_qty ).
      cv_from = ls_src-werks.
      cv_qty = lv_movable.
      cv_eta = lv_arrive.
    ENDIF.
  ENDLOOP.
ENDFORM.

" goto_sto : 처리 안내의 STO 링크를 누른 행의 데이터만 STO 생성 화면(ZMMSTO0100)으로 넘긴다.
"   출발 = 안내된 플랜트, 도착 = 입고플랜트, 자재·수량 = 그 행. 저장(생성·출고)은 STO 화면에서 STO 확인창을 거쳐 한다.
"   STO를 저장하고 돌아오면 그 행은 PR 입력에서 빼고, 저장 안 하고 돌아오면 그대로 둔다(PR 저장 가능).
"   [아니오]는 아무 메시지 없이 그대로 둔다(잘못 누른 경우).
FORM goto_sto.
  DATA(lv_index) = gv_sto_row.
  CLEAR gv_sto_row.
  READ TABLE gt_entry INDEX lv_index INTO DATA(ls_row).
  IF sy-subrc <> 0 OR ls_row-banfn IS NOT INITIAL OR ls_row-sto_from IS INITIAL
    OR ls_row-lfdat < sy-datum.
    RETURN.                            " STO 안내가 없는(또는 지난 희망납기일) 행의 처리 안내 클릭은 무시
  ENDIF.
  DATA: lv_question TYPE c LENGTH 200,
        lv_answer TYPE c LENGTH 1.
  DATA lv_qty_txt TYPE string.
  PERFORM qty_text USING ls_row-menge CHANGING lv_qty_txt.
  lv_question = |{ ls_row-matnr } { lv_qty_txt } { ls_row-meins }을(를) { ls_row-sto_from }에서 { n_werks }(으)로 옮기는 STO 생성 화면으로 이동할까요?|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'STO 생성' text_question = lv_question
      text_button_1 = '예' text_button_2 = '아니오'
      default_button = '1' display_cancel_button = space
    IMPORTING answer = lv_answer EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    RETURN.
  ENDIF.
  SELECT MAX( ebeln ) FROM z8mm_po_h WHERE bsart = 'UB' INTO @DATA(lv_before).
  SUBMIT zmmsto0100 WITH p_new = abap_true
                    WITH p_purwk = ls_row-sto_from
                    WITH p_purto = n_werks
                    WITH p_purmat = ls_row-matnr
                    WITH p_purqty = ls_row-menge
                    WITH p_purdt   = ls_row-lfdat AND RETURN.   " PR 희망납기일 = STO 도착희망일
  SELECT MAX( ebeln ) FROM z8mm_po_h WHERE bsart = 'UB' INTO @DATA(lv_after).
  IF lv_after IS NOT INITIAL AND lv_after > lv_before.
    DELETE gt_entry INDEX lv_index.
    " STO 화면에서 이미 완료 팝업을 봤으므로 여기서는 상태줄로만 알린다(팝업 두 번 방지).
    MESSAGE s133(z8_msg) WITH lv_after '생성'.   " &1 &2 완료 (STO 생성, 해당 PR 입력행은 지움)
    PERFORM refresh_entry.
  ENDIF.
ENDFORM.

" branch_plant : 구매지사(B001) → 입고플랜트(P100). 지금은 지사:플랜트 1:1, 여러 개면 첫 플랜트.
FORM branch_plant.
  CLEAR n_werks.
  IF n_bupla IS INITIAL.
    RETURN.
  ENDIF.
  SELECT werks FROM z8plant_m WHERE bupla = @n_bupla ORDER BY werks INTO @n_werks UP TO 1 ROWS.
  ENDSELECT.
ENDFORM.

" plant_branch : 넘어온/저장된 입고플랜트(P100) → 화면 구매지사(B001)
FORM plant_branch.
  CLEAR n_bupla.
  IF n_werks IS INITIAL.
    RETURN.
  ENDIF.
  SELECT SINGLE bupla FROM z8plant_m WHERE werks = @n_werks INTO @n_bupla.
ENDFORM.

" ------------------------------------------------------------
" moq_hint : 업체 최소발주량(Z8PURCH_INFO_M-MINBM) 안내. 읽기 전용, 저장을 막지 않는다.
"   PR 한 건이 최소발주량보다 적어도 같은 업체·자재 PR을 여러 건 묶으면 PO가 가능하므로
"   PR 단계에서는 막지 않고 알려만 준다. 실제 차단은 PO 생성 때 묶음 합계로 한다(ZMMPO0110).
"   이미 다른 안내(STO 가능 등)가 있으면 그 안내를 우선한다.
" ------------------------------------------------------------
FORM moq_hint CHANGING row TYPE ty_entry.
  IF gv_mode <> 'N' OR row-banfn IS NOT INITIAL OR row-detail IS NOT INITIAL
    OR row-matnr IS INITIAL OR row-lifnr IS INITIAL OR row-menge <= 0.
    RETURN.
  ENDIF.
  SELECT SINGLE minbm FROM z8purch_info_m
    WHERE matnr = @row-matnr AND lifnr = @row-lifnr INTO @DATA(lv_minbm).
  IF sy-subrc = 0 AND lv_minbm > 0 AND row-menge < lv_minbm.
    DATA lv_minbm_txt TYPE string.
    PERFORM qty_text USING lv_minbm CHANGING lv_minbm_txt.
    row-detail = |업체 최소발주량 { lv_minbm_txt } 미만(묶어서 발주)|.
  ENDIF.
ENDFORM.

" qty_text : 수량을 안내 문구용 글자로 바꾼다. 정수면 소수점 없이(100), 소수가 있으면 3자리(12.500). 천 단위 쉼표.
FORM qty_text USING iv_qty TYPE numeric CHANGING ev_text TYPE string.
  DATA lv_amount TYPE decfloat34.
  lv_amount = iv_qty.
  IF lv_amount = trunc( lv_amount ).
    ev_text = |{ lv_amount NUMBER = USER DECIMALS = 0 }|.
  ELSE.
    ev_text = |{ lv_amount NUMBER = USER DECIMALS = 3 }|.
  ENDIF.
ENDFORM.
