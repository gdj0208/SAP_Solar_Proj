*&---------------------------------------------------------------------*
*& Include ZMMPR0110_K01
*&---------------------------------------------------------------------*
*& 입력 ALV 이벤트(F4·셀 변경·처리 안내 링크) 로컬 클래스
*& 담당: MM(이규빈) / 프로그램: ZMMPR0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 구매지사 기준 PR 신규 입력·변경·삭제 (개발 10/01~10/06)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 입력 화면 개편(신호등·입력 열 색), 공급업체·희망납기일 자동 채움
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 저장·삭제 메시지 정리, ALV 행 버튼 제거, PR 변경은 수량·희망납기일만
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

CLASS lcl_pr_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS entry_f4 FOR EVENT onf4 OF cl_gui_alv_grid
      IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display.
    METHODS entry_changed FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed.
    METHODS entry_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified.
    " '처리 안내' 칸의 STO 안내(밑줄 링크)를 클릭 → 확인 → STO 생성 화면으로
    METHODS entry_hotspot FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.
CLASS lcl_pr_events IMPLEMENTATION.

  " ------------------------------------------------------------
  " METHOD entry_f4 : PR 입력 ALV에서 자재 또는 공급업체 F4 선택을 처리한다.
  " ------------------------------------------------------------
  METHOD entry_f4.
    IF e_display = abap_true OR ( e_fieldname <> 'MATNR' AND e_fieldname <> 'LIFNR' ).
      RETURN.
    ENDIF.
    er_event_data->m_event_handled = abap_true.
    READ TABLE gt_entry INDEX es_row_no-row_id INTO DATA(row).
    IF sy-subrc <> 0 OR ( gv_mode = 'C' AND gv_posted = abap_true )
      OR ( gv_mode = 'N' AND row-banfn IS NOT INITIAL ).
      RETURN.
    ENDIF.
    IF gv_mode = 'C' AND e_fieldname = 'MATNR'.
      RETURN.
    ENDIF.
    " 칸에 적힌 글자 일부(e_fieldvalue)로 걸러서 보여 준다. 1건이면 목록 없이 바로 들어간다.
    DATA value TYPE c LENGTH 40.
    IF e_fieldname = 'LIFNR' AND row-matnr IS NOT INITIAL.
      " 자재가 있으면 그 자재의 구매단가가 등록된 업체만 단가와 함께 보여준다.
      PERFORM vendor_pick USING row-matnr e_fieldvalue CHANGING value.
    ELSE.
      value = lcl_mm_f4=>pick( kind = COND string( WHEN e_fieldname = 'MATNR' THEN `MAT` ELSE `VEND` )
                               typed = e_fieldvalue ).
    ENDIF.
    IF value IS INITIAL.
      RETURN.
    ENDIF.
    FIELD-SYMBOLS <changes> TYPE lvc_t_modi.
    ASSIGN er_event_data->m_data->* TO <changes>.
    IF sy-subrc = 0.
      APPEND VALUE #( row_id = es_row_no-row_id fieldname = e_fieldname value = value ) TO <changes>.
    ENDIF.
  ENDMETHOD.
  " 수량/필요일 검증과 무관하게 변경된 행의 설명을 채운다.
  METHOD entry_changed.
    DATA row_ids TYPE SORTED TABLE OF i WITH UNIQUE KEY table_line.
    LOOP AT er_data_changed->mt_good_cells INTO DATA(cell).
      INSERT cell-row_id INTO TABLE row_ids.
    ENDLOOP.
    LOOP AT row_ids INTO DATA(row_id).
      READ TABLE gt_entry INDEX row_id INTO DATA(row).
      IF sy-subrc <> 0 OR ( gv_mode = 'N' AND row-banfn IS NOT INITIAL )
        OR ( gv_mode = 'C' AND gv_posted = abap_true ).
        CONTINUE.
      ENDIF.
      " 한 번에 붙여넣은 자재/업체 값도 이벤트 프로토콜에서 읽는다.
      er_data_changed->get_cell_value(
        EXPORTING i_row_id = row_id i_fieldname = 'MATNR' IMPORTING e_value = row-matnr ).
      er_data_changed->get_cell_value(
        EXPORTING i_row_id = row_id i_fieldname = 'LIFNR' IMPORTING e_value = row-lifnr ).
      " 자재·업체 칸에 글자 일부만 넣고 Enter → 1건이면 자동 완성, 여러 건이면 목록에서 고른다.
      DATA(lv_mat_typed) = row-matnr.
      DATA(lv_ven_typed) = row-lifnr.
      IF gv_mode = 'N'.
        lcl_mm_f4=>resolve( EXPORTING kind = 'MAT' CHANGING value = row-matnr ).
      ENDIF.
      lcl_mm_f4=>resolve( EXPORTING kind = 'VEND' CHANGING value = row-lifnr ).
      " 공급업체가 비어 있으면 구매단가가 등록된 업체 중 가장 싼 업체를 자동으로 넣는다.
      IF gv_mode = 'N' AND row-lifnr IS INITIAL AND row-matnr IS NOT INITIAL.
        PERFORM default_vendor CHANGING row.
        IF row-lifnr IS NOT INITIAL.
          lv_ven_typed = space.            " 아래에서 LIFNR 칸을 갱신하도록
        ENDIF.
      ENDIF.
      IF row-matnr <> lv_mat_typed.
        er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'MATNR' i_value = row-matnr ).
      ENDIF.
      IF row-lifnr <> lv_ven_typed.
        er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'LIFNR' i_value = row-lifnr ).
      ENDIF.
      er_data_changed->get_cell_value(
        EXPORTING i_row_id = row_id i_fieldname = 'MENGE' IMPORTING e_value = row-menge ).
      er_data_changed->get_cell_value(
        EXPORTING i_row_id = row_id i_fieldname = 'LFDAT' IMPORTING e_value = row-lfdat ).
      " 날짜를 비우거나 붙여넣기로 날짜 없이 들어오면 위쪽 기본 납기일을 쓴다.
      " (K01은 SEL보다 먼저 INCLUDE되어 n_lfdat을 직접 쓸 수 없으므로 FORM으로 받는다)
      IF row-lfdat IS INITIAL AND gv_mode = 'N'.
        PERFORM default_lfdat CHANGING row-lfdat.
        er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'LFDAT' i_value = row-lfdat ).
      ENDIF.
      " 자재·수량·희망납기일이 다 들어오고 구매지사가 있으면 저장 전에 바로 검사 결과를 보여준다.
      " (구매지사가 비어 있으면 행 안내 대신 상태줄로 '필수 입력'을 알린다)
      PERFORM auto_check CHANGING row.
      " STO 출발 플랜트는 화면 열이 아니라서 내부테이블에 직접 기억한다(처리 안내 링크 클릭용).
      MODIFY gt_entry INDEX row_id FROM row TRANSPORTING sto_from.
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'MAKTX' i_value = row-maktx ).
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'MEINS' i_value = row-meins ).
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'VENDOR_NAME' i_value = row-vendor_name ).
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'PREIS' i_value = row-preis ).
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'WAERS' i_value = row-waers ).
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'RESULT' i_value = row-result ).
      er_data_changed->modify_cell( i_row_id = row_id i_fieldname = 'DETAIL' i_value = row-detail ).
    ENDLOOP.
  ENDMETHOD.

  " SEL 변수(n_werks)를 여기서 못 쓰므로 행 번호만 기억하고 PAI(STOGO)로 넘긴다.
  METHOD entry_hotspot.
    IF e_column_id-fieldname <> 'DETAIL' OR e_row_id-index <= 0.
      RETURN.
    ENDIF.
    gv_sto_row = e_row_id-index.
    cl_gui_cfw=>set_new_ok_code( new_code = 'STOGO' ).
  ENDMETHOD.

  " entry_finished : 셀 변경이 끝나면 ALV를 다시 그리고 PAI(ECHG)를 일으켜 위쪽 요약줄도 갱신한다.
  METHOD entry_finished.
    IF e_modified = abap_true.
      PERFORM refresh_entry.
      " 상단 요약 COMMENT도 PBO를 거쳐 최신 입력행과 맞춘다.
      cl_gui_cfw=>set_new_ok_code( new_code = 'ECHG' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
DATA go_events TYPE REF TO lcl_pr_events.
