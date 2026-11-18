*&---------------------------------------------------------------------*
*& Include ZMMSTO0100_F01
*&---------------------------------------------------------------------*
*& 업무 처리 FORM - 조회·카드·입력 검사·저장(출고/예약)·STO 취소
*&   신호등 + 처리상태 글자, 줄 색은 방금 만든·취소한 STO만 파란 줄(+ 행 선택), 결과는 하단 상태줄
*&   오른쪽 카드 4개(전체 / 예약·이동 / 입고완료 / 취소). 예상도착일에 배치(Z8MMB0100)가 자동 입고하므로 도착지연 상태는 없다.
*&   저장: 미저장 행 전체를 STO 1건(품목 N개)으로 한 번에 COMMIT/ROLLBACK 한다(351 자재문서 1건 N줄).
*&   출고일이 오늘이면 바로 351 출고, 미래면 예약(출발지 예약재고 확보) 후 출고일에 배치가 출고한다.
*& 담당: MM(이규빈) / 프로그램: ZMMSTO0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: 지사 간 자재이동(STO) 목록·입력·취소 (개발 10/17~10/23)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: STO 1건 품목 N줄 구조, 목록 카드·이력 ALV
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: STO 예약 추가, 취소 메시지 202·134 구분, 수량 소수점·카드 크기 수정
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" ------------------------------------------------------------
" 공통 도우미: F4 / 이름 / 수량 / ALV 열
" ------------------------------------------------------------

" screen_help : F4. 칸에 글자 일부(예: P2, 충청, CAB)가 있으면 그 글자로 걸러서 보여준다.
" 1건뿐이면 목록 없이 바로 넣는다. 목록 조건(0100)은 값·이름만 반영하고 조회는 [조회]·Enter 때,
"   입력 화면 출발/도착 플랜트(0200)는 고르면 바로 재고·일정을 확인한다.
FORM screen_help USING iv_kind TYPE clike iv_dyn TYPE clike.
  " 잠긴 출발/도착 플랜트(자재 입력 후)에서 F4를 누르면 목록을 열지 않고 값을 그대로 둔다.
  IF iv_dyn = 'P_FROM' OR iv_dyn = 'P_TO'.
    DATA lv_locked TYPE abap_bool.
    PERFORM entry_header_locked CHANGING lv_locked.
    IF lv_locked = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
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
      EXPORTING functioncode = COND char20( WHEN iv_dyn = 'P_FROM' OR iv_dyn = 'P_TO' THEN 'QCHG' ELSE 'F4SET' )
      EXCEPTIONS function_not_supported = 1 OTHERS = 2.
  ENDIF.
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

" fill_names : 조회조건·입력조건 코드 옆 회색 글씨(지사명·자재명)를 채운다. 표시 전용이다.
FORM fill_names.
  CLEAR: gv_nsrc, gv_ndst, gv_nmat, gv_nefr, gv_neto.
  PERFORM one_plant_name USING p_sfrom CHANGING gv_nsrc.
  PERFORM one_plant_name USING p_sto CHANGING gv_ndst.
  PERFORM one_plant_name USING p_from CHANGING gv_nefr.
  PERFORM one_plant_name USING p_to CHANGING gv_neto.
  IF p_mat IS NOT INITIAL.
    DATA lv_mat_name TYPE z8material_txt_m-maktx.
    PERFORM material_name USING p_mat CHANGING lv_mat_name.
    gv_nmat = COND #( WHEN lv_mat_name IS NOT INITIAL THEN lv_mat_name ELSE '등록되지 않은 코드' ).
  ENDIF.
ENDFORM.

" one_plant_name : 코드가 있으면 지사명, 없는 코드면 '등록되지 않은 코드'
FORM one_plant_name USING iv_werks TYPE clike CHANGING cv_text TYPE clike.
  CLEAR cv_text.
  IF iv_werks IS INITIAL.
    RETURN.
  ENDIF.
  PERFORM plant_name USING iv_werks CHANGING cv_text.
  IF cv_text IS INITIAL.
    cv_text = '등록되지 않은 코드'.
  ENDIF.
ENDFORM.

" material_name : 로그인 언어 → 한국어 순서로 자재명을 찾는다.
FORM material_name USING iv_matnr TYPE clike CHANGING ev_name TYPE clike.
  CLEAR ev_name.
  SELECT SINGLE maktx FROM z8material_txt_m
    WHERE matnr = @iv_matnr AND spras = @sy-langu INTO @DATA(lv_name).
  IF sy-subrc <> 0.
    SELECT SINGLE maktx FROM z8material_txt_m
      WHERE matnr = @iv_matnr AND spras = '3' INTO @lv_name.
  ENDIF.
  ev_name = lv_name.
ENDFORM.

" add_column : ALV 열 한 개(제목·폭·단위)를 필드카탈로그에 추가한다. 폭 0은 숨김 열이다.
FORM add_column USING field TYPE clike title TYPE clike width TYPE i
  CHANGING catalog TYPE lvc_t_fcat.
  DATA fc TYPE lvc_s_fcat.
  fc-fieldname = field.
  fc-coltext = title.
  fc-scrtext_l = title.
  fc-scrtext_m = title.
  fc-scrtext_s = title.
  fc-outputlen = width.
  IF width = 0.
    fc-no_out = abap_true.
  ENDIF.
  CASE fc-fieldname.
    WHEN 'SIGNAL'.
      fc-icon = abap_true.
      fc-just = 'C'.
    WHEN 'MENGE' OR 'SRC_QTY' OR 'MOVABLE' OR 'DST_QTY' OR 'TRANSIT'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'MENGE'.
      " 수량은 단위(MEINS)를 참조해 EA·M 등 단위의 소수 자리로 표시한다(정수면 소수점 없음).
      "   입력 ALV는 숨김 단위 QTY_UNIT을 참조한다(자재 입력 전 EA).
      fc-qfieldname = 'MEINS'.
      fc-decimals_o = 0.
      fc-just = 'R'.
    WHEN 'MEINS'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'MEINS'.
    WHEN 'MATNR'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'MATNR'.
    WHEN 'EBELN'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'EBELN'.
    WHEN 'EBELP'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'EBELP'.
    WHEN 'DEP_DATE' OR 'ETA' OR 'GR_DATE' OR 'BUDAT' OR 'ERDAT'.
      fc-datatype = 'DATS'.
      fc-inttype = 'D'.
      fc-intlen = 8.
  ENDCASE.
  APPEND fc TO catalog.
ENDFORM.

" toolbar_excluded : ALV 위쪽 버튼줄과 오른쪽 클릭 메뉴에서 숨길 버튼 목록을 만든다.
"   정렬·찾기·필터만 남기고 편집·합계·인쇄·엑셀·레이아웃·그래프는 숨긴다.
FORM toolbar_excluded CHANGING et_excl TYPE ui_functions.
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

" 정수 열은 .000을 숨기고 실제 소수가 있는 열은 3자리로 표시한다.
FORM quantity_catalog USING rows TYPE STANDARD TABLE CHANGING catalog TYPE lvc_t_fcat.
  LOOP AT catalog ASSIGNING FIELD-SYMBOL(<qty_fc>) WHERE qfieldname IS NOT INITIAL OR fieldname = 'MENGE'.
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

" ------------------------------------------------------------
" 화면 0100 : STO 목록 + 선택 STO 이력
" ------------------------------------------------------------

