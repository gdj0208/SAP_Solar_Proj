*&---------------------------------------------------------------------*
*& Include          Z8FIFC0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form update_due_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM update_due_status .

  UPDATE z8sd_billing_h
         SET zzpayst = '03'
   WHERE bukrs = gc_bukrs
        AND fkart = 'F2'
        AND zzpayst = '01'
        AND zduedat <> '00000000'
        AND zduedat < sy-datum.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_100 .

  DATA:
    lr_bupla TYPE RANGE OF z8sd_billing_h-bupla,
    lr_kunnr TYPE RANGE OF z8sd_billing_h-kunnr,
    lr_vbeln TYPE RANGE OF z8sd_billing_h-vbeln.

  CLEAR gt_bill.

  "종사업장
  IF pa_bran IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_bran
    ) TO lr_bupla.
  ENDIF.

  "고객번호
  IF pa_kunnr IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_kunnr
    ) TO lr_kunnr.
  ENDIF.

  "청구번호
  IF pa_vbeln IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_vbeln
    ) TO lr_vbeln.
  ENDIF.

  IF pa_r1 = 'X'. "미입금

    SELECT
      a~bukrs,
      a~bupla,
      name AS brancht,
      a~vbeln,
      a~vgbel,
      a~kunnr,
      d~name1,
      a~fkdat,
      a~netwr,
      a~waerk,
      a~zzpayst,
      a~zduedat,
      a~zpaydat,
      c~belnr AS ar_belnr,
      c~gjahr AS ar_gjahr,
      c~augbl,
      c~augdt,
      c~auggj
      FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8ps_project AS p
      ON p~vbeln = a~vgbel
      LEFT OUTER JOIN z8fi_customer AS c
      ON c~bukrs = a~bukrs
      AND c~bupla = a~bupla
      AND c~kunnr = a~kunnr
      AND c~xblnr = p~pro_id
      LEFT OUTER JOIN z8branch_m AS b
      ON b~bukrs = a~bukrs
      AND b~branch = a~bupla
      LEFT OUTER JOIN z8customer_m AS d
      ON d~kunnr = a~kunnr
      INTO CORRESPONDING FIELDS OF TABLE @gt_bill
      WHERE a~bukrs = @gc_bukrs
            AND a~bupla IN @lr_bupla
            AND a~kunnr IN @lr_kunnr
            AND a~vbeln IN @lr_vbeln
            AND a~fkdat IN @so_fkdat
            AND a~fkart = 'F2'
            AND a~zzpayst = '01'.

  ELSEIF pa_r2 = 'X'. "입금완료

    SELECT
      a~bukrs,
      a~bupla,
      name AS brancht,
      a~vbeln,
      a~vgbel,
      a~kunnr,
      d~name1,
      a~fkdat,
      a~netwr,
      a~waerk,
      a~zzpayst,
      a~zduedat,
      a~zpaydat,
      c~belnr AS ar_belnr,
      c~gjahr AS ar_gjahr,
      c~augbl,
      c~augdt,
      c~auggj
      FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8ps_project AS p
      ON p~vbeln = a~vgbel
      LEFT OUTER JOIN z8fi_customer AS c
      ON c~bukrs = a~bukrs
      AND c~bupla = a~bupla
      AND c~kunnr = a~kunnr
      AND c~xblnr = p~pro_id
      LEFT OUTER JOIN z8branch_m AS b
      ON b~bukrs = a~bukrs
      AND b~branch = a~bupla
      LEFT OUTER JOIN z8customer_m AS d
      ON d~kunnr = a~kunnr
      INTO CORRESPONDING FIELDS OF TABLE @gt_bill
      WHERE a~bukrs = @gc_bukrs
            AND a~bupla IN @lr_bupla
            AND a~kunnr IN @lr_kunnr
            AND a~vbeln IN @lr_vbeln
            AND a~fkdat IN @so_fkdat
            AND a~fkart = 'F2'
            AND a~zzpayst = '02'.

  ELSEIF pa_r3 = 'X'. "전체

    SELECT
      a~bukrs,
      a~bupla,
      name AS brancht,
      a~vbeln,
      a~vgbel,
      a~kunnr,
      name1,
      a~fkdat,
      a~netwr,
      a~waerk,
      a~zzpayst,
      a~zduedat,
      a~zpaydat,
      c~belnr AS ar_belnr,
      c~gjahr AS ar_gjahr,
      c~augbl,
      c~augdt,
      c~auggj
      FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8ps_project AS p
      ON p~vbeln = a~vgbel
      LEFT OUTER JOIN z8fi_customer AS c
      ON c~bukrs = a~bukrs
      AND c~bupla = a~bupla
      AND c~kunnr = a~kunnr
      AND c~xblnr = p~pro_id
      LEFT OUTER JOIN z8branch_m AS b
      ON b~bukrs = a~bukrs
      AND b~branch = a~bupla
      LEFT OUTER JOIN z8customer_m AS d
      ON d~kunnr = a~kunnr
      INTO CORRESPONDING FIELDS OF TABLE @gt_bill
      WHERE a~bukrs = @gc_bukrs
            AND a~bupla IN @lr_bupla
            AND a~kunnr IN @lr_kunnr
            AND a~vbeln IN @lr_vbeln
            AND a~fkdat IN @so_fkdat
            AND a~fkart = 'F2'.

  ELSEIF pa_r4 = 'X'. "입금기한 경과

    SELECT
      a~bukrs,
      a~bupla,
      name AS brancht,
      a~vbeln,
      a~vgbel,
      a~kunnr,
      name1,
      a~fkdat,
      a~netwr,
      a~waerk,
      a~zzpayst,
      a~zduedat,
      a~zpaydat,
      c~belnr AS ar_belnr,
      c~gjahr AS ar_gjahr,
      c~augbl,
      c~augdt,
      c~auggj
      FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8ps_project AS p
      ON p~vbeln = a~vgbel
      LEFT OUTER JOIN z8fi_customer AS c
      ON c~bukrs = a~bukrs
      AND c~bupla = a~bupla
      AND c~kunnr = a~kunnr
      AND c~xblnr = p~pro_id
      LEFT OUTER JOIN z8branch_m AS b
      ON b~bukrs = a~bukrs
      AND b~branch = a~bupla
      LEFT OUTER JOIN z8customer_m AS d
      ON d~kunnr = a~kunnr
      INTO CORRESPONDING FIELDS OF TABLE @gt_bill
      WHERE a~bukrs = @gc_bukrs
            AND a~bupla IN @lr_bupla
            AND a~kunnr IN @lr_kunnr
            AND a~vbeln IN @lr_vbeln
            AND a~fkdat IN @so_fkdat
            AND a~fkart = 'F2'
            AND a~zzpayst = '03'.

  ENDIF.

