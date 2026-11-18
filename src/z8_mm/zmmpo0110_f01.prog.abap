*&---------------------------------------------------------------------*
*& Include ZMMPO0110_F01
*&---------------------------------------------------------------------*
*& 업무 처리 FORM - 조회·후보 판단·PO 생성·PO 취소
*&   DB 저장은 create_po / cancel_po 두 곳이며 건별 COMMIT/ROLLBACK 한다.
*& 담당: MM(이규빈) / 프로그램: ZMMPO0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-07  이규빈  최초 개발   최초 작성: PR 묶음 발주(PR N건 → PO 1건), PO 목록·취소 (개발 10/07~10/13)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등, 후보 ALV에서 골라 바로 PO 생성
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 생성 확인 메시지 축약, '납기 충족 / N일 지연', 취소 메시지 202·134 구분
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" ------------------------------------------------------------
" 공통 도우미: F4 / 이름 채우기 / 수량 표시 / ALV 도구
" ------------------------------------------------------------

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

" names : 자재명 / 공급업체명 / 구매지사 표시 문구를 채운다. 표시 전용이다.
FORM names USING iv_matnr TYPE z8mm_pr-matnr iv_lifnr TYPE z8mm_pr-lifnr iv_werks TYPE z8mm_pr-werks
           CHANGING ev_maktx TYPE z8material_txt_m-maktx ev_vendor TYPE z8vendor_m-name1 ev_site TYPE clike.
  CLEAR: ev_maktx, ev_vendor, ev_site.
  IF iv_matnr IS NOT INITIAL.
    SELECT SINGLE maktx FROM z8material_txt_m WHERE matnr = @iv_matnr AND spras = @sy-langu INTO @ev_maktx.
  ENDIF.
  IF iv_lifnr IS NOT INITIAL.
    SELECT SINGLE name1 FROM z8vendor_m WHERE lifnr = @iv_lifnr INTO @ev_vendor.
    IF sy-subrc <> 0.
      ev_vendor = iv_lifnr.
    ENDIF.
  ENDIF.
  " 구매지사는 이름만 넣는다(예: 충청지사). 플랜트 코드는 '입고플랜트' 열에 따로 보인다.
  IF iv_werks IS NOT INITIAL.
    PERFORM plant_name USING iv_werks CHANGING ev_site.
    IF ev_site IS INITIAL.
      ev_site = iv_werks.
    ENDIF.
  ENDIF.
ENDFORM.

" plant_name : 플랜트 코드로 지사명을 찾는다. 지사(z8branch_m) 이름이 하나면 그것, 아니면 플랜트명이다.
FORM plant_name USING iv_werks TYPE clike CHANGING ev_name TYPE clike.
  CLEAR ev_name.
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

" fill_names : 조회조건 코드 칸 옆에 이름을 보여준다. 없는 코드는 '등록되지 않은 코드'.
FORM fill_names.
  DATA lv_dummy_mat TYPE z8material_txt_m-maktx.
  DATA lv_dummy_ven TYPE z8vendor_m-name1.
  CLEAR: gv_nplt, gv_nven, gv_nmat, gv_ncplt, gv_ncven, gv_ncmat.
  " 0100 조회조건
  IF p_bupla IS NOT INITIAL.
    PERFORM branch_name USING p_bupla CHANGING gv_nplt.
    IF gv_nplt IS INITIAL.
      gv_nplt = '등록되지 않은 코드'.
    ENDIF.
  ENDIF.
  IF p_lifnr IS NOT INITIAL.
    SELECT SINGLE name1 FROM z8vendor_m WHERE lifnr = @p_lifnr INTO @lv_dummy_ven.
    gv_nven = COND #( WHEN sy-subrc = 0 THEN lv_dummy_ven ELSE '등록되지 않은 코드' ).
  ENDIF.
  IF p_matnr IS NOT INITIAL.
    SELECT SINGLE maktx FROM z8material_txt_m WHERE matnr = @p_matnr AND spras = @sy-langu INTO @lv_dummy_mat.
    gv_nmat = COND #( WHEN sy-subrc = 0 THEN lv_dummy_mat ELSE '등록되지 않은 코드' ).
  ENDIF.
  " 0200 후보조건
  IF c_bupla IS NOT INITIAL.
    PERFORM branch_name USING c_bupla CHANGING gv_ncplt.
    IF gv_ncplt IS INITIAL.
      gv_ncplt = '등록되지 않은 코드'.
    ENDIF.
  ENDIF.
  IF c_lifnr IS NOT INITIAL.
    SELECT SINGLE name1 FROM z8vendor_m WHERE lifnr = @c_lifnr INTO @lv_dummy_ven.
    gv_ncven = COND #( WHEN sy-subrc = 0 THEN lv_dummy_ven ELSE '등록되지 않은 코드' ).
  ENDIF.
  IF c_matnr IS NOT INITIAL.
    SELECT SINGLE maktx FROM z8material_txt_m WHERE matnr = @c_matnr AND spras = @sy-langu INTO @lv_dummy_mat.
    gv_ncmat = COND #( WHEN sy-subrc = 0 THEN lv_dummy_mat ELSE '등록되지 않은 코드' ).
  ENDIF.
ENDFORM.

" qty_text : 정수면 소수 없이, 소수가 있으면 3자리로 문구를 만든다(.000 숨김).
" 묶음수량(PR 수량)과 최소발주량(구매정보) 타입이 달라도 받도록 numeric으로 둔다.
FORM qty_text USING iv_qty TYPE numeric CHANGING ev_text TYPE string.
  DATA lv_amount TYPE decfloat34.
  lv_amount = iv_qty.
  IF lv_amount = trunc( lv_amount ).
    ev_text = |{ lv_amount NUMBER = USER DECIMALS = 0 }|.     " 100,000
  ELSE.
    ev_text = |{ lv_amount NUMBER = USER DECIMALS = 3 }|.     " 12.500
  ENDIF.
ENDFORM.

" quantity_catalog : 수량 열의 소수 자릿수를 데이터에 맞게 정한다.
FORM quantity_catalog USING rows TYPE STANDARD TABLE CHANGING catalog TYPE lvc_t_fcat.
  LOOP AT catalog ASSIGNING FIELD-SYMBOL(<qty_fc>) WHERE qfieldname = 'MEINS'.
    <qty_fc>-decimals_o = 0.
    LOOP AT rows ASSIGNING FIELD-SYMBOL(<qty_row>).
      ASSIGN COMPONENT <qty_fc>-fieldname OF STRUCTURE <qty_row> TO FIELD-SYMBOL(<qty_value>).
      IF sy-subrc = 0.
        DATA lv_amount_chk TYPE decfloat34.
        lv_amount_chk = CONV decfloat34( <qty_value> ).
        IF lv_amount_chk <> trunc( lv_amount_chk ).
          <qty_fc>-decimals_o = 3.
          EXIT.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

" add_fc : ALV 열 하나를 필드카탈로그에 추가한다.
FORM add_fc USING iv_name TYPE clike iv_title TYPE clike iv_len TYPE i CHANGING ct_cat TYPE lvc_t_fcat.
  DATA ls_fc TYPE lvc_s_fcat.
  ls_fc-fieldname = iv_name.
  ls_fc-coltext = iv_title.
  ls_fc-scrtext_l = iv_title.
  ls_fc-scrtext_m = iv_title.
  ls_fc-scrtext_s = iv_title.
  ls_fc-outputlen = iv_len.
  " 길이 0은 화면에 안 보이는 참조용 열이다(예: 구매단가의 통화).
  IF iv_len = 0.
    ls_fc-no_out = abap_true.
  ENDIF.
  CASE iv_name.
    WHEN 'SIGNAL'.
      ls_fc-icon = abap_true.
      ls_fc-just = 'C'.
    WHEN 'MENGE' OR 'BUNDLE_QTY'.
      ls_fc-qfieldname = 'MEINS'.
      ls_fc-just = 'R'.
      IF iv_name = 'BUNDLE_QTY'.
        ls_fc-no_zero = abap_true.
      ENDIF.
    WHEN 'NETPR'.
      ls_fc-cfieldname = 'WAERS'.
    WHEN 'BEDAT' OR 'LFDAT' OR 'ETA'.
      ls_fc-datatype = 'DATS'.
    WHEN 'BANFN'.
      ls_fc-ref_table = 'Z8MM_PR'.
      ls_fc-ref_field = 'BANFN'.
    WHEN 'EBELN'.
      ls_fc-ref_table = 'Z8MM_PO_H'.
      ls_fc-ref_field = 'EBELN'.
    WHEN 'MATNR'.
      ls_fc-ref_table = 'Z8MM_PR'.
      ls_fc-ref_field = 'MATNR'.
  ENDCASE.
  APPEND ls_fc TO ct_cat.
ENDFORM.

" toolbar_excluded : ALV 위쪽 버튼을 정렬(오름차순·내림차순)만 남기고 나머지는 숨긴다.
FORM toolbar_excluded CHANGING et_excl TYPE ui_functions.
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

