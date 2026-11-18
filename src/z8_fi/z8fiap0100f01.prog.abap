*&---------------------------------------------------------------------*
*& Include          Z8FIAP0100F01
*&---------------------------------------------------------------------*
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
      it_outtab                     = gt_vendor
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
*& Form get_data_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_100 .

  DATA: lr_bran  TYPE RANGE OF z8fi_vendor-bupla,
        lr_lifnr TYPE RANGE OF z8fi_vendor-lifnr,
        lr_invno TYPE RANGE OF z8mm_inv_h-inv_no,
        lr_belnr TYPE RANGE OF z8fi_vendor-belnr.

  CONSTANTS lc_ap_hkont TYPE z8fi_accdoc_i-hkont VALUE '21100000'.

  CLEAR gt_vendor.

  "종사업장
  IF pa_bran IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_bran
    ) TO lr_bran.
  ENDIF.

  "공급업체번호
  IF pa_lifnr IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_lifnr
    ) TO lr_lifnr.
  ENDIF.

  "송장
  IF pa_invno IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_invno
    ) TO lr_invno.
  ENDIF.

  "전표
  IF pa_belnr IS NOT INITIAL.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = pa_belnr
    ) TO lr_belnr.
  ENDIF.

  IF pa_r1 = 'X'.

    SELECT a~bukrs,
               a~bupla,
               c~name AS brancht,
               a~lifnr,
               d~name1,
               a~xblnr AS inv_no,
               a~bldat,
               a~budat,
               a~wrbtr,
               a~waers,
               a~belnr,
               a~gjahr,
               a~augdt,
               a~augbl,
               a~auggj
    FROM z8fi_vendor AS a
*      LEFT OUTER JOIN z8mm_inv_h AS b
*        ON b~inv_no = a~xblnr
*      AND b~lifnr = a~lifnr
      INNER JOIN z8fi_accdoc_h AS h
         ON h~bukrs = a~bukrs
       AND h~belnr = a~belnr
       AND h~gjahr = a~gjahr
      INNER JOIN z8fi_accdoc_i AS i
         ON i~bukrs = a~bukrs
       AND i~belnr = a~belnr
       AND i~gjahr = a~gjahr
       AND i~lifnr = a~lifnr
      AND i~hkont = @lc_ap_hkont
      LEFT OUTER JOIN  z8branch_m AS c
         ON c~bukrs = a~bukrs
       AND c~branch = a~bupla
      LEFT OUTER JOIN z8vendor_m AS d
         ON d~lifnr = a~lifnr
      INTO CORRESPONDING FIELDS OF TABLE @gt_vendor
  WHERE a~bukrs = @gc_bukrs
       AND a~bupla IN @lr_bran
       AND a~lifnr IN @lr_lifnr
       AND a~xblnr IN @lr_invno
       AND a~belnr IN @lr_belnr
       AND a~budat IN @so_budat
       AND a~augbl = @space.

    IF sy-subrc <> 0.
      MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*     IF sy-subrc <> 0.
*       MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
*       RETURN.
*     ENDIF.

  ELSEIF pa_r2 = 'X'.

    SELECT a~bukrs,
              a~bupla,
              c~name AS brancht,
              a~lifnr,
              d~name1,
              a~xblnr AS inv_no,
              a~bldat,
              a~budat,
              a~wrbtr,
              a~waers,
              a~belnr,
              a~gjahr,
              a~augdt,
              a~augbl,
              a~auggj
   FROM z8fi_vendor AS a
