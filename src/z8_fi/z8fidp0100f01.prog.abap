*&---------------------------------------------------------------------*
*& Include          Z8FIDR0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_objects
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_100.

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
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_100 .

  CALL METHOD go_alv_100->set_table_for_first_display
    EXPORTING
*     i_buffer_active               = 'X'
*     i_bypassing_buffer            = 'X'
*     i_consistency_check           =
*     i_structure_name              = 'Z139_HEADER'
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
*& Form get_data
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

    SELECT a~bukrs
                 a~bupla
                 c~name AS brancht
                 a~vbeln
                 a~vgbel
                 a~kunnr
                 b~name1
                 a~fkdat
                 a~netwr
                 a~waerk
                 a~zzpayst
                 a~zduedat
                 a~zpaydat
                 a~belnr
                 a~gjahr
       FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8customer_m AS b
      ON b~kunnr = a~kunnr
      LEFT OUTER JOIN z8branch_m AS c
      ON c~bukrs = a~bukrs
      AND c~branch = a~bupla
         INTO CORRESPONDING FIELDS OF TABLE gt_bill
     WHERE a~bukrs = gc_bukrs
          AND a~bupla IN lr_bupla
          AND a~kunnr IN lr_kunnr
          AND a~vbeln IN lr_vbeln
          AND a~fkdat IN so_fkdat
          AND a~fkart = 'F1'
          AND a~zzpayst = '01'.

  ELSEIF pa_r2 = 'X'. "입금완료

    SELECT a~bukrs
                 a~bupla
                 c~name AS brancht
                 a~vbeln
                 a~vgbel
                 a~kunnr
                 b~name1
                 a~fkdat
                 a~netwr
                 a~waerk
                 a~zzpayst
                 a~zduedat
                 a~zpaydat
                 a~belnr
                 a~gjahr
       FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8customer_m AS b
      ON b~kunnr = a~kunnr
      LEFT OUTER JOIN z8branch_m AS c
      ON c~bukrs = a~bukrs
      AND c~branch = a~bupla
         INTO CORRESPONDING FIELDS OF TABLE gt_bill
     WHERE a~bukrs = gc_bukrs
          AND a~bupla IN lr_bupla
          AND a~kunnr IN lr_kunnr
          AND a~vbeln IN lr_vbeln
          AND a~fkdat IN so_fkdat
          AND a~fkart = 'F1'
          AND a~zzpayst = '02'.

  ELSEIF pa_r3 = 'X'. "전체

    SELECT a~bukrs
                 a~bupla
                 c~name AS brancht
                 a~vbeln
                 a~vgbel
                 a~kunnr
                 b~name1
                 a~fkdat
                 a~netwr
                 a~waerk
                 a~zzpayst
                 a~zduedat
                 a~zpaydat
                 a~belnr
                 a~gjahr
       FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8customer_m AS b
      ON b~kunnr = a~kunnr
      LEFT OUTER JOIN z8branch_m AS c
      ON c~bukrs = a~bukrs
      AND c~branch = a~bupla
         INTO CORRESPONDING FIELDS OF TABLE gt_bill
     WHERE a~bukrs = gc_bukrs
          AND a~bupla IN lr_bupla
          AND a~kunnr IN lr_kunnr
          AND a~vbeln IN lr_vbeln
          AND a~fkdat IN so_fkdat
          AND a~fkart = 'F1'.

   ELSEIF pa_r4 = 'X'. "기한만료

     SELECT a~bukrs
                 a~bupla
                 c~name AS brancht
                 a~vbeln
                 a~vgbel
                 a~kunnr
                 b~name1
                 a~fkdat
                 a~netwr
                 a~waerk
                 a~zzpayst
                 a~zduedat
                 a~zpaydat
                 a~belnr
                 a~gjahr
       FROM z8sd_billing_h AS a
      LEFT OUTER JOIN z8customer_m AS b
      ON b~kunnr = a~kunnr
      LEFT OUTER JOIN z8branch_m AS c
      ON c~bukrs = a~bukrs
      AND c~branch = a~bupla
         INTO CORRESPONDING FIELDS OF TABLE gt_bill
     WHERE a~bukrs = gc_bukrs
          AND a~bupla IN lr_bupla
          AND a~kunnr IN lr_kunnr
          AND a~vbeln IN lr_vbeln
          AND a~fkdat IN so_fkdat
          AND a~fkart = 'F1'
          AND a~zzpayst = '03'.

  ENDIF.

  PERFORM get_add_data_100.