*  WHERE a~bukrs = @pa_bukrs
*       AND a~bupla IN @lr_bran
*       AND a~lifnr IN @lr_lifnr
*       AND b~inv_no IN @lr_invno
*       AND a~belnr IN @lr_belnr
*       AND a~budat IN @so_budat
*       AND a~augbl = @space.

  PERFORM get_add_data_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_100 .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_100
    EXPORTING
      container_name              = 'CONTROL_AREA_100'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_100
    EXPORTING
      i_parent          = go_cont_100 "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_100 .

  CALL METHOD go_alv_100->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_100
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_bill
      it_fieldcatalog               = gt_fcat_100
      it_sort                       = gt_sort
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_100 .

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'LIGHT'. "예외 컬럼 이름
  gs_fcat_100-coltext = '상태'.
*  gs_fcat-col_pos   = 7."삽입할 위치.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
*  gs_fcat-fieldname = 'ZZPAYST'.
  gs_fcat_100-fieldname = 'PAYSTT'.
  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '입금상태'.
  gs_fcat_100-outputlen = 13.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'ZDUEDAT'.
  gs_fcat_100-coltext = '입금기한'.
  gs_fcat_100-key = 'X'.
  gs_fcat_100-outputlen = 11.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'ZPAYDAT'.
  gs_fcat_100-coltext = '입금일자'.
  gs_fcat_100-outputlen = 11.
  APPEND gs_fcat_100 TO gt_fcat_100.


  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'VBELN'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '청구번호'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'VGBEL'.
  gs_fcat_100-coltext = 'SO번호'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BUPLA'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '지사'.
  gs_fcat_100-outputlen = 7.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BRANCHT'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '지사명'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'KUNNR'.
*  gs_fcat-key = 'X'.
  gs_fcat_100-coltext = '고객번호'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'NAME1'.
*  gs_fcat-key = 'X'.
  gs_fcat_100-coltext = '고객명'.
  gs_fcat_100-outputlen = 18.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'FKDAT'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '청구일'.
  gs_fcat_100-outputlen = 11.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'NETWR'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '청구금액'.
  gs_fcat_100-ref_field = 'NETWR'.
  gs_fcat_100-cfieldname = 'WAERK'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 15.
*  gs_fcat_100-do_sum = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'WAERK'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '통화'.
  gs_fcat_100-ref_field = 'WAERK'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 7.
  APPEND gs_fcat_100 TO gt_fcat_100.


  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'AR_BELNR'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '원전표번호'.
*  gs_fcat_100-hotspot = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'AUGBL'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '입금전표번호'.
*  gs_fcat_100-hotspot = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_add_data_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_add_data_100 .

  LOOP AT gt_bill INTO gs_bill.

    CASE gs_bill-zzpayst.
      WHEN '01'.
        gs_bill-paystt = '미입금'.
        gs_bill-light = '1'.
      WHEN '02'.
        gs_bill-paystt = '입금완료'.
        gs_bill-light = '3'.
      WHEN '03'.
        gs_bill-paystt = '입금기한 경과'.
        gs_bill-light = '2'.
    ENDCASE.

    MODIFY gt_bill FROM gs_bill.

  ENDLOOP.

  SORT gt_bill BY light ASCENDING
                            zduedat ASCENDING.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_100 .

  "라인 선택 기능 활성화(라인 선택)
  gs_layout_100-sel_mode = 'B'.
  gs_layout_100-zebra = 'X'.
  gs_layout_100-stylefname = 'CT'. "핫스팟