*     LEFT OUTER JOIN z8mm_inv_h AS b
*       ON b~inv_no = a~xblnr
*     AND b~lifnr = a~lifnr
      INNER JOIN z8fi_accdoc_h AS h
         ON h~bukrs = a~bukrs
       AND h~belnr = a~belnr
       AND h~gjahr = a~gjahr
      INNER JOIN z8fi_accdoc_i AS i
         ON i~bukrs = a~bukrs
       AND i~belnr = a~belnr
       AND i~gjahr = a~gjahr
       AND i~lifnr = a~lifnr
      AND i~hkont = @lc_ap_hkont
     LEFT OUTER JOIN  z8branch_m AS c
        ON c~bukrs = a~bukrs
      AND c~branch = a~bupla
     LEFT OUTER JOIN z8vendor_m AS d
        ON d~lifnr = a~lifnr
     INTO CORRESPONDING FIELDS OF TABLE @gt_vendor
 WHERE a~bukrs = @gc_bukrs
      AND a~bupla IN @lr_bran
      AND a~lifnr IN @lr_lifnr
      AND a~xblnr IN @lr_invno
      AND a~belnr IN @lr_belnr
      AND a~budat IN @so_budat
      AND a~augbl <> @space.

  ELSEIF pa_r3 = 'X'.

    SELECT a~bukrs, a~bupla, c~name AS brancht, a~lifnr, d~name1, a~xblnr AS inv_no,
      a~bldat, a~budat, a~wrbtr, a~waers, a~belnr, a~gjahr, a~augdt, a~augbl, a~auggj
  FROM z8fi_vendor AS a
      INNER JOIN z8fi_accdoc_h AS h
         ON h~bukrs = a~bukrs
       AND h~belnr = a~belnr
       AND h~gjahr = a~gjahr
      INNER JOIN z8fi_accdoc_i AS i
         ON i~bukrs = a~bukrs
       AND i~belnr = a~belnr
       AND i~gjahr = a~gjahr
       AND i~lifnr = a~lifnr
       AND i~hkont = @lc_ap_hkont
    LEFT OUTER JOIN  z8branch_m AS c
       ON c~bukrs = a~bukrs
     AND c~branch = a~bupla
    LEFT OUTER JOIN z8vendor_m AS d
       ON d~lifnr = a~lifnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_vendor
WHERE a~bukrs = @gc_bukrs
     AND a~bupla IN @lr_bran
     AND a~lifnr IN @lr_lifnr
     AND a~xblnr IN @lr_invno
     AND a~belnr IN @lr_belnr
     AND a~budat IN @so_budat.

  ENDIF.

  PERFORM get_add_data_100.


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

  CLEAR gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'LIGHT'. "예외 컬럼 이름
  gs_fcat_100-coltext = '상태'.
  gs_fcat_100-outputlen = 7.
*  gs_fcat-col_pos   = 7."삽입할 위치.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'STATUST'.
  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '지급상태'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'INV_NO'.
  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '송장번호'.
  gs_fcat_100-outputlen = 11.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BLDAT'.
  gs_fcat_100-coltext = '송장발행일'.
  gs_fcat_100-outputlen = 11.
*  gs_fcat_100-no_out = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BUDAT'.
  gs_fcat_100-coltext = '송장검증일'.
  gs_fcat_100-outputlen = 11.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BELNR'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '원전표번호'.
*  gs_fcat_100-hotspot = 'X'.
  gs_fcat_100-outputlen = 13.
  APPEND gs_fcat_100 TO gt_fcat_100.

*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'BUKRS'.
*  gs_fcat_100-key = 'X'.
*  gs_fcat_100-coltext = '회사코드'.
*  gs_fcat_100-outputlen = 7.
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
  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'LIFNR'.
*  gs_fcat-key = 'X'.
  gs_fcat_100-coltext = '공급업체번호'.
  gs_fcat_100-outputlen = 15.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'NAME1'.
*  gs_fcat-key = 'X'.
  gs_fcat_100-coltext = '공급업체명'.
  gs_fcat_100-outputlen = 15.
  APPEND gs_fcat_100 TO gt_fcat_100.

*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'INV_NO'.
**  gs_fcat_top-key = 'X'.
*  gs_fcat_100-coltext = '송장번호'.
*  gs_fcat_100-outputlen = 11.
*  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'WRBTR'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '외상매입금'.
  gs_fcat_100-ref_field = 'WRBTR'.
  gs_fcat_100-cfieldname = 'WAERS'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 15.
*  gs_fcat_100-do_sum = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'WAERS'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '통화'.
  gs_fcat_100-ref_field = 'WAERS'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 8.
  APPEND gs_fcat_100 TO gt_fcat_100.