*  SELECT bukrs bupla vbeln kunnr fkdat netwr waerk zzpayst belnr gjahr
*    FROM z8sd_billing_h
*      INTO CORRESPONDING FIELDS OF TABLE gt_bill
*  WHERE bukrs = pa_bukrs
*      AND bupla IN lr_bupla
*      AND kunnr IN lr_kunnr
*      AND vbeln IN lr_vbeln
*      AND fkdat IN so_fkdat.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_100 .

  CLEAR gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'LIGHT'. "예외 컬럼 이름
  gs_fcat_100-coltext = '상태'.
*  gs_fcat_100-key = 'X'.
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
  gs_fcat_100-outputlen = 11.
  gs_fcat_100-key = 'X'.
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
  gs_fcat_100-outputlen = 12.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'VGBEL'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '견적번호'.
  gs_fcat_100-outputlen = 12.
  APPEND gs_fcat_100 TO gt_fcat_100.

*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'BUKRS'.
*  gs_fcat_100-key = 'X'.
*  gs_fcat_100-coltext = '회사코드'.
*  gs_fcat_100-outputlen = 8.
*  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BUPLA'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '지사'.
  gs_fcat_100-outputlen = 10.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BRANCHT'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '지사명'.
  gs_fcat_100-outputlen = 15.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'KUNNR'.
*  gs_fcat-key = 'X'.
  gs_fcat_100-coltext = '고객번호'.
  gs_fcat_100-outputlen = 11.
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
  gs_fcat_100-outputlen = 8.
  APPEND gs_fcat_100 TO gt_fcat_100.

*  CLEAR gs_fcat_100.
**  gs_fcat-fieldname = 'ZZPAYST'.
*  gs_fcat_100-fieldname = 'PAYSTT'.
**  gs_fcat_top-key = 'X'.
*  gs_fcat_100-coltext = '입금상태'.
*  gs_fcat_100-outputlen = 13.
*  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BELNR'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '전표번호'.
  gs_fcat_100-outputlen = 13.
*  gs_fcat_100-hotspot = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
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
*  gs_sort-fieldname = 'VBELN'.
*  gs_sort-spos = 1.
*  gs_sort-up = 'X'.
*  INSERT gs_sort INTO TABLE gt_sort.

*  CLEAR gs_sort.
*  gs_sort-fieldname = 'BELNR'.
*  gs_sort-spos = 2.
*  gs_sort-up = 'X'.
*  INSERT gs_sort INTO TABLE gt_sort.

  "신호등
  gs_layout_100-excp_fname = 'LIGHT'.
  gs_layout_100-excp_led   = 'X'.

  PERFORM set_grid_title_100.

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

  SET HANDLER:
                lcl_handler=>on_hotspot_click FOR go_alv_100.
*               lcl_handler=>on_double_click FOR go_alv.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_add_data
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
*& Form pay_ment_process
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM payment_process .

  DATA:
    lt_rows TYPE lvc_t_roid,
    ls_row  TYPE lvc_s_roid.

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

  READ TABLE gt_bill INTO gs_bill
    INDEX ls_row-row_id.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

