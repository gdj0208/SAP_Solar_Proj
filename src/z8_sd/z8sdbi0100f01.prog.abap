*&---------------------------------------------------------------------*
*& Include          Z8SDBI0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_quot.

  DATA: lv_lines TYPE i.

  CLEAR gt_quot.

  "1. 견적 + 선수금 청구 + 고객 + 종사업장 한 번에 조회
  SELECT q~vbeln_q, q~audat, q~kunnr, q~bupla, q~netwr, q~waerk,
         c~name1,
         r~name   AS branch_nm,
         b~vbeln, b~fkdat, b~zduedat, b~zzpayst, b~netwr AS bill_amt
    FROM z8sd_quotation_h AS q
    LEFT OUTER JOIN z8sd_billing_h AS b
      ON  b~vgbel = q~vbeln_q
      AND b~fkart = 'F1'
    LEFT OUTER JOIN z8customer_m AS c
      ON  c~kunnr = q~kunnr
    LEFT OUTER JOIN z8branch_m AS r
      ON  r~branch = q~bupla
      AND r~bukrs  = '1000'
    WHERE q~status  = '20'
      AND q~bupla   IN @s_bupla
      AND q~kunnr   IN @s_kunnr
      AND q~vbeln_q IN @s_vbelnq
    AND q~audat IN @s_qdat
    INTO CORRESPONDING FIELDS OF TABLE @gt_quot.

  "2. 청구상태 조건으로 거르기
  IF p_st1 = 'X'.
    DELETE gt_quot WHERE vbeln IS NOT INITIAL.
  ELSEIF p_st2 = 'X'.
    DELETE gt_quot WHERE vbeln IS INITIAL.
  ENDIF.

  "3. 계산
  LOOP AT gt_quot INTO gs_quot.

    IF gs_quot-vbeln IS INITIAL.
      gs_quot-dp_amt = gs_quot-netwr * '0.3'.     " 미청구: 예정 금액
    ELSE.
      gs_quot-dp_amt = gs_quot-bill_amt.           " 청구완료: 실제 청구금액
    ENDIF.

    IF gs_quot-vbeln IS INITIAL.
      gs_quot-bill_limit = gs_quot-audat + 30.
    ENDIF.

    IF gs_quot-vbeln IS INITIAL.
      gs_quot-bill_tx = '미청구'.
      gs_quot-light   = '1'.
      gs_quot-icon   = icon_led_red.

    ELSE.
      gs_quot-bill_tx = '청구완료'.
      gs_quot-light   = '3'.
      gs_quot-icon   = icon_led_green.

    ENDIF.

    IF gs_quot-zzpayst = '01'.
      gs_quot-pay_tx = '미입금'.
    ELSEIF gs_quot-zzpayst = '02'.
      gs_quot-pay_tx = '입금완료'.
    ELSEIF gs_quot-zzpayst = '03'.
      gs_quot-pay_tx = '입금기한 만료'.
    ENDIF.

    MODIFY gt_quot FROM gs_quot.

  ENDLOOP.
*SORT gt_quot BY vbeln audat DESCENDING.
  SORT gt_quot BY light   ASCENDING
                                fkdat   DESCENDING
                                vbeln   DESCENDING
                                audat   DESCENDING.

  "셀단위 핫스팟 제어.
  PERFORM set_cell_style_quot.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_quot .
  CREATE OBJECT go_cont_quot
    EXPORTING
      container_name = 'Q_ALV'.

  CREATE OBJECT go_alv_quot
    EXPORTING
      i_parent = go_cont_quot.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout_quot .
*  CLEAR gs_layout_quot.
  gs_layout_quot-zebra      =  'X'.
*  gs_layout_quot-cwidth_opt = 'X'.
  gs_layout_quot-sel_mode   = 'B'.
  gs_layout_quot-stylefname = 'CT'.
*  gs_layout_quot-excp_fname = 'LIGHT'.
*  gs_layout_quot-excp_led = 'X'.

  PERFORM set_grid_title_quot.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_quot .
  DATA: lv_lines TYPE i,
        lv_cnt   TYPE c LENGTH 10,
        lv_state TYPE c LENGTH 10.

  DESCRIBE TABLE gt_quot LINES lv_lines.
  lv_cnt = lv_lines.
  CONDENSE lv_cnt.

  IF p_st1 = 'X'.
    lv_state = '미청구'.
  ELSEIF p_st2 = 'X'.
    lv_state = '청구완료'.
  ELSE.
    lv_state = '전체'.
  ENDIF.

  CONCATENATE '선수금' lv_state '(' INTO gs_layout_quot-grid_title
    SEPARATED BY space.
  CONCATENATE gs_layout_quot-grid_title lv_cnt '건)'
    INTO gs_layout_quot-grid_title.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_quot .
  CLEAR gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'ICON'.
  gw_fcat_quot-coltext   = '상태'.
  gw_fcat_quot-icon = 'X'.
  gw_fcat_quot-outputlen = 2.
  gw_fcat_quot-key       = 'X'.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'BILL_TX'.
  gw_fcat_quot-coltext   = '청구상태'.
  gw_fcat_quot-key       = 'X'.
  APPEND gw_fcat_quot TO gt_fcat_quot.


  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'VBELN_Q'.
  gw_fcat_quot-coltext   = '견적번호'.
  gw_fcat_quot-key       = 'X'.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'AUDAT'.
  gw_fcat_quot-coltext   = '견적일'.
  gw_fcat_quot-datatype  = 'DATS'.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'BILL_LIMIT'.
  gw_fcat_quot-coltext   = '청구가능기한'.
  gw_fcat_quot-datatype  = 'DATS'.
  gw_fcat_quot-just      = 'C'. "중간정렬.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'BUPLA'.
  gw_fcat_quot-coltext   = '지사'.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'BRANCH_NM'.
  gw_fcat_quot-coltext   = '지사명'.
  gw_fcat_quot-outputlen = 14.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'KUNNR'.
  gw_fcat_quot-coltext   = '고객번호'.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'NAME1'.
  gw_fcat_quot-coltext   = '고객명'.
  gw_fcat_quot-outputlen = 14.
  APPEND gw_fcat_quot TO gt_fcat_quot.


  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname  = 'NETWR'.
  gw_fcat_quot-coltext    = '견적금액'.
  gw_fcat_quot-cfieldname = 'WAERK'.
  gw_fcat_quot-datatype   = 'CURR'.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname  = 'DP_AMT'.
  gw_fcat_quot-coltext    = '선수금'.
  gw_fcat_quot-cfieldname = 'WAERK'.
  gw_fcat_quot-datatype   = 'CURR'.
  gw_fcat_quot-emphasize  = 'C311'.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'WAERK'.
  gw_fcat_quot-coltext   = '통화'.
  gw_fcat_quot-emphasize  = 'C311'.
  gw_fcat_quot-outputlen = 6.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'VBELN'.
  gw_fcat_quot-coltext   = '청구번호'.