*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'STATUST'.
**  gs_fcat_100-key = 'X'.
*  gs_fcat_100-coltext = '반제상태'.
*  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'GJAHR'.
**  gs_fcat_top-key = 'X'.
*  gs_fcat_100-coltext = '회계연도'.
*  gs_fcat_100-outputlen = 8.
*  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'AUGDT'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '지급일'.
  gs_fcat_100-outputlen = 11.
*  gs_fcat_100-hotspot = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'AUGBL'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '지급전표번호'.
*  gs_fcat_100-hotspot = 'X'.
  gs_fcat_100-outputlen = 13.
  APPEND gs_fcat_100 TO gt_fcat_100.

*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'AUGGJ'.
**  gs_fcat_top-key = 'X'.
*  gs_fcat_100-coltext = '지급전표연도'.
*  gs_fcat_100-outputlen = 8.
*  INSERT gs_fcat_100 INTO TABLE gt_fcat_100.

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

  LOOP AT gt_vendor INTO gs_vendor.

    IF gs_vendor-augbl IS INITIAL.
      gs_vendor-statust = '미지급'.
      gs_vendor-light = '1'.
    ELSE.
      gs_vendor-statust = '지급완료'.
      gs_vendor-light = '3'.
    ENDIF.

    MODIFY gt_vendor FROM gs_vendor.

  ENDLOOP.

  SORT gt_vendor BY light ASCENDING
                                 budat ASCENDING.

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

  gs_layout_100-sel_mode = 'B'.
  gs_layout_100-zebra = 'X'.
  gs_layout_100-stylefname = 'CT'. "핫스팟

*  "정렬
*  CLEAR gs_sort.
*  gs_sort-fieldname = 'BUDAT'.
*  gs_sort-spos = 1.
*  gs_sort-up = 'X'.
*  INSERT gs_sort INTO TABLE gt_sort.

*  CLEAR gs_sort.
*  gs_sort-fieldname = 'LIGHT'.
*  gs_sort-spos = 2.
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

  DESCRIBE TABLE gt_vendor LINES lv_count.

  IF pa_r1 = 'X'.
    gs_layout_100-grid_title = |미지급 ({ lv_count }건)|.
  ELSEIF pa_r2 = 'X'.
    gs_layout_100-grid_title = |지급완료 ({ lv_count }건)|.
  ELSEIF pa_r3 = 'X'.
    gs_layout_100-grid_title = |전체 ({ lv_count }건)|.
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
    lv_ap_ok    TYPE c,
    lv_clear_ok TYPE c.

  go_alv_100->get_selected_rows(
    IMPORTING
      et_row_no = lt_rows ).

  IF lt_rows IS INITIAL.
    MESSAGE '지급할 외상매입금을 선택해주세요.'
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

  "선택한 외상매입금 데이터
  READ TABLE gt_vendor INTO gs_vendor INDEX ls_row-row_id.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "반제된 건 불가능
  IF gs_vendor-augbl IS NOT INITIAL.
    MESSAGE s066(z8_msg) DISPLAY LIKE 'E' WITH '지급'."이미 지급 및 반제 처리된 건 입니다.'
    RETURN.
  ENDIF.

  "락 걸기
  CLEAR gv_return.
  PERFORM lock_vendor.

  IF gv_return <> 0.
    RETURN.
  ENDIF.

  "락 성공 후 실제 DB반제 상태 재확인
  PERFORM check_clear_status CHANGING lv_clear_ok.

  IF lv_clear_ok IS INITIAL.
    "락 해제
    PERFORM unlock_vendor.
    PERFORM refresh_alv_100.
    RETURN.
  ENDIF.

  PERFORM check_org_ap CHANGING lv_ap_ok.

  IF lv_ap_ok IS INITIAL.
    PERFORM unlock_vendor.
    RETURN.
  ENDIF.

  "지급정보 기본값
  gv_paydat = sy-datum.
  gv_pay = gs_vendor-wrbtr.
  gv_pay_waers = gs_vendor-waers.

  WRITE gs_vendor-wrbtr TO gv_netwr_txt CURRENCY gs_vendor-waers.
  CONDENSE gv_netwr_txt.
  WRITE gv_pay TO gv_pay_txt CURRENCY gs_vendor-waers.
  CONDENSE gv_pay_txt.

  "200번 화면 상단 alv
  PERFORM get_org_ap.
  "200번 화면 하단 alv + 지급전표 아이템
  PERFORM set_accdoc.

  CALL SCREEN '0200'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_100.

  DATA:
    ls_row TYPE lvc_s_row,
    ls_col TYPE lvc_s_col.

  "최신 데이터 다시 조회
  PERFORM get_data_100.
  PERFORM set_cell_style_100.

  "전표 생성 후 재조회 결과가 없는 경우
  IF gv_refresh_100 = 'X' AND gt_vendor IS INITIAL.
    CLEAR: gv_refresh_100, gv_last_bukrs, gv_last_gjahr, gv_last_belnr.
    MESSAGE s065(z8_msg) WITH '지급 및 반제'." 처리가 완료되어 현재 조회조건에 해당하는 데이터가 없습니다.'

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
*& Form check_org_ap
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_org_ap CHANGING pv_ok TYPE c..

  CLEAR gs_ap_item.

  SELECT SINGLE *
    FROM z8fi_accdoc_i
    INTO gs_ap_item
    WHERE bukrs = gs_vendor-bukrs
    AND belnr = gs_vendor-belnr
    AND gjahr = gs_vendor-gjahr
    AND koart = 'K'
    AND shkzg = 'H'
    AND lifnr = gs_vendor-lifnr.

  IF sy-subrc <> 0.
    MESSAGE '원전표의 외상매입금 항목을 찾을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "금액 일치 확인
  IF gs_ap_item-wrbtr <> gs_vendor-wrbtr.
    MESSAGE '원전표의 외상매입금과 미결금액이 일치하지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  pv_ok = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_text .