*  IF gs_bill-zzpayst = '02'.
*    MESSAGE '미입금 청구서만 입금처리할 수 있습니다.'
*            TYPE 'S' DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.

  gv_vbeln = gs_bill-vbeln.
  gv_bupla = gs_bill-bupla.
  gv_brancht = gs_bill-brancht.
  gv_kunnr = gs_bill-kunnr.
  gv_name1 = gs_bill-name1.
  gv_netwr = gs_bill-netwr.
  gv_waerk = gs_bill-waerk.
  gv_pay_waerk = gs_bill-waerk.
  gv_fkdat = gs_bill-fkdat.
  gv_duedat = gs_bill-zduedat.

  gv_date = sy-datum.
  gv_pay  = gs_bill-netwr.

  WRITE gv_netwr TO gv_netwr_txt CURRENCY gv_waerk.
  CONDENSE gv_netwr_txt.
  WRITE gv_pay TO gv_pay_txt CURRENCY gv_waerk.
  CONDENSE gv_pay_txt.

  "락 잡기
  CLEAR gv_return.
  PERFORM lock_billing CHANGING gv_return.

  IF gv_return <> 0.
    RETURN.
  ENDIF.

  "1. 락 성공 후 최신 입금 상태 재확인
  DATA: lv_payst TYPE z8sd_billing_h-zzpayst,
             lv_duedat TYPE z8sd_billing_h-zduedat.

  SELECT SINGLE zzpayst zduedat
     FROM z8sd_billing_h
     INTO (lv_payst, lv_duedat)
    WHERE bukrs = gc_bukrs
    AND vbeln = gv_vbeln
    AND fkart = 'F1'.

  IF sy-subrc <> 0.
    PERFORM unlock_billing.
    MESSAGE '해당 청구서 정보를 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_payst = '02'.
    PERFORM unlock_billing.
    PERFORM refresh_alv_100.
    MESSAGE '이미 입금처리된 청구건입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_payst = '03'.
*    PERFORM unlock_billing.
*    PERFORM refresh_alv_100.
    MESSAGE '입금기한이 경과한 청구건입니다. 실제 입금일을 확인해주세요' TYPE 'S'. "DISPLAY LIKE 'E'.
*    RETURN.
  ENDIF.

  PERFORM make_preview.

  CALL SCREEN '200'.

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
  CREATE OBJECT go_cont_200
    EXPORTING
      container_name              = 'CONTROL_AREA_200'
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
  CREATE OBJECT go_alv_200
    EXPORTING
      i_parent          = go_cont_200 "alv 담길 컨테이너 변수
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
*& Form set_alv_layout_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_200 .

  gs_layout_200-grid_title = '생성 예정 전표'.
  gs_layout_200-zebra = 'X'.
  gs_layout_200-no_toolbar = 'X'.

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

  CLEAR: gt_fcat_200, gs_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BUZEI'.
  gs_fcat_200-coltext = '항목'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'HKONT'.
  gs_fcat_200-coltext = 'G/L계정'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'TXT20'.
  gs_fcat_200-coltext = 'G/L계정 설명'.
  APPEND gs_fcat_200 TO gt_fcat_200.

*  CLEAR gs_fcat_200.
*  gs_fcat_200-fieldname = 'BUPLA'.
*  gs_fcat_200-coltext = '종사업장'.
*  INSERT gs_fcat_200 INTO TABLE gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'SHKZGT'.
  gs_fcat_200-coltext = '구분'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'DEBIT'.
  gs_fcat_200-coltext = '차변금액'.
  gs_fcat_200-cfieldname = 'WAERS'.
  gs_fcat_200-no_zero = 'X'.
  gs_fcat_200-outputlen = 15.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'CREDIT'.
  gs_fcat_200-coltext = '대변금액'.
  gs_fcat_200-cfieldname = 'WAERS'.
  gs_fcat_200-no_zero = 'X'.
  gs_fcat_200-outputlen = 15.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'WAERS'.
  gs_fcat_200-coltext = '통화'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'KUNNR'.
  gs_fcat_200-coltext = '고객번호'.
  APPEND gs_fcat_200 TO gt_fcat_200.

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

  CALL METHOD go_alv_200->set_table_for_first_display
    EXPORTING