" query_list : 조회조건으로 STO 품목을 읽어 신호등·상태·지사명을 계산한다. DB는 읽기만 한다.
FORM query_list.
  DATA lr_dates TYPE RANGE OF z8mm_po_i-sto_dep_date.
  " 조회 기간: 시작일 필수(문서번호로 찾을 때도), 종료일이 비면 시작일 하루.
  "   - 시작일 비면 Z8_MSG 046 / 종료일 비면 시작일 하루 / 시작일 > 종료일이면 결과 없음(BETWEEN과 동일)
  IF p_dfrom IS INITIAL.
    " 팀 공통 메시지 Z8_MSG 046 '조회 기간을 입력해주세요'
    MESSAGE s046(z8_msg) DISPLAY LIKE 'E'.
    SET CURSOR FIELD 'P_DFROM'.          " 시작일 칸에 커서
    RETURN.
  ENDIF.
  IF p_dto IS INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = p_dfrom ) TO lr_dates.
  ELSE.
    APPEND VALUE #( sign = 'I' option = 'BT' low = p_dfrom high = p_dto ) TO lr_dates.
  ENDIF.
  DATA result TYPE STANDARD TABLE OF ty_list WITH EMPTY KEY.
  SELECT i~ebeln, i~ebelp, i~matnr, i~reswk, i~reslo, i~werks, i~lgort,
    i~menge, i~meins, i~sto_dep_date AS dep_date, i~sto_arr_date AS eta,
    i~elikz, i~loekz, i~sto_rsv_qty AS rsv_qty
    FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
    WHERE h~bsart = 'UB' AND i~sto_dep_date IN @lr_dates
    INTO CORRESPONDING FIELDS OF TABLE @result.
  " 방금 만든·PUR에서 넘어온 STO(gt_new_sto)는 기간·조건 밖이어도 함께 읽는다(파란 줄로 보여줄 행).
  IF gt_new_sto IS NOT INITIAL.
    DATA lr_new TYPE RANGE OF z8mm_po_i-ebeln.
    DATA ls_new_range LIKE LINE OF lr_new.
    LOOP AT gt_new_sto INTO DATA(lv_new_doc).
      CLEAR ls_new_range.
      ls_new_range-sign = 'I'.
      ls_new_range-option = 'EQ'.
      ls_new_range-low = lv_new_doc.
      APPEND ls_new_range TO lr_new.
    ENDLOOP.
    SELECT i~ebeln, i~ebelp, i~matnr, i~reswk, i~reslo, i~werks, i~lgort,
      i~menge, i~meins, i~sto_dep_date AS dep_date, i~sto_arr_date AS eta,
      i~elikz, i~loekz, i~sto_rsv_qty AS rsv_qty
      FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
      WHERE h~bsart = 'UB' AND i~ebeln IN @lr_new
      APPENDING CORRESPONDING FIELDS OF TABLE @result.
    SORT result BY ebeln ebelp.
    DELETE ADJACENT DUPLICATES FROM result COMPARING ebeln ebelp.
  ENDIF.
  " 실제입고일: STO 이력의 101 입고일, 없으면(입고완료인데 이력이 빠진 경우) 101 자재문서 전기일.
  "   목록 전체를 한 번에 읽어 두고 줄마다 찾는다(루프 안 SELECT 없음).
  TYPES: BEGIN OF ty_gr_hist,
           ebeln TYPE z8mm_sto_hist-ebeln,
           ebelp TYPE z8mm_sto_hist-ebelp,
           budat TYPE z8mm_sto_hist-budat,
         END OF ty_gr_hist,
         BEGIN OF ty_gr_doc,
           zzrefdoc TYPE z8mm_matdoc_i-zzrefdoc,
           ref_item TYPE z8mm_matdoc_i-ref_item,
           budat TYPE z8mm_matdoc_h-budat,
         END OF ty_gr_doc.
  DATA: lt_gr_hist TYPE STANDARD TABLE OF ty_gr_hist WITH EMPTY KEY,
        lt_gr_doc TYPE STANDARD TABLE OF ty_gr_doc WITH EMPTY KEY.
  IF result IS NOT INITIAL.
    SELECT ebeln, ebelp, budat FROM z8mm_sto_hist FOR ALL ENTRIES IN @result
      WHERE ebeln = @result-ebeln AND ebelp = @result-ebelp AND bwart = '101'
      INTO CORRESPONDING FIELDS OF TABLE @lt_gr_hist.
    SELECT i~zzrefdoc, i~ref_item, h~budat FROM z8mm_matdoc_h AS h
      INNER JOIN z8mm_matdoc_i AS i ON i~mblnr = h~mblnr AND i~mjahr = h~mjahr
      FOR ALL ENTRIES IN @result
      WHERE i~zzreftype = '03' AND i~zzrefdoc = @result-ebeln AND i~bwart = '101'
      INTO CORRESPONDING FIELDS OF TABLE @lt_gr_doc.
  ENDIF.
  " 같은 품목에 여러 건이면 가장 늦은 날짜가 먼저 오게 정렬한다(이전 MAX( budat )와 같은 결과).
  SORT lt_gr_hist BY ebeln ebelp budat DESCENDING.
  SORT lt_gr_doc BY zzrefdoc ref_item budat DESCENDING.
  CLEAR gt_list.
  LOOP AT result INTO DATA(row).
    READ TABLE gt_new_sto TRANSPORTING NO FIELDS WITH TABLE KEY table_line = row-ebeln.
    IF sy-subrc <> 0 AND (
      ( p_doc IS NOT INITIAL AND row-ebeln <> p_doc )
      OR ( p_mat IS NOT INITIAL AND row-matnr <> p_mat )
      OR ( p_sfrom IS NOT INITIAL AND row-reswk <> p_sfrom )
      OR ( p_sto IS NOT INITIAL AND row-werks <> p_sto ) ).
      CONTINUE.
    ENDIF.
    IF row-loekz IS NOT INITIAL.
      row-state_key = 'V'.
      row-state = '취소'.
    ELSEIF row-elikz IS NOT INITIAL.
      row-state_key = 'C'.
      row-state = '입고완료'.
    ELSEIF row-rsv_qty > 0.
      row-state_key = 'R'.               " 예약중: 아직 출고 전(출고일에 배치가 출고)
      row-state = '예약중'.
    ELSE.
      row-state_key = 'M'.
      row-state = '이동중'.
    ENDIF.
    CLEAR row-gr_date.
    READ TABLE lt_gr_hist INTO DATA(ls_gr_hist) WITH KEY ebeln = row-ebeln ebelp = row-ebelp BINARY SEARCH.
    IF sy-subrc = 0.
      row-gr_date = ls_gr_hist-budat.
    ENDIF.
    IF row-gr_date IS INITIAL AND row-elikz IS NOT INITIAL.
      DATA(ref_item) = CONV z8mm_matdoc_i-ref_item( row-ebelp ).
      READ TABLE lt_gr_doc INTO DATA(ls_gr_doc)
        WITH KEY zzrefdoc = row-ebeln ref_item = ref_item BINARY SEARCH.
      IF sy-subrc = 0.
        row-gr_date = ls_gr_doc-budat.
      ENDIF.
    ENDIF.
    IF row-state_key = 'R'.
      DATA(lv_to_ship) = row-dep_date - sy-datum.
      row-due_key = 'F'.
      row-due_text = COND #( WHEN lv_to_ship <= 0 THEN '출고 처리 대기' ELSE |{ lv_to_ship }일 후 출고| ).
    ELSEIF row-state_key = 'M'.
      IF row-eta IS INITIAL.
        row-due_key = 'N'.
        row-due_text = '도착일 확인 필요'.
      ELSE.
        " 예정일이 되면 Z8MMB0100 배치가 자동 입고하므로 '지연' 상태는 없다.
        "   예정일이 지났는데 아직 이동중이면 배치 실행 전 상태라 '입고 처리 대기'로만 보여준다(빨강 아님).
        DATA(diff) = row-eta - sy-datum.
        IF diff < 0.
          row-due_key = 'T'.
          row-due_text = '입고 처리 대기'.
        ELSEIF diff = 0.
          row-due_key = 'T'.
          row-due_text = '오늘 도착예정'.
        ELSE.
          row-due_key = 'F'.
          row-due_text = |{ diff }일 남음|.
        ENDIF.
      ENDIF.
    ELSE.
      row-due_key = 'C'.
      row-due_text = '-'.
    ENDIF.
    " 신호등: 초록 입고완료 / 노랑 예약중·이동중 / 빨강 취소
    CASE row-state_key.
      WHEN 'C'.
        row-signal = icon_led_green.
      WHEN 'V'.
        row-signal = icon_led_red.
      WHEN OTHERS.
        row-signal = icon_led_yellow.
    ENDCASE.
    PERFORM material_name USING row-matnr CHANGING row-maktx.
    PERFORM plant_name USING row-reswk CHANGING row-src_name.
    PERFORM plant_name USING row-werks CHANGING row-dst_name.
    " 방금 생성한 STO: 목록 맨 위 + 파란 줄([조회]·다음 생성 전까지) + 행 선택 1회. 별도 '신규' 열은 없다.
    READ TABLE gt_new_sto TRANSPORTING NO FIELDS WITH TABLE KEY table_line = row-ebeln.
    IF sy-subrc = 0.
      row-is_new = abap_true.
      row-rowclr = 'C410'.
    ENDIF.
    APPEND row TO gt_list.
  ENDLOOP.
  " 기본정렬: 방금 생성한 STO → 이동중(도착예정일 빠른 순) → 입고완료 → 취소
  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<rank_sto>).
    <rank_sto>-sort_rank = SWITCH #( <rank_sto>-state_key WHEN 'M' OR 'R' THEN 1 WHEN 'C' THEN 2 ELSE 3 ).
  ENDLOOP.
  SORT gt_list BY is_new DESCENDING sort_rank eta ebeln ebelp.
  " 카드 건수는 상태 조건 적용 전(gt_summary), ALV는 카드로 고른 상태만 보여준다.
  gt_summary = gt_list.
  gv_key1 = |{ p_sfrom }/{ p_sto }/{ p_mat }/{ p_doc }/{ p_dfrom }/{ p_dto }|.   " 카드(p_state·p_due)는 조회조건 아님
  IF gt_summary IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.   " 조회 조건에 해당하는 데이터가 없습니다
  ENDIF.
  PERFORM filter_list.
ENDFORM.

" filter_list : 마지막 조회 결과(gt_summary)에서 카드로 고른 상태만 ALV에 남긴다. DB를 읽지 않는다.
"   방금 생성한 STO는 카드와 관계없이 보이고, 'M' 카드(예약·이동)는 예약중(R)과 이동중(M)을 함께 보여준다.
FORM filter_list.
  gt_list = gt_summary.
  IF p_state = 'M'.
    DELETE gt_list WHERE state_key <> 'M' AND state_key <> 'R' AND is_new = abap_false.
  ELSEIF p_state IS NOT INITIAL AND p_state <> 'A'.
    DELETE gt_list WHERE state_key <> p_state AND is_new = abap_false.
  ENDIF.
  IF p_due IS NOT INITIAL AND p_due <> 'A'.
    DELETE gt_list WHERE due_key <> p_due AND is_new = abap_false.
  ENDIF.
  " 선택 문서가 목록에서 빠지면 아래 이력도 비운다.
  IF gs_detail-ebeln IS NOT INITIAL.
    READ TABLE gt_list TRANSPORTING NO FIELDS
      WITH KEY ebeln = gs_detail-ebeln ebelp = gs_detail-ebelp.
    IF sy-subrc = 0.
      DATA selected_index TYPE i.
      selected_index = sy-tabix.
      PERFORM show_detail USING selected_index.
    ELSE.
      CLEAR: gs_detail, gt_hist.
      PERFORM display_history.
    ENDIF.
  ENDIF.
  IF go_list IS BOUND.
    DATA catalog TYPE lvc_t_fcat.
    go_list->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = catalog ).
    PERFORM quantity_catalog USING gt_list CHANGING catalog.
    go_list->set_frontend_fieldcatalog( it_fieldcatalog = catalog ).
    DATA list_title TYPE lvc_title.
    PERFORM list_title CHANGING list_title.
    go_list->set_gridtitle( i_gridtitle = list_title ).
    go_list->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
    PERFORM select_new_rows.
  ENDIF.