" ------------------------------------------------------------
" 화면 0100 : PO 조회 및 관리
" ------------------------------------------------------------

" query_po : 조회조건으로 외부구매 PO 품목을 읽고 신호등·상태를 계산한다.
FORM query_po.
  DATA: lr_plants TYPE RANGE OF z8mm_pr-werks,
        lr_mats TYPE RANGE OF z8mm_pr-matnr,
        lr_vendors TYPE RANGE OF z8mm_pr-lifnr,
        lr_docs TYPE RANGE OF z8mm_po_h-ebeln,
        lr_dates TYPE RANGE OF z8mm_po_h-bedat.
  PERFORM branch_plants USING p_bupla CHANGING lr_plants.
  IF p_matnr IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = p_matnr ) TO lr_mats.
  ENDIF.
  IF p_lifnr IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = p_lifnr ) TO lr_vendors.
  ENDIF.
  IF p_doc IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = p_doc ) TO lr_docs.
  ENDIF.
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
  SELECT i~ebeln, i~ebelp, i~banfn, i~matnr, i~werks, i~menge, i~meins, i~netpr, i~waers,
         i~lfdat, i~elikz, i~loekz, h~lifnr, h~procstat, h~bedat
    FROM z8mm_po_i AS i INNER JOIN z8mm_po_h AS h ON h~ebeln = i~ebeln
    WHERE h~bsart = 'NB' AND h~bedat IN @lr_dates AND i~werks IN @lr_plants
      AND i~matnr IN @lr_mats AND h~lifnr IN @lr_vendors AND i~ebeln IN @lr_docs
    INTO TABLE @DATA(lt_orders).
  " 방금 생성·취소한 PO는 조회조건(기간·지사 등)과 관계없이 함께 보여준다.
  IF gt_new_po IS NOT INITIAL.
    DATA lr_new TYPE RANGE OF z8mm_po_h-ebeln.
    DATA ls_new_range LIKE LINE OF lr_new.
    LOOP AT gt_new_po INTO DATA(lv_new_doc).
      CLEAR ls_new_range.
      ls_new_range-sign = 'I'.
      ls_new_range-option = 'EQ'.
      ls_new_range-low = lv_new_doc.
      APPEND ls_new_range TO lr_new.
    ENDLOOP.
    SELECT i~ebeln, i~ebelp, i~banfn, i~matnr, i~werks, i~menge, i~meins, i~netpr, i~waers,
           i~lfdat, i~elikz, i~loekz, h~lifnr, h~procstat, h~bedat
      FROM z8mm_po_i AS i INNER JOIN z8mm_po_h AS h ON h~ebeln = i~ebeln
      WHERE h~bsart = 'NB' AND i~ebeln IN @lr_new
      INTO TABLE @DATA(lt_marked).
    LOOP AT lt_marked INTO DATA(ls_marked).
      READ TABLE lt_orders TRANSPORTING NO FIELDS WITH KEY ebeln = ls_marked-ebeln ebelp = ls_marked-ebelp.
      IF sy-subrc <> 0.
        APPEND ls_marked TO lt_orders.
      ENDIF.
    ENDLOOP.
  ENDIF.
  CLEAR: gt_po, gt_po_all.
  LOOP AT lt_orders INTO DATA(ls_ord).
    DATA(ls_po) = VALUE ty_po( ebeln = ls_ord-ebeln ebelp = ls_ord-ebelp banfn = ls_ord-banfn
      matnr = ls_ord-matnr menge = ls_ord-menge meins = ls_ord-meins netpr = ls_ord-netpr
      waers = ls_ord-waers bedat = ls_ord-bedat lfdat = ls_ord-lfdat werks = ls_ord-werks ).
    " 처리상태 = 품목 취소표시(LOEKZ) + 헤더 PROCSTAT(입고 프로그램·송장검증이 바꾼다)
    "   LOEKZ = X → 취소 / 10 → 입고대기 / 15 → 부분입고 / 20·25(송장확인) 또는 ELIKZ = X → 입고완료
    "   상태카드는 4개: 부분입고는 [입고대기] 카드에 함께 센다. 취소는 입고대기(10)만 가능하다.
    IF ls_ord-loekz IS NOT INITIAL.
      ls_po-state = '취소'.
      ls_po-signal = icon_led_red.
    ELSEIF ls_ord-elikz IS NOT INITIAL OR ls_ord-procstat = '20' OR ls_ord-procstat = '25'.
      ls_po-state = '입고완료'.
      ls_po-signal = icon_led_green.
    ELSE.
      ls_po-state = COND #( WHEN ls_ord-procstat = '15' THEN '부분입고' ELSE '입고대기' ).
      ls_po-signal = icon_led_yellow.
      " 예상도착일이 지나도 신호등은 노랑 그대로, 처리 안내로만 알린다.
      IF ls_ord-lfdat IS NOT INITIAL AND ls_ord-lfdat < sy-datum.
        ls_po-detail = '예상도착일이 지났습니다.'.   " 짧게(가로 스크롤 방지)
      ENDIF.
    ENDIF.
    " 방금 생성한 PO: 파란 줄 + 목록 맨 위. 다음 조회 때 사라진다(I01에서 gt_new_po를 비움).
    " STO·PR과 같이 별도 '신규' 열은 두지 않는다.
    READ TABLE gt_new_po TRANSPORTING NO FIELDS WITH TABLE KEY table_line = ls_po-ebeln.
    IF sy-subrc = 0.
      ls_po-is_new = abap_true.
      ls_po-rowclr = 'C410'.
    ENDIF.
    PERFORM names USING ls_po-matnr ls_ord-lifnr ls_ord-werks
      CHANGING ls_po-maktx ls_po-vendor_name ls_po-site_text.
    APPEND ls_po TO gt_po_all.
  ENDLOOP.
  " 기본정렬: 방금 생성한 PO → 입고대기(예상도착일 빠른 순) → 입고완료 → 취소
  LOOP AT gt_po_all ASSIGNING FIELD-SYMBOL(<rank_po>).
    <rank_po>-sort_rank = SWITCH #( <rank_po>-state WHEN '입고대기' OR '부분입고' THEN 1 WHEN '입고완료' THEN 2 ELSE 3 ).
  ENDLOOP.
  SORT gt_po_all BY is_new DESCENDING sort_rank lfdat ebeln ebelp.
  " 상태카드 건수는 gt_po_all 기준, ALV는 선택한 카드(p_state)로 거른 결과이다.
  PERFORM filter_po.
  gv_key1 = |{ p_bupla }/{ p_matnr }/{ p_lifnr }/{ p_doc }/{ p_dfrom }/{ p_dto }|.   " 카드(p_state)는 조회조건 아님
  IF gt_po_all IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.   " 조회 조건에 해당하는 데이터가 없습니다
  ENDIF.
  PERFORM refresh_po.
ENDFORM.

" filter_po : 상태카드에서 고른 상태(p_state)만 ALV 목록에 남긴다.
FORM filter_po.
  DATA lv_want TYPE c LENGTH 12.
  CASE p_state.
    WHEN 'W'. lv_want = '입고대기'.
    WHEN 'F'. lv_want = '입고완료'.
    WHEN 'X'. lv_want = '취소'.
  ENDCASE.
  gt_po = gt_po_all.
  IF lv_want IS NOT INITIAL.
    " [입고대기] 카드는 부분입고도 함께 보여준다(아직 입고가 끝나지 않은 PO).
    "   방금 처리한 PO(is_new)는 카드와 관계없이 보인다.
    IF lv_want = '입고대기'.
      DELETE gt_po WHERE state <> '입고대기' AND state <> '부분입고' AND is_new = abap_false.
    ELSE.
      DELETE gt_po WHERE state <> lv_want AND is_new = abap_false.
    ENDIF.
  ENDIF.
ENDFORM.

" po_title : ALV 제목(목록 이름 · 건수).
FORM po_title CHANGING cv_title TYPE lvc_title.
  cv_title = |PO 목록 · { lines( gt_po ) }건|.
ENDFORM.

" po_filter_changed : 조회조건이 마지막 조회와 달라졌는지 본다.
FORM po_filter_changed CHANGING cv_changed TYPE abap_bool.
  DATA(lv_now) = |{ p_bupla }/{ p_matnr }/{ p_lifnr }/{ p_doc }/{ p_dfrom }/{ p_dto }|.
  cv_changed = xsdbool( lv_now <> gv_key1 ).
ENDFORM.