*  "정렬
*  CLEAR gs_sort.
*  gs_sort-fieldname = 'ZDUEDAT'.
*  gs_sort-spos = 1.
*  gs_sort-down = 'X'.
*  INSERT gs_sort INTO TABLE gt_sort.

  "신호등
  gs_layout_100-excp_fname = 'LIGHT'.
  gs_layout_100-excp_led   = 'X'.

  PERFORM set_grid_title_100.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_100 .

  "alv 그리드 제목
  DATA lv_count TYPE i.

  DESCRIBE TABLE gt_bill LINES lv_count.

  IF pa_r1 = 'X'.
    gs_layout_100-grid_title = |미입금 ({ lv_count }건)|.
  ELSEIF pa_r2 = 'X'.
    gs_layout_100-grid_title = |입금완료 ({ lv_count }건)|.
  ELSEIF pa_r3 = 'X'.
    gs_layout_100-grid_title = |전체 ({ lv_count }건)|.
  ELSEIF pa_r4 = 'X'.
    gs_layout_100-grid_title = |입금기한 경과 ({ lv_count }건)|.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form payment_process
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM payment_process .

  DATA:
    lt_rows     TYPE lvc_t_roid,
    ls_row      TYPE lvc_s_roid,
    lv_ar_ok    TYPE c,
    lv_clear_ok TYPE c.

  go_alv_100->get_selected_rows(
    IMPORTING
      et_row_no = lt_rows ).

  IF lt_rows IS INITIAL.
    MESSAGE '입금처리할 청구서를 선택해주세요.'
            TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lines( lt_rows ) > 1.
    MESSAGE s058(z8_msg) DISPLAY LIKE 'E'. "한 건만 선택해주세요.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE gt_bill INTO gs_bill INDEX ls_row-row_id.

  IF sy-subrc <> 0.
    MESSAGE '선택한 데이터를 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "이미 잔금 입금된 건 불가능
  IF gs_bill-augbl IS NOT INITIAL OR gs_bill-zzpayst = '02'.
    MESSAGE s066(z8_msg) DISPLAY LIKE 'E' WITH '입급'."이미 입금 및 반제 처리된 건 입니다.'
    RETURN.
  ENDIF.

  "연결된 외상매출금 원전표 존재 여부
  IF gs_bill-ar_belnr IS INITIAL OR gs_bill-ar_gjahr IS INITIAL.
    MESSAGE '연결된 외상매출금 전표가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "청구서 락 걸기
  CLEAR gv_return.
  PERFORM lock_billing.

  IF gv_return <> 0.
    MESSAGE '다른 사용자가 해당 청구건을 처리 중입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "고객 미결 락 걸기
  CLEAR gv_return.
  PERFORM lock_customer.

  IF gv_return <> 0.
    MESSAGE '다른 사용자가 해당 외상매입금을 처리 중입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "락 성공 후 실제 DB반제 상태 재확인
  PERFORM check_clear_status CHANGING lv_clear_ok.

  IF lv_clear_ok IS INITIAL.
    "락 해제
    PERFORM unlock_all.
    PERFORM refresh_alv_100.
    RETURN.
  ENDIF.

  "원 외상매출금 전표 검증
  PERFORM check_org_ar CHANGING lv_ar_ok.

  IF lv_ar_ok IS INITIAL.
    PERFORM unlock_all.
    RETURN.
  ENDIF.

  "입금 기본값 설정
  gv_paydat = sy-datum.
  gv_pay = gs_bill-netwr.
  gv_pay_waers = gs_bill-waerk.

  WRITE gs_bill-netwr TO gv_netwr_txt CURRENCY gs_bill-waerk.
  CONDENSE gv_netwr_txt.
  WRITE gv_pay TO gv_pay_txt CURRENCY gs_bill-waerk.
  CONDENSE gv_pay_txt.

  "200번 화면 상단 alv
  PERFORM get_org_ar.
  "200번 화면 하단 alv + 지급전표 아이템
  PERFORM set_accdoc.

  CALL SCREEN '0200'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form lock_customer
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM lock_customer .

  CALL FUNCTION 'ENQUEUE_EZ8FI_CUSTOMER'
    EXPORTING
*     MODE_Z8FI_CUSTOMER       = 'E'
*     MANDT          = SY-MANDT
      bukrs          = gs_bill-bukrs
      gjahr          = gs_bill-ar_gjahr
      belnr          = gs_bill-ar_belnr
*     X_BUKRS        = ' '
*     X_GJAHR        = ' '
*     X_BELNR        = ' '
*     _SCOPE         = '2'
*     _WAIT          = ' '
*     _COLLECT       = ' '
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  gv_return = sy-subrc.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_clear_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_CLEAR_OK
*&---------------------------------------------------------------------*
FORM check_clear_status  CHANGING pv_clear_ok.

  DATA: lv_augbl  TYPE z8fi_customer-augbl,
        lv_payst  TYPE z8sd_billing_h-zzpayst,
        lv_duedat TYPE z8sd_billing_h-zduedat.

  CLEAR: pv_clear_ok, lv_augbl, lv_payst.

  SELECT SINGLE zzpayst zduedat
     FROM z8sd_billing_h
     INTO (lv_payst, lv_duedat)
    WHERE bukrs = gc_bukrs
    AND vbeln = gs_bill-vbeln
    AND fkart = 'F2'.

  IF sy-subrc <> 0.
*    PERFORM unlock_billing.
    MESSAGE '해당 청구서 정보를 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_payst = '02'.
*    PERFORM unlock_billing.
*    PERFORM refresh_alv_100.
    MESSAGE '이미 입금처리된 청구건입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_payst = '03'.
*    PERFORM unlock_billing.
*    PERFORM refresh_alv_100.
    MESSAGE '입금기한이 경과한 청구건입니다. 실제 입금일을 확인해주세요' TYPE 'S'. "DISPLAY LIKE 'E'.
*    RETURN.
  ENDIF.

  SELECT SINGLE augbl
    FROM z8fi_customer
      INTO lv_augbl
  WHERE bukrs = gs_bill-bukrs
       AND gjahr = gs_bill-ar_gjahr
       AND belnr = gs_bill-ar_belnr.

  IF sy-subrc <> 0.
    MESSAGE s070(z8_msg) DISPLAY LIKE 'E'."고객 외상매출금 미결항목을 찾을 수 없습니다
    RETURN.
  ENDIF.

  IF lv_augbl IS NOT INITIAL.
    MESSAGE s066(z8_msg) DISPLAY LIKE 'E' WITH '입급'."이미 입급 및 반제 처리된 건 입니다.'
    RETURN.
  ENDIF.

  pv_clear_ok = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form unlock_customer
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM unlock_customer .

  CALL FUNCTION 'DEQUEUE_EZ8FI_CUSTOMER'
    EXPORTING
