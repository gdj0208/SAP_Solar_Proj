*&---------------------------------------------------------------------*
*& Include Z8MMB0100_F01
*&---------------------------------------------------------------------*
*& 배치 처리 FORM - 예약 STO 출고(351) → 이동중 STO 입고(101) → 결과 ALV
*& 담당: MM(이규빈) / 프로그램: Z8MMB0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-22  이규빈  최초 개발   최초 작성: 예상도착일이 된 이동중 STO 자동 101 입고 배치 (개발 10/22~10/26)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 예약 STO 351 출고 단계 추가, 모의 실행·결과 표시 보완
*& 2026-11-04  이규빈  수정사항    STO 번호 F4(STO 화면과 같은 공통 검색) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" execute_batch : STO 자동 처리 배치.
" ① 출고일이 도래한 예약 STO를 먼저 351 출고(ship_due) → ② 예상도착일이 도래한 이동중 STO를 101 입고.
"   ①에서 출고된 STO도 예상도착일이 지났으면 같은 실행의 ②에서 입고된다.
" 저장 확정: 공통 저장 호출 성공 후 COMMIT, 오류 시 CATCH에서 ROLLBACK한다.
FORM execute_batch.
  " 같은 실행 세션에서 다시 실행해도 지난 결과가 남지 않도록 초기화한다.
  CLEAR gt_result.
  PERFORM ship_due.                      " ① 예약 STO 출고
  DATA lt_items TYPE SORTED TABLE OF ty_candidate WITH NON-UNIQUE KEY ebeln ebelp.
  IF p_sto IS INITIAL.
    SELECT i~ebeln, i~ebelp, i~sto_arr_date AS eta, i~matnr, i~werks, i~menge, i~meins
      FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
      WHERE h~bsart = 'UB' AND i~loekz = @space AND i~elikz = @space
      AND i~kdauf = @space AND i~sto_arr_date <> '00000000'
      AND i~sto_arr_date <= @gv_asof AND i~sto_rsv_qty = 0      " 아직 출고 전(예약중)은 입고 대상 아님
      ORDER BY i~ebeln, i~ebelp INTO TABLE @lt_items.
  ELSE.
    SELECT i~ebeln, i~ebelp, i~sto_arr_date AS eta, i~matnr, i~werks, i~menge, i~meins
      FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
      WHERE h~bsart = 'UB' AND h~ebeln = @p_sto
      AND i~loekz = @space AND i~elikz = @space
      AND i~kdauf = @space AND i~sto_arr_date <> '00000000'
      AND i~sto_arr_date <= @gv_asof AND i~sto_rsv_qty = 0
      ORDER BY i~ebeln, i~ebelp INTO TABLE @lt_items.
  ENDIF.
  " STO 단위로 입고한다. 한 STO의 품목 N개 → 101 자재문서 1건(N줄).
  "   한 품목이라도 실패하면 그 STO 전체를 ROLLBACK하고 다음 실행에서 다시 시도한다.
  "   결과 목록은 품목별 한 줄이며, 같은 STO의 품목은 같은 입고 자재문서번호를 가진다.
  " 문서번호 목록에서 중복을 지운다. 같은 STO는 한 번만 저장한다.
  DATA lt_docs TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line.
  LOOP AT lt_items INTO DATA(ls_first).
    INSERT ls_first-ebeln INTO TABLE lt_docs.
  ENDLOOP.
  LOOP AT lt_docs INTO DATA(lv_sto).
    DATA lv_result TYPE c LENGTH 12.
    DATA lv_detail TYPE c LENGTH 120.
    DATA lv_signal TYPE icon_d.
    DATA lv_belnr TYPE z8mm_sto_hist-belnr.
    CLEAR: lv_result, lv_detail, lv_signal, lv_belnr.
    TRY.
      " 저장 직전에 잠금을 확보한다. 성공·실패 모두 unlock으로 해제해야 한다.
      lcl_mm_common=>lock( ).
      DATA(lv_doc) = lcl_mm_sto=>receive_sto( document = lv_sto asof = gv_asof simulation = p_sim ).
      IF p_sim = abap_true.
        " 모의실행: 검사만 하고 DB 변경을 되돌린다.
        ROLLBACK WORK.
        lv_result = '점검 완료'.
        lv_signal = icon_led_green.
        lv_detail = '입고할 수 있습니다 (모의 실행이라 저장하지 않음)'.
      ELSE.
        " 이 STO의 DB 변경을 확정한다. 이전에 성공한 STO는 다음 STO 오류로 취소되지 않는다.
        COMMIT WORK AND WAIT.
        lv_result = '입고 완료'.
        lv_signal = icon_led_green.
        lv_detail = '입고 완료: 도착 지사 재고에 반영했습니다'.
        lv_belnr = lv_doc.
      ENDIF.
      lcl_mm_common=>unlock( ).
    CATCH lcx_mm INTO DATA(lx_mm).
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      lv_result = '처리 실패'.
      lv_signal = icon_led_red.
      lv_detail = lx_mm->detail.
    CATCH cx_root INTO DATA(lx_unexpected).
      ROLLBACK WORK.
      lcl_mm_common=>unlock( ).
      lv_result = '처리 실패'.
      lv_signal = icon_led_red.
      lv_detail = lx_unexpected->get_text( ).
    ENDTRY.
    " 문서번호가 정렬키의 첫 필드라 해당 STO 품목만 찾는다.
    LOOP AT lt_items INTO DATA(ls_item) WHERE ebeln = lv_sto.
      DATA(ls_result) = CORRESPONDING ty_result( ls_item ).
      ls_result-result = lv_result.
      ls_result-signal = lv_signal.
      ls_result-detail = lv_detail.
      ls_result-belnr = lv_belnr.
      ls_result-step = '입고 101'.
      APPEND ls_result TO gt_result.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