*  gw_fcat_quot-hotspot = 'X'.
  gw_fcat_quot-outputlen = 14.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'FKDAT'.
  gw_fcat_quot-coltext   = '청구일'.
  gw_fcat_quot-datatype  = 'DATS'.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_quot TO gt_fcat_quot.

  CLEAR gw_fcat_quot.
  gw_fcat_quot-fieldname = 'ZDUEDAT'.
  gw_fcat_quot-coltext   = '입금기한'.
  gw_fcat_quot-datatype  = 'DATS'.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_quot TO gt_fcat_quot.

*  CLEAR gw_fcat_quot.
*  gw_fcat_quot-fieldname = 'PAY_TX'.
*  gw_fcat_quot-coltext   = '입금상태'.
*  APPEND gw_fcat_quot TO gt_fcat_quot.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_quot .
  CALL METHOD go_alv_quot->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_quot
    CHANGING
      it_outtab       = gt_quot
      it_fieldcatalog = gt_fcat_quot.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_quot .
  DATA: ls_stable TYPE lvc_s_stbl.

  PERFORM get_data_quot.
  PERFORM set_grid_title_quot.

  CALL METHOD go_alv_quot->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_quot-grid_title.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.

  CALL METHOD go_alv_quot->refresh_table_display
    EXPORTING
      is_stable = ls_stable.
  "마지막에 만들어진 청구에 커서 이동.
  PERFORM focus_last_vbeln.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_selected_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_selected_quot .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row,
        lv_limit TYPE sy-datum.

  CALL METHOD go_alv_quot->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE '청구할 견적을 선택하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.
  READ TABLE gt_quot INTO gs_quot INDEX ls_row-index.

  IF gs_quot-vbeln IS NOT INITIAL.
    MESSAGE '이미 청구된 견적입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "청구가능기한 확인 (견적일 + 30일)
  lv_limit = gs_quot-audat + 30.

  IF lv_limit < sy-datum.
    MESSAGE '청구가능기한이 지난 견적입니다. 견적을 다시 생성하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  PERFORM make_bill_h_f1.
  PERFORM make_bill_i_f1.
  IF gv_err = 'X'.
    RETURN.
  ENDIF.
  CALL SCREEN 0200.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_bill_h
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_bill_h_f1 .
  gv_fkart = 'F1'.
  CLEAR: gs_bill_h, gv_name1, gv_branch_nm.

  gs_bill_h-bukrs   = '1000'.
  gs_bill_h-fkart   = 'F1'.
  gs_bill_h-vgbel   = gs_quot-vbeln_q.
  gs_bill_h-kunnr   = gs_quot-kunnr.
  gs_bill_h-bupla   = gs_quot-bupla.
  gs_bill_h-netwr   = gs_quot-dp_amt.
  gs_bill_h-waerk   = gs_quot-waerk.
  gv_quot_netwr = gs_quot-netwr.
  gv_quot_waerk = gs_quot-waerk.
  gs_bill_h-fkdat   = sy-datum.
  gs_bill_h-zduedat = sy-datum + 7.
  gs_bill_h-zzpayst = '01'.

  gv_name1     = gs_quot-name1.
  gv_branch_nm = gs_quot-branch_nm.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_bill_i
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_bill_i_f1.

  DATA: lt_quot_i  TYPE TABLE OF z8sd_quotation_i,
        ls_quot_i  TYPE z8sd_quotation_i,
        lv_posnr   TYPE z8sd_billing_i-posnr,
        lv_transit TYPE z8sd_quotation_h-transit_cost,
        lv_install TYPE z8sd_quotation_h-install_cost,
        lv_sum     TYPE z8sd_billing_i-netwr,
        lv_diff    TYPE z8sd_billing_i-netwr,
        lv_last    TYPE i.

  CLEAR: gt_bill_i, lv_posnr, lv_sum.

  "1. 견적 품목 → 청구 품목 (30%)
  SELECT *
    FROM z8sd_quotation_i
    WHERE vbeln_q = @gs_quot-vbeln_q
    ORDER BY posnr
    INTO TABLE @lt_quot_i.

  LOOP AT lt_quot_i INTO ls_quot_i.
    CLEAR gs_bill_i.
    lv_posnr = lv_posnr + 10.

    gs_bill_i-posnr = lv_posnr.
    gs_bill_i-matnr = ls_quot_i-matnr.
    gs_bill_i-arktx = ls_quot_i-arktx.
    gs_bill_i-vgbel = ls_quot_i-vbeln_q.
    gs_bill_i-vgpos = ls_quot_i-posnr.
    gs_bill_i-fkimg = ls_quot_i-kwmeng.
    gs_bill_i-vrkme = ls_quot_i-vrkme.
    gs_bill_i-netwr = ls_quot_i-netwr * '0.3'.
    gs_bill_i-waerk = gs_bill_h-waerk.
    APPEND gs_bill_i TO gt_bill_i.
  ENDLOOP.

  "2. 운송비 / 설치비 → 청구 품목 줄 추가
  SELECT SINGLE transit_cost, install_cost
    FROM z8sd_quotation_h
    WHERE vbeln_q = @gs_quot-vbeln_q
    INTO (@lv_transit, @lv_install).

  IF lv_transit > 0.
    CLEAR gs_bill_i.
    lv_posnr = lv_posnr + 10.
    gs_bill_i-posnr = lv_posnr.
    gs_bill_i-arktx = '운송비'.
    gs_bill_i-vgbel = gs_quot-vbeln_q.
    gs_bill_i-fkimg = 1.
    gs_bill_i-netwr = lv_transit * '0.3'.
    gs_bill_i-waerk = gs_bill_h-waerk.
    gs_bill_i-matnr = 'SVC-TRANS'.
    gs_bill_i-vrkme = 'EA'.
    APPEND gs_bill_i TO gt_bill_i.
  ENDIF.

  IF lv_install > 0.
    CLEAR gs_bill_i.
    lv_posnr = lv_posnr + 10.
    gs_bill_i-posnr = lv_posnr.
    gs_bill_i-arktx = '설치비'.
    gs_bill_i-vgbel = gs_quot-vbeln_q.
    gs_bill_i-fkimg = 1.
    gs_bill_i-netwr = lv_install * '0.3'.
    gs_bill_i-waerk = gs_bill_h-waerk.
    gs_bill_i-matnr = 'SVC-INST'.
    gs_bill_i-vrkme = 'EA'.
    APPEND gs_bill_i TO gt_bill_i.
  ENDIF.

  "3. 품목 합계 계산
  CLEAR lv_sum.
  LOOP AT gt_bill_i INTO gs_bill_i.
    lv_sum = lv_sum + gs_bill_i-netwr.
  ENDLOOP.