ENDFORM.

" list_title : ALV 제목(목록 이름 · 건수).
FORM list_title CHANGING cv_title TYPE lvc_title.
  cv_title = |STO 목록 · { lines( gt_list ) }건|.
ENDFORM.

" list_filter_changed : 조회조건이 마지막 조회와 달라졌는지 본다.
FORM list_filter_changed CHANGING cv_changed TYPE abap_bool.
  DATA(lv_now) = |{ p_sfrom }/{ p_sto }/{ p_mat }/{ p_doc }/{ p_dfrom }/{ p_dto }|.
  cv_changed = xsdbool( lv_now <> gv_key1 ).
ENDFORM.

" select_new_rows : 방금 생성한 STO 행을 선택 상태로 보여준다(한 번만).
FORM select_new_rows.
  IF go_list IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA lt_rows TYPE lvc_t_row.
  IF gv_mark_new = abap_true.
    LOOP AT gt_list TRANSPORTING NO FIELDS WHERE is_new = abap_true.
      APPEND VALUE #( index = sy-tabix ) TO lt_rows.
    ENDLOOP.
    CLEAR gv_mark_new.
  ENDIF.
  go_list->set_selected_rows( it_index_rows = lt_rows ).
ENDFORM.

" display_list : 0100 목록 ALV(위)와 이력 ALV(아래)를 처음 한 번 만든다.
FORM display_list.
  IF go_list IS BOUND.
    RETURN.
  ENDIF.
  CREATE OBJECT go_main EXPORTING container_name = 'CC_MAIN'
    EXCEPTIONS cntl_error = 1 cntl_system_error = 2 create_error = 3 lifetime_error = 4
      lifetime_dynpro_dynpro_link = 5 OTHERS = 6.
  IF sy-subrc <> 0.
    MESSAGE s120(z8_msg) DISPLAY LIKE 'E' WITH 'STO 목록'.   " STO 목록 ALV를 그리는데 실패했습니다(0100 CC_MAIN 확인)
    FREE go_main.
    RETURN.
  ENDIF.
  " 같은 화면 안의 두 영역을 나눈다. 새 상세화면으로 이동하지 않는다.
  CREATE OBJECT go_split EXPORTING parent = go_main rows = 2 columns = 1.
  go_listc = go_split->get_container( row = 1 column = 1 ).
  go_histc = go_split->get_container( row = 2 column = 1 ).
  go_split->set_row_height( id = 1 height = 65 ).
  CREATE OBJECT go_list EXPORTING i_parent = go_listc.
  SET HANDLER go_events->double_click FOR go_list.
  DATA catalog TYPE lvc_t_fcat.
  PERFORM add_column USING 'SIGNAL' `상태` 4 CHANGING catalog.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM add_column USING 'STATE' `처리상태` 8 CHANGING catalog.
  PERFORM add_column USING 'EBELN' `STO 번호` 10 CHANGING catalog.
  PERFORM add_column USING 'EBELP' `품목` 5 CHANGING catalog.     " STO 1건에 자재 여러 개
  PERFORM add_column USING 'MATNR' `자재번호` 12 CHANGING catalog.
  PERFORM add_column USING 'MAKTX' `자재명` 18 CHANGING catalog.
  PERFORM add_column USING 'MENGE' `이동수량` 8 CHANGING catalog.
  PERFORM add_column USING 'MEINS' `단위` 4 CHANGING catalog.
  PERFORM add_column USING 'SRC_NAME' `출발지사` 10 CHANGING catalog.
  PERFORM add_column USING 'RESWK' `출발플랜트` 6 CHANGING catalog.
  PERFORM add_column USING 'DST_NAME' `도착지사` 10 CHANGING catalog.
  PERFORM add_column USING 'WERKS' `도착플랜트` 6 CHANGING catalog.
  PERFORM add_column USING 'DEP_DATE' `출고일` 10 CHANGING catalog.
  PERFORM add_column USING 'ETA' `예상도착일` 10 CHANGING catalog.
  PERFORM add_column USING 'GR_DATE' `실제입고일` 10 CHANGING catalog.
  PERFORM add_column USING 'DUE_TEXT' `도착 일정` 14 CHANGING catalog.
  " STO 번호 핫스팟은 쓰지 않는다. 행 더블클릭으로 아래 이력을 본다.
  DATA list_title TYPE lvc_title.
  PERFORM list_title CHANGING list_title.
  " 줄 색은 방금 생성한 STO(파란 줄)에만 쓴다. 위쪽 버튼줄 없음(정렬은 머리글 오른쪽 클릭).
  DATA(layout) = VALUE lvc_s_layo( no_toolbar = abap_false zebra = abap_true cwidth_opt = abap_false
    sel_mode = 'A' info_fname = 'ROWCLR' smalltitle = abap_true grid_title = list_title ).
  DATA excluded TYPE ui_functions.
  PERFORM toolbar_excluded CHANGING excluded.
  PERFORM quantity_catalog USING gt_list CHANGING catalog.
  go_list->set_table_for_first_display( EXPORTING is_layout = layout it_toolbar_excluding = excluded
    CHANGING it_outtab = gt_list it_fieldcatalog = catalog ).
  PERFORM select_new_rows.
  PERFORM display_history.
ENDFORM.

" ------------------------------------------------------------
" 화면 0200 : 지사 간 이동 입력 → 재고·일정 확인 → 저장(STO 생성 + 351 출고)
" ------------------------------------------------------------

" start_entry : 0100의 [STO 생성]. 입력화면을 열고, 돌아오면 목록을 다시 읽는다.
FORM start_entry.
  " 새로 만든 STO만 파란 줄 + 한 번 선택(이전 파란 줄은 정리).
  "   파란 줄은 [조회] 버튼을 누르거나 다시 STO를 만들 때까지 유지(Enter·카드 클릭에도 유지).
  CLEAR: gt_new_sto, gv_mark_new.
  PERFORM reset_entry.
  CALL SCREEN 0200.
  gv_mark_new = xsdbool( gt_new_sto IS NOT INITIAL ).
  PERFORM query_list.
ENDFORM.

" reset_entry : 새 이동 입력을 준비한다. 이전 출고 문서는 그대로 둔다.
FORM reset_entry.
  CLEAR: gt_entry, gv_checked, gv_stamp, gv_auto_stamp, gv_posted, p_eta, p_want, gv_nship.
  p_date = sy-datum.
  p_floc = '0001'.
  p_tloc = '0001'.
  " 출발 플랜트 기본값: PUR에서 넘긴 담당 지사 → 조회조건의 출발 플랜트 순서
  IF p_purwk IS NOT INITIAL.
    p_from = p_purwk.
  ELSEIF p_sfrom IS NOT INITIAL.
    p_from = p_sfrom.
  ENDIF.
  IF p_sto IS NOT INITIAL.
    p_to = p_sto.
  ENDIF.
  " PR 생성에서 넘어온 경우: 도착 플랜트·자재·수량을 채우고 바로 재고·일정 확인(한 번만)
  IF p_purto IS NOT INITIAL.
    p_to = p_purto.
  ENDIF.
  IF p_purmat IS NOT INITIAL.
    APPEND VALUE #( matnr = p_purmat menge = p_purqty ) TO gt_entry.
    p_want = p_purdt.                  " PR 희망납기일을 도착희망일로(빠르면 calc_schedule이 조정)
    CLEAR: p_purto, p_purmat, p_purqty, p_purdt.
    PERFORM preview_entries.
    RETURN.
  ENDIF.
  PERFORM calc_schedule.                 " 플랜트가 정해져 있으면 도착희망일 기본값(가장 빠른 도착)
  APPEND INITIAL LINE TO gt_entry.
ENDFORM.

" entry_header_locked : 출발/도착 플랜트 잠금 여부. 화면 표시·F4 제어 전용, DB 변경 없음.
" 잠금 = 자재번호가 들어간 행이 1건 이상 AND 출발·도착이 둘 다 등록된 플랜트이며 서로 다름.
" 플랜트가 비었거나 잘못된 상태에서 자재부터 넣은 경우에는 잠그지 않아 플랜트를 고칠 수 있게 둔다.
FORM entry_header_locked CHANGING cv_lock TYPE abap_bool.
  cv_lock = abap_false.
  " STO를 생성(저장)한 뒤에만 잠근다. 자재를 입력하는 중에는 플랜트를 바꿀 수 있고,
  "   바꾸면 입력한 자재를 새 플랜트 기준으로 다시 검사한다(entry_stamp에 플랜트 포함).
  IF gv_posted = abap_true.
    cv_lock = abap_true.
  ENDIF.
ENDFORM.

" add_entry_row : [자재 추가]. 출발/도착 플랜트가 정상일 때만 빈 입력행을 추가한다.
FORM add_entry_row.
  IF p_from IS INITIAL OR p_to IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '출발·도착 플랜트'.   " &1를 입력해주세요
    RETURN.
  ENDIF.
  IF p_from = p_to.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '출발과 다른 도착 플랜트'.   " 출발과 다른 도착 플랜트를 입력해주세요
    RETURN.
  ENDIF.
  SELECT COUNT(*) FROM z8plant_m WHERE werks = @p_from OR werks = @p_to INTO @DATA(lv_cnt).
  IF lv_cnt <> 2.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '등록된 플랜트'.   " 등록된 플랜트를 입력해주세요
    RETURN.
  ENDIF.
  APPEND INITIAL LINE TO gt_entry.
  CLEAR: gv_checked, gv_stamp, p_eta.
  PERFORM auto_entry.
  PERFORM refresh_entry.
ENDFORM.

