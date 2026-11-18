*&---------------------------------------------------------------------*
*& Include          Z8SDD0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_container
    EXPORTING
      container_name              = 'CONTROL_AREA'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_split
    EXPORTING
      parent            = go_container
      rows              = 2
      columns           = 1
    EXCEPTIONS
      cntl_error        = 1
      cntl_system_error = 2
      OTHERS            = 3.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CALL METHOD go_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_container_h.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CALL METHOD go_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_container_i.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_alv_h
    EXPORTING
      i_parent = go_container_h.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_alv_i
    EXPORTING
      i_parent = go_container_i.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler .
  SET HANDLER lcl_handler=>on_doublc_click FOR go_alv_h.
  SET HANDLER lcl_handler=>on_row_select FOR go_alv_h.
  SET HANDLER lcl_handler=>on_hotspot FOR go_alv_h.

  CALL METHOD go_alv_h->register_delayed_event
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_delayed_change_select.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  gs_layout_h-no_toolbar = 'X'.
  gs_layout_h-sel_mode = 'B'.
  gs_layout_h-excp_fname = 'LIGHT'.
  gs_layout_h-excp_led = 'X'. "신호등 1구
  gs_layout_h-stylefname = 'CT'.


  gs_layout_i-no_toolbar = 'X'.
  gs_layout_i-ctab_fname = 'CELL_COLOR'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat .
  CLEAR gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'STATUS_D'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'LFART'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'KUNAG'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'PERNR'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'LIGHT'.
  gw_fcat_h-coltext = '상태'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'MAT_STATUS_TXT'.
  gw_fcat_h-coltext = '자재 확보 상태'.
  gw_fcat_h-col_pos = 1.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'STATUS_TXT'.
  gw_fcat_h-coltext = '배송 상태'.
  gw_fcat_h-col_pos = 2.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'SDATE'.
  gw_fcat_h-coltext = '공사 시작 예정일'. "출고 계획일
  gw_fcat_h-col_pos = 3.
  gw_fcat_h-just = 'C'.
  gw_fcat_h-outputlen = 10.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VBELN_D'.
  gw_fcat_h-coltext = 'Delivery 번호'.
  gw_fcat_h-col_pos = 4.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VBELN_S'.
  gw_fcat_h-coltext = 'SO 번호'.
  gw_fcat_h-col_pos = 5.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'PRO_ID'.
  gw_fcat_h-coltext = '프로젝트'.
  gw_fcat_h-col_pos = 6.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'KUNNR'.
  gw_fcat_h-coltext = '고객'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'NAME1'.
  gw_fcat_h-coltext = '고객명'.
  gw_fcat_h-col_pos = 7.
  gw_fcat_h-outputlen = 15.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'WERKS'.
  gw_fcat_h-coltext = '플랜트'.
  gw_fcat_h-col_pos = 8.
  gw_fcat_h-outputlen = 5.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'WERKS_TXT'.
  gw_fcat_h-coltext = '플랜트명'.
  gw_fcat_h-col_pos = 8.
  gw_fcat_h-outputlen = 15.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'WADAT'.
  gw_fcat_h-coltext = '출고 예정일'. "출고 계획일
  gw_fcat_h-col_pos = 9.
  gw_fcat_h-just = 'C'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'LFDAT'.
  gw_fcat_h-coltext = '납품 예정일'. "현장에 납품할 예정일
  gw_fcat_h-just = 'C'.
  gw_fcat_h-col_pos = 10.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'WADAT_IST'.
  gw_fcat_h-coltext = '실제 출고일'. "GI 발생일
  gw_fcat_h-just = 'C'.
  gw_fcat_h-col_pos = 11.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'ENAME'.
  gw_fcat_h-coltext = '자재 인수 담당자'.
  gw_fcat_h-col_pos = 12.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'BELNR'.
  gw_fcat_h-coltext = '전표번호'.
  gw_fcat_h-col_pos = 13.