*
*  lv_diff = gs_bill_h-netwr - lv_sum.
  "4. 차이 확인 (10원 넘으면 데이터 오류로 차단)
  CLEAR gv_err.
  lv_diff =  gs_bill_h-netwr - lv_sum.
  IF lv_diff > '0.10' OR lv_diff < '-0.10'.
    gv_err = 'X'.
    MESSAGE '견적 총액과 견적 품목 금액이 맞지 않아 청구할 수 없습니다.'
        TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  "5. 가격 보정.
  IF lv_diff <> 0.
    DESCRIBE TABLE gt_bill_i LINES lv_last.
    READ TABLE gt_bill_i INTO gs_bill_i INDEX lv_last.
    gs_bill_i-netwr = gs_bill_i-netwr + lv_diff.
    MODIFY gt_bill_i FROM gs_bill_i INDEX lv_last.
  ENDIF.

  "6. 화면용 미리보기 만들기
  CLEAR gt_prev.

  LOOP AT gt_bill_i INTO gs_bill_i.
    CLEAR gs_prev.
    MOVE-CORRESPONDING gs_bill_i TO gs_prev.

    IF gs_bill_i-vgpos IS NOT INITIAL.
      "견적 품목에서 온 줄
      READ TABLE lt_quot_i INTO ls_quot_i WITH KEY posnr = gs_bill_i-vgpos.
      IF sy-subrc = 0.
        gs_prev-place_type = ls_quot_i-place_type.
        gs_prev-quot_amt   = ls_quot_i-netwr.
      ENDIF.
    ELSEIF gs_bill_i-matnr = 'SVC-TRANS'.
      gs_prev-quot_amt = lv_transit.
    ELSEIF gs_bill_i-matnr = 'SVC-INST'.
      gs_prev-quot_amt = lv_install.
    ENDIF.

    gs_prev-rest_amt = gs_prev-quot_amt - gs_prev-netwr.
    APPEND gs_prev TO gt_prev.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_prev
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_prev .
  CREATE OBJECT go_cont_prev
    EXPORTING
      container_name = 'P_ALV'.

  CREATE OBJECT go_alv_prev
    EXPORTING
      i_parent = go_cont_prev.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_prev
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout_prev .
  CLEAR gs_layout_prev.
  gs_layout_prev-zebra      = 'X'.