*     i_buffer_active               = 'X'
*     i_bypassing_buffer            = 'X'
*     i_consistency_check           =
*     i_structure_name              = 'Z139_HEADER'
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_200
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_preview
      it_fieldcatalog               = gt_fcat_200
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
*& Form make_preview
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_preview .

  DATA: lv_txt20 TYPE z8glacc_m-txt20.

  CONSTANTS: lc_bank TYPE z8fi_accdoc_i-hkont VALUE '10300100', "보통예금
             lc_adv  TYPE z8fi_accdoc_i-hkont VALUE '21000100'. "선수금

  CLEAR: gt_preview, gt_accdoc_i.

  "1. 차변 : 보통예금
  CLEAR: gs_preview, gs_accdoc_i, lv_txt20.

  "실제 전표 아이템
  gs_accdoc_i-buzei = '001'.
  gs_accdoc_i-koart = 'S'.
  gs_accdoc_i-hkont = lc_bank.
  gs_accdoc_i-bupla = gv_bupla.
  gs_accdoc_i-shkzg = 'S'.
  gs_accdoc_i-wrbtr = gv_pay.
  gs_accdoc_i-waers = gv_waerk.

  APPEND gs_accdoc_i TO gt_accdoc_i.

  SELECT SINGLE txt20
     FROM z8v_glacc
       INTO lv_txt20
   WHERE bukrs = gc_bukrs
        AND saknr = lc_bank.

  "alv 조회 용
  gs_preview-buzei = '001'.
  gs_preview-koart = 'S'.
  gs_preview-hkont = lc_bank.
  gs_preview-txt20 = lv_txt20.
*  gs_preview-bupla = gv_bupla.
  gs_preview-shkzg = 'S'.
  gs_preview-shkzgt = '차변'.
  gs_preview-debit = gv_pay.
  gs_preview-waers = gv_waerk.

  APPEND gs_preview TO gt_preview.

**********************************************************************
  "2. 대변 : 고객 선수금
  CLEAR: gs_preview, gs_accdoc_i, lv_txt20.

  "실제 전표 아이템
  gs_accdoc_i-buzei = '002'.
  gs_accdoc_i-koart = 'D'.
  gs_accdoc_i-hkont = lc_adv.
  gs_accdoc_i-bupla = gv_bupla.
  gs_accdoc_i-shkzg = 'H'.
  gs_accdoc_i-wrbtr = gv_pay.
  gs_accdoc_i-waers = gv_waerk.
  gs_accdoc_i-kunnr = gv_kunnr.
  gs_accdoc_i-umskz = 'A'.

  APPEND gs_accdoc_i TO gt_accdoc_i.

  SELECT SINGLE txt20
     FROM z8v_glacc
       INTO lv_txt20
   WHERE bukrs = gc_bukrs
        AND saknr = lc_adv.

  "alv 조회 용
  gs_preview-buzei = '002'.
  gs_preview-koart = 'D'.
  gs_preview-hkont = lc_adv.
  gs_preview-txt20 = lv_txt20.
*  gs_preview-bupla = gv_bupla.
  gs_preview-shkzg = 'H'.
  gs_preview-shkzgt = '대변'.
  gs_preview-credit = gv_pay.
  gs_preview-waers = gv_waerk.
  gs_preview-kunnr = gv_kunnr.
  gs_preview-umskz = 'A'.

  APPEND gs_preview TO gt_preview.


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

  "1. alv 파괴
  IF go_alv_200 IS BOUND.

    CALL METHOD go_alv_200->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

*  ---------------------------------------------------------------
  "2. 컨테이너 파괴
  IF go_cont_200 IS BOUND.

    CALL METHOD go_cont_200->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  CLEAR: go_alv_200, go_cont_200. "clear 대신 free써도 됨

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

  DATA: lv_belnr  TYPE z8fi_accdoc_h-belnr,
        lv_gjahr  TYPE z8fi_accdoc_h-gjahr,
        lv_monat  TYPE z8fi_accdoc_h-monat,
        lv_payst  TYPE z8sd_billing_h-zzpayst,
        lv_duedat TYPE z8sd_billing_h-zduedat,
        lv_debit  TYPE z8fi_accdoc_i-wrbtr,
        lv_credit TYPE z8fi_accdoc_i-wrbtr,
        lv_lines  TYPE i.

  "1. 검증(입금일자 입력 여부, 전표 아이템 존재 여부, 청구서가 아직 미입금 상태인지)