*  IF gc_bukrs IS NOT INITIAL.
*    SELECT SINGLE butxt FROM z8company_m INTO gv_butxt
*      WHERE bukrs = gc_bukrs.
*    IF sy-subrc <> 0.
*      gc_butxt = 'error'.
*    ENDIF.
*  ELSE.
*    CLEAR gc_butxt.
*  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'G0200'.
  SET TITLEBAR 'T0200'.
ENDMODULE.
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
  gs_fcat_org-fieldname = 'LIFNR'.
  gs_fcat_org-coltext = '공급업체번호'.
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
  gs_fcat_pre-fieldname = 'LIFNR'.
  gs_fcat_pre-coltext = '공급업체번호'.
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
*& Form get_org_ap
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_org_ap.

  CLEAR: gt_acc_i, gt_org.

  SELECT *
     FROM z8fi_accdoc_i
       INTO TABLE gt_acc_i
   WHERE bukrs = gs_vendor-bukrs
        AND belnr = gs_vendor-belnr
        AND gjahr = gs_vendor-gjahr
        AND bupla = gs_vendor-bupla.

  LOOP AT gt_acc_i INTO gs_acc_i.

    CLEAR gs_org.

    gs_org-buzei = gs_acc_i-buzei.
    gs_org-hkont = gs_acc_i-hkont.
    gs_org-waers = gs_acc_i-waers.
    gs_org-lifnr = gs_acc_i-lifnr.

    IF gs_acc_i-shkzg = 'S'. "차변이면
      gs_org-shkzgt = '차변'.
      gs_org-debit = gs_acc_i-wrbtr.
    ELSEIF gs_acc_i-shkzg = 'H'. "대변이면
      gs_org-shkzgt = '대변'.
      gs_org-credit = gs_acc_i-wrbtr.
    ENDIF.

    "반제대상
    IF gs_acc_i-koart = 'K' AND gs_acc_i-lifnr = gs_vendor-lifnr.
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

  "1) 차변
  CLEAR gs_acc_i.

  gs_acc_i-bukrs = gs_vendor-bukrs.
  gs_acc_i-buzei = '001'.
  gs_acc_i-koart = gs_ap_item-koart.
  gs_acc_i-hkont = gs_ap_item-hkont.
  gs_acc_i-bupla = gs_vendor-bupla.
  gs_acc_i-shkzg = 'S'.
  gs_acc_i-wrbtr = gv_pay.
  gs_acc_i-waers = gs_vendor-waers.
  gs_acc_i-lifnr = gs_vendor-lifnr.

  CLEAR: gs_acc_i-kostl, gs_acc_i-prctr, gs_acc_i-kunnr, gs_acc_i-umskz.

  APPEND gs_acc_i TO gt_acc_i.

  "2) 대변
  CONSTANTS: lc_bank TYPE z8fi_accdoc_i-hkont VALUE '10300100'.

  CLEAR gs_acc_i.

  gs_acc_i-bukrs = gs_vendor-bukrs.
  gs_acc_i-buzei = '002'.
  gs_acc_i-koart = 'S'.
  gs_acc_i-hkont = lc_bank.
  gs_acc_i-bupla = gs_vendor-bupla.
  gs_acc_i-shkzg = 'H'.
  gs_acc_i-wrbtr = gv_pay.
  gs_acc_i-waers = gs_vendor-waers.

  CLEAR: gs_acc_i-kostl, gs_acc_i-prctr, gs_acc_i-kunnr, gs_acc_i-lifnr, gs_acc_i-umskz.

  APPEND gs_acc_i TO gt_acc_i.

  "preview
  LOOP AT gt_acc_i INTO gs_acc_i.

    CLEAR gs_pre.

    gs_pre-buzei = gs_acc_i-buzei.
    gs_pre-hkont = gs_acc_i-hkont.
    gs_pre-waers = gs_acc_i-waers.
    gs_pre-lifnr = gs_acc_i-lifnr.

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
*& Form create_accdoc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_accdoc .

  DATA:
    lv_belnr TYPE z8fi_accdoc_h-belnr,
    lv_gjahr TYPE z8fi_accdoc_h-gjahr,
    lv_monat TYPE z8fi_accdoc_h-monat,
    lv_augbl TYPE z8fi_vendor-augbl,
    lv_lines TYPE i.

  IF gt_acc_i IS INITIAL.
    MESSAGE e063(z8_msg). "'생성할 전표 아이템이 없습니다.'
  ENDIF.

  "회계전표 2개인지
  DESCRIBE TABLE gt_acc_i LINES lv_lines.

  IF lv_lines <> 2.
    MESSAGE e064(z8_msg)."'전표 아이템 구성이 올바르지 않습니다.' TYPE 'E'.
  ENDIF.

  "실제 전표 생성 직전에 미결 건이 맞는지 확인
  SELECT SINGLE augbl
    FROM z8fi_vendor
      INTO lv_augbl
  WHERE bukrs = gs_vendor-bukrs
       AND gjahr = gs_vendor-gjahr
       AND belnr = gs_vendor-belnr.

  IF sy-subrc <> 0.
    MESSAGE s067(z8_msg) DISPLAY LIKE 'E'. "'지급 대상 외상매입금 정보를 찾을 수 없습니다.'
    RETURN.
  ENDIF.

  IF lv_augbl IS NOT INITIAL.
    MESSAGE s066(z8_msg) DISPLAY LIKE 'E' WITH '지급'. "'이미 지급 및 반제 처리된 건입니다.' TYPE 'S' DISPLAY LIKE 'E'.
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

  "4. 회계전표h 구성
  CLEAR gs_acc_h.

  gs_acc_h-bukrs = gs_vendor-bukrs.
  gs_acc_h-belnr = lv_belnr.
  gs_acc_h-gjahr = lv_gjahr.
  gs_acc_h-monat = lv_monat.
  gs_acc_h-blart = 'KZ'. "외상매입금 지급/입금
  gs_acc_h-bldat = gv_paydat. "문서증빙일
  gs_acc_h-budat = gv_paydat. "실제입금일
  gs_acc_h-waers = gs_vendor-waers.
  gs_acc_h-stjah = '0000'.
  CLEAR gs_acc_h-stblg.

  gs_acc_h-xblnr = gs_vendor-inv_no. "참조문서 = 청구번호

  "5. 회계전표i key값에 값 넣기
  LOOP AT gt_acc_i INTO gs_acc_i.
    gs_acc_i-bukrs = gs_vendor-bukrs.
    gs_acc_i-belnr = lv_belnr.
    gs_acc_i-gjahr = lv_gjahr.

    MODIFY gt_acc_i FROM gs_acc_i INDEX sy-tabix
    TRANSPORTING bukrs belnr gjahr.

  ENDLOOP.

  " 6. 회계전표 h, i에 insert
  INSERT z8fi_accdoc_h FROM gs_acc_h.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e081(z8_msg) WITH '회계전표 헤더'.
  ENDIF.

  INSERT z8fi_accdoc_i FROM TABLE gt_acc_i.
  IF sy-subrc <> 0 OR sy-dbcnt <> lv_lines.
    ROLLBACK WORK.
    MESSAGE e081(z8_msg) WITH '회계전표 아이템'.
  ENDIF.

  "fi_vendor 반제 정보 update
  UPDATE z8fi_vendor
         SET augdt = gv_paydat
                augbl = lv_belnr
                auggj = lv_gjahr
   WHERE bukrs = gs_vendor-bukrs
        AND gjahr = gs_vendor-gjahr
        AND belnr = gs_vendor-belnr
        AND augbl = space.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e215(z8_msg) WITH '외상매입금 지급정보'.   " 갱신에 실패했습니다.' TYPE 'E'.
  ENDIF.

  COMMIT WORK AND WAIT.

  gv_last_bukrs = gs_vendor-bukrs.
  gv_last_gjahr = gs_vendor-gjahr.
  gv_last_belnr = gs_vendor-belnr.

  "100번 화면 갱신
  gv_refresh_100 = 'X'.

  MESSAGE |송장번호 { gs_vendor-inv_no } / 원전표 { gs_vendor-belnr }에 대한 지급전표 { lv_belnr }가 생성되었습니다.| TYPE 'I'.

  "락 풀고, 이전화면으로 돌아가기
  PERFORM unlock_vendor.
  PERFORM free_control_200.
  LEAVE TO SCREEN 0.

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

  "지급일자 입력값 체크
  IF gv_paydat IS INITIAL.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '지급일자'.
    RETURN.
  ELSEIF gv_paydat > sy-datum.
    MESSAGE s074(z8_msg) DISPLAY LIKE 'E' WITH '지급일자'.
    RETURN.
  ELSEIF gv_paydat < gs_vendor-budat.
    MESSAGE s075(z8_msg) DISPLAY LIKE 'E' WITH '지급일자' '전기일자'.
    RETURN.
  ENDIF.

  "팝업창 띄우기
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '지급 및 반제 확인'
      text_question         = |송장번호 { gs_vendor-inv_no } / 원전표 { gs_vendor-belnr }에 대한 외상매입금 지급 처리를 진행하시겠습니까?|
      text_button_1         = '예'(001)
      text_button_2         = '아니오'(002)
      display_cancel_button = space
      default_button        = '2'
    IMPORTING
      answer                = lv_answer.

  IF lv_answer = '1'.
    PERFORM create_accdoc.
  ELSE.
    MESSAGE '외상매입금 지급처리가 취소되었습니다.' TYPE 'S'.
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

  LOOP AT gt_vendor INTO gs_vendor.

    IF gs_vendor-bukrs = gv_last_bukrs
      AND gs_vendor-gjahr = gv_last_gjahr
      AND gs_vendor-belnr = gv_last_belnr.

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
*& Form lock_vendor
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM lock_vendor .

  CALL FUNCTION 'ENQUEUE_EZ8FI_VENDOR'
    EXPORTING