" show_po : 0100의 ALV를 처음 한 번 만든다(이미 있으면 그대로 둔다).
FORM show_po.
  IF go_grid1 IS BOUND.
    RETURN.
  ENDIF.
  CREATE OBJECT go_cont1 EXPORTING container_name = 'CC_PO'.
  CREATE OBJECT go_grid1 EXPORTING i_parent = go_cont1.
  DATA lt_cat TYPE lvc_t_fcat.
  PERFORM add_fc USING 'SIGNAL' `상태` 4 CHANGING lt_cat.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM add_fc USING 'STATE' `처리상태` 9 CHANGING lt_cat.
  " 열 폭은 한 화면에 가로 스크롤 없이 들어가도록 맞춘 값이다.
  PERFORM add_fc USING 'EBELN' `PO 번호` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'BANFN' `원본 PR` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'MATNR' `자재번호` 12 CHANGING lt_cat.
  PERFORM add_fc USING 'MAKTX' `자재명` 18 CHANGING lt_cat.
  PERFORM add_fc USING 'MENGE' `발주수량` 9 CHANGING lt_cat.
  PERFORM add_fc USING 'MEINS' `단위` 4 CHANGING lt_cat.
  PERFORM add_fc USING 'VENDOR_NAME' `공급업체` 12 CHANGING lt_cat.
  PERFORM add_fc USING 'SITE_TEXT' `구매지사` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'WERKS' `입고플랜트` 7 CHANGING lt_cat.
  PERFORM add_fc USING 'NETPR' `구매단가` 11 CHANGING lt_cat.
  PERFORM add_fc USING 'WAERS' `통화` 0 CHANGING lt_cat.
  PERFORM add_fc USING 'BEDAT' `발주일` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'LFDAT' `예상도착일` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'DETAIL' `안내` 20 CHANGING lt_cat.
  PERFORM quantity_catalog USING gt_po CHANGING lt_cat.
  DATA lt_excl TYPE ui_functions.
  PERFORM toolbar_excluded CHANGING lt_excl.
  DATA lv_first_title TYPE lvc_title.
  PERFORM po_title CHANGING lv_first_title.
  go_grid1->set_table_for_first_display(
    " 줄 색은 방금 생성한 PO(파란 줄)에만 쓴다. 상태 색은 쓰지 않고 신호등으로만 구분한다.
    EXPORTING is_layout = VALUE lvc_s_layo( zebra = abap_true sel_mode = 'A' info_fname = 'ROWCLR'
      smalltitle = abap_true grid_title = lv_first_title )
      it_toolbar_excluding = lt_excl
    CHANGING it_outtab = gt_po it_fieldcatalog = lt_cat ).
  PERFORM select_new_po.             " PO 생성 후 돌아오면 새 PO 행 선택
ENDFORM.

" refresh_po : 조회 후 이미 떠 있는 ALV를 새 데이터로 갱신한다.
FORM refresh_po.
  IF go_grid1 IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA lt_cat TYPE lvc_t_fcat.
  go_grid1->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_cat ).
  PERFORM quantity_catalog USING gt_po CHANGING lt_cat.
  go_grid1->set_frontend_fieldcatalog( it_fieldcatalog = lt_cat ).
  DATA lv_title TYPE lvc_title.
  PERFORM po_title CHANGING lv_title.
  go_grid1->set_gridtitle( i_gridtitle = lv_title ).
  go_grid1->set_selected_rows( it_index_rows = VALUE lvc_t_row( ) ).
  go_grid1->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  PERFORM select_new_po.
ENDFORM.

" select_new_po : 방금 생성·취소한 PO 행을 한 번 선택 상태로 걸어 둔다.
FORM select_new_po.
  IF go_grid1 IS NOT BOUND OR gv_sel_new = abap_false.
    RETURN.
  ENDIF.
  DATA lt_rows TYPE lvc_t_row.
  LOOP AT gt_po TRANSPORTING NO FIELDS WHERE is_new = abap_true.
    APPEND VALUE #( index = sy-tabix ) TO lt_rows.
  ENDLOOP.
  go_grid1->set_selected_rows( it_index_rows = lt_rows ).
  CLEAR gv_sel_new.
ENDFORM.

" free_po_grid : 다른 화면으로 가기 전에 0100의 ALV를 정리한다.
FORM free_po_grid.
  IF go_grid1 IS BOUND.
    go_grid1->free( ).
    FREE go_grid1.
  ENDIF.
  IF go_cont1 IS BOUND.
    go_cont1->free( ).
    FREE go_cont1.
  ENDIF.
ENDFORM.

" cancel_selected : 선택한 PO를 확인창 뒤에 취소한다. 모든 검사를 통과해야 확인창이 뜬다.
FORM cancel_selected.
  IF go_grid1 IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA lt_idx TYPE lvc_t_row.
  go_grid1->get_selected_rows( IMPORTING et_index_rows = lt_idx ).
  IF lt_idx IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  DATA: lt_docs TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line,
        lv_blocked TYPE i,
        lv_blocked_doc TYPE string,            " 취소할 수 없는 첫 PO 번호(메시지용)
        lv_blocked_st  TYPE string.            " 그 PO의 처리상태(메시지용)
  LOOP AT lt_idx INTO DATA(ls_idx).
    READ TABLE gt_po INDEX ls_idx-index INTO DATA(ls_sel).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    IF ls_sel-state <> '입고대기'.     " 부분입고·입고완료·취소는 취소할 수 없다
      lv_blocked = lv_blocked + 1.
      IF lv_blocked_doc IS INITIAL.
        lv_blocked_doc = |{ ls_sel-ebeln ALPHA = OUT }|.
        lv_blocked_st = ls_sel-state.
      ENDIF.
      CONTINUE.
    ENDIF.
    INSERT ls_sel-ebeln INTO TABLE lt_docs.
  ENDLOOP.
  IF lv_blocked > 0.
    " 끝난 PO(취소·입고완료)는 '이미 처리 완료', 진행 중(부분입고)은 '상태라 취소 불가'로 알린다.
    IF lv_blocked_st = '취소' OR lv_blocked_st = '입고완료'.
      MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH lv_blocked_doc.                 " &1번은 이미 처리 완료된 품목입니다.
    ELSE.
      MESSAGE s134(z8_msg) DISPLAY LIKE 'E' WITH lv_blocked_doc lv_blocked_st.   " &1번은 &2 상태 취소할 수 없습니다
    ENDIF.
    RETURN.
  ENDIF.
  " 확인창 전에 DB 기준으로 취소 가능 여부를 모두 확인한다.
  "   일부 입고(헤더 PROCSTAT ≠ 10)·입고/취소 품목 포함·자재문서·구매 처리이력이 있는 PO가
  "   하나라도 섞이면 아무것도 바꾸지 않고 그 PO 번호만 알린다(목록 신호등·상태 그대로).
  IF lt_docs IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  " 고른 PO를 테이블마다 한 번씩 읽어 두고, 아래 루프에서는 읽은 표만 찾는다(루프 안 SELECT 없음).
  "   lt_chk_head : PO 헤더 처리상태(NB만)
  "   lt_chk_used : 입고·취소 품목 / 입고 자재문서 / 구매 처리이력 중 하나라도 있는 PO
  TYPES: BEGIN OF ty_chk_head,
           ebeln TYPE z8mm_po_h-ebeln,
           procstat TYPE z8mm_po_h-procstat,
         END OF ty_chk_head.
  DATA: lt_chk_head TYPE SORTED TABLE OF ty_chk_head WITH NON-UNIQUE KEY ebeln,
        lt_chk_used TYPE STANDARD TABLE OF z8mm_po_h-ebeln WITH EMPTY KEY,
        lt_chk_part TYPE STANDARD TABLE OF z8mm_po_h-ebeln WITH EMPTY KEY.
  SELECT ebeln, procstat FROM z8mm_po_h FOR ALL ENTRIES IN @lt_docs
    WHERE ebeln = @lt_docs-table_line AND bsart = 'NB'
    INTO CORRESPONDING FIELDS OF TABLE @lt_chk_head.
  SELECT ebeln FROM z8mm_po_i FOR ALL ENTRIES IN @lt_docs
    WHERE ebeln = @lt_docs-table_line AND ( elikz <> @space OR loekz <> @space )
    INTO TABLE @lt_chk_part.
  APPEND LINES OF lt_chk_part TO lt_chk_used.
  SELECT zzrefdoc FROM z8mm_matdoc_i FOR ALL ENTRIES IN @lt_docs
    WHERE zzrefdoc = @lt_docs-table_line AND zzreftype = '01'
    INTO TABLE @lt_chk_part.
  APPEND LINES OF lt_chk_part TO lt_chk_used.
  SELECT ebeln FROM z8mm_po_hist FOR ALL ENTRIES IN @lt_docs
    WHERE ebeln = @lt_docs-table_line
    INTO TABLE @lt_chk_part.
  APPEND LINES OF lt_chk_part TO lt_chk_used.
  SORT lt_chk_used BY table_line.
  DELETE ADJACENT DUPLICATES FROM lt_chk_used COMPARING table_line.
  DATA lv_chk_stat TYPE z8mm_po_h-procstat.
  LOOP AT lt_docs INTO DATA(lv_chk_doc).
    CLEAR lv_chk_stat.                     " 못 읽으면 이전 PO 값이 남지 않게
    READ TABLE lt_chk_head INTO DATA(ls_chk_head) WITH TABLE KEY ebeln = lv_chk_doc.
    IF sy-subrc = 0.
      lv_chk_stat = ls_chk_head-procstat.
    ENDIF.
    READ TABLE lt_chk_used TRANSPORTING NO FIELDS WITH KEY table_line = lv_chk_doc BINARY SEARCH.
    DATA(lv_cannot) = xsdbool( lv_chk_stat <> '10' OR sy-subrc = 0 ).
    IF lv_cannot = abap_true.
      lv_blocked_doc = |{ lv_chk_doc ALPHA = OUT }|.
      " 목록을 연 뒤 다른 사람이 입고한 경우 등: DB 상태로 문구를 정한다.
      IF lv_chk_stat = '20' OR lv_chk_stat = '25'.
        MESSAGE s202(z8_msg) DISPLAY LIKE 'E' WITH lv_blocked_doc.                 " &1번은 이미 처리 완료된 품목입니다.
      ELSE.
        lv_blocked_st = SWITCH #( lv_chk_stat WHEN '15' THEN `부분입고` ELSE `입고 진행` ).
        MESSAGE s134(z8_msg) DISPLAY LIKE 'E' WITH lv_blocked_doc lv_blocked_st.   " &1번은 &2 상태 취소할 수 없습니다
      ENDIF.
      RETURN.
    ENDIF.
  ENDLOOP.
  DATA lv_question TYPE c LENGTH 200.
  DATA lv_answer TYPE c LENGTH 1.
  lv_question = |PO { lines( lt_docs ) }건을 취소합니다. 원본 PR은 발주대기로 돌아갑니다. 취소할까요?|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'PO 취소' text_question = lv_question
      default_button = '2' display_cancel_button = space
    IMPORTING answer = lv_answer EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    RETURN.
  ENDIF.
  DATA lv_ng TYPE i.
  DATA lt_cancelled TYPE string_table.      " 취소한 PO 번호(완료 메시지용)
  LOOP AT lt_docs INTO DATA(lv_doc).
    TRY.
        lcl_mm_common=>lock_doc( ).          " PO 취소는 재고 잠금 없이 문서 잠금만
        lcl_mm_purchase=>cancel_po( lv_doc ).
        COMMIT WORK AND WAIT.
        lcl_mm_common=>unlock( ).
        APPEND CONV string( lv_doc ) TO lt_cancelled.
        INSERT lv_doc INTO TABLE gt_new_po.   " 방금 취소한 PO도 파란 줄·선택 유지
        LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<po_ok>) WHERE ebeln = lv_doc.
          <po_ok>-is_new = abap_true.
          <po_ok>-state = '취소'.
          <po_ok>-signal = icon_led_red.
          <po_ok>-rowclr = 'C410'.           " 방금 취소한 PO도 파란 줄(다음 조회 때 사라짐)
          CLEAR <po_ok>-detail.
        ENDLOOP.
        " 상태카드 건수도 바로 바뀌도록 원본 목록에도 반영한다.
        LOOP AT gt_po_all ASSIGNING FIELD-SYMBOL(<po_all_ok>) WHERE ebeln = lv_doc.
          <po_all_ok>-state = '취소'.
          <po_all_ok>-signal = icon_led_red.
          <po_all_ok>-rowclr = 'C410'.
          <po_all_ok>-is_new = abap_true.
        ENDLOOP.
      CATCH lcx_mm INTO DATA(lx_cancel).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_ng = lv_ng + 1.
        " 실패 행은 신호등·상태를 바꾸지 않고 처리 안내에 사유만 남긴다(취소된 것처럼 보이지 않게).
        LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<po_bad>) WHERE ebeln = lv_doc.
          <po_bad>-detail = lx_cancel->detail.
        ENDLOOP.
      CATCH cx_root INTO DATA(lx_root_cancel).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_ng = lv_ng + 1.
        LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<po_bad2>) WHERE ebeln = lv_doc.
          <po_bad2>-detail = lx_root_cancel->get_text( ).
        ENDLOOP.
    ENDTRY.
  ENDLOOP.
  IF lv_ng > 0.
    MESSAGE s105(z8_msg) DISPLAY LIKE 'E'.   " 상태 변경에 실패했습니다(사유는 행의 처리 안내)
  ELSE.
    DATA(lv_cancel_txt) = lcl_mm_f4=>doc_text( lt_cancelled ).
    MESSAGE s133(z8_msg) WITH lv_cancel_txt '취소'.   " &1 &2 완료
  ENDIF.
  go_grid1->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  gv_sel_new = abap_true.
  PERFORM select_new_po.