" goto_list : 0200 → STO 목록. 0100에서 왔으면 0100으로 돌아가고,
" PUR에서 바로 왔으면 0200 자리를 0100으로 바꾼다(0100에서 뒤로 누르면 PUR).
FORM goto_list.
  PERFORM leave_entry.
  p_state = 'A'.
  p_due = 'A'.
  " 방금 만든 STO가 조회조건에 걸려 안 보이는 일이 없도록 조건을 넓힌다.
  IF gt_new_sto IS NOT INITIAL.
    CLEAR: p_doc, p_mat.
    IF p_sfrom IS NOT INITIAL AND p_sfrom <> p_from.
      CLEAR p_sfrom.
    ENDIF.
    IF p_sto IS NOT INITIAL AND p_sto <> p_to.
      CLEAR p_sto.
    ENDIF.
    IF p_dto IS NOT INITIAL AND p_dto < p_date.
      p_dto = p_date.                    " 예약 STO(출고일 미래)도 목록에 보이게
    ENDIF.
    IF p_dfrom IS INITIAL OR p_dfrom > sy-datum.
      p_dfrom = sy-datum.               " 시작일 필수 규칙: 비우지 않고 오늘로
    ENDIF.
  ENDIF.
  IF gv_direct = abap_true.
    gv_direct = abap_false.
    gv_mark_new = xsdbool( gt_new_sto IS NOT INITIAL ).
    PERFORM query_list.
    LEAVE TO SCREEN 0100.
  ELSE.
    " start_entry 의 CALL SCREEN 0200 다음 줄(재조회)로 돌아간다.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.

" display_entry : 0200 입력 ALV를 만들고 편집·F4·입력 이벤트를 설정한다.
FORM display_entry.
  IF go_items IS BOUND.
    RETURN.
  ENDIF.
  " SE51 0200에 커스텀컨트롤 CC_ITEMS가 없으면 ALV가 안 보이므로 바로 알려준다.
  CREATE OBJECT go_itemc EXPORTING container_name = 'CC_ITEMS'
    EXCEPTIONS cntl_error = 1 cntl_system_error = 2 create_error = 3 lifetime_error = 4
      lifetime_dynpro_dynpro_link = 5 OTHERS = 6.
  IF sy-subrc <> 0.
    MESSAGE s120(z8_msg) DISPLAY LIKE 'E' WITH 'STO 입력'.   " STO 입력 ALV를 그리는데 실패했습니다(0200 CC_ITEMS 확인)
    FREE go_itemc.
    RETURN.
  ENDIF.
  CREATE OBJECT go_items EXPORTING i_parent = go_itemc.
  SET HANDLER go_events->material_f4 go_events->entry_changed go_events->entry_finished FOR go_items.
  DATA catalog TYPE lvc_t_fcat.
  PERFORM add_column USING 'SIGNAL' `상태` 4 CHANGING catalog.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM add_column USING 'RESULT' `처리결과` 9 CHANGING catalog.
  PERFORM add_column USING 'MATNR' `자재번호` 12 CHANGING catalog.
  PERFORM add_column USING 'MAKTX' `자재명` 18 CHANGING catalog.
  PERFORM add_column USING 'MENGE' `이동수량` 8 CHANGING catalog.
  PERFORM add_column USING 'MEINS' `단위` 4 CHANGING catalog.
  PERFORM add_column USING 'MOVABLE' `이동가능` 9 CHANGING catalog.
  PERFORM add_column USING 'SRC_QTY' `출발지 재고` 9 CHANGING catalog.
  PERFORM add_column USING 'DST_QTY' `도착지 재고` 9 CHANGING catalog.
  PERFORM add_column USING 'EBELN' `생성 STO` 10 CHANGING catalog.
  PERFORM add_column USING 'DETAIL' `안내` 30 CHANGING catalog.
  PERFORM add_column USING 'QTY_UNIT' `표시단위` 0 CHANGING catalog.   " 폭 0 = 숨김
  LOOP AT catalog ASSIGNING FIELD-SYMBOL(<fc>).
    CASE <fc>-fieldname.
      WHEN 'MATNR'.
        <fc>-edit = abap_true.
        <fc>-f4availabl = abap_true.
        <fc>-emphasize = 'C300'.        " 직접 입력 열(연노랑) — PR 입력과 같은 표시
      WHEN 'MENGE'.
        <fc>-edit = abap_true.
        <fc>-emphasize = 'C300'.
      WHEN 'QTY_UNIT'.
        <fc>-ref_table = 'Z8MM_PO_I'.
        <fc>-ref_field = 'MEINS'.
    ENDCASE.
    " 입력 ALV 수량은 숨김 단위 QTY_UNIT을 참조한다. 자재보다 수량을 먼저 적으면 MEINS가 비어
    "   5.000처럼 보이므로, QTY_UNIT에는 자재 단위(없으면 EA)를 넣어 소수점 없이 보이게 한다(entry_signals).
    IF <fc>-qfieldname = 'MEINS'.
      <fc>-qfieldname = 'QTY_UNIT'.
    ENDIF.
  ENDLOOP.
  PERFORM entry_signals.
  DATA layout TYPE lvc_s_layo.
  layout = VALUE #( zebra = abap_true cwidth_opt = abap_false sel_mode = 'D' no_toolbar = abap_false
    stylefname = 'CELLSTYLE' smalltitle = abap_true
    grid_title = '이동 자재 입력' ).
  DATA excluded TYPE ui_functions.
  PERFORM toolbar_excluded CHANGING excluded.
  PERFORM quantity_catalog USING gt_entry CHANGING catalog.
  go_items->set_table_for_first_display( EXPORTING is_layout = layout it_toolbar_excluding = excluded
    CHANGING it_outtab = gt_entry it_fieldcatalog = catalog ).
  DATA f4 TYPE lvc_t_f4.
  f4 = VALUE #( ( fieldname = 'MATNR' register = abap_true getbefore = abap_true chngeafter = abap_true ) ).
  go_items->register_f4_for_fields( it_f4 = f4 ).
  go_items->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
  go_items->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
  go_items->set_ready_for_input( i_ready_for_input = 1 ).
ENDFORM.

" entry_signals : 입력행의 신호등를 처리결과에 맞춘다. 화면 표시용이다.
FORM entry_signals.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<sig>).
    " 수량 표시용 단위: 자재 단위가 정해지기 전에는 EA로 표시해 5.000처럼 보이지 않게 한다.
    <sig>-qty_unit = COND #( WHEN <sig>-meins IS NOT INITIAL THEN <sig>-meins ELSE 'EA' ).
    CLEAR <sig>-signal.
    CASE <sig>-result.
      WHEN '출고 가능' OR '출고 완료' OR '예약 가능' OR '예약 완료'.
        <sig>-signal = icon_led_green.
      WHEN '확인 필요' OR '저장 실패'.
        <sig>-signal = icon_led_red.
      WHEN OTHERS.
        IF <sig>-matnr IS NOT INITIAL OR <sig>-menge <> 0.
          <sig>-signal = icon_led_yellow.
        ENDIF.
    ENDCASE.
  ENDLOOP.
ENDFORM.

" refresh_entry : 입력 내부테이블의 최신 값을 ALV에 다시 표시한다.
FORM refresh_entry.
  PERFORM entry_signals.
  IF go_items IS BOUND.
    DATA catalog TYPE lvc_t_fcat.
    go_items->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = catalog ).
    PERFORM quantity_catalog USING gt_entry CHANGING catalog.
    go_items->set_frontend_fieldcatalog( it_fieldcatalog = catalog ).
    go_items->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  ENDIF.
ENDFORM.

" entry_stamp : 플랜트·창고·날짜·미저장 자재수량을 한 문자열로 기억한다.
FORM entry_stamp CHANGING stamp TYPE string.
  stamp = |{ p_from }/{ p_floc }/{ p_to }/{ p_tloc }/{ p_date }|.
  LOOP AT gt_entry INTO DATA(row) WHERE ebeln IS INITIAL.
    stamp = |{ stamp };{ row-matnr }={ row-menge NUMBER = RAW }|.
  ENDLOOP.
ENDFORM.

" invalidate_if_changed : 확인 이후 입력이 바뀌면 이전 확인결과를 무효화한다.
FORM invalidate_if_changed.
  IF gv_checked <> abap_true.
    RETURN.
  ENDIF.
  DATA stamp TYPE string.
  PERFORM entry_stamp CHANGING stamp.
  IF stamp = gv_stamp.
    RETURN.
  ENDIF.
  CLEAR: gv_checked, gv_stamp, p_eta.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<row>) WHERE ebeln IS INITIAL.
    CLEAR: <row>-src_qty, <row>-movable, <row>-dst_qty, <row>-transit.
    <row>-result = '재확인 필요'.
    CLEAR <row>-detail.
  ENDLOOP.
  PERFORM refresh_entry.
ENDFORM.