*     MODE_Z8FI_VENDOR       = 'E'
*     MANDT          = SY-MANDT
      bukrs          = gs_vendor-bukrs
      gjahr          = gs_vendor-gjahr
      belnr          = gs_vendor-belnr
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

  IF gv_return <> 0.
    MESSAGE s136(z8_msg) DISPLAY LIKE 'E' WITH '외상매입금을'.
    RETURN.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_clear_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_CLEAR_OK
*&---------------------------------------------------------------------*
FORM check_clear_status  CHANGING pv_clear_ok TYPE c.

  DATA lv_augbl TYPE z8fi_vendor-augbl.

  CLEAR pv_clear_ok.

  SELECT SINGLE augbl
    FROM z8fi_vendor
      INTO lv_augbl
  WHERE bukrs = gs_vendor-bukrs
       AND gjahr = gs_vendor-gjahr
       AND belnr = gs_vendor-belnr.

  IF sy-subrc <> 0.
    MESSAGE s067(z8_msg) DISPLAY LIKE 'E'."지급 대상 외상매입금 정보를 찾을 수 없습니다.
    RETURN.
  ENDIF.

  IF lv_augbl IS NOT INITIAL.
    MESSAGE s066(z8_msg) DISPLAY LIKE 'E' WITH '지급'."이미 지급 및 반제 처리된 건 입니다.'
    RETURN.
  ENDIF.

  pv_clear_ok = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form unlock_vendor
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM unlock_vendor .

  CALL FUNCTION 'DEQUEUE_EZ8FI_VENDOR'
    EXPORTING