ENDFORM.

" ------------------------------------------------------------
" 화면 0200 : PO 생성 (후보 선택 → 검사 → 확인창 → 생성, 한 화면)
" ------------------------------------------------------------

" open_create : 0200에 들어가기 전에 후보 PR을 읽는다.
FORM open_create.
  CLEAR: c_bupla, c_matnr, c_lifnr, c_lfdat.
  " PO 조회화면(또는 PUR)에서 고른 지사를 후보조건 기본값으로 이어받는다.
  c_bupla = p_bupla.
  PERFORM load_cand.
ENDFORM.

" load_cand : 발주대기 PR을 읽어 업체 구매가격·예상입고일·납기판단·신호등을 계산한다.
FORM load_cand.
  DATA: lr_plants TYPE RANGE OF z8mm_pr-werks,
        lr_locs TYPE RANGE OF z8mm_pr-lgort,
        lr_mats TYPE RANGE OF z8mm_pr-matnr,
        lr_vendors TYPE RANGE OF z8mm_pr-lifnr.
  PERFORM branch_plants USING c_bupla CHANGING lr_plants.
  APPEND VALUE #( sign = 'I' option = 'EQ' low = lcl_mm_purchase=>c_lgort ) TO lr_locs.
  IF c_matnr IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = c_matnr ) TO lr_mats.
  ENDIF.
  IF c_lifnr IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = c_lifnr ) TO lr_vendors.
  ENDIF.
  DATA(lt_prs) = lcl_mm_stock=>requests( plants = lr_plants locs = lr_locs mats = lr_mats vendors = lr_vendors ).
  CLEAR: gt_cand, gt_pr, gt_quote.
  LOOP AT lt_prs INTO DATA(ls_pr) WHERE status = 'PENDING'.
    IF c_lfdat IS NOT INITIAL AND ls_pr-lfdat > c_lfdat.
      CONTINUE.
    ENDIF.
    IF ls_pr-source_type = 'STO_REPL'.
      CONTINUE.                          " STO 재보충 PR은 PO 생성 후보가 아니다
    ENDIF.
    DATA(ls_cand) = VALUE ty_cand( banfn = ls_pr-banfn bnfpo = ls_pr-bnfpo matnr = ls_pr-matnr
      menge = ls_pr-menge meins = ls_pr-meins lifnr = ls_pr-lifnr werks = ls_pr-werks
      lgort = ls_pr-lgort lfdat = ls_pr-lfdat ok = abap_true state = '발주대기' ).
    ls_cand-src_type = ls_pr-source_type.
    PERFORM source_text USING ls_pr-source_type CHANGING ls_cand-src_text.
    PERFORM names USING ls_cand-matnr ls_cand-lifnr ls_cand-werks
      CHANGING ls_cand-maktx ls_cand-vendor_name ls_cand-site_text.
    TRY.
        IF ls_cand-lifnr IS INITIAL.
          lcl_mm_common=>fail( `PR에 공급업체가 없습니다. PR 변경에서 공급업체를 지정하세요.` ).
        ENDIF.
        DATA(ls_info) = lcl_mm_stock=>price( material = ls_cand-matnr vendor = ls_cand-lifnr ).
        IF ls_info-meins <> ls_cand-meins.
          lcl_mm_common=>fail( `PR 단위와 구매정보 단위가 다릅니다.` ).
        ENDIF.
        DATA(lv_arrival) = lcl_mm_stock=>eta( vendor = ls_cand-lifnr plant = ls_cand-werks ).
        ls_cand-eta = lv_arrival.
        ls_cand-netpr = ls_info-netpr.
        ls_cand-waers = ls_info-waers.
        APPEND VALUE #( banfn = ls_cand-banfn bnfpo = ls_cand-bnfpo price = ls_info arrival = lv_arrival ) TO gt_quote.
      CATCH lcx_mm INTO DATA(lx_quote).
        ls_cand-ok = abap_false.
        ls_cand-state = '발주불가'.
        ls_cand-detail = lx_quote->detail.
    ENDTRY.
    IF ls_cand-ok = abap_true.
      IF ls_cand-lfdat IS INITIAL.
        ls_cand-schedule = '희망일 없음'.
      ELSEIF ls_cand-eta <= ls_cand-lfdat.
        ls_cand-schedule = '납기 충족'.
      ELSE.
        DATA lv_late_days TYPE i.
        lv_late_days = ls_cand-eta - ls_cand-lfdat.
        ls_cand-schedule = |{ lv_late_days }일 지연|.
        ls_cand-late = abap_true.
      ENDIF.
    ENDIF.
    IF ls_cand-ok = abap_false.
      ls_cand-signal = icon_led_red.          " 상태는 신호등으로만(줄 색은 방금 처리한 행만)
    ELSEIF ls_cand-late = abap_true.
      ls_cand-signal = icon_led_yellow.
    ELSE.
      ls_cand-signal = icon_led_green.
    ENDIF.
    APPEND ls_cand TO gt_cand.
    DATA ls_pr_row TYPE z8mm_pr.
    ls_pr_row = CORRESPONDING #( ls_pr ).
    APPEND ls_pr_row TO gt_pr.
  ENDLOOP.
  SORT gt_cand BY lifnr matnr werks lgort banfn bnfpo.
  " 같은 업체·자재·지사·창고·단위는 한 PO로 묶인다. 묶음 번호를 미리 보여준다.
  DATA lt_keys TYPE ty_cands.
  lt_keys = gt_cand.
  DELETE lt_keys WHERE ok = abap_false.
  DATA: lv_group TYPE i, ls_prev TYPE ty_cand.
  LOOP AT lt_keys INTO DATA(ls_key).
    IF lv_group = 0 OR ls_key-lifnr <> ls_prev-lifnr OR ls_key-matnr <> ls_prev-matnr
      OR ls_key-werks <> ls_prev-werks OR ls_key-lgort <> ls_prev-lgort OR ls_key-meins <> ls_prev-meins.
      lv_group = lv_group + 1.
    ENDIF.
    READ TABLE gt_cand ASSIGNING FIELD-SYMBOL(<cand_b>) WITH KEY banfn = ls_key-banfn bnfpo = ls_key-bnfpo.
    IF sy-subrc = 0.
      " 내부 묶음 번호(화면에는 아래에서 '2건 → PO 1건' 형태로 바꾼다)
      <cand_b>-bundle = |{ lv_group }|.
    ENDIF.
    ls_prev = ls_key.
  ENDLOOP.
  " 같은 업체·자재·지사·창고·단위 PR이 2건 이상이면 함께 선택했을 때 PO 1건으로 묶인다.
  " 그런 행에만 '함께 발주'와 합계수량을 보여주고, 혼자인 PR은 비워 둔다.
  DATA lv_same_cnt TYPE i.
  DATA lv_same_qty TYPE z8mm_pr-menge.
  LOOP AT gt_cand ASSIGNING FIELD-SYMBOL(<cand_sum>) WHERE bundle IS NOT INITIAL.
    CLEAR: lv_same_cnt, lv_same_qty.
    LOOP AT gt_cand INTO DATA(ls_same) WHERE bundle = <cand_sum>-bundle.
      lv_same_cnt = lv_same_cnt + 1.
      lv_same_qty = lv_same_qty + ls_same-menge.
    ENDLOOP.
    <cand_sum>-bundle_qty = lv_same_qty.
    <cand_sum>-ok_cnt = lv_same_cnt.
    " 같은 묶음 후보를 전부 합쳐도 업체 최소발주량(MINBM)에 못 미치면
    "   어떻게 선택해도 PO를 만들 수 없으므로 '발주불가'로 보여준다(생성 대상에서 제외).
    "   단, 신호등은 노랑: PR을 더 모으면 발주할 수 있는 상태라 빨강(오류)과 구분한다.
    READ TABLE gt_quote INTO DATA(ls_q_moq) WITH KEY banfn = <cand_sum>-banfn bnfpo = <cand_sum>-bnfpo.
    IF sy-subrc = 0 AND ls_q_moq-price-minbm > 0 AND lv_same_qty < ls_q_moq-price-minbm.
      DATA lv_moq_txt TYPE string.
      PERFORM qty_text USING ls_q_moq-price-minbm CHANGING lv_moq_txt.
      <cand_sum>-ok = abap_false.
      <cand_sum>-state = '발주불가'.
      <cand_sum>-signal = icon_led_yellow.
      <cand_sum>-detail = |최소발주량 { lv_moq_txt } 미만|.
    ENDIF.
  ENDLOOP.
  LOOP AT gt_cand ASSIGNING FIELD-SYMBOL(<cand_txt>).
    IF <cand_txt>-ok_cnt > 1.
      <cand_txt>-bundle = |{ <cand_txt>-ok_cnt }건→PO 1|.
    ELSE.
      CLEAR: <cand_txt>-bundle, <cand_txt>-bundle_qty.
    ENDIF.
  ENDLOOP.
  " 상태·요청구분 조건: 묶음 합계·최소발주량 판단이 끝난 뒤에 거른다(일부만 보여도 판단은 전체 기준).
  CASE c_stat.
    WHEN 'G'. DELETE gt_cand WHERE signal <> icon_led_green.
    WHEN 'L'. DELETE gt_cand WHERE signal <> icon_led_yellow.
    WHEN 'X'. DELETE gt_cand WHERE signal <> icon_led_red.
  ENDCASE.
  IF c_src IS NOT INITIAL AND c_src <> 'ALL'.
    DELETE gt_cand WHERE src_type <> c_src.
  ENDIF.
  " 기본정렬: 희망납기일 빠른 PR부터(같은 날이면 업체·자재 순으로 묶음끼리 붙여 보이게)
  SORT gt_cand BY lfdat lifnr matnr banfn bnfpo.
  gv_key2 = |{ c_bupla }/{ c_matnr }/{ c_lifnr }/{ c_lfdat }/{ c_stat }/{ c_src }|.
  IF gt_cand IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.   " 조회 조건에 해당하는 데이터가 없습니다
  ENDIF.
  PERFORM refresh_cand.