" preview_entries : 자재별 재고·운송일정을 검사한다(DB 변경 없음). 같은 자재 합계도 확인한다.
FORM preview_entries.
  PERFORM calc_schedule.                 " 출고일·예상도착일을 최신 입력으로 다시 계산
  CLEAR: gv_checked, gv_stamp, p_eta.
  DATA all_ok TYPE abap_bool VALUE abap_true.
  DATA: pending TYPE i, bad TYPE i, incomplete TYPE i.
  DATA total_qty TYPE z8mm_po_i-menge.
  IF p_from IS INITIAL OR p_to IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '출발·도착 플랜트'.   " &1를 입력해주세요
    RETURN.
  ENDIF.
  IF p_from = p_to.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '출발과 다른 도착 플랜트'.   " 출발과 다른 도착 플랜트를 입력해주세요
    RETURN.
  ENDIF.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<row>) WHERE ebeln IS INITIAL.
    IF <row>-matnr IS INITIAL AND <row>-menge = 0.
      CONTINUE.
    ENDIF.
    pending = pending + 1.
    CLEAR: <row>-src_qty, <row>-movable,
      <row>-dst_qty, <row>-transit, <row>-detail.
    PERFORM entry_names CHANGING <row>.
    PERFORM entry_stock CHANGING <row>.
    " 아직 입력 중인 행(자재 또는 수량만 있음)은 오류로 보지 않는다.
    "   빨간불·상태줄 경고 없이 노란불 + 안내 칸에 남은 입력만 알려준다. 저장 때만 막는다.
    IF <row>-matnr IS INITIAL OR <row>-menge <= 0.
      incomplete = incomplete + 1.
      CLEAR <row>-result.
      <row>-detail = COND #( WHEN <row>-matnr IS INITIAL THEN '자재번호를 입력하세요.'
                             ELSE '이동수량을 입력하세요.' ).
      CONTINUE.
    ENDIF.
    <row>-result = '확인 중'.
    TRY.
      DATA(item) = VALUE z8mm_po_i( matnr = <row>-matnr menge = <row>-menge
        reswk = p_from reslo = p_floc werks = p_to lgort = p_tloc sto_dep_date = p_date ).
      DATA(check) = lcl_mm_sto=>preview_sto( item ).
      <row>-meins = check-source-meins.
      <row>-src_qty = check-source-labst.
      <row>-movable = check-movable.
      <row>-dst_qty = check-dest-labst.
      <row>-transit = check-dest-umlme.
      CLEAR total_qty.
      LOOP AT gt_entry INTO DATA(other) WHERE ebeln IS INITIAL AND matnr = <row>-matnr.
        total_qty = total_qty + other-menge.
      ENDLOOP.
      IF total_qty > check-movable.
        lcl_mm_common=>fail( `이동가능수량보다 많습니다.` ).
      ENDIF.
      p_eta = check-arrival.
      <row>-result = COND #( WHEN p_date > sy-datum THEN '예약 가능' ELSE '출고 가능' ).
      CLEAR <row>-detail.               " 안내 간단히(예상도착일은 위 칸에 표시)
    CATCH lcx_mm INTO DATA(error).
      all_ok = abap_false.
      bad = bad + 1.
      <row>-result = '확인 필요'.
      PERFORM short_reason USING error->detail CHANGING <row>-detail.
    CATCH cx_root INTO DATA(unexpected).
      all_ok = abap_false.
      bad = bad + 1.
      <row>-result = '확인 필요'.
      <row>-detail = unexpected->get_text( ).
    ENDTRY.
  ENDLOOP.
  IF pending = 0.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '이동할 자재'.   " &1를 입력해주세요
  ELSEIF all_ok = abap_true AND incomplete > 0.
    " 입력 중인 행이 있으면 메시지 없이 기다린다(저장 가능 상태는 아님).
  ELSEIF all_ok = abap_true.
    gv_checked = abap_true.
    PERFORM entry_stamp CHANGING gv_stamp.
    " 정상이면 메시지 없이 행의 처리 결과('예약 가능'/'출고 가능')와 오른쪽 일정 안내로 보여준다.
  ELSE.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'W' WITH '정확한 데이터'.   " 정확한 데이터를 입력해주세요
  ENDIF.
  PERFORM entry_stamp CHANGING gv_auto_stamp.
  PERFORM refresh_entry.
ENDFORM.

" short_reason : 공통 검사의 긴 오류문을 "무엇이 문제인지" 한 줄로 바꾼다. 표시 전용이다.
FORM short_reason USING iv_text TYPE clike CHANGING cv_detail TYPE clike.
  DATA(lv_text) = CONV string( iv_text ).
  IF lv_text CS '저장위치 기준정보'.
    cv_detail = '출발 또는 도착 지사에 등록되지 않은 자재입니다.'.
  ELSEIF lv_text CS '루트'.
    cv_detail = '출발→도착 운송 경로(루트)가 없습니다.'.
  ELSEIF lv_text CS '재고 수량 또는 기본단위'.
    cv_detail = '재고 단위가 자재 단위와 다릅니다.'.
  ELSEIF lv_text CS '자재 기본단위' OR lv_text CS '자재 마스터'.
    cv_detail = '등록되지 않은 자재번호입니다.'.
  ELSE.
    cv_detail = lv_text.
  ENDIF.
ENDFORM.

" save_entries : 미저장 행별로 STO 생성 + 351 출고. 모두 성공하면 STO 목록으로 가서 새 STO를 선택해 보여준다.
" 저장 확정: 공통 저장 호출 성공 후 COMMIT, 오류 시 CATCH에서 ROLLBACK한다.
FORM save_entries.
  DATA current_stamp TYPE string.
  PERFORM entry_stamp CHANGING current_stamp.
  " 입력 중인 행(자재 또는 수량 빠짐)이 있으면 무엇을 넣어야 하는지 알려준다.
  LOOP AT gt_entry INTO DATA(ls_part) WHERE ebeln IS INITIAL
    AND ( ( matnr IS INITIAL AND menge <> 0 ) OR ( matnr IS NOT INITIAL AND menge <= 0 ) ).
    IF ls_part-matnr IS INITIAL.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '자재번호'.   " &1를 입력해주세요
    ELSE.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '이동수량'.   " &1를 입력해주세요
    ENDIF.
    RETURN.
  ENDLOOP.
  IF gv_checked <> abap_true OR current_stamp <> gv_stamp OR p_date < sy-datum.
    CLEAR gv_checked.
    MESSAGE s054(z8_msg) DISPLAY LIKE 'E'.   " 데이터를 저장하지 못했습니다(확인 필요 행 있음)
    RETURN.
  ENDIF.
  DATA lv_cnt TYPE i.
  LOOP AT gt_entry TRANSPORTING NO FIELDS WHERE ebeln IS INITIAL AND matnr IS NOT INITIAL.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.
  DATA question TYPE c LENGTH 200.
  " 출고일이 미래면 예약, 오늘이면 바로 출고
  DATA(lv_reserve) = xsdbool( p_date > sy-datum ).
  IF lv_reserve = abap_true.
    question = |STO 1건(자재 { lv_cnt }개)을 예약합니다. { p_date DATE = USER } 출고 예정 · { p_want DATE = USER } 도착 예정. 진행할까요?|.
  ELSE.
    question = |STO 1건(자재 { lv_cnt }개)을 생성하고 바로 출고합니다. 진행할까요?|.
  ENDIF.
  DATA answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = COND string( WHEN lv_reserve = abap_true THEN `STO 예약` ELSE `STO 생성·출고` )
    text_question = question
    text_button_1 = '예' text_button_2 = '아니오' default_button = '2'
    display_cancel_button = space
    IMPORTING answer = answer EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR answer <> '1'.
    RETURN.
  ENDIF.
  " 행별 저장을 시작하기 전에 DB 변경 없는 전체 미리보기를 다시 수행한다.
  PERFORM preview_entries.
  IF gv_checked <> abap_true.
    RETURN.
  ENDIF.
  " 미저장 행 전체를 STO 1건(품목 10·20·30…)으로 한 번에 저장한다.
  "   351 출고 자재문서도 1건(N줄). 하나라도 실패하면 전체 ROLLBACK → 반쪽 STO가 생기지 않는다.
  DATA items TYPE lcl_mm_common=>ty_items.
  LOOP AT gt_entry INTO DATA(save_row) WHERE ebeln IS INITIAL AND matnr IS NOT INITIAL.
    APPEND VALUE #( matnr = save_row-matnr menge = save_row-menge meins = save_row-meins
      reswk = p_from reslo = p_floc werks = p_to lgort = p_tloc sto_dep_date = p_date
      lfdat = p_want ) TO items.   " LFDAT = 도착희망일
  ENDLOOP.
  DATA document TYPE z8mm_po_h-ebeln.
  DATA lv_error TYPE string.
  TRY.
      " 저장 직전에 잠금을 확보한다. 성공·실패 모두 unlock으로 해제해야 한다.
      lcl_mm_common=>lock( ).
      document = lcl_mm_sto=>create_sto( items = items expected_arrival = p_eta ).
      COMMIT WORK AND WAIT.
      lcl_mm_common=>unlock( ).
    CATCH lcx_mm INTO DATA(error).
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      lv_error = error->detail.
    CATCH cx_root INTO DATA(unexpected).
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      lv_error = unexpected->get_text( ).
  ENDTRY.
  CLEAR: gv_checked, gv_stamp.
  IF lv_error IS NOT INITIAL.
    " 오류 메시지 앞의 자재번호(예: 'PANEL01: …')로 문제 행만 빨강, 나머지는 '저장 안 됨'으로 표시한다.
    LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<fail>) WHERE ebeln IS INITIAL AND matnr IS NOT INITIAL.
      IF lv_error CS |{ <fail>-matnr }:|.
        <fail>-result = '저장 실패'.
        PERFORM short_reason USING lv_error CHANGING <fail>-detail.
      ELSE.
        <fail>-result = '저장 안 됨'.
        <fail>-detail = '다른 자재 오류로 STO 전체를 저장하지 않았습니다.'.
      ENDIF.
    ENDLOOP.
    READ TABLE gt_entry TRANSPORTING NO FIELDS WITH KEY result = '저장 실패'.
    IF sy-subrc <> 0.
      " 특정 자재가 아닌 공통 오류(운송일수 변경 등)는 모든 행에 사유를 보여준다.
      LOOP AT gt_entry ASSIGNING <fail> WHERE ebeln IS INITIAL AND matnr IS NOT INITIAL.
        <fail>-result = '저장 실패'.
        PERFORM short_reason USING lv_error CHANGING <fail>-detail.
      ENDLOOP.
    ENDIF.
    MESSAGE s081(z8_msg) DISPLAY LIKE 'E' WITH 'STO'.   " STO 생성에 실패했습니다(사유는 행의 처리 안내)
    PERFORM refresh_entry.
    RETURN.
  ENDIF.
  LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<row>) WHERE ebeln IS INITIAL AND matnr IS NOT INITIAL.
    <row>-ebeln = document.
    <row>-result = COND #( WHEN lv_reserve = abap_true THEN '예약 완료' ELSE '출고 완료' ).
    CLEAR <row>-detail.                 " 생성 STO 번호는 '생성 STO' 열에 표시
    <row>-cellstyle = VALUE #( ( fieldname = 'MATNR' style = cl_gui_alv_grid=>mc_style_disabled )
      ( fieldname = 'MENGE' style = cl_gui_alv_grid=>mc_style_disabled ) ).
  ENDLOOP.
  INSERT document INTO TABLE gt_new_sto.
  gv_posted = abap_true.
  IF lv_reserve = abap_true.
    MESSAGE i133(z8_msg) WITH document '예약'.   " &1 &2 완료 (출고일에 배치가 출고)
  ELSE.
    MESSAGE i133(z8_msg) WITH document '생성·출고'.   " &1 &2 완료 (생성 완료는 팝업 I)
  ENDIF.
  PERFORM goto_list.