*     MODE_Z8FI_CUSTOMER       = 'E'
*     MANDT = SY-MANDT
      bukrs = gs_bill-bukrs
      gjahr = gs_bill-ar_gjahr
      belnr = gs_bill-ar_belnr
*     X_BUKRS                  = ' '
*     X_GJAHR                  = ' '
*     X_BELNR                  = ' '
*     _SCOPE                   = '3'
*     _SYNCHRON                = ' '
*     _COLLECT                 = ' '
    .


ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_100 .

  DATA:
    ls_row TYPE lvc_s_row,
    ls_col TYPE lvc_s_col.

  "최신 데이터 다시 조회
  PERFORM update_due_status.
  PERFORM get_data_100.
  PERFORM set_cell_style_100.

  "전표 생성 후 재조회 결과가 없는 경우
  IF gv_refresh_100 = 'X' AND gt_bill IS INITIAL.
    CLEAR: gv_refresh_100, gv_last_bukrs, gv_last_gjahr, gv_last_belnr.
    MESSAGE s065(z8_msg) WITH '입금 및 반제'." 처리가 완료되어 현재 조회조건에 해당하는 데이터가 없습니다.'

    LEAVE TO SCREEN 0.
  ENDIF.

  "alv 제목 재설정
  PERFORM set_grid_title_100.

  CALL METHOD go_alv_100->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_100-grid_title.

  gs_stable-row = 'X'.
  gs_stable-col = 'X'.

  CALL METHOD go_alv_100->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh = ' '
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
*       Implement suitable error handling here
  ENDIF.

  IF gv_refresh_100 = 'X'.
    PERFORM select_last_row_100.
    CLEAR gv_refresh_100.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form select_last_row_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_last_row_100 .

  DATA:
    lt_rows TYPE lvc_t_row,
    ls_row  TYPE lvc_s_row.

  CLEAR lt_rows.

  LOOP AT gt_bill INTO gs_bill.

*    IF gs_bill-bukrs = gv_last_bukrs
*      AND gs_bill-ar_gjahr = gv_last_gjahr
*      AND gs_bill-ar_belnr = gv_last_belnr.

    IF gs_bill-vbeln = gv_last_vbeln.

      ls_row-index = sy-tabix.
      APPEND ls_row TO lt_rows.

      EXIT.
    ENDIF.

  ENDLOOP.

  IF lt_rows IS NOT INITIAL.
    CALL METHOD go_alv_100->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows
*       it_row_no     =
*       is_keep_other_selections =
      .


  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_org_ar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_AR_OK