" ------------------------------------------------------------
" FORM display_results : 배치 실행이면 스풀용 WRITE, 직접 실행이면 SALV로 결과를 표시한다.
" ------------------------------------------------------------
FORM display_results.
  IF gt_result IS INITIAL.
    MESSAGE s061(z8_msg).   " 조회 조건에 해당하는 데이터가 없습니다
    RETURN.
  ENDIF.
  IF sy-batch = abap_true.
    LOOP AT gt_result INTO DATA(ls_line).
      WRITE: / ls_line-signal AS ICON, ls_line-step, ls_line-ebeln, ls_line-ebelp, ls_line-matnr, ls_line-werks,
        ls_line-menge UNIT ls_line-meins, ls_line-meins, ls_line-result, ls_line-belnr, ls_line-detail.
    ENDLOOP.
  ELSE.
    TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
        CHANGING t_table = gt_result ).
      " PO·PR·STO 화면과 같이: 맨 앞 1구 LED, 제목에 성공/실패 건수. 정렬은 머리글 오른쪽 클릭.
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_columns( )->set_optimize( abap_true ).
      DATA lv_ok TYPE i.
      LOOP AT gt_result TRANSPORTING NO FIELDS WHERE signal = icon_led_green.
        lv_ok = lv_ok + 1.
      ENDLOOP.
      DATA(lv_ng) = lines( gt_result ) - lv_ok.
      lo_alv->get_display_settings( )->set_list_header(
        CONV lvc_title( |STO 자동 출고·입고 결과 · 정상 { lv_ok }건 / 실패 { lv_ng }건{ COND string( WHEN p_sim = abap_true THEN ` (시뮬레이션: 저장 안 함)` ) }| ) ).
      PERFORM batch_column USING lo_alv 'SIGNAL' `상태`.
      PERFORM batch_column USING lo_alv 'STEP' `처리`.
      PERFORM batch_column USING lo_alv 'EBELN' `STO 번호`.
      PERFORM batch_column USING lo_alv 'EBELP' `품목`.
      PERFORM batch_column USING lo_alv 'ETA' `처리기준일`.   " 출고=출고일, 입고=예상도착일
      PERFORM batch_column USING lo_alv 'MATNR' `자재`.
      PERFORM batch_column USING lo_alv 'WERKS' `플랜트`.   " 출고=출발, 입고=도착
      PERFORM batch_column USING lo_alv 'MENGE' `수량`.
      PERFORM batch_column USING lo_alv 'MEINS' `단위`.
      PERFORM batch_column USING lo_alv 'BELNR' `자재문서`.
      PERFORM batch_column USING lo_alv 'RESULT' `처리결과`.
      PERFORM batch_column USING lo_alv 'DETAIL' `안내`.
      lo_alv->display( ).
    CATCH cx_salv_msg.
      MESSAGE s120(z8_msg) DISPLAY LIKE 'E' WITH '결과'.   " &1 ALV를 그리는데 실패했습니다
    ENDTRY.
  ENDIF.
ENDFORM.