*     MODE_Z8FI_VENDOR       = 'E'
*     MANDT = SY-MANDT
      bukrs = gs_vendor-bukrs
      gjahr = gs_vendor-gjahr
      belnr = gs_vendor-belnr
*     X_BUKRS                = ' '
*     X_GJAHR                = ' '
*     X_BELNR                = ' '
*     _SCOPE                 = '3'
*     _SYNCHRON              = ' '
*     _COLLECT               = ' '
    .

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
      months  = -3
      olddate = sy-datum
    IMPORTING
      newdate = lv_from.

  CLEAR so_budat.
  so_budat-sign   = 'I'.
  so_budat-option = 'BT'.
  so_budat-low    = lv_from.
  so_budat-high = sy-datum.
  APPEND so_budat.

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
    IF so_budat[] IS INITIAL.
      SET CURSOR FIELD 'SO_BUDAT-LOW'.
      MESSAGE e121(z8_msg)  WITH '청구일은'.
    ENDIF.

    "종료일만 입력한 경우
    IF so_budat-low IS INITIAL AND so_budat-high IS NOT INITIAL.
      SET CURSOR FIELD 'SO_BUDAT-LOW'.
      MESSAGE e124(z8_msg). "'시작일을 입력해주세요.'
    ENDIF.

    "기간 역전 확인
    IF so_budat-low IS NOT INITIAL
      AND so_budat-high IS NOT INITIAL
      AND so_budat-low > so_budat-high.

      SET CURSOR FIELD 'SO_BUDAT-LOW'.
      MESSAGE e126(z8_msg). "조회범위를 확인해주세요
    ENDIF.

    "조회 시작일이 현재보다 작아야함
    IF so_budat-low > sy-datum.
      SET CURSOR FIELD 'SO_BUDAT-LOW'.
      MESSAGE e123(z8_msg). "조회시작일은 현재 날짜보다 클 수 없습니다
    ENDIF.

  ENDIF.

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

  IF pa_lifnr IS NOT INITIAL.
    SELECT SINGLE name1
      FROM z8vendor_m
      INTO gv_vent
      WHERE lifnr = pa_lifnr.
  ELSE.
    CLEAR gv_vent.
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

  IF sy-subrc <> 0.
    CLEAR gv_brant.
    MESSAGE s146(z8_msg) DISPLAY LIKE 'E' WITH '지사'. "정보를 찾을 수 없습니다.'
    RETURN.
  ENDIF.

  "화면의 지사명 즉시 갱신
  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_BRANT'.
  ls_dynp-fieldvalue = gv_brant.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname               = sy-repid
      dynumb               = sy-dynnr
    TABLES
      dynpfields           = lt_dynp
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      undefind_error       = 7
      OTHERS               = 8.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_lifnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_lifnr .

  DATA:
    lt_return TYPE TABLE OF ddshretval,
    lt_dynp   TYPE TABLE OF dynpread,
    ls_dynp   TYPE dynpread.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8VENDOR_M'
      fieldname   = 'LIFNR'
      searchhelp  = 'Z8SH_VENDOR'
      shlpparam   = 'LIFNR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'PA_LIFNR'
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

  pa_lifnr = ls_return-fieldval.

  "공급업체명 조회
  CLEAR gv_vent.

  SELECT SINGLE name1
      FROM z8vendor_m
      INTO gv_vent
      WHERE lifnr = pa_lifnr.

  "화면의 공급업체명 즉시 갱신
  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_VENT'.
  ls_dynp-fieldvalue = gv_vent.
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

  IF pa_lifnr IS INITIAL.
    CLEAR gv_vent.
  ELSE.
    SELECT SINGLE name1
      FROM z8vendor_m
      INTO gv_vent
      WHERE lifnr = pa_lifnr.

    IF sy-subrc <> 0.
      CLEAR gv_vent.
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

  LOOP AT gt_vendor ASSIGNING FIELD-SYMBOL(<fs_alv>).

    CLEAR <fs_alv>-ct.

    "belnr이 있는 셀만 Hotspot
    IF <fs_alv>-belnr IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'BELNR'.
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
    MESSAGE e200(z8_msg) WITH 'FI'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_pa_invno
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_pa_invno .

  DATA: BEGIN OF ls_f4,
          inv_no TYPE z8mm_inv_h-inv_no,
          lifnr  TYPE z8fi_vendor-lifnr,
          lifnrt TYPE z8vendor_m-name1,
          bupla  TYPE z8fi_vendor-bupla,
          buplat TYPE z8branch_m-name,
          budat  TYPE z8fi_vendor-budat,
        END OF ls_f4,

        lt_f4     LIKE TABLE OF ls_f4,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_dynp   TYPE TABLE OF dynpread,
        ls_dynp   TYPE dynpread.

  CLEAR: ls_f4, lt_f4.

  SELECT DISTINCT
    a~xblnr AS inv_no,
    a~lifnr,
    d~name1,
    a~bupla,
    c~name AS buplat,
    a~budat
    FROM z8fi_vendor AS a
    INNER JOIN z8fi_accdoc_h AS h
         ON h~bukrs = a~bukrs
       AND h~belnr = a~belnr
       AND h~gjahr = a~gjahr
    INNER JOIN z8fi_accdoc_i AS i
         ON i~bukrs = a~bukrs
       AND i~belnr = a~belnr
       AND i~gjahr = a~gjahr
       AND i~lifnr = a~lifnr
       AND i~koart = 'K'
      LEFT OUTER JOIN  z8branch_m AS c
         ON c~bukrs = a~bukrs
       AND c~branch = a~bupla
      LEFT OUTER JOIN z8vendor_m AS d
         ON d~lifnr = a~lifnr
    WHERE a~bukrs = @gc_bukrs
       AND a~budat IN @so_budat
      INTO TABLE @lt_f4.

  IF lt_f4 IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = ' '
      retfield        = 'INV_NO'