*&---------------------------------------------------------------------*
FORM check_org_ar  CHANGING pv_ok TYPE c.

  CLEAR gs_ar_item.

  SELECT SINGLE *
    FROM z8fi_accdoc_i
    INTO gs_ar_item
    WHERE bukrs = gs_bill-bukrs
    AND belnr = gs_bill-ar_belnr
    AND gjahr = gs_bill-ar_gjahr
    AND koart = 'D'
    AND hkont = '11010000'
    AND shkzg = 'S'
    AND kunnr = gs_bill-kunnr.

  IF sy-subrc <> 0.
    MESSAGE '원전표의 외상매출금 항목을 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "금액 일치 확인
  IF gs_ar_item-wrbtr <> gs_bill-netwr.
    MESSAGE '원전표의 외상출금과 미결금액이 일치하지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  pv_ok = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_org_ar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_org_ar .

  CLEAR: gt_acc_i, gt_org.

  SELECT *
     FROM z8fi_accdoc_i
       INTO TABLE gt_acc_i
   WHERE bukrs = gs_bill-bukrs
        AND belnr = gs_bill-ar_belnr
        AND gjahr = gs_bill-ar_gjahr
        AND bupla = gs_bill-bupla
    ORDER BY buzei.

  IF sy-subrc <> 0.
    MESSAGE s072(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_acc_i INTO gs_acc_i.

    CLEAR gs_org.

    gs_org-buzei = gs_acc_i-buzei.
    gs_org-koart = gs_acc_i-koart.
    gs_org-hkont = gs_acc_i-hkont.
    gs_org-shkzg = gs_acc_i-shkzg.
    gs_org-waers = gs_acc_i-waers.
    gs_org-kunnr = gs_acc_i-kunnr.
    gs_org-umskz = gs_acc_i-umskz.

    IF gs_acc_i-shkzg = 'S'. "차변이면
      gs_org-shkzgt = '차변'.
      gs_org-debit = gs_acc_i-wrbtr.
    ELSEIF gs_acc_i-shkzg = 'H'. "대변이면
      gs_org-shkzgt = '대변'.
      gs_org-credit = gs_acc_i-wrbtr.
    ENDIF.

    "반제대상
    IF gs_acc_i-koart = 'D' AND gs_acc_i-kunnr = gs_bill-kunnr.
      gs_org-target = '대상'.
    ENDIF.

    "계정명
    SELECT SINGLE txt20
      FROM z8v_glacc
      INTO gs_org-txt20
      WHERE saknr = gs_acc_i-hkont.

    APPEND gs_org TO gt_org.

  ENDLOOP.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form lock_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM lock_billing .

  CALL FUNCTION 'ENQUEUE_EZ8SD_BILL'
    EXPORTING
*     MODE_Z8SD_BILLING_H       = 'E'
*     MANDT          = SY-MANDT
      vbeln          = gs_bill-vbeln
*     X_VBELN        = ' '
*     _SCOPE         = '2'
*     _WAIT          = ' '
*     _COLLECT       = ' '
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  gv_return = sy-subrc.

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
*     MODE_Z8SD_BILLING_H       = 'E'
*     MANDT = SY-MANDT
      vbeln = gs_bill-vbeln
*     X_VBELN                   = ' '
*     _SCOPE                    = '3'
*     _SYNCHRON                 = ' '
*     _COLLECT                  = ' '
    .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_200 .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_org
    EXPORTING
      container_name              = 'CC_ORG'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_org
    EXPORTING
      i_parent          = go_cont_org "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_pre
    EXPORTING
      container_name              = 'CC_PRE'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_pre
    EXPORTING
      i_parent          = go_cont_pre "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_200 .

  CALL METHOD go_alv_org->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_org
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_org
      it_fieldcatalog               = gt_fcat_org
*     it_sort                       =
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  CALL METHOD go_alv_pre->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_pre
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_pre
      it_fieldcatalog               = gt_fcat_pre
*     it_sort                       =
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_200 .

  "원전표 내역
  CLEAR: gt_fcat_org, gs_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'BUZEI'.
  gs_fcat_org-coltext = '항목'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'HKONT'.
  gs_fcat_org-coltext = 'G/L계정'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'TXT20'.
  gs_fcat_org-coltext = 'G/L계정명'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'SHKZGT'.
  gs_fcat_org-coltext = '구분'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'DEBIT'.
  gs_fcat_org-coltext = '차변금액'.
  gs_fcat_org-cfieldname = 'WAERS'.
  gs_fcat_org-no_zero = 'X'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'CREDIT'.
  gs_fcat_org-coltext = '대변금액'.
  gs_fcat_org-cfieldname = 'WAERS'.
  gs_fcat_org-no_zero = 'X'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'WAERS'.
  gs_fcat_org-coltext = '통화'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'KUNNR'.
  gs_fcat_org-coltext = '고객번호'.
  APPEND gs_fcat_org TO gt_fcat_org.

  CLEAR gs_fcat_org.
  gs_fcat_org-fieldname = 'TARGET'.
  gs_fcat_org-coltext = '반제대상'.
  APPEND gs_fcat_org TO gt_fcat_org.

  "--생성 예정 전표---------------------------------------------------
  CLEAR: gt_fcat_pre, gs_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'BUZEI'.
  gs_fcat_pre-coltext = '항목'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'HKONT'.
  gs_fcat_pre-coltext = 'G/L계정'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'TXT20'.
  gs_fcat_pre-coltext = 'G/L계정명'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'SHKZGT'.
  gs_fcat_pre-coltext = '구분'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'DEBIT'.
  gs_fcat_pre-coltext = '차변금액'.
  gs_fcat_pre-cfieldname = 'WAERS'.
  gs_fcat_pre-no_zero = 'X'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'CREDIT'.
  gs_fcat_pre-coltext = '대변금액'.
  gs_fcat_pre-cfieldname = 'WAERS'.
  gs_fcat_pre-no_zero = 'X'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'WAERS'.
  gs_fcat_pre-coltext = '통화'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

  CLEAR gs_fcat_pre.
  gs_fcat_pre-fieldname = 'KUNNR'.
  gs_fcat_pre-coltext = '고객번호'.
  APPEND gs_fcat_pre TO gt_fcat_pre.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_200 .

  gs_layout_org-grid_title = '지급 대상 전표'.
  gs_layout_org-zebra = 'X'.
  gs_layout_org-no_toolbar = 'X'.

  gs_layout_pre-grid_title = '생성 예정 전표'.
  gs_layout_pre-zebra = 'X'.
  gs_layout_pre-no_toolbar = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_accdoc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_accdoc .

  "실제 전표에 입력될 값
  CLEAR: gt_acc_i, gt_pre.

  "1) 차변-매출
  CONSTANTS: lc_bank TYPE z8fi_accdoc_i-hkont VALUE '10300100'.

  CLEAR gs_acc_i.

  gs_acc_i-bukrs = gs_bill-bukrs.
  gs_acc_i-buzei = '001'.
  gs_acc_i-koart = 'S'.
  gs_acc_i-hkont = lc_bank.
  gs_acc_i-bupla = gs_bill-bupla.
  gs_acc_i-shkzg = 'S'.
  gs_acc_i-wrbtr = gv_pay.
  gs_acc_i-waers = gs_bill-waerk.
*  gs_acc_i-kunnr = gs_bill-kunnr.

  CLEAR: gs_acc_i-kostl, gs_acc_i-prctr, gs_acc_i-kunnr, gs_acc_i-lifnr, gs_acc_i-umskz.

  APPEND gs_acc_i TO gt_acc_i.

  "2) 대변-외상매출금

  CLEAR gs_acc_i.

  gs_acc_i-bukrs = gs_bill-bukrs.
  gs_acc_i-buzei = '002'.
  gs_acc_i-koart = gs_ar_item-koart.
  gs_acc_i-hkont = gs_ar_item-hkont.
  gs_acc_i-bupla = gs_bill-bupla.
  gs_acc_i-shkzg = 'H'.
  gs_acc_i-wrbtr = gv_pay.
  gs_acc_i-waers = gs_bill-waerk.
  gs_acc_i-kunnr = gs_bill-kunnr.

  CLEAR: gs_acc_i-kostl, gs_acc_i-prctr, gs_acc_i-lifnr, gs_acc_i-umskz.

  APPEND gs_acc_i TO gt_acc_i.

  "preview
  LOOP AT gt_acc_i INTO gs_acc_i.

    CLEAR gs_pre.

    gs_pre-buzei = gs_acc_i-buzei.
    gs_pre-hkont = gs_acc_i-hkont.
    gs_pre-waers = gs_acc_i-waers.
    gs_pre-kunnr = gs_acc_i-kunnr.

    "계정명
    SELECT SINGLE txt20
     FROM z8v_glacc
       INTO gs_pre-txt20
   WHERE saknr = gs_acc_i-hkont.

    "차대 표시
    IF gs_acc_i-shkzg = 'S'. "차변이면
      gs_pre-shkzgt = '차변'.
      gs_pre-debit = gs_acc_i-wrbtr.
    ELSEIF gs_acc_i-shkzg = 'H'. "대변이면
      gs_pre-shkzgt = '대변'.
      gs_pre-credit = gs_acc_i-wrbtr.
    ENDIF.

    APPEND gs_pre TO gt_pre.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_200 .

  "1. ORG alv, cont 파괴
  IF go_alv_org IS BOUND.

    CALL METHOD go_alv_org->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  IF go_cont_org IS BOUND.

    CALL METHOD go_cont_org->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  CLEAR: go_alv_org, go_cont_org. "clear 대신 free써도 됨

  "2. PRE alv, cont 파괴
  IF go_alv_pre IS BOUND.

    CALL METHOD go_alv_pre->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  IF go_cont_pre IS BOUND.

    CALL METHOD go_cont_pre->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  CLEAR: go_alv_pre, go_cont_pre. "clear 대신 free써도 됨

ENDFORM.
*&---------------------------------------------------------------------*
*& Form post_check
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM post_check .

  DATA lv_answer(1) TYPE c.

  "입금일자 필수 입력
  IF gv_paydat IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '입금일자'. "입력x
  ELSEIF gv_paydat > sy-datum.
    MESSAGE s074(z8_msg) DISPLAY LIKE 'E' WITH '입금일자'. "미래
  ELSEIF gv_paydat < gs_bill-fkdat.
    MESSAGE s075(z8_msg) DISPLAY LIKE 'E' WITH '입금일자' '청구일자'. "청구일 이전
*  ELSEIF gv_paydat > gs_bill-zduedat."gv_fkdat.
*    MESSAGE s076(z8_msg) DISPLAY LIKE 'E'.
  ELSE.

    "팝업창 띄우기
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '전표 생성 확인'
        text_question         = |청구번호 { gs_bill-vbeln }의 입금 전표를 생성하시겠습니까?|
        text_button_1         = '예'(001)
        text_button_2         = '아니오'(002)
        display_cancel_button = space
        default_button        = '2'
      IMPORTING
        answer                = lv_answer.

    IF lv_answer = '1'.
      PERFORM create_accdoc.
      "방금 처리한 청구번호 기억
      gv_last_vbeln = gs_bill-vbeln.
      "100번 화면 갱신
      gv_refresh_100 = 'X'.
      "락 풀기
      PERFORM unlock_all.
      "200번 화면 파괴하고 100번 화면으로 돌아가기
      PERFORM free_control_200.
      LEAVE TO SCREEN 0.
    ELSE.
      MESSAGE '입금처리에 대한 회계전표 생성이 취소되었습니다.' TYPE 'S'.
    ENDIF.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_accdoc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_accdoc .

  DATA:
    lv_belnr  TYPE z8fi_accdoc_h-belnr,
    lv_gjahr  TYPE z8fi_accdoc_h-gjahr,
    lv_monat  TYPE z8fi_accdoc_h-monat,
    lv_payst  TYPE z8sd_billing_h-zzpayst,
    lv_paybl  TYPE z8sd_billing_h-belnr,
    lv_augbl  TYPE z8fi_customer-augbl,
    lv_duedat TYPE z8sd_billing_h-zduedat,
    lv_debit  TYPE z8fi_accdoc_i-wrbtr,
    lv_credit TYPE z8fi_accdoc_i-wrbtr,
    lv_lines  TYPE i.

  IF gt_acc_i IS INITIAL.
    MESSAGE e063(z8_msg). "'생성할 전표 아이템이 없습니다.'
  ENDIF.

  "회계전표 2개인지
  DESCRIBE TABLE gt_acc_i LINES lv_lines.

  IF lv_lines <> 2.
    MESSAGE e064(z8_msg)."'전표 아이템 구성이 올바르지 않습니다.' TYPE 'E'.
  ENDIF.

  "대차 평형 검증
  CLEAR: lv_debit, lv_credit.

  LOOP AT gt_acc_i INTO gs_acc_i.
    IF gs_acc_i-shkzg = 'S'.  "차변
      lv_debit = lv_debit + gs_acc_i-wrbtr.
    ELSEIF gs_acc_i-shkzg = 'H'. "대변
      lv_credit = lv_credit + gs_acc_i-wrbtr.
    ENDIF.
  ENDLOOP.

  IF lv_debit IS INITIAL OR lv_credit IS INITIAL OR lv_debit <> lv_credit.
    MESSAGE s079(z8_msg) DISPLAY LIKE 'E'. "'차변금액과 대변금액이 일치하지 않습니다.' TYPE 'E'
    RETURN.
  ENDIF.

  "잔금 입금 상태 확인
  SELECT SINGLE zzpayst belnr
    FROM z8sd_billing_h
    INTO ( lv_payst, lv_paybl )
    WHERE bukrs = gs_bill-bukrs
    AND vbeln = gs_bill-vbeln
    AND fkart = 'F2'.

  IF sy-subrc <> 0.
    MESSAGE e077(z8_msg). "'해당 청구서에 대한 정보를 찾을 수 없습니다.' TYPE 'E'.
  ENDIF.

  "외상매출금 반제상태 확인
  SELECT SINGLE augbl
    FROM z8fi_customer
    INTO lv_augbl
    WHERE bukrs = gs_bill-bukrs
    AND belnr = gs_bill-ar_belnr
    AND gjahr = gs_bill-ar_gjahr.

  IF sy-subrc <> 0.
    MESSAGE '입금 대상 외상매출금 정보를 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "입금 완료 + 반제완료
  IF ( lv_payst = '02' OR lv_paybl IS NOT INITIAL ) AND lv_augbl IS NOT INITIAL.
    MESSAGE '이미 입금 및 반제 완료된 건입니다.' TYPE 'S'  DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "입금완료 + 미반제
  IF ( lv_payst = '02' OR lv_paybl IS NOT INITIAL ) AND lv_augbl IS INITIAL.
    MESSAGE '이미 입금 완료된 건이며 아직 미반제 상태입니다.' TYPE 'S'  DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "반제 + 미입금 => 비정상
  IF lv_payst <> '02' AND lv_paybl IS INITIAL AND lv_augbl IS NOT INITIAL.
    MESSAGE '입금상태와 반제상태가 일치하지 않습니다.' TYPE 'S'  DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "회계연도, 기간
  lv_gjahr = gv_paydat+0(4).
  lv_monat = gv_paydat+4(2).

  "전표번호(belnr) 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8FI_BELNR'
      toyear                  = lv_gjahr
    IMPORTING
      number                  = lv_belnr
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
  ENDIF.

  "회계전표 h
  CLEAR gs_acc_h.

  gs_acc_h-bukrs = gs_bill-bukrs.
  gs_acc_h-belnr = lv_belnr.
  gs_acc_h-gjahr = lv_gjahr.
  gs_acc_h-monat = lv_monat.
  gs_acc_h-blart = 'DZ'. "외상매입금 지급/입금
  gs_acc_h-bldat = gv_paydat. "문서증빙일
  gs_acc_h-budat = gv_paydat. "실제입금일
  gs_acc_h-waers = gs_bill-waerk.
  gs_acc_h-stjah = '0000'.
  CLEAR gs_acc_h-stblg.
  gs_acc_h-xblnr = gs_bill-vbeln. "참조문서 = 청구번호

  "회계전표i key값에 값 넣기
  LOOP AT gt_acc_i INTO gs_acc_i.
    gs_acc_i-bukrs = gs_bill-bukrs..
    gs_acc_i-belnr = lv_belnr.
    gs_acc_i-gjahr = lv_gjahr.

    MODIFY gt_acc_i FROM gs_acc_i INDEX sy-tabix
    TRANSPORTING bukrs belnr gjahr.
  ENDLOOP.

  " 회계전표 h, i에 insert
  INSERT z8fi_accdoc_h FROM gs_acc_h.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e081(z8_msg) WITH '회계전표 헤더'. "'회계전표 헤더 생성에 실패했습니다.' TYPE 'E'.
  ENDIF.

  INSERT z8fi_accdoc_i FROM TABLE gt_acc_i.
  IF sy-subrc <> 0 OR sy-dbcnt <> lv_lines.
    ROLLBACK WORK.
    MESSAGE e081(z8_msg) WITH '회계전표 아이템'.
  ENDIF.

  "잔금 청구서 입금상태 update
  PERFORM update_billing  USING lv_belnr lv_gjahr.

  IF gv_return <> 0.
    ROLLBACK WORK.
    PERFORM unlock_all.
    RETURN.
  ENDIF.

  "외상매출금 반제 정보 update
  PERFORM update_customer_clear USING lv_belnr lv_gjahr.

  IF gv_return <> 0.
    ROLLBACK WORK.
    PERFORM unlock_all.
    RETURN.
  ENDIF.

  COMMIT WORK AND WAIT.
  MESSAGE |청구번호 { gs_bill-vbeln }의 전표 { lv_belnr }가 생성되었습니다.| TYPE 'I'.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_BELNR
*&      --> LV_GJAHR
*&---------------------------------------------------------------------*
FORM update_billing  USING pv_belnr TYPE z8fi_accdoc_h-belnr
                                            pv_gjahr TYPE z8fi_accdoc_h-gjahr.

  CLEAR gv_return.

  UPDATE z8sd_billing_h
         SET zzpayst = '02',
                zpaydat = @gv_paydat,
                belnr = @pv_belnr,
                gjahr = @pv_gjahr
   WHERE bukrs = @gs_bill-bukrs
        AND vbeln = @gs_bill-vbeln
        AND fkart = 'F2'
*        AND zzpayst = '01'.
        AND ( zzpayst = '01' OR zzpayst = '03' ).

  gv_return = sy-subrc.

  IF gv_return <> 0.
    MESSAGE s083(z8_msg) DISPLAY LIKE 'E'. "'청구서 입금 상태 변경에 실패했습니다.' TYPE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_customer_clear
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_BELNR
*&      --> LV_GJAHR
*&---------------------------------------------------------------------*
FORM update_customer_clear  USING pv_belnr TYPE z8fi_accdoc_h-belnr
                                                          pv_gjahr TYPE z8fi_accdoc_h-gjahr.

  CLEAR gv_return.

  UPDATE z8fi_customer
     SET augdt = @gv_paydat,
            augbl = @pv_belnr,
            auggj = @pv_gjahr
   WHERE bukrs = @gs_bill-bukrs
     AND gjahr = @gs_bill-ar_gjahr
     AND belnr = @gs_bill-ar_belnr
     AND augbl = @space.

  gv_return = sy-subrc.

  IF gv_return <> 0.
    MESSAGE s084(z8_msg) DISPLAY LIKE 'E'."'외상매출금 반제정보 갱신에 실패했습니다.'
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form unlock_all
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM unlock_all .

  PERFORM unlock_customer.
  PERFORM unlock_billing.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM get_text .
*
*  IF pa_bukrs IS NOT INITIAL.
*    SELECT SINGLE butxt FROM z8company_m INTO gv_butxt
*      WHERE bukrs = pa_bukrs.
*    IF sy-subrc <> 0.
*      gv_butxt = 'error'.
*    ENDIF.
*  ELSE.
*    CLEAR gv_butxt.
*  ENDIF.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler .

  SET HANDLER:
                lcl_handler=>on_hotspot_click FOR go_alv_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_default_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_default_data .

  DATA: lv_from TYPE sy-datum.

  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months  = -2
      olddate = sy-datum
    IMPORTING
      newdate = lv_from.

  CLEAR so_fkdat.
  so_fkdat-sign   = 'I'.
  so_fkdat-option = 'BT'.
  so_fkdat-low    = lv_from.
  so_fkdat-high = sy-datum.
  APPEND so_fkdat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_obligatory
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_obligatory .

  IF sscrfields-ucomm = 'ONLI'.

    "날짜조건 자체가 없는 경우
    IF so_fkdat[] IS INITIAL.
      SET CURSOR FIELD 'SO_FKDAT-LOW'.
    MESSAGE E121(z8_msg)  WITH '청구일은'.
    ENDIF.

    "종료일만 입력한 경우
    IF so_fkdat-low IS INITIAL AND so_fkdat-high IS NOT INITIAL.
      SET CURSOR FIELD 'SO_FKDAT-LOW'.
      MESSAGE E124(z8_msg). "'시작일을 입력해주세요.'
    ENDIF.

    "기간 역전 확인
    IF so_fkdat-low IS NOT INITIAL
      AND so_fkdat-high IS NOT INITIAL
      AND so_fkdat-low > so_fkdat-high.

      SET CURSOR FIELD 'SO_FKDAT-LOW'.
      MESSAGE E126(z8_msg). "조회범위를 확인해주세요
    ENDIF.

    IF so_fkdat-low > sy-datum.
      SET CURSOR FIELD 'SO_FKDAT-LOW'.
      MESSAGE E123(z8_msg). "조회시작일은 현재 날짜보다 클 수 없습니다
    ENDIF.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_100 .

  DATA ls_ct TYPE lvc_s_styl.

  LOOP AT gt_bill ASSIGNING FIELD-SYMBOL(<fs_alv>).

    CLEAR <fs_alv>-ct.

    "belnr이 있는 셀만 Hotspot
    IF <fs_alv>-ar_belnr IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'AR_BELNR'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.

      INSERT ls_ct INTO TABLE <fs_alv>-ct.

    ENDIF.

    "augbl이 있는 셀만 Hotspot
    IF <fs_alv>-augbl IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'AUGBL'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.

      INSERT ls_ct INTO TABLE <fs_alv>-ct.

    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form comment_clear
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM comment_clear .

  IF pa_bran IS NOT INITIAL.
    SELECT SINGLE name
      FROM z8branch_m
      INTO gv_brant
      WHERE bukrs = gc_bukrs
      AND branch = pa_bran.
  ELSE.
    CLEAR gv_brant.
  ENDIF.

  IF pa_kunnr IS NOT INITIAL.
    SELECT SINGLE name1
      FROM z8customer_m
      INTO gv_custt
      WHERE kunnr = pa_kunnr.
  ELSE.
    CLEAR gv_custt.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_bupla
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_bupla .

  DATA:
    lt_return TYPE TABLE OF ddshretval,
    lt_dynp   TYPE TABLE OF dynpread,
    ls_dynp   TYPE dynpread.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8BRANCH_M'
      fieldname   = 'BRANCH'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'PA_BRAN'
    TABLES
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE lt_return INTO DATA(ls_return) INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  pa_bran = ls_return-fieldval.

  "지사명 조회
  CLEAR gv_brant.

  SELECT SINGLE name
    FROM z8branch_m
    INTO gv_brant
    WHERE bukrs  = gc_bukrs
      AND branch = pa_bran.

  "화면의 지사명 즉시 갱신
  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_BRANT'.
  ls_dynp-fieldvalue = gv_brant.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_kunnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_kunnr .

  DATA:
    lt_return TYPE TABLE OF ddshretval,
    lt_dynp   TYPE TABLE OF dynpread,
    ls_dynp   TYPE dynpread.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8CUSTOMER_M'
      fieldname   = 'KUNNR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'PA_KUNNR'
    TABLES
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE lt_return INTO DATA(ls_return) INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  pa_kunnr = ls_return-fieldval.

  "지사명 조회
  CLEAR gv_custt.

  SELECT SINGLE name1
    FROM z8customer_m
    INTO gv_custt
    WHERE kunnr  = pa_kunnr.

  "화면의 지사명 즉시 갱신
  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_CUSTT'.
  ls_dynp-fieldvalue = gv_custt.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_comment_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_comment_text .

  IF pa_bran IS INITIAL.
    CLEAR gv_brant.
  ELSE.
    SELECT SINGLE name
      FROM z8branch_m
      INTO gv_brant
      WHERE bukrs = gc_bukrs
      AND branch = pa_bran.

    IF sy-subrc <> 0.
      CLEAR gv_brant.
    ENDIF.
  ENDIF.

  IF pa_kunnr IS INITIAL.
    CLEAR gv_custt.
  ELSE.
    SELECT SINGLE name1
      FROM z8customer_m
      INTO gv_custt
      WHERE kunnr = pa_kunnr.

      IF sy-subrc <> 0.
      CLEAR gv_custt.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form authority_check
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM authority_check .

  AUTHORITY-CHECK OBJECT 'Z8FI_ADMIN'
    ID 'ACTVT' FIELD '16'.

  IF sy-subrc <> 0.
    MESSAGE E200(z8_msg) WITH 'FI'.
  ENDIF.

ENDFORM.