*  gs_layout_prev-cwidth_opt = 'X'.
  gs_layout_prev-no_toolbar = 'X'.
  gs_layout_prev-grid_title = '청구 품목'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_prev
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_prev.

  CLEAR gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname = 'POSNR'.
  gw_fcat_prev-coltext   = '품목'.
  gw_fcat_prev-outputlen = 8.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname = 'MATNR'.
  gw_fcat_prev-coltext   = '자재코드'.
  gw_fcat_prev-outputlen = 13.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname = 'ARKTX'.
  gw_fcat_prev-coltext   = '품목명'.
  gw_fcat_prev-outputlen = 20.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname = 'PLACE_TYPE'.
  gw_fcat_prev-coltext   = '설치장소'.
  gw_fcat_prev-outputlen = 10.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname  = 'FKIMG'.
  gw_fcat_prev-coltext    = '수량'.
  gw_fcat_prev-qfieldname = 'VRKME'.
  gw_fcat_prev-decimals_o = '0'.
  gw_fcat_prev-datatype   = 'QUAN'.
  gw_fcat_prev-outputlen = 4.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname = 'VRKME'.
  gw_fcat_prev-coltext   = '단위'.
  gw_fcat_prev-outputlen = 4.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  "견적/SO 금액
  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname  = 'QUOT_AMT'.
  IF gv_fkart = 'F1'.
    gw_fcat_prev-coltext = '견적금액'.
  ELSE.
    gw_fcat_prev-coltext = 'SO금액'.
  ENDIF.
  gw_fcat_prev-cfieldname = 'WAERK'.
  gw_fcat_prev-datatype   = 'CURR'.
  gw_fcat_prev-do_sum     = 'X'.
  gw_fcat_prev-outputlen = 15.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  "청구금액
  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname  = 'NETWR'.
  IF gv_fkart = 'F1'.
    gw_fcat_prev-coltext = '청구금액(30%)'.
  ELSE.
    gw_fcat_prev-coltext = '잔금 청구금액'.
  ENDIF.
  gw_fcat_prev-cfieldname = 'WAERK'.
  gw_fcat_prev-datatype   = 'CURR'.
  gw_fcat_prev-do_sum     = 'X'.
  gw_fcat_prev-emphasize  = 'C311'.
  gw_fcat_prev-outputlen = 15.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  "잔여금액
  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname  = 'REST_AMT'.
  IF gv_fkart = 'F1'.
    gw_fcat_prev-coltext = '잔여금액'.
  ELSE.
    gw_fcat_prev-coltext = '선수금 청구분'.
  ENDIF.

  gw_fcat_prev-cfieldname = 'WAERK'.
  gw_fcat_prev-datatype   = 'CURR'.
  gw_fcat_prev-do_sum     = 'X'.
  gw_fcat_prev-outputlen = 15.
  APPEND gw_fcat_prev TO gt_fcat_prev.

  CLEAR gw_fcat_prev.
  gw_fcat_prev-fieldname = 'WAERK'.
  gw_fcat_prev-coltext   = '통화'.
  gw_fcat_prev-outputlen = 6.
  APPEND gw_fcat_prev TO gt_fcat_prev.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_prev
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_prev .
  CALL METHOD go_alv_prev->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_prev
    CHANGING
      it_outtab       = gt_prev
      it_fieldcatalog = gt_fcat_prev.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_prev
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_prev .
  IF go_alv_prev IS NOT INITIAL.
    CALL METHOD go_alv_prev->free.
  ENDIF.

  IF go_cont_prev IS NOT INITIAL.
    CALL METHOD go_cont_prev->free.
  ENDIF.

  CLEAR: go_alv_prev, go_cont_prev.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_billing.

  DATA: lv_answer TYPE c LENGTH 1,
        lv_text   TYPE c LENGTH 100,
        lv_cnt    TYPE i,
        lv_num    TYPE n LENGTH 9,
        lv_msg    TYPE c LENGTH 100.

  "1. 확인 팝업
  IF gs_bill_h-fkart = 'F1'.
    CONCATENATE '견적번호' gs_bill_h-vgbel '의 선수금 청구문서를 생성하시겠습니까?'
      INTO lv_text SEPARATED BY space.
  ELSE.
    CONCATENATE 'SO번호' gs_bill_h-vgbel '의 잔금 청구문서를 생성하시겠습니까?'
      INTO lv_text SEPARATED BY space.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '청구문서 생성'
      text_question         = lv_text
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

  "2. 저장 직전 재확인: 같은 견적으로 F1이 이미 있는지
  SELECT COUNT(*)
    FROM z8sd_billing_h
    WHERE vgbel = @gs_bill_h-vgbel
    AND fkart = @gs_bill_h-fkart
    INTO @lv_cnt.

  IF lv_cnt > 0.
    MESSAGE S138(Z8_MSG) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "3. 청구번호 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'Z8SD_VBELN'
    IMPORTING
      number      = lv_num
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0.
    MESSAGE S139(Z8_MSG) DISPLAY LIKE 'E' WITH '청구번호 채번'.
    RETURN.
  ENDIF.

  CONCATENATE 'B' lv_num INTO gs_bill_h-vbeln.

  "4. 품목에 청구번호 넣기
  LOOP AT gt_bill_i INTO gs_bill_i.
    gs_bill_i-vbeln = gs_bill_h-vbeln.
    MODIFY gt_bill_i FROM gs_bill_i.
  ENDLOOP.

  "5. 헤더 INSERT
  INSERT z8sd_billing_h FROM gs_bill_h.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE S139(Z8_MSG) DISPLAY LIKE 'E' WITH '청구헤더 저장'.
    RETURN.
  ENDIF.

  "6. 품목 INSERT
  INSERT z8sd_billing_i FROM TABLE gt_bill_i.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE S139(Z8_MSG) DISPLAY LIKE 'E' WITH '청구품목 저장'.
    RETURN.
  ENDIF.

  "7. 모두 성공
  COMMIT WORK AND WAIT.
  gv_last_vbeln = gs_bill_h-vbeln.

  CONCATENATE '청구문서' gs_bill_h-vbeln '가 생성되었습니다.'
    INTO lv_msg SEPARATED BY space.

  gv_refresh_100 = 'X'.
  PERFORM free_control_prev.
  MESSAGE lv_msg TYPE 'I'.
  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form focus_last_vbeln
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM focus_last_vbeln .
  DATA: lv_index TYPE i,
        ls_row   TYPE lvc_s_row,
        ls_col   TYPE lvc_s_col,
        lt_rows  TYPE lvc_t_row.

  IF gv_last_vbeln IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE gt_quot INTO gs_quot WITH KEY vbeln = gv_last_vbeln.
  IF sy-subrc <> 0.
    CLEAR gv_last_vbeln.
    RETURN.
  ENDIF.
  lv_index = sy-tabix.

  "줄 선택
  ls_row-index = lv_index.
  APPEND ls_row TO lt_rows.
  CALL METHOD go_alv_quot->set_selected_rows
    EXPORTING
      it_index_rows = lt_rows.

  "커서를 청구번호 칸으로 (해당 위치로 스크롤)
  ls_col-fieldname = 'VBELN'.
  CALL METHOD go_alv_quot->set_current_cell_via_id
    EXPORTING
      is_row_id    = ls_row
      is_column_id = ls_col.

  CLEAR gv_last_vbeln.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_so .
  CLEAR gt_so.

  SELECT s~vbeln_s, s~audat, s~vbeln_q, s~kunnr, s~bupla,
         s~netwr, s~waerk,
         c~name1,
         r~name     AS branch_nm,
         d~vbeln    AS dp_vbeln,
         d~netwr    AS dp_amt,
         d~zzpayst  AS dp_payst,
         b~vbeln, b~fkdat, b~zduedat, b~zzpayst
    FROM z8ps_project AS p
    INNER JOIN z8sd_so_h AS s
      ON  s~vbeln_s = p~vbeln
    LEFT OUTER JOIN z8sd_billing_h AS d
      ON  d~vgbel = s~vbeln_q
      AND d~fkart = 'F1'
    LEFT OUTER JOIN z8sd_billing_h AS b
      ON  b~vgbel = s~vbeln_s
      AND b~fkart = 'F2'
    LEFT OUTER JOIN z8customer_m AS c
      ON  c~kunnr = s~kunnr
    LEFT OUTER JOIN z8branch_m AS r
      ON  r~branch = s~bupla
      AND r~bukrs  = '1000'
    WHERE p~status_p = '60'
      AND s~bupla   IN @s_bupla
      AND s~kunnr   IN @s_kunnr
      AND s~vbeln_s IN @s_vbelns
     AND s~audat IN @s_sdat
    INTO CORRESPONDING FIELDS OF TABLE @gt_so.

  "청구상태 조건
  IF p_st1 = 'X'.
    DELETE gt_so WHERE vbeln IS NOT INITIAL.
  ELSEIF p_st2 = 'X'.
    DELETE gt_so WHERE vbeln IS INITIAL.
  ENDIF.

  LOOP AT gt_so INTO gs_so.

    gs_so-bal_amt = gs_so-netwr - gs_so-dp_amt.

    IF gs_so-vbeln IS NOT INITIAL.
      gs_so-bill_tx = '청구완료'.
      gs_so-light   = '3'.
      gs_so-icon    = icon_led_green.
    ELSEIF gs_so-dp_payst = '02'.
      gs_so-bill_tx = '미청구'.
      gs_so-light   = '1'.
      gs_so-icon    = icon_led_red.
    ELSE.
      gs_so-bill_tx = '청구대기'.
      gs_so-light   = '2'.
      gs_so-icon    = icon_led_yellow.
    ENDIF.

    IF gs_so-zzpayst = '01'.
      gs_so-pay_tx = '미입금'.
    ELSEIF gs_so-zzpayst = '02'.
      gs_so-pay_tx = '입금완료'.
    ELSEIF gs_so-zzpayst = '03'.
      gs_so-pay_tx = '입금기한 만료'.
    ENDIF.

    MODIFY gt_so FROM gs_so.

  ENDLOOP.