*  gw_fcat_h-hotspot = 'X'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fcat_i
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat_i .
  CLEAR gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'STATUS_I'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'NETPR'.
  gw_fcat_i-coltext = '단가'.
  gw_fcat_i-outputlen = 10.
  gw_fcat_i-emphasize ='C310'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VERPR'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.


  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'WAERS'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.


  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'EISBE'.
  gw_fcat_i-coltext = '안전재고'.
  gw_fcat_i-col_pos = 7.
  gw_fcat_i-qfieldname = 'VRKME'.
  gw_fcat_i-outputlen = 8.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'LGORT'.
  gw_fcat_i-coltext = '저장위치'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'NETWR'.
  gw_fcat_i-coltext = '자재 총액'.
  gw_fcat_i-outputlen = 10.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'LFIMG'.
  gw_fcat_i-coltext = '출고예정수량'.
  gw_fcat_i-outputlen = 6.
  gw_fcat_i-col_pos = 11.
  gw_fcat_i-qfieldname = 'VRKME'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'STATUS_TXT'.
  gw_fcat_i-coltext = '상태'.
  gw_fcat_i-col_pos = 1.
  gw_fcat_i-outputlen = 12.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'POSNR'.
  gw_fcat_i-coltext = '품목'.
  gw_fcat_i-outputlen = 3.
  gw_fcat_i-col_pos = 2.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'MATNR'.
  gw_fcat_i-coltext = '자재'.
  gw_fcat_i-outputlen = 15.
  gw_fcat_i-col_pos = 3.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'ARKTX'.
  gw_fcat_i-coltext = '자재명'.
  gw_fcat_i-outputlen = 15.
  gw_fcat_i-col_pos = 4.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VBELN_S'.
  gw_fcat_i-coltext = 'SO 번호'.
  gw_fcat_i-col_pos = 5.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'LABST'.
  gw_fcat_i-coltext = '현재고'.
  gw_fcat_i-col_pos = 6.
  gw_fcat_i-qfieldname = 'VRKME'.
  gw_fcat_i-outputlen = 8.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'AVAILABLE_STOCK'.
  gw_fcat_i-coltext = '가용재고'.
  gw_fcat_i-col_pos = 7.
  gw_fcat_i-outputlen = 8.
  gw_fcat_i-qfieldname = 'VRKME'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'KWMENG'.
  gw_fcat_i-coltext = '필요수량'.
  gw_fcat_i-qfieldname = 'VRKME'.
  gw_fcat_i-col_pos = 8.
  gw_fcat_i-outputlen = 8.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'STOCK_SHORTAGE'.
  gw_fcat_i-coltext = '부족수량'.
  gw_fcat_i-qfieldname = 'VRKME'.
  gw_fcat_i-col_pos = 9.
  gw_fcat_i-outputlen = 8.
  gw_fcat_i-just = 'R'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VRKME'.
  gw_fcat_i-coltext = '단위'.
  gw_fcat_i-col_pos = 10.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'PLACE_TYPE'.
  gw_fcat_i-coltext = '설치장소'.
  gw_fcat_i-outputlen = 11.
  gw_fcat_i-col_pos = 11.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'ZZRSVQTY'.
  gw_fcat_i-coltext = '예약재고'.
  gw_fcat_i-col_pos = 12.
  gw_fcat_i-qfieldname = 'VRKME'.
  gw_fcat_i-outputlen = 8.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VRKME2'.
  gw_fcat_i-coltext = '단위'.
  gw_fcat_i-col_pos = 13.
  APPEND gw_fcat_i TO gt_fcat_i.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_header_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL METHOD go_alv_h->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8SD_DELIV_H'
      is_layout                     = gs_layout_h
    CHANGING
      it_outtab                     = gt_deliv_h
      it_fieldcatalog               = gt_fcat_h
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE e012(z8_msg).
  ENDIF.

  CALL METHOD go_alv_i->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8SD_SO_I'
      is_layout                     = gs_layout_i
    CHANGING
      it_outtab                     = gt_deliv_i
      it_fieldcatalog               = gt_fcat_i
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE e012(z8_msg).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_selected_line
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_INDEX
*&---------------------------------------------------------------------*
FORM set_selected_line.
  DATA: lt_rows  TYPE lvc_t_row,
        ls_row   TYPE lvc_s_row,
        lv_index TYPE i.

  IF gv_selected_so IS INITIAL.
    READ TABLE gt_deliv_h INTO gw_deliv_h INDEX 1.
  ELSE.
    READ TABLE gt_deliv_h INTO gw_deliv_h WITH KEY vbeln_s = gv_selected_so.
  ENDIF.

  IF sy-subrc = 0.
    gv_selected_so = gw_deliv_h-vbeln_s. "첫 진입 시 첫번째 행, 선택된 행이 있을 시 해당 행 선택
    ls_row = sy-tabix.

    APPEND ls_row TO lt_rows.

    CALL METHOD go_alv_h->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_item_alv.

  CALL METHOD go_alv_i->refresh_table_display
    EXPORTING
      is_stable = gs_stable_i.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_SELECTED_SO
*&---------------------------------------------------------------------*