" ------------------------------------------------------------
" FORM batch_column : SALV 열의 한글 제목과 수량 표시를 설정한다.
" USING은 받는 값, CHANGING은 호출한 쪽에 돌려줄 변경값이다.
" ------------------------------------------------------------
FORM batch_column USING alv TYPE REF TO cl_salv_table name TYPE clike title TYPE string.
  TRY.
    DATA(column) = alv->get_columns( )->get_column( CONV lvc_fname( name ) ).
    column->set_short_text( CONV scrtext_s( title ) ).
    column->set_medium_text( CONV scrtext_m( title ) ).
    column->set_long_text( CONV scrtext_l( title ) ).
    IF name = 'SIGNAL'.
      CAST cl_salv_column_table( column )->set_icon( if_salv_c_bool_sap=>true ).
      column->set_output_length( 4 ).
    ENDIF.
    IF name = 'MENGE'.
      DATA(table_column) = CAST cl_salv_column_table( column ).
      table_column->set_quantity_column( 'MEINS' ).
      DATA decimals TYPE lvc_decmls VALUE '0'.
      LOOP AT gt_result INTO DATA(quantity_row).
        IF quantity_row-menge <> trunc( quantity_row-menge ).
          decimals = '3'.
          EXIT.
        ENDIF.
      ENDLOOP.
      table_column->set_decimals( decimals ).
    ENDIF.
  CATCH cx_salv_not_found cx_salv_data_error.
    RETURN.
  ENDTRY.
ENDFORM.

" ------------------------------------------------------------
" FORM ship_due : 출고일(STO_DEP_DATE)이 도래한 예약 STO(STO_RSV_QTY > 0)를 STO 단위로 351 출고한다.
"   STO마다 잠금 → lcl_mm_sto=>ship_sto → COMMIT(모의실행이면 ROLLBACK) → 잠금해제. 결과는 gt_result에 '출고 351'로.
" ------------------------------------------------------------
FORM ship_due.
  DATA lt_ship TYPE SORTED TABLE OF ty_candidate WITH NON-UNIQUE KEY ebeln ebelp.
  DATA lr_doc TYPE RANGE OF z8mm_po_h-ebeln.
  IF p_sto IS NOT INITIAL.
    lr_doc = VALUE #( ( sign = 'I' option = 'EQ' low = p_sto ) ).
  ENDIF.
  SELECT i~ebeln, i~ebelp, i~sto_dep_date AS eta, i~matnr, i~reswk AS werks, i~menge, i~meins
    FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
    WHERE h~bsart = 'UB' AND h~ebeln IN @lr_doc
    AND i~loekz = @space AND i~elikz = @space AND i~kdauf = @space
    AND i~sto_rsv_qty > 0 AND i~sto_dep_date <> '00000000' AND i~sto_dep_date <= @gv_asof
    ORDER BY i~ebeln, i~ebelp INTO TABLE @lt_ship.
  " 문서번호 목록에서 중복을 지운다. 같은 STO는 한 번만 저장한다.
  DATA lt_docs TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line.
  LOOP AT lt_ship INTO DATA(ls_first).
    INSERT ls_first-ebeln INTO TABLE lt_docs.
  ENDLOOP.
  LOOP AT lt_docs INTO DATA(lv_sto).
    DATA: lv_result TYPE c LENGTH 12, lv_detail TYPE c LENGTH 120,
          lv_signal TYPE icon_d, lv_belnr TYPE z8mm_sto_hist-belnr.
    CLEAR: lv_result, lv_detail, lv_signal, lv_belnr.
    TRY.
        lcl_mm_common=>lock( ).
        DATA(lv_doc) = lcl_mm_sto=>ship_sto( document = lv_sto asof = gv_asof simulation = p_sim ).
        IF p_sim = abap_true.
          ROLLBACK WORK.
          lv_result = '점검 완료'.
          lv_detail = '출고할 수 있습니다 (모의 실행이라 저장하지 않음)'.
        ELSE.
          COMMIT WORK AND WAIT.
          lv_result = '출고 완료'.
          lv_detail = '출고 완료: 출발 지사에서 보냈습니다 (이동 중)'.
          lv_belnr = lv_doc.
        ENDIF.
        lv_signal = icon_led_green.
        lcl_mm_common=>unlock( ).
      CATCH lcx_mm INTO DATA(lx_ship).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_result = '처리 실패'.
        lv_signal = icon_led_red.
        lv_detail = lx_ship->detail.
      CATCH cx_root INTO DATA(lx_ship_root).
        ROLLBACK WORK.
        lcl_mm_common=>unlock( ).
        lv_result = '처리 실패'.
        lv_signal = icon_led_red.
        lv_detail = lx_ship_root->get_text( ).
    ENDTRY.
    LOOP AT lt_ship INTO DATA(ls_item) WHERE ebeln = lv_sto.
      DATA(ls_res) = CORRESPONDING ty_result( ls_item ).
      ls_res-step = '출고 351'.
      ls_res-result = lv_result.
      ls_res-signal = lv_signal.
      ls_res-detail = lv_detail.
      ls_res-belnr = lv_belnr.
      APPEND ls_res TO gt_result.
    ENDLOOP.
  ENDLOOP.
ENDFORM.
