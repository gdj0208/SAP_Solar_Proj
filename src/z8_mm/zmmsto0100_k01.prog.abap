*&---------------------------------------------------------------------*
*& Include ZMMSTO0100_K01
*&---------------------------------------------------------------------*
*& ALV 이벤트(행 클릭·F4) 로컬 클래스
*& 담당: MM(이규빈) / 프로그램: ZMMSTO0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: 지사 간 자재이동(STO) 목록·입력·취소 (개발 10/17~10/23)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: STO 1건 품목 N줄 구조, 목록 카드·이력 ALV
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: STO 예약 추가, 취소 메시지 202·134 구분, 수량 소수점·카드 크기 수정
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

CLASS lcl_sto_events DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no.
    METHODS material_f4 FOR EVENT onf4 OF cl_gui_alv_grid
      IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data et_bad_cells e_display.
    METHODS entry_changed FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed.
    METHODS entry_finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified.
ENDCLASS.
CLASS lcl_sto_events IMPLEMENTATION.
  " ------------------------------------------------------------
  " METHOD double_click : ALV에서 더블클릭한 행 번호를 상세조회 FORM에 넘긴다(아래 이력 갱신, CALL SCREEN 없음).
  " ------------------------------------------------------------
  METHOD double_click.
    IF es_row_no-row_id > 0.
      DATA row_index TYPE i.
      row_index = es_row_no-row_id.
      PERFORM show_detail USING row_index.
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD material_f4 : STO 입력 ALV에서 자재 F4 선택을 처리한다.
  " ------------------------------------------------------------
  METHOD material_f4.
    IF e_fieldname <> 'MATNR' OR e_display = abap_true.
      RETURN.
    ENDIF.
    er_event_data->m_event_handled = abap_true.
    READ TABLE gt_entry INDEX es_row_no-row_id INTO DATA(row).
    IF sy-subrc <> 0 OR row-ebeln IS NOT INITIAL.
      RETURN.
    ENDIF.
    " 칸에 적힌 글자 일부(e_fieldvalue)로 걸러서 보여 준다. 1건이면 목록 없이 바로 들어간다.
    DATA selected_mat TYPE z8mm_po_i-matnr.
    selected_mat = lcl_mm_f4=>pick( kind = 'MAT' typed = e_fieldvalue ).
    IF selected_mat IS INITIAL.
      RETURN.
    ENDIF.
    FIELD-SYMBOLS <changes> TYPE lvc_t_modi.
    ASSIGN er_event_data->m_data->* TO <changes>.
    IF sy-subrc = 0.
      APPEND VALUE #( row_id = es_row_no-row_id fieldname = 'MATNR' value = selected_mat ) TO <changes>.
    ENDIF.
    CLEAR gv_checked.
  ENDMETHOD.
  " entry_changed : STO 입력 ALV 셀 변경. 자재 글자 일부 → 자동 완성, 이름·단위를 바로 채운다.
  METHOD entry_changed.
    CLEAR: gv_checked, gv_stamp.
    LOOP AT er_data_changed->mt_good_cells INTO DATA(cell) WHERE fieldname = 'MATNR'.
      READ TABLE gt_entry INDEX cell-row_id INTO DATA(row).
      IF sy-subrc <> 0 OR row-ebeln IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      row-matnr = cell-value.
      " 글자 일부만 넣고 Enter → 1건이면 자동 완성, 여러 건이면 목록에서 고른다.
      DATA(lv_typed_mat) = row-matnr.
      lcl_mm_f4=>resolve( EXPORTING kind = 'MAT' CHANGING value = row-matnr ).
      IF row-matnr <> lv_typed_mat.
        er_data_changed->modify_cell( i_row_id = cell-row_id i_fieldname = 'MATNR' i_value = row-matnr ).
      ENDIF.
      PERFORM entry_names CHANGING row.
      er_data_changed->modify_cell( i_row_id = cell-row_id i_fieldname = 'MAKTX' i_value = row-maktx ).
      er_data_changed->modify_cell( i_row_id = cell-row_id i_fieldname = 'MEINS' i_value = row-meins ).
    ENDLOOP.
  ENDMETHOD.

  " entry_finished : 셀 변경이 끝나면 PAI(ECHG)로 재고·일정 자동 확인을 일으킨다.
  METHOD entry_finished.
    IF e_modified = abap_true.
      " 편집 완료 후 PAI에서 상단 입력값까지 받아 재계산한다.
      cl_gui_cfw=>set_new_ok_code( new_code = 'ECHG' ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
DATA go_events TYPE REF TO lcl_sto_events.

" lcl_summary_events : 오른쪽 카드(HTML) 클릭 이벤트. 정의와 이벤트 객체는 TOP에 있다.
CLASS lcl_summary_events IMPLEMENTATION.
  " on_click : 카드의 SAPEVENT를 받아 PAI(SCARD)를 일으킨다. 여기서는 조회하지 않는다.
  METHOD on_click.
    CASE action.
      WHEN 'ALL' OR 'MOVE' OR 'DONE' OR 'VOID'.   " 전체 / 예약·이동 / 입고완료 / 취소 카드
        gv_summary_action = action.
        DATA rc TYPE i.
        cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = 'SCARD' IMPORTING rc = rc ).
        IF rc <> cl_gui_cfw=>rc_posted.
          CLEAR gv_summary_action.
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