FORM get_item USING VALUE(p_selected_so).

  DATA: lr_so        TYPE RANGE OF z8sd_so_i-vbeln_s,
        lv_available TYPE z8material_stk_m-labst, "가용재고 담을 변수
        lv_shortage  TYPE z8material_stk_m-labst.

  "선택된 SO가 있을 때만 조회 조건 추가
  IF p_selected_so IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = p_selected_so
    ) TO lr_so.
  ENDIF.

  SELECT so~*,
         di~vbeln_d,
         di~lfimg,
         di~status_i,
         stk~lgort,
         stk~labst,
         stk~zzrsvqty,
         stk~werks,
         mat~eisbe,
         price~netpr AS netpr_p
    FROM z8sd_so_i AS so
    INNER JOIN z8sd_so_h AS so_h      ON so_h~vbeln_s = so~vbeln_s
    LEFT JOIN z8sd_deliv_i AS di      ON di~vgbel = so~vbeln_s AND di~vgpos = so~posnr
    LEFT JOIN z8matplant_m AS mat     ON mat~werks = so_h~werks AND mat~matnr = so~matnr
    LEFT JOIN z8material_stk_m AS stk ON stk~werks = so_h~werks AND stk~matnr = so~matnr
    LEFT JOIN z8sd_price_m AS price   ON price~matnr = so~matnr AND use_yn = 'Y'
    INTO CORRESPONDING FIELDS OF TABLE @gt_deliv_i
    WHERE so_h~status_s = '30' AND so~vbeln_s IN @lr_so.

  IF sy-subrc <> 0.
    MESSAGE s071(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.

  LOOP AT gt_deliv_i ASSIGNING FIELD-SYMBOL(<fs_i>).
    CLEAR lv_shortage.

    "가용재고 계산
    lv_available = <fs_i>-labst
                 - <fs_i>-zzrsvqty
                 - <fs_i>-eisbe.

    <fs_i>-available_stock = lv_available.

    <fs_i>-vrkme2 = <fs_i>-vrkme. "예약재고 단위


    IF lv_available - <fs_i>-kwmeng < 0 AND <fs_i>-status_i IS INITIAL.

      lv_shortage =  lv_available - <fs_i>-kwmeng . "부족 수량

      <fs_i>-stock_shortage = |{ lv_shortage DECIMALS = 0 SIGN = LEFT }|.


      APPEND VALUE lvc_s_scol(
        fname     = 'STOCK_SHORTAGE'
        color-col = 6
        color-int = 0
        color-inv = 0
      ) TO <fs_i>-cell_color.
    ELSE.
      <fs_i>-stock_shortage = '0'.
    ENDIF.


    IF <fs_i>-status_i IS NOT INITIAL.
      CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
        EXPORTING
          iv_domname    = 'Z8D_DELIVI_STATUS'
          iv_value      = <fs_i>-status_i
        IMPORTING
          ev_value_text = <fs_i>-status_txt.
    ELSE.
      <fs_i>-status_txt = ' '.
    ENDIF.


  ENDLOOP.

  SORT gt_deliv_i BY vbeln_s ASCENDING
                     posnr   ASCENDING.

  PERFORM refresh_item_alv.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form refresh_header_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_header_alv .
  CALL METHOD go_alv_h->refresh_table_display
    EXPORTING
      is_stable = gs_stable_h.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_delivery
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_delivery.
  DATA: ls_deliv_h TYPE z8sd_deliv_h,
        lt_deliv_i TYPE TABLE OF z8sd_deliv_i,
        lw_deliv_i LIKE LINE OF lt_deliv_i.

  DATA: lv_transit_days TYPE i,
        lv_number       TYPE n LENGTH 9,
        lv_calc_date    TYPE dats,
        lv_lbkum        TYPE z8material_val_m-lbkum. "자재평가 테이블 수량 필드

  DATA: lt_locked_i    TYPE TABLE OF z8sd_deliv_i.

  CLEAR: ls_deliv_h,
         lt_deliv_i,
         lw_deliv_i,
         lv_transit_days,
         lv_number,
         lv_lbkum.

*1. 출고 예정일 계산 - Delivery 생성일 + 2영업일
*2. 납품 예정일 계산 - WADAT(출고 예정일) + 권역 별 예상 운송일수 적용
*3. 실제 출고일 - GI 처리 날짜
*4. Delivery 번호 채번
*5. 자재 예약재고 잡기

******************************** 헤더 세팅 ********************************

*  gw_deliv_h-wadat = lv_wadat.
*  gw_deliv_h-lfdat = lv_lfdat.
  gw_deliv_h-lfart = 'LF'.
  gw_deliv_h-status_d = '10'.

  "담당자 배정
  SELECT SINGLE pernr
    INTO CORRESPONDING FIELDS OF @gw_deliv_h
    FROM z8ps_tech_hist
    WHERE pro_id = @gw_deliv_h-pro_id AND stell = '설치기사'.

  IF sy-subrc <> 0.
    MESSAGE s235(z8_msg) DISPLAY LIKE 'E'. "배정된 설치기사가 없습니다
    RETURN.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8SD_DELIV'
    IMPORTING
      number                  = lv_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    MESSAGE e014(z8_msg).
    RETURN.
  ENDIF.

  gw_deliv_h-vbeln_d = |D{ lv_number }|.

  MOVE-CORRESPONDING gw_deliv_h TO ls_deliv_h.

******************************** 아이템 세팅 ********************************
  LOOP AT gt_deliv_i INTO gw_deliv_i WHERE vbeln_s = gw_deliv_h-vbeln_s.

    CLEAR lw_deliv_i.

    lw_deliv_i-vbeln_d = gw_deliv_h-vbeln_d.
    lw_deliv_i-posnr = gw_deliv_i-posnr.
    lw_deliv_i-vgbel = gw_deliv_i-vbeln_s.
    lw_deliv_i-vgpos = gw_deliv_i-posnr.
    lw_deliv_i-matnr = gw_deliv_i-matnr.
    lw_deliv_i-werks = gw_deliv_h-werks.
    lw_deliv_i-lgort = '0001'.
    lw_deliv_i-lfimg = gw_deliv_i-kwmeng.
    lw_deliv_i-vrkme = gw_deliv_i-vrkme.
    lw_deliv_i-status_i = '10'.


    APPEND lw_deliv_i TO lt_deliv_i.
  ENDLOOP.

******************************* 재고 Lock ***************************************
  "전체 자재 Lock
  LOOP AT lt_deliv_i INTO lw_deliv_i.

    "이미 Lock한 자재면 건너뛰기
    READ TABLE lt_locked_i TRANSPORTING NO FIELDS WITH KEY matnr = lw_deliv_i-matnr
                                                           werks = lw_deliv_i-werks
                                                           lgort = lw_deliv_i-lgort.

    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'ENQUEUE_EZ8MATSTK'
      EXPORTING
        mode_z8material_stk_m = 'E'
        mandt                 = sy-mandt
        matnr                 = lw_deliv_i-matnr
        werks                 = lw_deliv_i-werks
        lgort                 = lw_deliv_i-lgort
        _scope                = '1'
      EXCEPTIONS
        foreign_lock          = 1
        system_failure        = 2
        OTHERS                = 3.

    IF sy-subrc <> 0.
      PERFORM release_stock_lock USING lt_locked_i.
      MESSAGE s097(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    APPEND lw_deliv_i TO lt_locked_i.

  ENDLOOP.

  "전체 자재 Lock 성공 후 최신 재고 조회
  PERFORM get_item USING gw_deliv_h-vbeln_s.

  "최신 가용재고 검증
  LOOP AT lt_deliv_i INTO lw_deliv_i.

    READ TABLE gt_deliv_i INTO DATA(ls_item) WITH KEY vbeln_s = lw_deliv_i-vgbel
                                                      posnr   = lw_deliv_i-vgpos.

    IF sy-subrc <> 0.
      PERFORM release_stock_lock USING lt_locked_i.
      MESSAGE s093(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF ls_item-available_stock < lw_deliv_i-lfimg.
      PERFORM release_stock_lock USING lt_locked_i.
      MESSAGE s093(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

******************************* 재고 예약 및 차감 ***************************************
  LOOP AT lt_deliv_i INTO lw_deliv_i.

    UPDATE z8material_stk_m
       SET zzrsvqty = zzrsvqty + @lw_deliv_i-lfimg
     WHERE matnr = @lw_deliv_i-matnr
       AND werks = @lw_deliv_i-werks
       AND lgort = @lw_deliv_i-lgort.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s093(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

****************************** DB 반영 ******************************************

  INSERT z8sd_deliv_h FROM @ls_deliv_h.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s094(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  INSERT z8sd_deliv_i FROM TABLE @lt_deliv_i.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s094(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK AND WAIT.

  PERFORM dequeue_so.
  PERFORM release_stock_lock USING lt_locked_i.


  MESSAGE i090(z8_msg).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_selected_d
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_DELIVERY_ID
*&---------------------------------------------------------------------*
FORM get_selected_line CHANGING lv_result.
  DATA: ls_row  TYPE lvc_s_row,
        lt_rows TYPE lvc_t_row.

  CLEAR: ls_row, lt_rows.

  lv_result = abap_true.

  go_alv_h->get_selected_rows(
    IMPORTING
      et_index_rows = lt_rows
  ).

  IF lt_rows IS INITIAL.
    CLEAR gv_selected_so.
    MESSAGE s031(z8_msg) DISPLAY LIKE 'E'.
    lv_result = abap_false.
    RETURN.
  ENDIF.

  IF lines( lt_rows ) > 1.
    MESSAGE s032(z8_msg) DISPLAY LIKE 'E'.
    lv_result = abap_false.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.

  IF sy-subrc <> 0.
    lv_result = abap_false.
    RETURN.
  ENDIF.

  "선택한 행의 데이터 읽기
  READ TABLE gt_deliv_h INTO gw_deliv_h INDEX ls_row-index.

  IF sy-subrc <> 0.
    lv_result = abap_false.
    RETURN.
  ENDIF.

  gv_selected_so = gw_deliv_h-vbeln_s.

  PERFORM get_item USING gv_selected_so.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .
  DATA: lv_index     TYPE i,
        lv_is_enough TYPE abap_bool,
        lv_available TYPE z8material_stk_m-labst, "가용재고 담을 변수
        ls_ct        TYPE lvc_s_styl.



  CLEAR: gw_deliv_h, gw_deliv_i, lv_index, lv_is_enough, lv_available.

  DATA lv_search_so TYPE string.

  lv_search_so = |%{ gv_search_so }%|.


  SELECT so~*,
         p~name1 AS werks_txt,
         c~kunnr AS kunag,
         c~name1 AS name1,
         pr~pro_id,
         pr~sdate,
         d~vbeln_d,
         d~lfdat,
         d~wadat,
         d~wadat_ist,
         d~status_d,
         d~pernr,
         e~ename,
         f~belnr
    FROM z8sd_so_h AS so
    LEFT JOIN z8sd_deliv_h AS d ON d~vbeln_s = so~vbeln_s
    LEFT JOIN z8plant_m AS p ON so~werks = p~werks
    LEFT JOIN z8customer_m AS c ON so~kunnr = c~kunnr
    LEFT JOIN z8ps_project AS pr ON pr~vbeln = so~vbeln_s
    LEFT JOIN z8employee_m AS e ON e~pernr = d~pernr
    LEFT JOIN z8branch_m AS b ON b~branch = so~bupla
    LEFT JOIN z8fi_accdoc_h AS f ON f~xblnr = d~vbeln_d
    WHERE so~status_s = '30' "인력배정완료 건
    AND ( ( @gv_edate IS INITIAL
       AND pr~sdate = @gv_sdate )
     OR
     ( @gv_edate IS NOT INITIAL
       AND pr~sdate BETWEEN @gv_sdate AND @gv_edate )
    )
    AND ( @gv_werks IS INITIAL OR p~werks = @gv_werks )
    AND ( @gv_status_d IS INITIAL OR d~status_d = @gv_status_d )
    AND ( @gv_search_so IS INITIAL OR so~vbeln_s LIKE @lv_search_so )
    INTO CORRESPONDING FIELDS OF TABLE @gt_deliv_h.

  IF sy-subrc <> 0.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
*    RETURN.
  ENDIF.

  SORT gt_deliv_h BY sdate ASCENDING.

  PERFORM get_item USING ' '.

  LOOP AT gt_deliv_h ASSIGNING FIELD-SYMBOL(<fs_h>).

    IF <fs_h>-status_d IS NOT INITIAL.
      CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
        EXPORTING
          iv_domname    = 'Z8D_DELIV_STATUS'
          iv_value      = <fs_h>-status_d
        IMPORTING
          ev_value_text = <fs_h>-status_txt.
    ELSE.
      <fs_h>-status_txt = ' '.
    ENDIF.

    IF <fs_h>-belnr IS NOT INITIAL.
      CLEAR ls_ct.

      ls_ct-fieldname = 'BELNR'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.

      INSERT ls_ct INTO TABLE <fs_h>-ct.
    ENDIF.


    <fs_h>-light = '1'. "기본값
    <fs_h>-mat_status_txt = TEXT-001. "확보 대기

    IF <fs_h>-vbeln_d IS NOT INITIAL. "재고 확보가 완료 되어야 delivery 문서를 생성할 수 있으므로
      <fs_h>-light = '3'.
      <fs_h>-mat_status_txt = TEXT-002. "확보 완료
      CONTINUE.
    ENDIF.



    lv_is_enough = abap_true. "SO 마다 초기화

    LOOP AT gt_deliv_i INTO gw_deliv_i WHERE vbeln_s = <fs_h>-vbeln_s.

      IF gw_deliv_i-kwmeng > gw_deliv_i-available_stock. "하나라도 재고가 부족하면 아이템 조회 루프 종료
        <fs_h>-light = '1'.
        lv_is_enough = abap_false.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lv_is_enough = abap_true.
      <fs_h>-light = '3'.
      <fs_h>-mat_status_txt = TEXT-002.


    ENDIF.

  ENDLOOP.

  "자재 확보 상태 조회조건 적용
  CASE gv_status_mat.

    WHEN '10'. "확보 대기
      DELETE gt_deliv_h WHERE light <> '1'.

    WHEN '20'. "확보 완료
      DELETE gt_deliv_h WHERE light <> '3'.

  ENDCASE.

  PERFORM refresh_header_alv.


  IF gt_deliv_h IS NOT INITIAL.
    READ TABLE gt_deliv_h INTO gw_deliv_h WITH KEY vbeln_s = gv_selected_so.
    IF sy-subrc <> 0. "없으면 다시 첫번째 행 선택
      READ TABLE gt_deliv_h INTO gw_deliv_h INDEX 1.

      IF sy-subrc = 0.
        gv_selected_so = gw_deliv_h-vbeln_s.
      ENDIF.
    ENDIF.

    "헤더가 존재하면 선택한 SO의 Item 조회
    PERFORM set_selected_line. "어떤 라인이 선택 됐는지 알 수 있게끔 설정
    PERFORM get_item USING gw_deliv_h-vbeln_s.
  ELSE.

    "헤더가 없으면 하단 Item 초기화
    CLEAR: gt_deliv_i, gw_deliv_i, gw_deliv_h.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.

  ENDIF.

  PERFORM refresh_item_alv.

  gs_layout_h-grid_title = |전체 ({ lines( gt_deliv_h ) })건|.

  go_alv_h->set_frontend_layout(
    EXPORTING
      is_layout = gs_layout_h
  ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form validation1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_VAL
*&---------------------------------------------------------------------*
FORM validation1  CHANGING p_val.

  IF gw_deliv_h-status_d = space. "Delivery 생성 건이 없고

    IF gw_deliv_h-light = '3'. "모든 자재가 확보된 경우 Delivery 생성 가능

      p_val = abap_true.

    ELSE.

      MESSAGE s089(z8_msg) DISPLAY LIKE 'E' WITH gw_deliv_h-werks. "재고가 없는 경우 에러 메세지
      p_val = abap_false.

      RETURN.

    ENDIF.

  ELSE.

    MESSAGE s088(z8_msg) DISPLAY LIKE 'E' WITH gw_deliv_h-vbeln_s gw_deliv_h-vbeln_d. "이미 생성된 Delivery가 있는 경우 에러 메시지

    p_val = abap_false.

    RETURN.

  ENDIF.

  PERFORM get_date CHANGING p_val.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_date
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_WADAT
*&      <-- LV_LFDAT
*&      <-- LV_TRANSIT_DAYS
*&---------------------------------------------------------------------*
FORM get_date  CHANGING p_result.

  DATA: lv_factorydate   TYPE scal-facdate,
        lv_start_factory TYPE scal-facdate,
        lv_calc_date     TYPE z8ps_project-sdate,
        lv_wadat         TYPE z8sd_deliv_h-wadat,
        lv_lfdat         TYPE z8sd_deliv_h-lfdat.

  p_result = abap_true.

  "공사 시작 예정일 → 영업일 번호
  CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
    EXPORTING
      date                = gw_deliv_h-sdate
      factory_calendar_id = 'KR'
      correct_option      = '-'
    IMPORTING
      factorydate         = lv_start_factory
    EXCEPTIONS
      OTHERS              = 1.

  IF sy-subrc <> 0.
    p_result = abap_false.
    RETURN.
  ENDIF.

  "공사 시작 예정일 - 5영업일
  lv_start_factory = lv_start_factory - 5.

  CALL FUNCTION 'FACTORYDATE_CONVERT_TO_DATE'
    EXPORTING
      factorydate         = lv_start_factory
      factory_calendar_id = 'KR'
    IMPORTING
      date                = lv_calc_date
    EXCEPTIONS
      OTHERS              = 1.


  IF sy-datum < lv_calc_date.
    p_result = abap_false.
    MESSAGE s096(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  "Delivery 생성일을 공장 달력 영업일 번호로 변환
  CALL FUNCTION 'DATE_CONVERT_TO_FACTORYDATE'
    EXPORTING
      date                = sy-datum
      factory_calendar_id = 'KR'
      correct_option      = '-' "생성일이 휴무일이면 직전 영업일을 기준으로 변환
    IMPORTING
      factorydate         = lv_factorydate
    EXCEPTIONS
      OTHERS              = 1.

  IF sy-subrc <> 0.
    p_result = abap_false.
    MESSAGE s216(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  lv_factorydate = lv_factorydate + 2. "Delivery 생성일 + 2 영업일

  "영업일 번호를 출고 예정일로 변환
  CALL FUNCTION 'FACTORYDATE_CONVERT_TO_DATE'
    EXPORTING
      factorydate         = lv_factorydate
      factory_calendar_id = 'KR'
    IMPORTING
      date                = lv_wadat
    EXCEPTIONS
      OTHERS              = 1.

  IF sy-subrc <> 0.
    p_result = abap_false.
    MESSAGE s217(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT SINGLE r~est_transit_days
    FROM z8sd_quot_req AS req
    INNER JOIN z8sd_quotation_h AS q ON req~request_id = q~request_id
    INNER JOIN z8plant_m AS p ON p~werks = q~werks
    INNER JOIN z8route_m AS r ON r~from_region = p~region_code
                             AND r~to_region = req~region_code
    INTO @DATA(lv_transit_days).

  IF sy-subrc <> 0.
    MESSAGE s230(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "권역별 운송일수는 달력일로 계산
  lv_lfdat = lv_wadat + lv_transit_days.

  gw_deliv_h-wadat = lv_wadat.
  gw_deliv_h-lfdat = lv_lfdat.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form enqueue_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM enqueue_so CHANGING p_result.
  p_result = abap_true.

  CALL FUNCTION 'ENQUEUE_EZ8SD_SO'
    EXPORTING
      mode_z8sd_so_h = 'E'
      mandt          = sy-mandt
      vbeln_s        = gw_deliv_h-vbeln_s
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc <> 0.
    p_result = abap_false.
    MESSAGE s097(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form dequeue_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM dequeue_so .
  CALL FUNCTION 'DEQUEUE_EZ8SD_SO'
    EXPORTING
      mode_z8sd_so_h = 'E'
      mandt          = sy-mandt
      vbeln_s        = gw_deliv_h-vbeln_s.
  RETURN.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form release_stock_lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_LOCKED_I
*&---------------------------------------------------------------------*
FORM release_stock_lock  USING p_locked_i TYPE STANDARD TABLE.
  FIELD-SYMBOLS <ls_locked_i> TYPE z8sd_deliv_i.

  LOOP AT p_locked_i ASSIGNING <ls_locked_i>.

    CALL FUNCTION 'DEQUEUE_EZ8MATSTK'
      EXPORTING
        mode_z8material_stk_m = 'E'
        mandt                 = sy-mandt
        matnr                 = <ls_locked_i>-matnr
        werks                 = <ls_locked_i>-werks
        lgort                 = <ls_locked_i>-lgort
        _scope                = '1'.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form validation2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_RESULT
*&---------------------------------------------------------------------*
FORM validation2  CHANGING p_result.

  p_result = abap_true.

  CASE gw_deliv_h-status_d.

    WHEN space.

      MESSAGE s102(z8_msg) DISPLAY LIKE 'E'.
      p_result = abap_false.
      RETURN.

    WHEN '10'.

      "Picking 가능

    WHEN '20' OR '30'.

      "이미 Picking이 완료 되었습니다
      MESSAGE s099(z8_msg) DISPLAY LIKE 'E'.
      p_result = abap_false.
      RETURN.

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form picking
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM picking CHANGING p_result.

  UPDATE z8sd_deliv_h SET status_d = '20' WHERE vbeln_s = gw_deliv_h-vbeln_s.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s094(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "Delivery Item 상태 변경
  UPDATE z8sd_deliv_i SET status_i = '20' WHERE vbeln_d = @gw_deliv_h-vbeln_d
                                            AND status_i = '10'.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s093(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK.

  MESSAGE i091(z8_msg).

  p_result = abap_true.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form validation3
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_RESULT
*&---------------------------------------------------------------------*
FORM validation3  CHANGING p_result.
  CASE gw_deliv_h-status_d.
    WHEN space.
      MESSAGE s102(z8_msg) DISPLAY LIKE 'E'.
      p_result = abap_false.
      RETURN.
    WHEN '10'.
      "Picking이 완료되지 않았습니다 101
      MESSAGE s101(z8_msg) DISPLAY LIKE 'E'.
      p_result = abap_false.
      RETURN.
    WHEN '20'.
      "GI 가능
    WHEN '30'.
      "이미 출고가 완료된 건입니다 100
      MESSAGE s100(z8_msg) DISPLAY LIKE 'E'.
      p_result = abap_false.
      RETURN.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form gi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM gi.
* 1. WERKS, MATNR 별 예약재고(zzrsvqty), 현재고 차감(labst)
* 2. 상태 20 -> 30으로 업데이트 Header, Item
* 3. 회계전표 생성
* 4. 자재문서 생성

  DATA: ls_fi_accdoc_h   TYPE z8fi_accdoc_h,
        lt_fi_accdoc_i   TYPE TABLE OF z8fi_accdoc_i,
        lw_fi_accdoc_i   LIKE LINE OF lt_fi_accdoc_i,
        lv_number        TYPE n LENGTH 10,
        lv_total_price   TYPE z8fi_accdoc_i-wrbtr, "출고원가 - 이동평균가
        ls_matdoc_h      TYPE z8mm_matdoc_h,
        lt_matdoc_i      TYPE TABLE OF z8mm_matdoc_i,
        lw_matdoc_i      TYPE z8mm_matdoc_i,
        lv_matdoc_number TYPE z8mm_matdoc_h-mblnr,
        lv_zeile         TYPE z8mm_matdoc_i-zeile,
        lv_salk3         TYPE z8MATERIAL_val_M-salk3,
        lv_verpr         TYPE z8material_val_m-verpr,
        lv_peinh         TYPE z8material_val_m-peinh.

  CONSTANTS: gc_expense TYPE z8fi_accdoc_i-hkont VALUE '51000000',
             gc_stock   TYPE z8fi_accdoc_i-hkont VALUE '14100000'.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8FI_BELNR'
    IMPORTING
      number                  = lv_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    MESSAGE s014(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8MATDOCH'
    IMPORTING
      number                  = lv_matdoc_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    MESSAGE s014(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  LOOP AT gt_deliv_i ASSIGNING FIELD-SYMBOL(<fs_i>).

    UPDATE z8material_stk_m SET zzrsvqty = zzrsvqty - @<fs_i>-lfimg,
                                labst    = labst - @<fs_i>-lfimg
                           WHERE matnr    = @<fs_i>-matnr
                             AND werks    = @<fs_i>-werks
                             AND lgort    = @<fs_i>-lgort
                             AND zzrsvqty >= @<fs_i>-lfimg
                             AND labst    >= @<fs_i>-lfimg.

    IF sy-subrc <> 0 OR sy-dbcnt <> 1.
      MESSAGE s104(z8_msg) DISPLAY LIKE 'E'. "재고 차감에 실패했습니다
      ROLLBACK WORK.
      RETURN.
    ENDIF.

    UPDATE z8sd_deliv_i SET status_i = '30' WHERE vbeln_d = @gw_deliv_h-vbeln_d
                                              AND posnr   = @<fs_i>-posnr
                                              AND status_i = '20'.

    IF sy-subrc <> 0.
      MESSAGE s095(z8_msg) DISPLAY LIKE 'E'. "아이템 저장에 실패했습니다
      ROLLBACK WORK.
      RETURN.
    ENDIF.


    SELECT SINGLE verpr, peinh "이동평균가, 가격단위(수량 기준)
      FROM z8material_val_m
      INTO (@lv_verpr, @lv_peinh)
      WHERE matnr = @<fs_i>-matnr
        AND bwkey = @<fs_i>-werks.

    IF sy-subrc <> 0.
      MESSAGE s118(z8_msg) DISPLAY LIKE 'E'. "이동평균가 조회에 실패했습니다
      RETURN.
    ENDIF.

    UPDATE z8material_val_m
      SET lbkum = lbkum - @<fs_i>-lfimg
      WHERE matnr = @<fs_i>-matnr
       AND bwkey = @<fs_i>-werks.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s104(z8_msg) DISPLAY LIKE 'E'. "재고 차감에 실패했습니다
      RETURN.
    ENDIF.


    <fs_i>-wrbtr = lv_verpr * <fs_i>-lfimg / lv_peinh.

    lv_total_price = lv_total_price + <fs_i>-wrbtr.

***********************************자재문서 아이템 ****************************
    CLEAR lw_matdoc_i.

    lv_zeile += 1.

    lw_matdoc_i-mblnr = lv_matdoc_number.
    lw_matdoc_i-mjahr = sy-datum+0(4).
    lw_matdoc_i-zeile = lv_zeile.
    lw_matdoc_i-bwart = '601'. "판매오더(SD) 기준 고객에게 출고
    lw_matdoc_i-matnr = <fs_i>-matnr.
    lw_matdoc_i-werks = <fs_i>-werks.
    lw_matdoc_i-lgort = <fs_i>-lgort.
    lw_matdoc_i-menge = <fs_i>-lfimg.
    lw_matdoc_i-meins = <fs_i>-vrkme.
    lw_matdoc_i-kdauf = <fs_i>-vbeln_s.
    lw_matdoc_i-kdpos = <fs_i>-posnr.
    lw_matdoc_i-wrbtr = <fs_i>-wrbtr.
    lw_matdoc_i-waers = <fs_i>-waers.
    lw_matdoc_i-ref_item = <fs_i>-posnr.
    lw_matdoc_i-zzreftype = '04'.
    lw_matdoc_i-zzaccdoc = lv_number.
    lw_matdoc_i-zzrefdoc = <fs_i>-vbeln_d.

    APPEND lw_matdoc_i TO lt_matdoc_i.

  ENDLOOP.


  UPDATE z8sd_deliv_h SET status_d = '30', wadat_ist = @sy-datum  WHERE vbeln_d = @gw_deliv_h-vbeln_d AND status_d  = '20'.

  IF sy-subrc <> 0.
    MESSAGE s094(z8_msg) DISPLAY LIKE 'E'. "헤더 저장에 실패했습니다
    ROLLBACK WORK.
    RETURN.
  ENDIF.


************************************ 회계 전표 ***********************************

  ls_fi_accdoc_h-belnr = lv_number.
  ls_fi_accdoc_h-bukrs = '1000'.
  ls_fi_accdoc_h-gjahr = sy-datum+0(4).
  ls_fi_accdoc_h-monat = sy-datum+4(2).
  ls_fi_accdoc_h-blart = 'WL'.
  ls_fi_accdoc_h-bldat = sy-datum.
  ls_fi_accdoc_h-budat = sy-datum.
  ls_fi_accdoc_h-waers = 'KRW'.
  ls_fi_accdoc_h-xblnr = gw_deliv_h-vbeln_d.

  INSERT z8fi_accdoc_h FROM ls_fi_accdoc_h . "회계전표 헤더

  IF sy-subrc <> 0.
    MESSAGE s106(z8_msg) DISPLAY LIKE 'E'.
    ROLLBACK WORK.
    RETURN.
  ENDIF.


  "차변: 출고원가
  CLEAR lw_fi_accdoc_i.
  lw_fi_accdoc_i-bukrs = '1000'.
  lw_fi_accdoc_i-belnr = lv_number.
  lw_fi_accdoc_i-gjahr = sy-datum+0(4).
  lw_fi_accdoc_i-buzei = '001'.
  lw_fi_accdoc_i-koart = 'S'.
  lw_fi_accdoc_i-hkont = gc_expense.
  lw_fi_accdoc_i-bupla = gw_deliv_h-bupla.
  lw_fi_accdoc_i-shkzg = 'S'.
  lw_fi_accdoc_i-wrbtr = lv_total_price.
  lw_fi_accdoc_i-waers = 'KRW'.
*  lw_fi_accdoc_i-kunnr = gw_deliv_h-kunnr.
  APPEND lw_fi_accdoc_i TO lt_fi_accdoc_i.

  "대변: 재고자산
  CLEAR lw_fi_accdoc_i.
  lw_fi_accdoc_i-bukrs = '1000'.
  lw_fi_accdoc_i-belnr = lv_number.
  lw_fi_accdoc_i-gjahr = sy-datum+0(4).
  lw_fi_accdoc_i-buzei = '002'.
  lw_fi_accdoc_i-koart = 'S'.
  lw_fi_accdoc_i-hkont = gc_stock.
  lw_fi_accdoc_i-bupla = gw_deliv_h-bupla.
  lw_fi_accdoc_i-shkzg = 'H'.
  lw_fi_accdoc_i-wrbtr = lv_total_price.
  lw_fi_accdoc_i-waers = 'KRW'.
*  lw_fi_accdoc_i-kunnr = gw_deliv_h-kunnr.
  APPEND lw_fi_accdoc_i TO lt_fi_accdoc_i.


  INSERT z8fi_accdoc_i FROM TABLE lt_fi_accdoc_i. "회계전표 아이템

  IF sy-subrc <> 0.
    MESSAGE s106(z8_msg) DISPLAY LIKE 'E'.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

************************************ 자재 문서 ***********************************


  ls_matdoc_h-mblnr = lv_matdoc_number.
  ls_matdoc_h-mjahr = sy-datum+0(4).
  ls_matdoc_h-bldat = sy-datum.
  ls_matdoc_h-budat = sy-datum.

  INSERT z8mm_matdoc_h FROM ls_matdoc_h.

  IF sy-subrc <> 0.
    MESSAGE s107(z8_msg) DISPLAY LIKE 'E'.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  INSERT z8mm_matdoc_i FROM TABLE lt_matdoc_i.

  IF sy-subrc <> 0.
    MESSAGE s107(z8_msg) DISPLAY LIKE 'E'. "자재문서 생성에 실패했습니다
    ROLLBACK WORK.
    RETURN.
  ENDIF.


  COMMIT WORK AND WAIT.

  MESSAGE i108(z8_msg) WITH lv_matdoc_number lv_number .


ENDFORM.
*&---------------------------------------------------------------------*
*& Form remember_selected_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM remember_selected_row .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  CLEAR: lt_rows, ls_row.

  go_alv_h->get_selected_rows(
    IMPORTING
      et_index_rows = lt_rows
  ).

  "선택된 행이 정확히 1개일 때만 기억
  IF lines( lt_rows ) <> 1.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE gt_deliv_h INTO gw_deliv_h INDEX ls_row-index.

  IF sy-subrc = 0.
    gv_selected_so = gw_deliv_h-vbeln_s.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_default_date
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_default_date .
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = sy-datum
      days      = 0
      months    = 3
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = gv_sdate.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = sy-datum
      days      = 0
      months    = 3
      signum    = '+'
      years     = 0
    IMPORTING
      calc_date = gv_edate.
ENDFORM.