ENDFORM.

" cand_filter_changed : 후보조건이 마지막 조회와 달라졌는지 본다.
FORM cand_filter_changed CHANGING cv_changed TYPE abap_bool.
  DATA(lv_now) = |{ c_bupla }/{ c_matnr }/{ c_lifnr }/{ c_lfdat }/{ c_stat }/{ c_src }|.
  cv_changed = xsdbool( lv_now <> gv_key2 ).
ENDFORM.

" show_cand : 0200의 후보 ALV를 처음 한 번 만들고, PR 목록에서 넘어온 PR을 미리 선택한다.
FORM show_cand.
  IF go_grid2 IS BOUND.
    RETURN.
  ENDIF.
  CREATE OBJECT go_cont2 EXPORTING container_name = 'CC_PR'.
  CREATE OBJECT go_grid2 EXPORTING i_parent = go_cont2.
  DATA lt_cat TYPE lvc_t_fcat.
  PERFORM add_fc USING 'SIGNAL' `상태` 4 CHANGING lt_cat.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM add_fc USING 'SCHEDULE' `납기판단` 9 CHANGING lt_cat.
  PERFORM add_fc USING 'BANFN' `PR 번호` 11 CHANGING lt_cat.
  PERFORM add_fc USING 'SRC_TEXT' `요청구분` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'MATNR' `자재번호` 12 CHANGING lt_cat.
  PERFORM add_fc USING 'MAKTX' `자재명` 18 CHANGING lt_cat.
  PERFORM add_fc USING 'MENGE' `요청수량` 9 CHANGING lt_cat.
  PERFORM add_fc USING 'MEINS' `단위` 4 CHANGING lt_cat.
  PERFORM add_fc USING 'VENDOR_NAME' `공급업체` 14 CHANGING lt_cat.
  PERFORM add_fc USING 'SITE_TEXT' `구매지사` 12 CHANGING lt_cat.
  PERFORM add_fc USING 'WERKS' `입고플랜트` 7 CHANGING lt_cat.
  PERFORM add_fc USING 'NETPR' `구매단가` 11 CHANGING lt_cat.
  PERFORM add_fc USING 'WAERS' `통화` 0 CHANGING lt_cat.
  PERFORM add_fc USING 'LFDAT' `희망납기일` 10 CHANGING lt_cat.
  PERFORM add_fc USING 'ETA' `예상입고일` 10 CHANGING lt_cat.
  " 같은 업체·자재 PR이 몇 건 묶이는지는 생성 확인창의 "PO N건(PR M건)"으로 보여준다.
  PERFORM add_fc USING 'DETAIL' `안내` 30 CHANGING lt_cat.
  PERFORM quantity_catalog USING gt_cand CHANGING lt_cat.
  DATA lt_excl TYPE ui_functions.
  PERFORM toolbar_excluded CHANGING lt_excl.
  go_grid2->set_table_for_first_display(
    EXPORTING is_layout = VALUE lvc_s_layo( zebra = abap_true sel_mode = 'A' info_fname = 'ROWCLR'
      smalltitle = abap_true grid_title = |발주 후보 PR · { lines( gt_cand ) }건| )
      it_toolbar_excluding = lt_excl
    CHANGING it_outtab = gt_cand it_fieldcatalog = lt_cat ).
  PERFORM preselect_cand.
ENDFORM.