*  SORT gt_so BY vbeln audat DESCENDING.
  SORT gt_so BY light   ASCENDING
                            fkdat   DESCENDING
                            vbeln   DESCENDING
                            audat   DESCENDING.

  PERFORM set_cell_style_so.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_so .
  CREATE OBJECT go_cont_so
    EXPORTING
      container_name = 'S_ALV'.

  CREATE OBJECT go_alv_so
    EXPORTING
      i_parent = go_cont_so.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout_so .
  CLEAR gs_layout_so.
  gs_layout_so-zebra      = 'X'.
*  gs_layout_so-cwidth_opt = 'X'.
  gs_layout_so-sel_mode   = 'B'.
  gs_layout_so-stylefname = 'CT'.
*  gs_layout_so-excp_fname = 'LIGHT'.
*  gs_layout_so-excp_led   = 'X'.
*  gs_layout_so-excp_rolln = 'Z8E_BILL_LIGHT'.

  PERFORM set_grid_title_so.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_so .
  DATA: lv_lines TYPE i,
        lv_cnt   TYPE c LENGTH 10,
        lv_state TYPE c LENGTH 10.

  DESCRIBE TABLE gt_so LINES lv_lines.
  lv_cnt = lv_lines.
  CONDENSE lv_cnt.

  IF p_st1 = 'X'.
    lv_state = '미청구'.
  ELSEIF p_st2 = 'X'.
    lv_state = '청구완료'.
  ELSE.
    lv_state = '전체'.
  ENDIF.

  CONCATENATE '잔금' lv_state '(' INTO gs_layout_so-grid_title
    SEPARATED BY space.
  CONCATENATE gs_layout_so-grid_title lv_cnt '건)'
    INTO gs_layout_so-grid_title.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_so .
  CLEAR gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'ICON'.
  gw_fcat_so-coltext   = '상태'.
  gw_fcat_so-icon = 'X'.
  gw_fcat_so-outputlen = 2.
  gw_fcat_so-key       = 'X'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'BILL_TX'.
  gw_fcat_so-coltext   = '청구상태'.
  gw_fcat_so-key       = 'X'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'VBELN_S'.
  gw_fcat_so-coltext   = 'SO번호'.
  gw_fcat_so-key       = 'X'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'AUDAT'.
  gw_fcat_so-coltext   = 'SO생성일'.
  gw_fcat_so-datatype  = 'DATS'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'BUPLA'.
  gw_fcat_so-coltext   = '지사'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'BRANCH_NM'.
  gw_fcat_so-coltext   = '지사명'.
    gw_fcat_so-outputlen = 13.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'KUNNR'.
  gw_fcat_so-coltext   = '고객번호'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'NAME1'.
  gw_fcat_so-coltext   = '고객명'.
  gw_fcat_so-outputlen = 13.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname  = 'NETWR'.
  gw_fcat_so-coltext    = 'SO금액'.
  gw_fcat_so-cfieldname = 'WAERK'.
  gw_fcat_so-datatype   = 'CURR'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'DP_VBELN'.
  gw_fcat_so-coltext   = '선수금 청구번호'.
  APPEND gw_fcat_so TO gt_fcat_so.


  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname  = 'DP_AMT'.
  gw_fcat_so-coltext    = '선수금'.
  gw_fcat_so-cfieldname = 'WAERK'.
  gw_fcat_so-datatype   = 'CURR'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname  = 'BAL_AMT'.
  gw_fcat_so-coltext    = '잔금'.
  gw_fcat_so-cfieldname = 'WAERK'.
  gw_fcat_so-datatype   = 'CURR'.
  gw_fcat_so-emphasize  = 'C311'.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'WAERK'.
  gw_fcat_so-coltext   = '통화'.
  gw_fcat_so-emphasize  = 'C311'.
  gw_fcat_so-outputlen = 6.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'VBELN'.
  gw_fcat_so-coltext   = '잔금 청구번호'.
*  gw_fcat_so-emphasize = 'C410'.
*  gw_fcat_so-hotspot = 'X'.
  gw_fcat_so-outputlen = 13.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'FKDAT'.
  gw_fcat_so-coltext   = '청구일'.
  gw_fcat_so-datatype  = 'DATS'.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_so TO gt_fcat_so.

  CLEAR gw_fcat_so.
  gw_fcat_so-fieldname = 'ZDUEDAT'.
  gw_fcat_so-coltext   = '입금기한'.
  gw_fcat_so-datatype  = 'DATS'.
  gw_fcat_quot-outputlen = 12.
  APPEND gw_fcat_so TO gt_fcat_so.