*  IF gv_date IS INITIAL.
*    MESSAGE '입금일자를 입력해주세요.' TYPE 'E'.
*  ENDIF.

  IF gt_accdoc_i IS INITIAL.
    MESSAGE e063(z8_msg)."MESSAGE '생성할 전표 아이템이 없습니다.' TYPE 'E'.
  ENDIF.

  "회계전표 2개인지
  DESCRIBE TABLE gt_accdoc_i LINES lv_lines.

  IF lv_lines <> 2.
    MESSAGE e064(z8_msg)."MESSAGE '전표 아이템 구성이 올바르지 않습니다.' TYPE 'E'.
  ENDIF.

  SELECT SINGLE zzpayst zduedat
    FROM z8sd_billing_h
      INTO (lv_payst, lv_duedat)
  WHERE bukrs = gc_bukrs
       AND vbeln = gv_vbeln
       AND fkart = 'F1'.

  IF sy-subrc <> 0.
    MESSAGE e077(z8_msg). "'해당 청구서에 대한 정보를 찾을 수 없습니다.' TYPE 'E'.
  ENDIF.

  IF lv_payst = '02'.
    MESSAGE e078(z8_msg). "'입금처리가 불가능한 청구건입니다.' TYPE 'E'.
  ENDIF.

  IF gv_date > lv_duedat.
    MESSAGE e076(z8_msg). "'실제 입금일이 입금기한을 초과했습니다.' TYPE 'E'.
  ENDIF.

  "2. 회계연도(gjahr), 회계기간(monat)
  lv_gjahr = gv_date+0(4).
  lv_monat = gv_date+4(2).

  "대차 평형 검증
  CLEAR: lv_debit, lv_credit.

  LOOP AT gt_accdoc_i INTO gs_accdoc_i.
    IF gs_accdoc_i-shkzg = 'S'.  "차변
      lv_debit = lv_debit + gs_accdoc_i-wrbtr.
    ELSEIF gs_accdoc_i-shkzg = 'H'. "대변
      lv_credit = lv_credit + gs_accdoc_i-wrbtr.
    ENDIF.
  ENDLOOP.

  IF lv_debit <> lv_credit.
    MESSAGE e079(z8_msg). "'차변금액과 대변금액이 일치하지 않습니다.' TYPE 'E'.
  ENDIF.

  "3. 전표번호(belnr) 채번
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
    MESSAGE e014(z8_msg). "'전표번호 채번 중 오류가 발생했습니다.' TYPE 'E'.
  ENDIF.

  "4. 회계전표h 구성
  CLEAR gs_accdoc_h.

  gs_accdoc_h-bukrs = gc_bukrs.
  gs_accdoc_h-belnr = lv_belnr.
  gs_accdoc_h-gjahr = lv_gjahr.
  gs_accdoc_h-monat = lv_monat.
  gs_accdoc_h-blart = 'DZ'. "고객 지급/입금
  gs_accdoc_h-bldat = gv_date. "문서증빙일
  gs_accdoc_h-budat = gv_date. "실제입금일
  gs_accdoc_h-waers = gv_waerk.
  gs_accdoc_h-xblnr = gv_vbeln. "참조문서 = 청구번호

  "5. 회계전표i key값에 값 넣기
  LOOP AT gt_accdoc_i INTO gs_accdoc_i.
    gs_accdoc_i-bukrs = gc_bukrs.
    gs_accdoc_i-belnr = lv_belnr.
    gs_accdoc_i-gjahr = lv_gjahr.

    MODIFY gt_accdoc_i FROM gs_accdoc_i INDEX sy-tabix
    TRANSPORTING bukrs belnr gjahr.
  ENDLOOP.

  " 6. 회계전표 h, i에 insert
  INSERT z8fi_accdoc_h FROM gs_accdoc_h.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e081(z8_msg) WITH '회계전표 헤더'.  "'회계전표 헤더 생성에 실패했습니다.' TYPE 'E'.
  ENDIF.

  INSERT z8fi_accdoc_i FROM TABLE gt_accdoc_i.
  IF sy-subrc <> 0 OR sy-dbcnt <> lv_lines.
    ROLLBACK WORK.
    MESSAGE e081(z8_msg) WITH '회계전표 아이템'.
  ENDIF.

  "7. 청구서 입금 상태, 전표번호 update UPDATE <테이블 이름> SET <변경내역> WHERE <조건>.
  UPDATE z8sd_billing_h
         SET zzpayst = '02',
                zpaydat = @gv_date,
                belnr = @lv_belnr,
                gjahr = @lv_gjahr
   WHERE bukrs = @gc_bukrs
        AND vbeln = @gv_vbeln
        AND fkart = 'F1'
        AND ( zzpayst = '01' OR zzpayst = '03' ).

  IF sy-subrc <> 0  OR sy-dbcnt <> 1. "update 안됐거나 처리한 건수가 1건이 아니면
    ROLLBACK WORK.
    MESSAGE e083(z8_msg). "'청구서 입금 상태 변경에 실패했습니다.' TYPE 'E'.
  ENDIF.

  "8. 모든 작업 성공 시 commit
  COMMIT WORK AND WAIT.
  MESSAGE |청구번호 { gv_vbeln }의 전표 { lv_belnr }가 생성되었습니다.| TYPE 'I'.

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

  DATA: ls_row TYPE lvc_s_row,
             lt_rows TYPE lvc_t_row,
             ls_col TYPE lvc_s_col.

  "최신 데이터 다시 조회
  PERFORM update_due_status.
  PERFORM get_data_100.
  PERFORM set_cell_style_100.

  "전표 생성 후 재조회 결과가 없는 경우
  IF gv_last_vbeln IS NOT INITIAL AND gt_bill IS INITIAL.
    CLEAR gv_last_vbeln.
    MESSAGE s065(z8_msg) WITH '입금'.