" preselect_cand : PR 목록에서 넘어온 PR 중 발주 가능한 행을 미리 선택한다.
FORM preselect_cand.
  IF gt_presel IS INITIAL OR go_grid2 IS NOT BOUND.
    RETURN.
  ENDIF.
  " PR 목록·PUR에서 넘겨받은 PR을 후보 목록에서 찾아 그대로 선택해 둔다(빨간 발주불가 행도 선택).
  "   빨간 행이 섞인 채 [PO 생성]을 누르면 create_po_selected에서 그 PR 번호로 막고, 사유는 안내 열에 보인다.
  DATA lt_rows TYPE lvc_t_row.
  LOOP AT gt_presel INTO DATA(ls_pre).
    READ TABLE gt_cand TRANSPORTING NO FIELDS WITH KEY banfn = ls_pre-banfn bnfpo = ls_pre-bnfpo.
    IF sy-subrc = 0.
      APPEND VALUE #( index = sy-tabix ) TO lt_rows.
    ENDIF.
  ENDLOOP.
  CLEAR gt_presel.
  go_grid2->set_selected_rows( it_index_rows = lt_rows ).
ENDFORM.

" refresh_cand : 조회 후 이미 떠 있는 후보 ALV를 새 데이터로 갱신한다.
FORM refresh_cand.
  IF go_grid2 IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA lt_cat TYPE lvc_t_fcat.
  go_grid2->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_cat ).
  PERFORM quantity_catalog USING gt_cand CHANGING lt_cat.
  go_grid2->set_frontend_fieldcatalog( it_fieldcatalog = lt_cat ).
  DATA lv_title TYPE lvc_title.
  lv_title = |발주 후보 PR · { lines( gt_cand ) }건|.
  go_grid2->set_gridtitle( i_gridtitle = lv_title ).
  go_grid2->set_selected_rows( it_index_rows = VALUE lvc_t_row( ) ).
  go_grid2->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  PERFORM preselect_cand.
ENDFORM.

" free_cand_grid : 0200을 떠나기 전에 후보 ALV를 정리한다.
FORM free_cand_grid.
  IF go_grid2 IS BOUND.
    go_grid2->free( ).
    FREE go_grid2.
  ENDIF.
  IF go_cont2 IS BOUND.
    go_cont2->free( ).
    FREE go_cont2.
  ENDIF.
ENDFORM.