ENDFORM.

" delete_entries : 선택한 미저장 입력행만 지운다. 저장된 STO를 취소하는 기능이 아니다.
FORM delete_entries.
  DATA rows TYPE lvc_t_roid.
  go_items->get_selected_rows( IMPORTING et_row_no = rows ).
  IF rows IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  SORT rows BY row_id DESCENDING.
  DATA deleted TYPE i.
  LOOP AT rows INTO DATA(selected).
    READ TABLE gt_entry INDEX selected-row_id INTO DATA(row).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    IF row-ebeln IS NOT INITIAL.
      CONTINUE.
    ENDIF.
    DELETE gt_entry INDEX selected-row_id.
    deleted = deleted + 1.
  ENDLOOP.
  IF gt_entry IS INITIAL.
    APPEND INITIAL LINE TO gt_entry.
  ENDIF.
  " 미저장 행을 지웠으면 삭제 완료, 저장된 STO 행만 골랐으면(지운 행 없음) 다시 고르라고 알린다.
  IF deleted > 0.
    MESSAGE s204(z8_msg).   " 데이터를 삭제했습니다.
  ELSE.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
  ENDIF.
  CLEAR: gv_checked, gv_stamp, gv_auto_stamp, p_eta.
  PERFORM auto_entry.
  PERFORM refresh_entry.
ENDFORM.

" leave_entry : 입력화면을 떠날 때 ALV를 정리한다.
FORM leave_entry.
  IF go_items IS BOUND.
    go_items->free( ).
    FREE go_items.
  ENDIF.
  IF go_itemc IS BOUND.
    go_itemc->free( ).
    FREE go_itemc.
  ENDIF.
  CLEAR: gv_checked, gv_stamp.
ENDFORM.

" new_input : [초기화]. 입력 화면을 빈 상태로 돌린다(출발·도착 플랜트, 도착희망일, 자재 행 모두).
"   입력한 값이 하나라도 있으면 확인창([초기화] / [계속 작성])을 띄운다. 이미 저장한 STO는 그대로 둔다.
"   끝나면 상태줄에 "입력값 초기화 완료"를 띄운다.
FORM new_input.
  DATA has_pending TYPE abap_bool.
  IF p_from IS NOT INITIAL OR p_to IS NOT INITIAL OR p_want IS NOT INITIAL.
    has_pending = abap_true.
  ENDIF.
  LOOP AT gt_entry INTO DATA(pending_row) WHERE ebeln IS INITIAL.
    IF pending_row-matnr IS NOT INITIAL OR pending_row-menge <> 0.
      has_pending = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.
  IF has_pending = abap_true.
    DATA answer TYPE c LENGTH 1.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING titlebar = '초기화'
        text_question = '입력한 내용을 지우고 처음 상태로 돌릴까요? (저장된 STO는 그대로입니다)'
        text_button_1 = '초기화' text_button_2 = '계속 작성'
        default_button = '2' display_cancel_button = space
      IMPORTING answer = answer EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0 OR answer <> '1'.
      RETURN.
    ENDIF.
  ENDIF.
  PERFORM reset_entry.
  " reset_entry가 채우는 기본 플랜트(PUR 지사·조회조건)까지 비워 완전히 빈 입력 화면으로 둔다.
  CLEAR: p_purwk, p_from, p_to, p_want, p_eta, gv_nefr, gv_neto.
  gv_nship = '출발·도착 플랜트를 넣으면 출고일을 계산합니다.'.
  PERFORM refresh_entry.
  MESSAGE s133(z8_msg) WITH '입력값' '초기화'.   " &1 &2 완료 → 입력값 초기화 완료
ENDFORM.

" entry_names : 자재명·단위만 채운다(수량·일정 검사와 분리).
FORM entry_names CHANGING row TYPE ty_entry.
  CLEAR: row-maktx, row-meins.
  IF row-matnr IS INITIAL.
    RETURN.
  ENDIF.
  SELECT SINGLE meins FROM z8material_m WHERE matnr = @row-matnr INTO @row-meins.
  PERFORM material_name USING row-matnr CHANGING row-maktx.
ENDFORM.

" entry_stock : 수량이 미완성이어도 선택 지사의 재고를 보여준다. DB 변경 없음.
FORM entry_stock CHANGING row TYPE ty_entry.
  IF row-matnr IS INITIAL.
    RETURN.
  ENDIF.
  IF p_from IS NOT INITIAL.
    TRY.
      DATA(source) = lcl_mm_stock=>location(
        VALUE #( matnr = row-matnr werks = p_from lgort = p_floc ) ).
      row-src_qty = source-labst.
      SELECT SINGLE eisbe FROM z8matplant_m
        WHERE matnr = @row-matnr AND werks = @p_from AND lgort = @p_floc INTO @DATA(safety).
      IF sy-subrc = 0.
        row-movable = nmax( val1 = 0 val2 = source-labst - source-zzrsvqty - safety ).
      ENDIF.
    CATCH lcx_mm.
      " 전체 확인에서 사유를 안내한다.
    ENDTRY.
  ENDIF.
  IF p_to IS NOT INITIAL.
    TRY.
      DATA(dest) = lcl_mm_stock=>location(
        VALUE #( matnr = row-matnr werks = p_to lgort = p_tloc ) ).
      row-dst_qty = dest-labst.
      row-transit = dest-umlme.
    CATCH lcx_mm.
      " 전체 확인에서 사유를 안내한다.
    ENDTRY.
  ENDIF.
ENDFORM.

" auto_entry : Enter·셀 이동·F4 뒤 입력이 바뀌었으면 재고·일정을 다시 확인한다(저장 아님).
FORM auto_entry.
  DATA current TYPE string.
  PERFORM entry_stamp CHANGING current.
  IF current = gv_auto_stamp.
    RETURN.
  ENDIF.
  DATA has_input TYPE abap_bool.
  LOOP AT gt_entry TRANSPORTING NO FIELDS
    WHERE ebeln IS INITIAL AND ( matnr IS NOT INITIAL OR menge <> 0 ).
    has_input = abap_true.
    EXIT.
  ENDLOOP.
  IF has_input = abap_true.
    PERFORM preview_entries.
  ELSE.
    CLEAR: gv_checked, gv_stamp.
    " 저장 완료 후에는 예상도착일을 유지한다.
    IF gv_posted = abap_false.
      CLEAR p_eta.
    ENDIF.
    LOOP AT gt_entry ASSIGNING FIELD-SYMBOL(<row>) WHERE ebeln IS INITIAL.
      CLEAR: <row>-maktx, <row>-meins, <row>-src_qty, <row>-movable,
        <row>-dst_qty, <row>-transit, <row>-result, <row>-detail.
    ENDLOOP.
    gv_auto_stamp = current.
    PERFORM refresh_entry.
  ENDIF.
ENDFORM.

" ------------------------------------------------------------
" 0100 아래쪽 : 선택 STO의 출고·입고 이력
" ------------------------------------------------------------

" show_detail : STO 한 행의 이동이력과 관련 자재문서를 읽어 아래 이력 ALV에 보여준다.
FORM show_detail USING index TYPE i.
  READ TABLE gt_list INDEX index INTO gs_detail.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  CLEAR gt_hist.
  SELECT * FROM z8mm_sto_hist WHERE ebeln = @gs_detail-ebeln AND ebelp = @gs_detail-ebelp
    INTO CORRESPONDING FIELDS OF TABLE @gt_hist.
  LOOP AT gt_hist ASSIGNING FIELD-SYMBOL(<hist>).
    <hist>-origin = 'STO 이력'.
  ENDLOOP.
  " STO_HIST 이전에 만든 즉시출고 문서도 있으므로 자재문서도 함께 읽는다(조회만, 이력을 만들지 않음).
  DATA(ref_item) = CONV z8mm_matdoc_i-ref_item( gs_detail-ebelp ).
  SELECT i~mblnr, i~mjahr, i~zeile, i~bwart, i~menge, i~meins, h~budat
    FROM z8mm_matdoc_i AS i INNER JOIN z8mm_matdoc_h AS h
    ON h~mblnr = i~mblnr AND h~mjahr = i~mjahr
    WHERE i~zzreftype = '03' AND i~zzrefdoc = @gs_detail-ebeln AND i~ref_item = @ref_item
    INTO TABLE @DATA(movements).
  LOOP AT movements INTO DATA(move).
    DATA(belnr) = move-mblnr.          " 자재문서번호(타입이 같아 변환 불필요)
    DATA(buzei) = CONV z8mm_sto_hist-buzei( move-zeile ).
    READ TABLE gt_hist TRANSPORTING NO FIELDS WITH KEY gjahr = move-mjahr belnr = belnr buzei = buzei.
    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.
    APPEND VALUE #( ebeln = gs_detail-ebeln ebelp = gs_detail-ebelp gjahr = move-mjahr
      belnr = belnr buzei = buzei bwart = move-bwart budat = move-budat
      matnr = gs_detail-matnr reswk = gs_detail-reswk reslo = gs_detail-reslo
      werks = gs_detail-werks lgort = gs_detail-lgort menge = move-menge meins = move-meins
      origin = '기존 자재문서' ) TO gt_hist.
  ENDLOOP.
  LOOP AT gt_hist ASSIGNING <hist>.
    CASE <hist>-bwart.
      WHEN '351'.
        <hist>-action = '출발 창고 출고'.
        <hist>-bwart_txt = 'TF→운송중재고'.
      WHEN '101'.
        <hist>-action = '도착 창고 입고'.
        <hist>-bwart_txt = '운송중→입고'.
      WHEN '352'.
        <hist>-action = '출고 취소'.
        <hist>-bwart_txt = '351 취소'.
      WHEN '102'.
        <hist>-action = '입고 취소'.
        <hist>-bwart_txt = '101 취소'.
      WHEN 'RSV'.                         " 재고 이동 없음(예약재고만)
        <hist>-action = '출고 예약'.
        <hist>-bwart_txt = '예약재고 확보'.
      WHEN 'CAN'.
        <hist>-action = '예약 취소'.
        <hist>-bwart_txt = '예약재고 해제'.
      WHEN OTHERS.
        <hist>-action = '기타 이동'.
    ENDCASE.
  ENDLOOP.
  SORT gt_hist BY budat gjahr belnr buzei.
  PERFORM display_history.
ENDFORM.

" display_history : 출고·입고 이력을 아래 ALV에 연결한다.
FORM display_history.
  IF go_histc IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA history_title TYPE lvc_title.
  IF gs_detail-ebeln IS INITIAL.
    history_title = '출고·입고 이력 · 위 목록의 STO 번호를 누르세요'.
  ELSE.
    history_title = |{ gs_detail-ebeln } · { gs_detail-maktx } · { gs_detail-src_name } → { gs_detail-dst_name } · { gs_detail-state }|.
  ENDIF.
  IF go_hist IS BOUND.
    DATA current_catalog TYPE lvc_t_fcat.
    go_hist->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = current_catalog ).
    PERFORM quantity_catalog USING gt_hist CHANGING current_catalog.
    go_hist->set_frontend_fieldcatalog( it_fieldcatalog = current_catalog ).
    go_hist->set_gridtitle( i_gridtitle = history_title ).
    go_hist->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
    RETURN.
  ENDIF.
  CREATE OBJECT go_hist EXPORTING i_parent = go_histc.
  DATA catalog TYPE lvc_t_fcat.
  PERFORM add_column USING 'BUDAT' `처리일` 10 CHANGING catalog.
  PERFORM add_column USING 'ACTION' `처리내용` 14 CHANGING catalog.
  PERFORM add_column USING 'BWART' `이동유형` 6 CHANGING catalog.
  PERFORM add_column USING 'BWART_TXT' `이동유형 설명` 14 CHANGING catalog.
  PERFORM add_column USING 'MENGE' `처리수량` 8 CHANGING catalog.
  PERFORM add_column USING 'MEINS' `단위` 4 CHANGING catalog.
  PERFORM add_column USING 'BELNR' `자재문서` 10 CHANGING catalog.
  PERFORM add_column USING 'GJAHR' `연도` 5 CHANGING catalog.
  PERFORM add_column USING 'ERNAM' `처리자` 10 CHANGING catalog.
  PERFORM add_column USING 'ORIGIN' `이력 출처` 12 CHANGING catalog.
  DATA(layout) = VALUE lvc_s_layo( zebra = abap_true cwidth_opt = abap_false
    no_toolbar = abap_false smalltitle = abap_true grid_title = history_title ).
  DATA excluded TYPE ui_functions.
  PERFORM toolbar_excluded CHANGING excluded.
  PERFORM quantity_catalog USING gt_hist CHANGING catalog.
  go_hist->set_table_for_first_display( EXPORTING is_layout = layout it_toolbar_excluding = excluded
    CHANGING it_outtab = gt_hist it_fieldcatalog = catalog ).