*     PVALKEY         = ' '
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'PA_INVNO'
*     STEPL           = 0
*     WINDOW_TITLE    =
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = ' '
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     CALLBACK_METHOD =
*     MARK_TAB        =
*     IMPORTING
*     USER_RESET      =
    TABLES
      value_tab       = lt_f4
*     FIELD_TAB       =
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "선택한 송장번호
  READ TABLE lt_return INTO ls_return INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "선택한 송장의 정보 조회
  READ TABLE lt_f4 INTO ls_f4 WITH KEY inv_no = ls_return-fieldval.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "프로그램 변수에 반영
  pa_invno = ls_f4-inv_no.
  pa_lifnr = ls_f4-lifnr.
  pa_bran  = ls_f4-bupla.
  gv_vent  = ls_f4-lifnrt.
  gv_brant = ls_f4-buplat.


  "송장 번호 선택 시 공급업체, 지사에도 값 넣어주기
  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'PA_INVNO'.
  ls_dynp-fieldvalue = ls_f4-inv_no.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'PA_LIFNR'.
  ls_dynp-fieldvalue = ls_f4-lifnr.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_VENT'.
  ls_dynp-fieldvalue = ls_f4-lifnrt.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'PA_BRAN'.
  ls_dynp-fieldvalue = ls_f4-bupla.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_BRANT'.
  ls_dynp-fieldvalue = ls_f4-buplat.
  APPEND ls_dynp TO lt_dynp.


  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp.

ENDFORM.