*  CLEAR gw_fcat_so.
*  gw_fcat_so-fieldname = 'PAY_TX'.
*  gw_fcat_so-coltext   = '입금상태'.
*  gw_fcat_so-outputlen = 14.
*  APPEND gw_fcat_so TO gt_fcat_so.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_so .
  CALL METHOD go_alv_so->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_so
    CHANGING
      it_outtab       = gt_so
      it_fieldcatalog = gt_fcat_so.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_so .
  DATA: ls_stable TYPE lvc_s_stbl.

  PERFORM get_data_so.
  PERFORM set_grid_title_so.

  CALL METHOD go_alv_so->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_so-grid_title.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.

  CALL METHOD go_alv_so->refresh_table_display
    EXPORTING
      is_stable = ls_stable.
  PERFORM focus_last_vbeln_so.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_so .
  IF go_alv_so IS NOT INITIAL.
    CALL METHOD go_alv_so->free.
  ENDIF.

  IF go_cont_so IS NOT INITIAL.
    CALL METHOD go_cont_so->free.
  ENDIF.

  CLEAR: go_alv_so, go_cont_so.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_selected_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_selected_so .
  DATA: lt_rows  TYPE lvc_t_row,
        ls_row   TYPE lvc_s_row,
        lv_lines TYPE i.

  CALL METHOD go_alv_so->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE '청구할 SO를 선택하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  DESCRIBE TABLE lt_rows LINES lv_lines.
  IF lv_lines > 1.
    MESSAGE '청구는 한 건씩 선택하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.
  READ TABLE gt_so INTO gs_so INDEX ls_row-index.

  IF gs_so-vbeln IS NOT INITIAL.
    MESSAGE '이미 잔금이 청구된 SO입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_so-dp_payst <> '02'.
    MESSAGE '선수금 입금이 완료되지 않아 잔금을 청구할 수 없습니다.'
            TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  "잔금 0이하일 때 예외처리
  IF gs_so-bal_amt <= 0.
    MESSAGE '잔금이 0 이하입니다. 선수금 청구금액을 확인하세요.'
            TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM make_bill_h_f2.
  PERFORM make_bill_i_f2.
  IF gv_err = 'X'.
    RETURN.
  ENDIF.
  CALL SCREEN 0210.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_quot .
  IF go_alv_quot IS NOT INITIAL.
    CALL METHOD go_alv_quot->free.
  ENDIF.

  IF go_cont_quot IS NOT INITIAL.
    CALL METHOD go_cont_quot->free.
  ENDIF.

  CLEAR: go_alv_quot, go_cont_quot.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_bill_h_f2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_bill_h_f2.

  CLEAR: gs_bill_h, gv_name1, gv_branch_nm,
         gv_so_netwr, gv_so_waerk, gv_dp_vbeln, gv_dp_amt,gv_dp_waerk.

  gv_fkart = 'F2'.

  gs_bill_h-bukrs   = '1000'.
  gs_bill_h-fkart   = 'F2'.
  gs_bill_h-vgbel   = gs_so-vbeln_s.
  gs_bill_h-kunnr   = gs_so-kunnr.
  gs_bill_h-bupla   = gs_so-bupla.
  gs_bill_h-netwr   = gs_so-bal_amt.
  gs_bill_h-waerk   = gs_so-waerk.
  gs_bill_h-fkdat   = sy-datum.
  gs_bill_h-zduedat = sy-datum + 7.
  gs_bill_h-zzpayst = '01'.

  gv_name1     = gs_so-name1.
  gv_branch_nm = gs_so-branch_nm.
  gv_so_netwr  = gs_so-netwr.
  gv_so_waerk = gs_so-waerk.
  gv_dp_vbeln  = gs_so-dp_vbeln.
  gv_dp_amt    = gs_so-dp_amt.
  gv_dp_waerk  = gs_so-waerk.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_bill_i_f2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_bill_i_f2.

  DATA: lt_so_i    TYPE TABLE OF z8sd_so_i,
        ls_so_i    TYPE z8sd_so_i,
        lv_posnr   TYPE z8sd_billing_i-posnr,
        lv_transit TYPE z8sd_quotation_h-transit_cost,
        lv_install TYPE z8sd_quotation_h-install_cost.

  CLEAR: gt_bill_i, lv_posnr, gv_err.

  IF gs_so-netwr = 0.
    gv_err = 'X'.
    MESSAGE 'SO 금액이 0이라 잔금을 계산할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "1. SO 품목 → 잔금 품목
  SELECT *
    FROM z8sd_so_i
    WHERE vbeln_s = @gs_so-vbeln_s
    ORDER BY posnr
    INTO TABLE @lt_so_i.

  LOOP AT lt_so_i INTO ls_so_i.
    CLEAR gs_bill_i.
    lv_posnr = lv_posnr + 10.

    gs_bill_i-posnr = lv_posnr.
    gs_bill_i-matnr = ls_so_i-matnr.
    gs_bill_i-arktx = ls_so_i-arktx.
    gs_bill_i-vgbel = ls_so_i-vbeln_s.
    gs_bill_i-vgpos = ls_so_i-posnr.
    gs_bill_i-fkimg = ls_so_i-kwmeng.
    gs_bill_i-vrkme = ls_so_i-vrkme.
    gs_bill_i-netwr = ls_so_i-netwr * gs_bill_h-netwr / gs_so-netwr.
    gs_bill_i-waerk = gs_bill_h-waerk.
    APPEND gs_bill_i TO gt_bill_i.
  ENDLOOP.

  "2. 운송비 / 설치비 (SO에 없으니 견적 헤더에서)
  SELECT SINGLE transit_cost, install_cost
    FROM z8sd_quotation_h
    WHERE vbeln_q = @gs_so-vbeln_q
    INTO (@lv_transit, @lv_install).

  IF lv_transit > 0.
    CLEAR gs_bill_i.
    lv_posnr = lv_posnr + 10.
    gs_bill_i-posnr = lv_posnr.
    gs_bill_i-matnr = 'SVC-TRANS'.
    gs_bill_i-arktx = '운송비'.
    gs_bill_i-vgbel = gs_so-vbeln_s.
    gs_bill_i-fkimg = 1.
    gs_bill_i-vrkme = 'EA'.
    gs_bill_i-netwr = lv_transit * gs_bill_h-netwr / gs_so-netwr.
    gs_bill_i-waerk = gs_bill_h-waerk.
    APPEND gs_bill_i TO gt_bill_i.
  ENDIF.

  IF lv_install > 0.
    CLEAR gs_bill_i.
    lv_posnr = lv_posnr + 10.
    gs_bill_i-posnr = lv_posnr.
    gs_bill_i-matnr = 'SVC-INST'.
    gs_bill_i-arktx = '설치비'.
    gs_bill_i-vgbel = gs_so-vbeln_s.
    gs_bill_i-fkimg = 1.
    gs_bill_i-vrkme = 'EA'.
    gs_bill_i-netwr = lv_install * gs_bill_h-netwr / gs_so-netwr.
    gs_bill_i-waerk = gs_bill_h-waerk.
    APPEND gs_bill_i TO gt_bill_i.
  ENDIF.

  "3. 합계 확인 + 끝전 보정
  PERFORM adjust_bill_items.
  IF gv_err = 'X'.
    RETURN.
  ENDIF.

  "4. 화면용 미리보기
  CLEAR gt_prev.

  LOOP AT gt_bill_i INTO gs_bill_i.
    CLEAR gs_prev.
    MOVE-CORRESPONDING gs_bill_i TO gs_prev.

    IF gs_bill_i-vgpos IS NOT INITIAL.
      READ TABLE lt_so_i INTO ls_so_i WITH KEY posnr = gs_bill_i-vgpos.
      IF sy-subrc = 0.
        gs_prev-place_type = ls_so_i-place_type.
        gs_prev-quot_amt   = ls_so_i-netwr.
      ENDIF.
    ELSEIF gs_bill_i-matnr = 'SVC-TRANS'.
      gs_prev-quot_amt = lv_transit.
    ELSEIF gs_bill_i-matnr = 'SVC-INST'.
      gs_prev-quot_amt = lv_install.
    ENDIF.

    gs_prev-rest_amt = gs_prev-quot_amt - gs_prev-netwr.
    APPEND gs_prev TO gt_prev.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form adjust_bill_items
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM adjust_bill_items.
  "합계확인 + 금액 보정.

  DATA: lv_sum  TYPE z8sd_billing_i-netwr,
        lv_diff TYPE z8sd_billing_i-netwr,
        lv_last TYPE i.

  CLEAR: lv_sum, gv_err.

  LOOP AT gt_bill_i INTO gs_bill_i.
    lv_sum = lv_sum + gs_bill_i-netwr.
  ENDLOOP.

  lv_diff = gs_bill_h-netwr - lv_sum.

  IF lv_diff > '0.10' OR lv_diff < '-0.10'.
    gv_err = 'X'.
    MESSAGE S140(Z8_MSG) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_diff <> 0.
    DESCRIBE TABLE gt_bill_i LINES lv_last.
    READ TABLE gt_bill_i INTO gs_bill_i INDEX lv_last.
    gs_bill_i-netwr = gs_bill_i-netwr + lv_diff.
    MODIFY gt_bill_i FROM gs_bill_i INDEX lv_last.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler_quot .
  SET HANDLER lcl_handler=>on_hotspot_quot FOR go_alv_quot.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler_so .
  SET HANDLER lcl_handler=>on_hotspot_so FOR go_alv_so.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_billing.

  CLEAR: gs_bill_h, gt_bill_i, gv_name1, gv_branch_nm,
         gv_fkart_tx, gv_pay_tx.

  SELECT SINGLE *
    FROM z8sd_billing_h
    WHERE vbeln = @gv_detail_vbeln
    INTO @gs_bill_h.

  IF sy-subrc <> 0.
    MESSAGE '청구문서를 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT *
    FROM z8sd_billing_i
    WHERE vbeln = @gv_detail_vbeln
    ORDER BY posnr
    INTO TABLE @gt_bill_i.

  SELECT SINGLE name1
    FROM z8customer_m
    WHERE kunnr = @gs_bill_h-kunnr
    INTO @gv_name1.

  SELECT SINGLE name
    FROM z8branch_m
    WHERE bukrs  = @gs_bill_h-bukrs
      AND branch = @gs_bill_h-bupla
    INTO @gv_branch_nm.

  IF gs_bill_h-fkart = 'F1'.
    gv_fkart_tx = '선수금'.
  ELSE.
    gv_fkart_tx = '잔금'.
  ENDIF.

  IF gs_bill_h-zzpayst = '01'.
    gv_pay_tx = '미입금'.
  ELSEIF gs_bill_h-zzpayst = '02'.
    gv_pay_tx = '입금완료'.
  ELSEIF gs_bill_h-zzpayst = '03'.
    gv_pay_tx = '입금기한 만료'.
  ENDIF.

  CALL SCREEN 0300.
  IF gv_refresh_100 = 'X' AND p_detail IS INITIAL.
    IF p_r1 = 'X'.
      PERFORM refresh_alv_quot.
    ELSE.
      PERFORM refresh_alv_so.
    ENDIF.
    CLEAR gv_refresh_100.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_detail .
  CREATE OBJECT go_cont_detail
    EXPORTING
      container_name = 'D_ALV'.
  CREATE OBJECT go_alv_detail
    EXPORTING
      i_parent = go_cont_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout_detail .
  CLEAR gs_layout_detail.
  gs_layout_detail-zebra      = 'X'.
  gs_layout_detail-no_toolbar = 'X'.
  gs_layout_detail-grid_title = '청구 품목'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_detail .
  CLEAR gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname = 'POSNR'.
  gw_fcat_detail-coltext   = '품목'.
  gw_fcat_detail-outputlen = 5.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname = 'MATNR'.
  gw_fcat_detail-coltext   = '자재코드'.
  gw_fcat_detail-outputlen = 12.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname = 'ARKTX'.
  gw_fcat_detail-coltext   = '품목명'.
  gw_fcat_detail-outputlen = 22.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname  = 'FKIMG'.
  gw_fcat_detail-coltext    = '수량'.
  gw_fcat_detail-qfieldname = 'VRKME'.
  gw_fcat_detail-decimals_o = '0'.
  gw_fcat_detail-datatype   = 'QUAN'.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname = 'VRKME'.
  gw_fcat_detail-coltext   = '단위'.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname  = 'NETWR'.
  gw_fcat_detail-coltext    = '청구금액'.
  gw_fcat_detail-cfieldname = 'WAERK'.
  gw_fcat_detail-datatype   = 'CURR'.
  gw_fcat_detail-do_sum     = 'X'.
  gw_fcat_detail-emphasize  = 'C311'.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname = 'WAERK'.
  gw_fcat_detail-coltext   = '통화'.
  gw_fcat_detail-emphasize  = 'C311'.
  APPEND gw_fcat_detail TO gt_fcat_detail.

  CLEAR gw_fcat_detail.
  gw_fcat_detail-fieldname = 'VGBEL'.
  gw_fcat_detail-coltext   = '참조번호'.
  APPEND gw_fcat_detail TO gt_fcat_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_detail .
  CALL METHOD go_alv_detail->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_detail
    CHANGING
      it_outtab       = gt_bill_i
      it_fieldcatalog = gt_fcat_detail.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_deatil
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_deatil .
  IF go_alv_detail IS NOT INITIAL.
    CALL METHOD go_alv_detail->free.
  ENDIF.

  IF go_cont_detail IS NOT INITIAL.
    CALL METHOD go_cont_detail->free.
  ENDIF.

  CLEAR: go_alv_detail, go_cont_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form cancel_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM cancel_billing .
  DATA: lv_payst  TYPE z8sd_billing_h-zzpayst,
        lv_belnr  TYPE z8sd_billing_h-belnr,
        lv_answer TYPE c LENGTH 1,
        lv_text   TYPE c LENGTH 100,
        lv_msg    TYPE c LENGTH 100.

  "1. Lock (FI 입금처리와 동시에 못 하게)
  CALL FUNCTION 'ENQUEUE_EZ8SD_BILL'
    EXPORTING
      vbeln          = gs_bill_h-vbeln
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc <> 0.
    MESSAGE '다른 사용자가 해당 청구건을 처리 중입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "2. 최신 상태 다시 확인
  SELECT SINGLE zzpayst, belnr
    FROM z8sd_billing_h
    WHERE vbeln = @gs_bill_h-vbeln
    INTO (@lv_payst, @lv_belnr).

  IF lv_payst <> '01' OR lv_belnr IS NOT INITIAL.
    PERFORM unlock_billing.
    MESSAGE '입금처리된 청구문서는 취소할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "3. 확인 팝업
  CONCATENATE '청구문서' gs_bill_h-vbeln '를 취소하시겠습니까?'
    INTO lv_text SEPARATED BY space.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '청구취소'
      text_question         = lv_text
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    PERFORM unlock_billing.
    RETURN.
  ENDIF.

  "4. 품목 → 헤더 순으로 삭제
  DELETE FROM z8sd_billing_i WHERE vbeln = gs_bill_h-vbeln.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    PERFORM unlock_billing.
    MESSAGE '청구 품목 삭제에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  DELETE FROM z8sd_billing_h WHERE vbeln = gs_bill_h-vbeln.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    PERFORM unlock_billing.
    MESSAGE '청구 헤더 삭제에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK AND WAIT.
  PERFORM unlock_billing.

  CONCATENATE '청구문서' gs_bill_h-vbeln '가 취소되었습니다.'
    INTO lv_msg SEPARATED BY space.

  gv_refresh_100 = 'X'.
  PERFORM free_control_detail.
  MESSAGE lv_msg TYPE 'I'.
  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form unlock_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM unlock_billing .
  CALL FUNCTION 'DEQUEUE_EZ8SD_BILL'
    EXPORTING
      vbeln = gs_bill_h-vbeln.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_detail .
  IF go_alv_detail IS NOT INITIAL.
    CALL METHOD go_alv_detail->free.
  ENDIF.

  IF go_cont_detail IS NOT INITIAL.
    CALL METHOD go_cont_detail->free.
  ENDIF.

  CLEAR: go_alv_detail, go_cont_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form focus_last_vbeln_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM focus_last_vbeln_so .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row,
        ls_col  TYPE lvc_s_col.

  IF gv_last_vbeln IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE gt_so INTO gs_so WITH KEY vbeln = gv_last_vbeln.
  IF sy-subrc <> 0.
    CLEAR gv_last_vbeln.
    RETURN.
  ENDIF.

  ls_row-index = sy-tabix.
  APPEND ls_row TO lt_rows.
  CALL METHOD go_alv_so->set_selected_rows
    EXPORTING
      it_index_rows = lt_rows.

  ls_col-fieldname = 'VBELN'.
  CALL METHOD go_alv_so->set_current_cell_via_id
    EXPORTING
      is_row_id    = ls_row
      is_column_id = ls_col.

  CLEAR gv_last_vbeln.

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
  DATA: lv_from TYPE sy-datum.
  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months        = -3
      olddate       = sy-datum
   IMPORTING
     NEWDATE       = lv_from.

  "견적일
  CLEAR s_qdat.
  s_qdat-sign   = 'I'.
  s_qdat-option = 'BT'.
  s_qdat-low    = lv_from.
  s_qdat-high   = sy-datum.
  APPEND s_qdat.

  "SO일
  CLEAR s_sdat.
  s_sdat-sign   = 'I'.
  s_sdat-option = 'BT'.
  s_sdat-low    = lv_from.
  s_sdat-high   = sy-datum.
  APPEND s_sdat.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_required
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_required.

  DATA: lt_date  TYPE RANGE OF sy-datum,
        ls_date  LIKE LINE OF lt_date,
        lv_label TYPE c LENGTH 30,
        lv_start TYPE c LENGTH 30,
        lv_field TYPE c LENGTH 20.

  "진행현황 프로그램에서 바로 들어온 경우
  IF p_detail IS NOT INITIAL.
    RETURN.
  ENDIF.

  "실행할 때만 체크
  IF sy-ucomm <> 'ONLI' AND sy-ucomm <> 'SJOB'.
    RETURN.
  ENDIF.

  "1. 지금 보이는 날짜를 임시로 꺼내기
  IF p_r1 = 'X'.
    lt_date  = s_qdat[].
    lv_label = '견적일은'.
    lv_start = '견적일 시작일은'.
    lv_field = 'S_QDAT-LOW'.
  ELSE.
    lt_date  = s_sdat[].
    lv_label = 'SO생성일은'.
    lv_start = 'SO일 시작일은'.
    lv_field = 'S_SDAT-LOW'.
  ENDIF.

  "2. 시작·종료 둘 다 비어 있음 → 막기
  IF lt_date IS INITIAL.
    SET CURSOR FIELD lv_field.
    MESSAGE e121(z8_msg) WITH lv_label.
  ENDIF.

  "3. 시작 없이 종료만 있는 줄이 있음 → 막기
  READ TABLE lt_date INTO ls_date WITH KEY low = '00000000'.
  IF sy-subrc = 0.
    SET CURSOR FIELD lv_field.
    MESSAGE e121(z8_msg) WITH lv_start.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_quot .
    DATA: ls_ct TYPE lvc_s_styl.

  LOOP AT gt_quot INTO gs_quot.

    CLEAR gs_quot-ct.

    "청구번호가 있는 줄만 청구번호 핫스팟.
    IF gs_quot-vbeln IS NOT INITIAL.
      CLEAR ls_ct.
      ls_ct-fieldname = 'VBELN'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.
      INSERT ls_ct INTO TABLE gs_quot-ct.
    ENDIF.


    MODIFY gt_quot FROM gs_quot.

 ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_so .
  DATA: ls_ct TYPE lvc_s_styl.

  LOOP AT gt_so INTO gs_so.

    CLEAR gs_so-ct.

    "청구번호가 있는 줄만 청구번호 핫스팟.
    IF gs_so-vbeln IS NOT INITIAL.
      CLEAR ls_ct.
      ls_ct-fieldname = 'VBELN'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.
      INSERT ls_ct INTO TABLE gs_so-ct.
    ENDIF.


    MODIFY gt_so FROM gs_so.

 ENDLOOP.

ENDFORM.