" create_po_selected : 선택 PR을 업체·자재별로 묶어 PO를 만든다.
"   1) 선택 검사  2) 묶음 검사  3) 확인창  4) 묶음별 저장(건별 COMMIT/ROLLBACK)
"   발주할 수 없는 PR(발주불가·묶음 최소발주량 미만)은 막지 않고 빼고, 확인창에 PR 번호와 사유를 보여준다.
"   고른 PR이 모두 발주할 수 없으면 사유 팝업만 띄우고 끝낸다.
FORM create_po_selected.
  IF go_grid2 IS NOT BOUND.
    RETURN.
  ENDIF.
  DATA lt_idx TYPE lvc_t_row.
  go_grid2->get_selected_rows( IMPORTING et_index_rows = lt_idx ).
  IF lt_idx IS INITIAL.
    MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
    RETURN.
  ENDIF.
  IF n_ekgrp IS INITIAL.
    MESSAGE s121(z8_msg) DISPLAY LIKE 'E' WITH '구매그룹'.   " &1은 필수 입력입니다.
    RETURN.
  ENDIF.
  " 1) 선택 검사
  DATA: lt_sel TYPE STANDARD TABLE OF ty_sel WITH EMPTY KEY,
        lt_skip TYPE string_table.             " 빼는 PR: 'PR번호(사유)' - 확인창·팝업용
  LOOP AT lt_idx INTO DATA(ls_idx).
    READ TABLE gt_cand INTO DATA(ls_row) INDEX ls_idx-index.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    IF ls_row-ebeln IS NOT INITIAL.
      " 방금 PO를 만든 행(파란 줄)이 선택에 남아 있어도 막지 않고 뺀다.
      APPEND |{ ls_row-banfn ALPHA = OUT }(이미 PO 생성)| TO lt_skip.
      CONTINUE.
    ENDIF.
    IF ls_row-ok = abap_false.
      APPEND |{ ls_row-banfn ALPHA = OUT }({ ls_row-detail })| TO lt_skip.   " 발주불가: 빼고 사유만 알린다
      CONTINUE.
    ENDIF.
    APPEND VALUE #( banfn = ls_row-banfn bnfpo = ls_row-bnfpo lifnr = ls_row-lifnr matnr = ls_row-matnr
      werks = ls_row-werks lgort = ls_row-lgort meins = ls_row-meins menge = ls_row-menge
      late = ls_row-late ) TO lt_sel.
  ENDLOOP.
  " 2) 묶음 검사: 같은 업체·자재·지사·창고·단위 = 한 PO. 합계가 최소발주량 이상이어야 한다.
  "   선택한 PR만으로 합계가 모자라는 묶음은 통째로 빼고(사유 기록) 남은 묶음을 저장한다.
  DATA: lt_grp TYPE STANDARD TABLE OF ty_grp WITH EMPTY KEY,
        ls_prev_sel TYPE ty_sel,
        lv_gno TYPE i,
        lv_late TYPE i,
        lt_reject TYPE STANDARD TABLE OF i WITH EMPTY KEY.
  " 묶음은 한 번 만든다. 최소발주량 미달 묶음은 번호를 기억했다가 함께 뺀다.
  CLEAR: lt_grp, ls_prev_sel, lv_gno, lv_late, lt_reject.
  SORT lt_sel BY lifnr matnr werks lgort meins banfn bnfpo.
  LOOP AT lt_sel ASSIGNING FIELD-SYMBOL(<sel>).
    IF lv_gno = 0 OR <sel>-lifnr <> ls_prev_sel-lifnr OR <sel>-matnr <> ls_prev_sel-matnr
      OR <sel>-werks <> ls_prev_sel-werks OR <sel>-lgort <> ls_prev_sel-lgort
      OR <sel>-meins <> ls_prev_sel-meins.
      lv_gno = lv_gno + 1.
      APPEND VALUE #( gno = lv_gno banfn = <sel>-banfn bnfpo = <sel>-bnfpo
        lifnr = <sel>-lifnr matnr = <sel>-matnr ) TO lt_grp.
    ENDIF.
    <sel>-gno = lv_gno.
    READ TABLE lt_grp ASSIGNING FIELD-SYMBOL(<grp>) INDEX lv_gno.
    <grp>-total = <grp>-total + <sel>-menge.
    <grp>-count = <grp>-count + 1.
    IF <sel>-late = abap_true.
      lv_late = lv_late + 1.
    ENDIF.
    ls_prev_sel = <sel>.
  ENDLOOP.
  LOOP AT lt_grp INTO DATA(ls_grp_chk).
    READ TABLE gt_quote INTO DATA(ls_quote_chk) WITH KEY banfn = ls_grp_chk-banfn bnfpo = ls_grp_chk-bnfpo.
    IF sy-subrc <> 0.
      MESSAGE s114(z8_msg) DISPLAY LIKE 'E'.   " 데이터 조회에 실패했습니다(가격 정보 없음, 다시 조회)
      RETURN.
    ENDIF.
    IF ls_grp_chk-total < ls_quote_chk-price-minbm.
      DATA lv_total_txt TYPE string.
      DATA lv_min_txt TYPE string.
      PERFORM qty_text USING ls_grp_chk-total CHANGING lv_total_txt.
      PERFORM qty_text USING ls_quote_chk-price-minbm CHANGING lv_min_txt.
      " 사유는 그 묶음 행의 처리 안내에도 남기고, 이 묶음은 생성 대상에서 뺀다.
      LOOP AT lt_sel INTO DATA(ls_moq) WHERE gno = ls_grp_chk-gno.
        READ TABLE gt_cand ASSIGNING FIELD-SYMBOL(<cand_moq>) WITH KEY banfn = ls_moq-banfn bnfpo = ls_moq-bnfpo.
        IF sy-subrc = 0.
          <cand_moq>-detail = |묶음 수량 { lv_total_txt } < 최소발주량 { lv_min_txt }|.
        ENDIF.
        APPEND |{ ls_moq-banfn ALPHA = OUT }(묶음 수량 { lv_total_txt } < 최소발주량 { lv_min_txt })| TO lt_skip.
      ENDLOOP.
      DELETE lt_sel WHERE gno = ls_grp_chk-gno.
      APPEND ls_grp_chk-gno TO lt_reject.
    ENDIF.
  ENDLOOP.
  LOOP AT lt_reject INTO DATA(lv_reject).
    DELETE lt_grp WHERE gno = lv_reject.
  ENDLOOP.
  " 묶음번호에 빈 번호가 있어도 연결에는 지장이 없다. 화면 건수는 남은 묶음 수이다.
  lv_gno = lines( lt_grp ).
  CLEAR lv_late.
  LOOP AT lt_sel TRANSPORTING NO FIELDS WHERE late = abap_true.
    lv_late = lv_late + 1.
  ENDLOOP.
  " 빼는 PR 목록 글자: 앞 2건 + '외 N건'
  DATA lv_skip_txt TYPE string.
  LOOP AT lt_skip INTO DATA(lv_skip_one) FROM 1 TO 2.
    lv_skip_txt = COND #( WHEN lv_skip_txt IS INITIAL THEN lv_skip_one ELSE |{ lv_skip_txt }, { lv_skip_one }| ).
  ENDLOOP.
  IF lines( lt_skip ) > 2.
    lv_skip_txt = |{ lv_skip_txt } 외 { lines( lt_skip ) - 2 }건|.
  ENDIF.
  " 고른 PR이 모두 발주할 수 없으면 사유 팝업만 보여주고 끝낸다(선택·안내 칸 유지).
  IF lt_sel IS INITIAL.
    IF lt_skip IS INITIAL.
      MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.   " 처리할 행을 선택해주세요
      RETURN.
    ENDIF.
    DATA: lv_inf2 TYPE c LENGTH 70,
          lv_inf3 TYPE c LENGTH 70,
          lv_inf4 TYPE c LENGTH 70.
    lv_inf2 = lt_skip[ 1 ].
    IF lines( lt_skip ) >= 2.
      lv_inf3 = lt_skip[ 2 ].
    ENDIF.
    lv_inf4 = COND #( WHEN lines( lt_skip ) > 2 THEN |외 { lines( lt_skip ) - 2 }건 · 사유는 안내 칸을 참고하세요.|
                      ELSE `사유는 안내 칸을 참고하세요.` ).
    CALL FUNCTION 'POPUP_TO_INFORM'
      EXPORTING titel = 'PO 생성'
        txt1 = '선택한 PR은 모두 발주할 수 없습니다.'
        txt2 = lv_inf2 txt3 = lv_inf3 txt4 = lv_inf4.
    go_grid2->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
    go_grid2->set_selected_rows( it_index_rows = lt_idx ).
    RETURN.
  ENDIF.
  " 3) 확인창: 빼는 PR이 있으면 번호와 사유를 함께 보여준다.
  DATA lv_question TYPE c LENGTH 400.
  DATA lv_answer TYPE c LENGTH 1.
  DATA lv_late_txt TYPE string.
  IF lv_late > 0.
    lv_late_txt = |, 납기 지연 { lv_late }건 포함|.
  ENDIF.
  " 짧게: "PR00000330(최소발주량 100 미만) 제외. PO 2건(PR 2건, 납기 지연 1건 포함)을 생성할까요?"
  IF lt_skip IS NOT INITIAL.
    lv_question = |{ lv_skip_txt } 제외. PO { lv_gno }건(PR { lines( lt_sel ) }건{ lv_late_txt })을 생성할까요?|.
  ELSE.
    lv_question = |PO { lv_gno }건(PR { lines( lt_sel ) }건{ lv_late_txt })을 생성할까요?|.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING titlebar = 'PO 생성' text_question = lv_question
      default_button = '1' display_cancel_button = space
    IMPORTING answer = lv_answer EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    " [아니오]: 묶음 최소발주량 안내가 바뀐 행이 있을 수 있어 화면만 다시 그린다(선택 유지).
    go_grid2->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
    go_grid2->set_selected_rows( it_index_rows = lt_idx ).
    RETURN.
  ENDIF.
  " 4) 묶음별 저장
  DATA lv_ng TYPE i.
  DATA lt_created TYPE string_table.        " 생성한 PO 번호(완료 메시지용)
  LOOP AT lt_grp INTO DATA(ls_grp).
    DATA lt_reqs TYPE lcl_mm_common=>ty_prs.
    CLEAR lt_reqs.
    LOOP AT lt_sel INTO DATA(ls_member) WHERE gno = ls_grp-gno.
      READ TABLE gt_pr INTO DATA(ls_req) WITH KEY banfn = ls_member-banfn bnfpo = ls_member-bnfpo.
      IF sy-subrc = 0.
        APPEND ls_req TO lt_reqs.
      ENDIF.
    ENDLOOP.
    READ TABLE gt_quote INTO DATA(ls_quote) WITH KEY banfn = ls_grp-banfn bnfpo = ls_grp-bnfpo.
    DATA(lv_quote_found) = xsdbool( sy-subrc = 0 ).
    TRY.
        IF lv_quote_found = abap_false OR lines( lt_reqs ) <> ls_grp-count.
          lcl_mm_common=>fail( `조회 정보가 맞지 않습니다. 조회 후 다시 선택하세요.` ).
        ENDIF.
        lcl_mm_common=>lock( ).
        DATA(lv_po) = lcl_mm_purchase=>create_po( requests = lt_reqs
          purchasing_org = lcl_mm_purchase=>c_ekorg purchasing_group = n_ekgrp
          expected_price = ls_quote-price expected_arrival = ls_quote-arrival ).
        COMMIT WORK AND WAIT.
        lcl_mm_common=>unlock( ).
        INSERT lv_po INTO TABLE gt_new_po.
        APPEND CONV string( lv_po ) TO lt_created.
        LOOP AT lt_sel INTO DATA(ls_m_ok) WHERE gno = ls_grp-gno.
          READ TABLE gt_cand ASSIGNING FIELD-SYMBOL(<cand_ok>) WITH KEY banfn = ls_m_ok-banfn bnfpo = ls_m_ok-bnfpo.
          IF sy-subrc = 0.
            <cand_ok>-ebeln = lv_po.
            <cand_ok>-state = 'PO 생성'.
            <cand_ok>-signal = icon_led_green.
            <cand_ok>-rowclr = 'C410'.        " 방금 PO 만든 PR 파란 줄
            <cand_ok>-detail = |PO { lv_po ALPHA = OUT } 생성 완료|.
          ENDIF.
        ENDLOOP.
      CATCH lcx_mm INTO DATA(lx_create).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_ng = lv_ng + 1.
        LOOP AT lt_sel INTO DATA(ls_m_bad) WHERE gno = ls_grp-gno.
          READ TABLE gt_cand ASSIGNING FIELD-SYMBOL(<cand_bad>) WITH KEY banfn = ls_m_bad-banfn bnfpo = ls_m_bad-bnfpo.
          IF sy-subrc = 0.
            <cand_bad>-state = '생성실패'.
            <cand_bad>-signal = icon_led_red.
            <cand_bad>-rowclr = 'C610'.
            <cand_bad>-detail = lx_create->detail.
          ENDIF.
        ENDLOOP.
      CATCH cx_root INTO DATA(lx_root_create).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_ng = lv_ng + 1.
        LOOP AT lt_sel INTO DATA(ls_m_bad2) WHERE gno = ls_grp-gno.
          READ TABLE gt_cand ASSIGNING FIELD-SYMBOL(<cand_bad2>) WITH KEY banfn = ls_m_bad2-banfn bnfpo = ls_m_bad2-bnfpo.
          IF sy-subrc = 0.
            <cand_bad2>-state = '생성실패'.
            <cand_bad2>-signal = icon_led_red.
            <cand_bad2>-rowclr = 'C610'.
            <cand_bad2>-detail = lx_root_create->get_text( ).
          ENDIF.
        ENDLOOP.
    ENDTRY.
  ENDLOOP.
  IF lv_ng > 0.
    MESSAGE s060(z8_msg) DISPLAY LIKE 'E'.   " 저장에 실패했습니다(사유는 행의 처리 안내)
  ELSE.
    DATA(lv_created_txt) = lcl_mm_f4=>doc_text( lt_created ).
    MESSAGE i133(z8_msg) WITH lv_created_txt '생성'.   " &1 &2 완료 (생성 완료는 팝업 I)
  ENDIF.
  go_grid2->refresh_table_display( EXPORTING is_stable = VALUE #( row = abap_true col = abap_true ) ).
  " 방금 PO가 만들어진 후보 행을 선택 상태로 걸어 둔다(선택 해제하지 않음).
  DATA lt_done TYPE lvc_t_row.
  LOOP AT gt_cand TRANSPORTING NO FIELDS WHERE ebeln IS NOT INITIAL AND rowclr = 'C410'.
    APPEND VALUE #( index = sy-tabix ) TO lt_done.
  ENDLOOP.
  go_grid2->set_selected_rows( it_index_rows = lt_done ).
ENDFORM.

" ------------------------------------------------------------
" 표시 문구 / 화면 0100 오른쪽 상태카드
" ------------------------------------------------------------

" cand_listbox : PO 생성 후보조건의 상태(c_stat)·요청구분(c_src) 드롭다운 목록을 채운다.
FORM cand_listbox.
  DATA lt_values TYPE vrm_values.
  lt_values = VALUE #( ( key = 'A' text = '전체' )
                       ( key = 'G' text = '정상(초록)' )
                       ( key = 'L' text = '주의(노랑)' )   " 납기지연 · 최소발주량 미만
                       ( key = 'X' text = '발주불가(빨강)' ) ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING id = 'C_STAT' values = lt_values
    EXCEPTIONS id_illegal_name = 1 OTHERS = 2.
  " 요청구분 목록 = 도메인 Z8D_SOURCE_TYPE 고정값(SE11). 맨 위 '전체'만 프로그램이 붙인다.
  lt_values = VALUE #( ( key = 'ALL' text = '전체' ) ).
  DATA(lt_src) = lcl_mm_f4=>domain_values( 'Z8D_SOURCE_TYPE' ).
  LOOP AT lt_src INTO DATA(ls_src).
    IF ls_src-value = 'STO_REPL'.
      CONTINUE.                          " STO 재보충은 더 이상 PR로 만들지 않는다(PO 대상 아님)
    ENDIF.
    APPEND VALUE #( key = ls_src-value text = ls_src-text ) TO lt_values.
  ENDLOOP.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING id = 'C_SRC' values = lt_values
    EXCEPTIONS id_illegal_name = 1 OTHERS = 2.
ENDFORM.

" source_text : PR 요청구분 코드(SOURCE_TYPE)를 도메인 고정값 내역으로 바꾼다. DB 값은 그대로이다.
FORM source_text USING iv_type TYPE clike CHANGING ev_text TYPE clike.
  " 요청구분 = Z8MM_PR-SOURCE_TYPE. 화면 글자는 도메인 Z8D_SOURCE_TYPE 고정값 내역을 그대로 쓴다.
  ev_text = lcl_mm_f4=>domain_text( domain = 'Z8D_SOURCE_TYPE' value = iv_type ).
ENDFORM.

" show_cards : 상태별 PO 품목 건수를 카드로 보여준다. 건수가 같으면 다시 그리지 않는다.
FORM show_cards.
  DATA: lv_all TYPE i, lv_wait TYPE i, lv_done TYPE i, lv_void TYPE i.
  lv_all = lines( gt_po_all ).
  LOOP AT gt_po_all INTO DATA(ls_card_row).
    CASE ls_card_row-state.
      WHEN '입고대기' OR '부분입고'.
        lv_wait = lv_wait + 1.
      WHEN '입고완료'.
        lv_done = lv_done + 1.
      WHEN '취소'.
        lv_void = lv_void + 1.
    ENDCASE.
  ENDLOOP.
  DATA lv_active TYPE c LENGTH 1.
  lv_active = p_state.
  IF lv_active IS INITIAL.
    lv_active = 'A'.
  ENDIF.
  DATA(lv_stamp) = |{ lv_all }/{ lv_wait }/{ lv_done }/{ lv_void }/{ lv_active }|.
  IF go_card_html IS BOUND AND lv_stamp = gv_card_stamp.
    RETURN.
  ENDIF.
  IF go_card_box IS NOT BOUND.
    CREATE OBJECT go_card_box EXPORTING container_name = 'CC_SUM' EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_card_html IS NOT BOUND.
    CREATE OBJECT go_card_html EXPORTING parent = go_card_box EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CREATE OBJECT go_card_events.
    SET HANDLER go_card_events->on_click FOR go_card_html.
    DATA lt_events TYPE cntl_simple_events.
    lt_events = VALUE #( ( eventid = cl_gui_html_viewer=>m_id_sapevent appl_event = abap_false ) ).
    go_card_html->set_registered_events( EXPORTING events = lt_events EXCEPTIONS OTHERS = 1 ).
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
  APPEND 'border-radius:8px;padding:8px 2px}a.c:hover{border-color:#1684bf;background:#f3f9ff}' TO lt_html.
  APPEND 'a.on{border:2px solid #1684bf;background:#edf6ff;padding:7px 1px}' TO lt_html.
  APPEND '.v{font-size:22px;font-weight:bold;color:#243b53;padding-top:3px}' TO lt_html.
  APPEND '.d{display:inline-block;width:8px;height:8px;border-radius:4px;margin-right:4px}' TO lt_html.
  APPEND '.g{background:#2e9d4f}.y{background:#e3b100}.r{background:#d34343}.n{background:#9aa9bb}' TO lt_html.
  APPEND '.t{font-size:11px;color:#8090a0;padding:6px 6px 0}</style></head><body><div class="p"><table><tr>' TO lt_html.
  PERFORM card_cell USING 'ALL' 'A' lv_active 'n' '&#51204;&#52404;' lv_all CHANGING lt_html.
  PERFORM card_cell USING 'WAIT' 'W' lv_active 'y' '&#51077;&#44256;&#45824;&#44592;' lv_wait CHANGING lt_html.
  PERFORM card_cell USING 'DONE' 'F' lv_active 'g' '&#51077;&#44256;&#50756;&#47308;' lv_done CHANGING lt_html.
  PERFORM card_cell USING 'VOID' 'X' lv_active 'r' '&#52712;&#49548;' lv_void CHANGING lt_html.
  " 아래 안내: 카드를 누르면 해당 상태만 조회
  APPEND '</tr></table></div></body></html>' TO lt_html.
  DATA lv_url TYPE c LENGTH 255.
  go_card_html->load_data( EXPORTING type = 'text' subtype = 'html'
    IMPORTING assigned_url = lv_url CHANGING data_table = lt_html EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  go_card_html->show_url( EXPORTING url = lv_url in_place = abap_true EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    gv_card_stamp = lv_stamp.
  ENDIF.
ENDFORM.

" card_cell : 카드 한 칸의 HTML을 만든다. 선택된 카드는 파란 테두리이다.
FORM card_cell USING iv_action TYPE clike iv_key TYPE clike iv_active TYPE clike
                     iv_dot TYPE clike iv_label TYPE clike iv_count TYPE i
               CHANGING ct_html TYPE STANDARD TABLE.
  DATA lv_class TYPE string.
  lv_class = 'c'.
  IF iv_key = iv_active.
    lv_class = 'c on'.
  ENDIF.
  DATA lv_line TYPE w3html.
  lv_line-line = |<td><a class="{ lv_class }" href="SAPEVENT:{ iv_action }"><span class="d { iv_dot }"></span>|.
  APPEND lv_line TO ct_html.
  lv_line-line = |{ iv_label }<div class="v">{ iv_count NUMBER = RAW }</div></a></td>|.
  APPEND lv_line TO ct_html.
ENDFORM.

" apply_card : 카드 클릭 후 PAI에서 상태조건을 바꾸고 다시 조회한다. 저장은 하지 않는다.
FORM apply_card.
  CASE gv_card_action.
    WHEN 'ALL'.
      p_state = 'A'.
    WHEN 'WAIT'.
      p_state = 'W'.
    WHEN 'DONE'.
      p_state = 'F'.
    WHEN 'VOID'.
      p_state = 'X'.
    WHEN OTHERS.
      CLEAR gv_card_action.
      RETURN.
  ENDCASE.
  CLEAR gv_card_action.
  " 카드는 마지막 조회 결과(gt_po_all) 안에서만 거른다(DB 재조회 없음). 조회조건 변경은 [조회]·Enter로 반영한다.
  PERFORM filter_po.
  PERFORM refresh_po.
ENDFORM.

CLASS lcl_card_events IMPLEMENTATION.
  " on_click : 카드의 SAPEVENT를 받아 PAI(SCARD)를 일으킨다. 여기서는 조회하지 않는다.
  METHOD on_click.
    CASE action.
      WHEN 'ALL' OR 'WAIT' OR 'DONE' OR 'VOID'.
        gv_card_action = action.
        DATA lv_rc TYPE i.
        cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'SCARD' IMPORTING rc = lv_rc ).
        IF lv_rc <> cl_gui_cfw=>rc_posted.
          CLEAR gv_card_action.
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

" branch_plants : 구매지사(B001) → 그 지사의 입고플랜트(P100...) 범위. 지사 비면 전체.
FORM branch_plants USING iv_bupla TYPE clike CHANGING ct_plants TYPE STANDARD TABLE.
  DATA lr_plants TYPE RANGE OF z8mm_pr-werks.
  CLEAR ct_plants.
  IF iv_bupla IS INITIAL.
    RETURN.
  ENDIF.
  SELECT werks FROM z8plant_m WHERE bupla = @iv_bupla INTO TABLE @DATA(lt_site).
  DATA ls_range LIKE LINE OF lr_plants.
  LOOP AT lt_site INTO DATA(ls_site).
    CLEAR ls_range.
    ls_range-sign = 'I'.
    ls_range-option = 'EQ'.
    ls_range-low = ls_site-werks.
    APPEND ls_range TO lr_plants.
  ENDLOOP.
  IF lr_plants IS INITIAL.
    lr_plants = VALUE #( ( sign = 'I' option = 'EQ' low = '####' ) ).   " 플랜트 없는 지사 → 결과 없음
  ENDIF.
  ct_plants = lr_plants.
ENDFORM.

" branch_name : 구매지사 코드 → 지사명(z8branch_m)
FORM branch_name USING iv_bupla TYPE clike CHANGING ev_name TYPE clike.
  DATA lv_name TYPE z8branch_m-name.
  CLEAR ev_name.
  SELECT name FROM z8branch_m WHERE branch = @iv_bupla INTO @lv_name UP TO 1 ROWS.
  ENDSELECT.
  ev_name = lv_name.
ENDFORM.