*    PERFORM free_control_100.
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

  "방금 전표를 생성한 청구건을 자동 선택
  IF  gv_last_vbeln IS NOT INITIAL.

    READ TABLE gt_bill INTO gs_bill WITH KEY vbeln = gv_last_vbeln.

    IF sy-subrc = 0.
      CLEAR: ls_row, ls_col.

      ls_row-index = sy-tabix.
      APPEND ls_row TO lt_rows.
*      ls_col-fieldname = 'VBELN'.

      CALL METHOD go_alv_100->set_selected_rows
        EXPORTING
          it_index_rows            = lt_rows
*          it_row_no                =
*          is_keep_other_selections =
          .

*       "셀에 포인트
*      CALL METHOD go_alv_100->set_current_cell_via_id
*        EXPORTING
*          is_row_id    = ls_row
*          is_column_id = ls_col
**          is_row_no    =
*          .
    ENDIF.

    CLEAR gv_last_vbeln.

  ENDIF.


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
*& Form lock_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM lock_billing CHANGING pv_return TYPE sy-subrc.

  CALL FUNCTION 'ENQUEUE_EZ8SD_BILL'
    EXPORTING
*     MODE_Z8SD_BILLING_H       = 'E'
*     MANDT          = SY-MANDT
      vbeln          = gv_vbeln
*     X_VBELN        = ' '
*     _SCOPE         = '2'
*     _WAIT          = ' '
*     _COLLECT       = ' '
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  pv_return = sy-subrc.

  IF pv_return <> 0.
    MESSAGE s136(z8_msg) DISPLAY LIKE 'E' WITH '청구건을'. "다른 사용자가 해당 청구건을 처리 중입니다.
    RETURN.
  ENDIF.


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
      vbeln = gv_vbeln
*     X_VBELN                   = ' '
*     _SCOPE                    = '3'
*     _SYNCHRON                 = ' '
*     _COLLECT                  = ' '
    .


ENDFORM.
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
        AND fkart = 'F1'
        AND zzpayst = '01'
        AND zduedat <> '00000000'
        AND zduedat < sy-datum.

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
*  IF gc_bukrs IS NOT INITIAL.
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

    "전표번호가 있는 셀만 Hotspot
    IF <fs_alv>-belnr IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'BELNR'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.

      INSERT ls_ct INTO TABLE <fs_alv>-ct.

    ENDIF.

  ENDLOOP.

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