ENDFORM.

" ------------------------------------------------------------
" 0100 오른쪽 상태카드 (PO와 같은 모양, 카드 3개, 아래 설명 문구 없음)
" ------------------------------------------------------------

" show_cards : 상태별 STO 품목 건수를 카드로 보여준다. 건수가 같으면 다시 그리지 않는다.
FORM show_cards.
  " 카드 4장: 전체 / 예약·이동(마우스를 올리면 '예약 N · 이동 M') / 입고완료 / 취소
  DATA: lv_all TYPE i, lv_move TYPE i, lv_rsv TYPE i, lv_done TYPE i, lv_void TYPE i.
  lv_all = lines( gt_summary ).
  LOOP AT gt_summary INTO DATA(ls_card_row).
    CASE ls_card_row-state_key.
      WHEN 'M'.
        lv_move = lv_move + 1.
      WHEN 'R'.
        lv_rsv = lv_rsv + 1.
      WHEN 'C'.
        lv_done = lv_done + 1.
      WHEN 'V'.
        lv_void = lv_void + 1.
    ENDCASE.
  ENDLOOP.
  DATA lv_active TYPE c LENGTH 1.
  IF p_state = 'M' OR p_state = 'C' OR p_state = 'V'.
    lv_active = p_state.
  ELSE.
    lv_active = 'A'.
  ENDIF.
  DATA(lv_stamp) = |{ lv_all }/{ lv_move }/{ lv_rsv }/{ lv_done }/{ lv_void }/{ lv_active }|.
  IF go_summary IS BOUND AND lv_stamp = gv_summary_stamp.
    RETURN.
  ENDIF.
  IF go_summary_box IS NOT BOUND.
    CREATE OBJECT go_summary_box EXPORTING container_name = 'CC_SUM' EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_summary IS NOT BOUND.
    CREATE OBJECT go_summary EXPORTING parent = go_summary_box EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CREATE OBJECT go_summary_events.
    SET HANDLER go_summary_events->on_click FOR go_summary.
    DATA lt_events TYPE cntl_simple_events.
    lt_events = VALUE #( ( eventid = cl_gui_html_viewer=>m_id_sapevent appl_event = abap_false ) ).
    go_summary->set_registered_events( EXPORTING events = lt_events EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  " 한글은 HTML 문자참조로 넣어 GUI 코드페이지와 무관하게 표시한다.
  DATA lt_html TYPE STANDARD TABLE OF w3html WITH EMPTY KEY.
  APPEND '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' TO lt_html.
  " 카드 세로 가운데: html·body·table을 영역(CC_SUM) 높이 100%로 채우고 칸 안에서 가운데 정렬
  APPEND 'html,body{height:100%;margin:0;overflow:hidden}' TO lt_html.
  " 바깥(body)은 GUI 화면 배경색(#f2f2f2), 카드는 흰 판(.p) 안에 둔다(PR 조회 화면과 같은 모양).
  "   흰 판 테두리는 왼쪽 조회조건 틀과 같은 색이고, 아래 여백 8px로 틀의 아래 끝과 높이를 맞춘다.
  APPEND 'body{padding:0 0 8px;box-sizing:border-box;background:#f2f2f2;font:12px Arial,sans-serif;color:#243b53}' TO lt_html.
  APPEND '.p{height:100%;box-sizing:border-box;padding:0 8px;background:#fff;border:1px solid #e5e5e5}' TO lt_html.
  APPEND 'table{width:100%;height:100%;table-layout:fixed;border-spacing:6px 0}' TO lt_html.
  APPEND 'td{text-align:center;vertical-align:middle}' TO lt_html.
  APPEND 'a.c{display:block;text-decoration:none;color:#607ca2;border:1px solid #d6e0ee;' TO lt_html.
  " 카드 크기·글씨는 PR·PO 화면과 같다. 예약·이동 카드의 '예약 N · 이동 M'은 마우스를 올리면 보인다(title).
  APPEND 'border-radius:8px;padding:8px 2px}a.c:hover{border-color:#1684bf;background:#f3f9ff}' TO lt_html.
  APPEND 'a.on{border:2px solid #1684bf;background:#edf6ff;padding:7px 1px}' TO lt_html.
  APPEND '.v{font-size:22px;font-weight:bold;color:#243b53;padding-top:3px}' TO lt_html.
  APPEND '.d{display:inline-block;width:8px;height:8px;border-radius:4px;margin-right:4px}' TO lt_html.
  APPEND '.g{background:#2e9d4f}.y{background:#e3b100}.r{background:#d34343}.n{background:#9aa9bb}' TO lt_html.
  APPEND '.t{font-size:11px;color:#8090a0;padding:6px 6px 0}</style></head><body><div class="p"><table><tr>' TO lt_html.
  " 한글: 전체 / 예약·이동 / 입고완료 / 취소, 말풍선 '예약 N · 이동 M'
  DATA(lv_sub) = |&#50696;&#50557; { lv_rsv } &#183; &#51060;&#46041; { lv_move }|.
  PERFORM card_cell USING 'ALL' 'A' lv_active 'n' '&#51204;&#52404;' lv_all '' CHANGING lt_html.
  DATA(lv_open) = lv_rsv + lv_move.
  PERFORM card_cell USING 'MOVE' 'M' lv_active 'y' '&#50696;&#50557;&#183;&#51060;&#46041;'
    lv_open lv_sub CHANGING lt_html.
  PERFORM card_cell USING 'DONE' 'C' lv_active 'g' '&#51077;&#44256;&#50756;&#47308;' lv_done '' CHANGING lt_html.
  PERFORM card_cell USING 'VOID' 'V' lv_active 'r' '&#52712;&#49548;' lv_void '' CHANGING lt_html.
  APPEND '</tr></table></div></body></html>' TO lt_html.
  DATA lv_url TYPE c LENGTH 255.
  go_summary->load_data( EXPORTING type = 'text' subtype = 'html'
    IMPORTING assigned_url = lv_url CHANGING data_table = lt_html EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  go_summary->show_url( EXPORTING url = lv_url in_place = abap_true EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    gv_summary_stamp = lv_stamp.
  ENDIF.
ENDFORM.

" card_cell : 카드 한 칸의 HTML을 만든다. 선택된 카드는 파란 테두리이다.
FORM card_cell USING iv_action TYPE clike iv_key TYPE clike iv_active TYPE clike
                     iv_dot TYPE clike iv_label TYPE clike iv_count TYPE i iv_sub TYPE clike
               CHANGING ct_html TYPE STANDARD TABLE.
  DATA lv_class TYPE string.
  lv_class = 'c'.
  IF iv_key = iv_active.
    lv_class = 'c on'.
  ENDIF.
  DATA lv_line TYPE w3html.
  " 보조 설명(예: 예약 2 · 이동 2)은 카드에 마우스를 올리면 보이는 말풍선(title)으로 넣는다.
  "   카드 안에 글씨를 더 넣지 않아 PR·PO 카드와 모양이 같다.
  DATA lv_tip TYPE string.
  IF iv_sub IS NOT INITIAL.
    lv_tip = | title="{ iv_sub }"|.
  ENDIF.
  lv_line-line = |<td><a class="{ lv_class }"{ lv_tip } href="SAPEVENT:{ iv_action }"><span class="d { iv_dot }"></span>|.
  APPEND lv_line TO ct_html.
  lv_line-line = |{ iv_label }<div class="v">{ iv_count NUMBER = RAW }</div></a></td>|.
  APPEND lv_line TO ct_html.
ENDFORM.

" apply_summary : 카드 클릭 후 PAI에서 상태조건을 바꾸고 다시 조회한다. 저장은 하지 않는다.
FORM apply_summary.
  CASE gv_summary_action.
    WHEN 'ALL'.
      p_state = 'A'.
      p_due = 'A'.
    WHEN 'MOVE'.
      p_state = 'M'.
      p_due = 'A'.
    WHEN 'DONE'.
      p_state = 'C'.
      p_due = 'A'.
    WHEN 'VOID'.
      p_state = 'V'.
      p_due = 'A'.
    WHEN OTHERS.
      CLEAR gv_summary_action.
      RETURN.
  ENDCASE.
  CLEAR gv_summary_action.
  " 카드는 마지막 조회 결과 안에서만 거른다(DB 재조회 없음). 조회조건 변경은 [조회]·Enter로 반영한다.
  PERFORM filter_list.
ENDFORM.
" 카드 클릭 이벤트 클래스 lcl_summary_events 는 TOP에 있다.

" ------------------------------------------------------------
" calc_schedule : 도착희망일 → 출고일 역산 (출고일 = 도착희망일 − 운송일수)
"   - 도착희망일이 비었으면 가장 빠른 도착일(오늘 + 운송일수)로 채운다 → 그대로 저장하면 오늘 바로 출고.
"   - 가장 빠른 도착일보다 앞이면 그 날짜로 올리고 상태줄로 알려준다(출고일이 과거가 되지 않게).
"   - 결과는 p_date(출고일)·p_eta(예상도착일)에 넣고 오른쪽 글자 gv_nship 으로 보여준다. DB 변경 없음.
"     예) 오늘 출고 2026.10.30 (운송 2일) / 출고 예정 2026.10.31 (운송 2일)
"   - 출발·도착 플랜트가 같으면 상태줄 오류 + 오른쪽 안내만 하고 계산하지 않는다([자재 추가]·저장도 막힘).
" ------------------------------------------------------------
FORM calc_schedule.
  IF gv_posted = abap_true.
    RETURN.                              " 저장한 뒤에는 다시 계산하지 않는다.
  ENDIF.
  CLEAR gv_nship.
  IF p_from IS INITIAL OR p_to IS INITIAL.
    gv_nship = '출발·도착 플랜트를 넣으면 출고일을 계산합니다.'.
    RETURN.
  ENDIF.
  IF p_from = p_to.
    gv_nship = '출발과 다른 도착 플랜트를 입력하세요.'.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '출발과 다른 도착 플랜트'.   " 출발과 다른 도착 플랜트를 입력해주세요
    RETURN.
  ENDIF.
  DATA lv_days TYPE i.
  TRY.
      lv_days = lcl_mm_sto=>route_days( source = p_from dest = p_to ).
    CATCH lcx_mm INTO DATA(lx_route).
      gv_nship = lx_route->detail.
      RETURN.
  ENDTRY.
  DATA(lv_earliest) = CONV sy-datum( sy-datum + lv_days ).
  IF p_want IS INITIAL.
    p_want = lv_earliest.
  ELSEIF p_want < lv_earliest.
    DATA(lv_earliest_txt) = |{ lv_earliest DATE = USER }|.
    MESSAGE s075(z8_msg) DISPLAY LIKE 'W' WITH '도착희망일자' lv_earliest_txt.   " &1는 &2보다 이전일 수 없습니다(가장 빠른 도착일로 맞춤)
    p_want = lv_earliest.
  ENDIF.
  p_date = p_want - lv_days.
  p_eta = p_want.
  IF p_date = sy-datum.
    gv_nship = |오늘 출고 { p_date DATE = USER } (운송 { lv_days }일)|.
  ELSE.
    gv_nship = |출고 예정 { p_date DATE = USER } (운송 { lv_days }일)|.
  ENDIF.
ENDFORM.

" ------------------------------------------------------------
" cancel_selected_sto : [STO 취소]. 목록에서 고른 STO 중 예약중(출고 전)인 것만 취소한다.
"   STO 단위로 잠금 → cancel_sto(예약재고 해제·품목 취소·'예약 취소' 이력) → COMMIT → 잠금해제.
"   이미 출고된(이동중·입고완료) STO가 섞여 있으면 아무것도 하지 않고 안내한다.
"   취소한 STO는 파란 줄 + 선택으로 표시한다(목록 규칙과 동일).
" ------------------------------------------------------------
FORM cancel_selected_sto.
  IF go_list IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA lt_idx TYPE lvc_t_row.
  go_list->get_selected_rows( IMPORTING et_index_rows = lt_idx ).
  IF lt_idx IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  DATA lt_docs TYPE SORTED TABLE OF z8mm_po_i-ebeln WITH UNIQUE KEY table_line.
  LOOP AT lt_idx INTO DATA(ls_idx).
    READ TABLE gt_list INDEX ls_idx-index INTO DATA(ls_sel).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    IF ls_sel-state_key <> 'R'.
      " 예약중이 아닌 STO(이동중·입고완료·취소)는 이미 처리된 문서라 취소하지 않는다.
      DATA(lv_done_sto) = |{ ls_sel-ebeln ALPHA = OUT }|.
      " 끝난 STO(취소·입고완료)는 '이미 처리 완료', 진행 중(이동중)은 '이동중 상태라 취소할 수 없다.'
      IF ls_sel-state = '취소' OR ls_sel-state = '입고완료'.
        MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH lv_done_sto.                 " &1번은 이미 처리 완료된 품목입니다.
      ELSE.
        MESSAGE s134(z8_msg) DISPLAY LIKE 'E' WITH lv_done_sto ls_sel-state.   " &1번은 &2 상태 취소할 수 없습니다.
      ENDIF.
      RETURN.
    ENDIF.
    INSERT ls_sel-ebeln INTO TABLE lt_docs.
  ENDLOOP.
  DATA: lv_question TYPE c LENGTH 200,
        lv_answer TYPE c LENGTH 1.
  lv_question = |예약중 STO { lines( lt_docs ) }건을 취소합니다. 출발지 예약재고가 풀리고 취소 이력이 남습니다. 진행할까요?|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'STO 취소' text_question = lv_question
      text_button_1 = '예' text_button_2 = '아니오'
      default_button = '2' display_cancel_button = space
    IMPORTING answer = lv_answer EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    RETURN.
  ENDIF.
  DATA: lv_ng TYPE i, lv_err TYPE string.
  DATA lt_cancelled TYPE string_table.      " 취소한 STO 번호(완료 메시지용)
  CLEAR: gt_new_sto, gv_mark_new.
  LOOP AT lt_docs INTO DATA(lv_doc).
    TRY.
        lcl_mm_common=>lock( ).
        lcl_mm_sto=>cancel_sto( lv_doc ).
        COMMIT WORK AND WAIT.
        lcl_mm_common=>unlock( ).
        INSERT lv_doc INTO TABLE gt_new_sto.
        APPEND CONV string( lv_doc ) TO lt_cancelled.
      CATCH lcx_mm INTO DATA(lx_cancel).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_ng = lv_ng + 1.
        lv_err = lx_cancel->detail.
      CATCH cx_root INTO DATA(lx_cancel_root).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_ng = lv_ng + 1.
        lv_err = lx_cancel_root->get_text( ).
    ENDTRY.
  ENDLOOP.
  gv_mark_new = xsdbool( gt_new_sto IS NOT INITIAL ).
  PERFORM query_list.
  IF lv_ng > 0.
    MESSAGE s105(z8_msg) DISPLAY LIKE 'E'.   " 상태 변경에 실패했습니다(사유는 이력·목록 확인)
  ELSE.
    DATA(lv_cancel_txt) = lcl_mm_f4=>doc_text( lt_cancelled ).
    MESSAGE s133(z8_msg) WITH lv_cancel_txt '취소'.   " &1 &2 완료
  ENDIF.
ENDFORM.
