*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_F01
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

  CREATE OBJECT go_alv
    EXPORTING
      i_parent          = go_container
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_summary_container
    EXPORTING
      container_name = 'CONTROL_AREA_SUMMARY'.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.


  CREATE OBJECT go_html_viewer
    EXPORTING
      parent = go_summary_container.

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
  SET HANDLER lcl_handler=>on_hotspot FOR go_alv.

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
  gs_layout-excp_fname = 'LIGHT'.
  gs_layout-excp_led = 'X'. "신호등 1구
  gs_layout-zebra = 'X'.

*  gs_layout-grid_title = |전체 ({ lines( gt_accdoc_h ) })건|.
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
  CLEAR gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'BUKRS'.
  gw_fcat-coltext = '회사 코드'.
  gw_fcat-no_out = 'X'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'STBLG'.
  gw_fcat-no_out = 'X'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'STJAH'.
  gw_fcat-coltext = '연도'.
  gw_fcat-no_out = 'X'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'LIGHT'.
  gw_fcat-coltext = '상태'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'STATUS_TXT'.
  gw_fcat-coltext = '상태명'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'BELNR'.
  gw_fcat-coltext = '전표번호'.
  gw_fcat-col_pos = 1.
  gw_fcat-hotspot = 'X'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'BUDAT'.
  gw_fcat-coltext = '전기일자'.
  gw_fcat-col_pos = 2.
  gw_fcat-just = 'C'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'BLART'.
  gw_fcat-coltext = '유형'.
  gw_fcat-col_pos = 3.
  gw_fcat-outputlen = 3.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'LTEXT'.
  gw_fcat-coltext = '전표유형명'.
  gw_fcat-col_pos = 4.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'BUPLA'.
  gw_fcat-coltext = '지사'.
  gw_fcat-col_pos = 5.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'NAME'.
  gw_fcat-coltext = '지사명'.
  gw_fcat-col_pos = 6.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'KUNNR'.
  gw_fcat-coltext = '고객/공급업체'.
  gw_fcat-col_pos = 7.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'NAME1'.
  gw_fcat-coltext = '고객/공급업체명'.
  gw_fcat-col_pos = 8.
  gw_fcat-outputlen = 20.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'XBLNR'.
  gw_fcat-coltext = '참조문서'.
  gw_fcat-col_pos = 9.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'WRBTR'.
  gw_fcat-coltext = '전표금액'.
  gw_fcat-cfieldname = 'WAERS'.
  gw_fcat-col_pos = 10.
  gw_fcat-outputlen = 13.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'WAERS'.
  gw_fcat-coltext = '통화'.
  gw_fcat-col_pos = 11.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'MONAT'.
  gw_fcat-coltext = '전기월'.
  gw_fcat-col_pos = 12.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'GJAHR'.
  gw_fcat-col_pos = 13.
  APPEND gw_fcat TO gt_fcat.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL METHOD go_alv->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8FI_ACCDOC_H'
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_accdoc_h
      it_fieldcatalog               = gt_fcat
*     it_sort                       =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
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

  IF so_date[] IS INITIAL.

    so_date-sign = 'I'.
    so_date-option = 'BT'.
    so_date-low = sy-datum.
    so_date-high = sy-datum.

    CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
      EXPORTING
        date      = sy-datum
        days      = 0
        months    = 1
        years     = 0
        signum    = '-'
      IMPORTING
        calc_date = so_date-low.

    APPEND so_date.
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
FORM get_data CHANGING p_result.
  DATA: lv_debit      TYPE z8fi_accdoc_i-wrbtr,
        lv_credit     TYPE z8fi_accdoc_i-wrbtr,
        lv_item_count TYPE i,
        lv_invalid    TYPE abap_bool.

  DATA: lt_belnr LIKE so_belnr[].

  CLEAR: gt_accdoc_h,
         gt_accdoc_i,
         gv_cnt_stock,
         gv_cnt_invoice,
         gv_cnt_payment,
         gv_cnt_other,
         gv_cnt_mismatch,
         lt_belnr.



  lt_belnr = so_belnr[].


  LOOP AT lt_belnr ASSIGNING FIELD-SYMBOL(<fs_belnr>).

    IF <fs_belnr>-low IS NOT INITIAL.
      <fs_belnr>-low = |{ <fs_belnr>-low ALPHA = IN }|. "숫자로만 구성된 문자열의 앞쪽에 0을 채워서 필드 길이에 맞추는 변환
    ENDIF.

    IF <fs_belnr>-high IS NOT INITIAL.
      <fs_belnr>-high = |{ <fs_belnr>-high ALPHA = IN }|.
    ENDIF.

  ENDLOOP.


  p_result = abap_true.


  SELECT h~*,
         t~ltext
    FROM z8fi_accdoc_h AS h
    LEFT JOIN t003t AS t ON t~blart = h~blart AND spras = @sy-langu
     WHERE h~belnr IN @lt_belnr
       AND ( @pa_blart IS INITIAL OR h~blart = @pa_blart )
       AND ( @pa_xblnr IS INITIAL OR xblnr = @pa_xblnr )
       AND h~gjahr IN @so_gjahr
       AND h~budat IN @so_date
       AND ( @pa_bupla IS INITIAL OR
              EXISTS (
                SELECT *
                  FROM z8fi_accdoc_i AS i
                  WHERE i~bukrs = h~bukrs
                    AND i~belnr = h~belnr
                    AND i~gjahr = h~gjahr
                    AND i~bupla = @pa_bupla
    ) )
     INTO CORRESPONDING FIELDS OF TABLE @gt_accdoc_h.

  IF sy-subrc <> 0.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    p_result = abap_false.
    RETURN.
  ENDIF.

  SELECT i~*,
         b~branch AS bupla,
         b~name,
         c~name1,
         v~name1 AS vname,
         v~lifnr
    FROM z8fi_accdoc_i AS i
    LEFT JOIN z8customer_m AS c ON c~kunnr = i~kunnr
    LEFT JOIN z8branch_m AS b ON b~branch = i~bupla
                              AND b~bukrs = i~bukrs
    LEFT JOIN z8vendor_m AS v ON v~lifnr = i~lifnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_accdoc_i.

  IF sy-subrc <> 0.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    p_result = abap_false.
    RETURN.
  ENDIF.


  LOOP AT gt_accdoc_h ASSIGNING FIELD-SYMBOL(<fs_h>).

    CLEAR: lv_debit, lv_credit, lv_item_count, lv_invalid.


    LOOP AT gt_accdoc_i ASSIGNING FIELD-SYMBOL(<fs_i>) WHERE belnr = <fs_h>-belnr
                                                         AND bukrs = <fs_h>-bukrs
                                                         AND gjahr = <fs_h>-gjahr.

      lv_item_count += 1.

      "차변 / 대변 금액 집계
      CASE <fs_i>-shkzg.
        WHEN 'S'.
          lv_debit += <fs_i>-wrbtr.
        WHEN 'H'.
          lv_credit += <fs_i>-wrbtr.
        WHEN OTHERS. "
          lv_invalid = abap_true.
      ENDCASE.

      <fs_h>-bupla = <fs_i>-bupla.
      <fs_h>-name  = <fs_i>-name.

      IF <fs_i>-lifnr IS NOT INITIAL. "공급업체

        <fs_h>-name1 = <fs_i>-vname.
        <fs_h>-kunnr = <fs_i>-lifnr.

      ELSEIF <fs_i>-kunnr IS NOT INITIAL. "고객

        <fs_h>-name1 = <fs_i>-name1.
        <fs_h>-kunnr = <fs_i>-kunnr.

      ENDIF.

    ENDLOOP.

    "전표금액: 차변 합계 기준
    <fs_h>-wrbtr = lv_debit.


    "차대 검증
    IF lv_item_count = 0. "분개 항목 없음

      <fs_h>-light = '2'.
      <fs_h>-status_f = '30'.

    ELSEIF lv_invalid = abap_true. ""차대 구분 오류

      <fs_h>-light = '2'.
      <fs_h>-status_f = '40'.

    ELSEIF lv_debit = lv_credit.

      <fs_h>-light = '3'. "초록: 차대 일치
      <fs_h>-status_f = '10'.

    ELSE.

      <fs_h>-light = '1'. "빨강: 차대 불일치
      <fs_h>-status_f = '20'.

    ENDIF.

    CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
      EXPORTING
        iv_domname      = 'Z8DFI_STATUS'
        iv_value        = <fs_h>-status_f
      IMPORTING
        ev_value_text   = <fs_h>-status_txt
      EXCEPTIONS
        value_not_found = 1
        OTHERS          = 2.

  ENDLOOP.

  IF gv_status IS NOT INITIAL.
    DELETE gt_accdoc_h WHERE status_f <> gv_status.
  ENDIF.

*  IF pa_bupla IS NOT INITIAL.
*    DELETE gt_accdoc_h WHERE bupla <> pa_bupla.
*  ENDIF.

  PERFORM get_cnt_html.

  "최신 전기일자 순
  SORT gt_accdoc_h BY budat DESCENDING belnr DESCENDING.

  IF gt_accdoc_h IS INITIAL.

    MESSAGE s114(z8_msg) DISPLAY LIKE 'E'.

  ENDIF.

ENDFORM.


FORM display_summary.

  DATA: lt_html      TYPE STANDARD TABLE OF w3html,
        lv_url       TYPE w3url,
        lv_led_color TYPE string.

  IF go_html_viewer IS NOT BOUND.
    RETURN.
  ENDIF.

  "차대 불일치 여부에 따른 LED 색상
  IF gv_cnt_mismatch > 0.
    lv_led_color = '#dc3545'.
  ELSE.
    lv_led_color = '#28a745'.
  ENDIF.


  "---------------------------------------------
  "1. HTML 및 CSS
  "---------------------------------------------
  APPEND VALUE #( line =
    '<html><head><style>'
  ) TO lt_html.

  APPEND VALUE #( line =
    'html,body{margin:0;background:#fff;font-family:Arial,sans-serif;}body{padding:12px 0 0 0;}'
  ) TO lt_html.

  "카드 테이블
  APPEND VALUE #( line =
    '.cards{width:100%;table-layout:fixed;border-spacing:5px 0;}'
  ) TO lt_html.

  "카드 디자인
  APPEND VALUE #( line =
    '.card{background:#fff;border:1px solid #dce3ec;border-radius:10px;text-align:center;padding:7px 2px;}'
  ) TO lt_html.

  "카드 제목
  APPEND VALUE #( line =
    '.label{font-size:11px;color:#64748b;white-space:nowrap;}'
  ) TO lt_html.

  "카드 건수
  APPEND VALUE #( line =
    '.num{font-size:21px;font-weight:bold;color:#24364b;margin-top:3px;}'
  ) TO lt_html.

  "건 단위
  APPEND VALUE #( line =
    '.unit{font-size:11px;font-weight:normal;color:#64748b;}'
  ) TO lt_html.


  APPEND VALUE #( line =
    '.status{margin:5px 10px 0 0;text-align:right;}'
  ) TO lt_html.

  "검증 상태 제목
  APPEND VALUE #( line =
    '.status-title{font-size:10px;color:#94a3b8;margin-bottom:2px;}'
  ) TO lt_html.

  "우측 하단 위치
  APPEND VALUE #( line =
    '.status{margin:7px 10px 0 0;text-align:right;}'
  ) TO lt_html.


  "차대 불일치 문구
  APPEND VALUE #( line =
    '.status-text{font-size:11px;color:#64748b;}'
  ) TO lt_html.

  "차대 불일치 건수
*  APPEND VALUE #( line =
*    '.status-num{font-size:12px;font-weight:bold;color:#24364b;}'
*  ) TO lt_html.
  APPEND VALUE #( line =
    '.status-num{font-size:14px;font-weight:bold;color:#c2413b;}'
  ) TO lt_html.

  APPEND VALUE #( line =
    '</style></head><body>'
  ) TO lt_html.


  "---------------------------------------------
  "3. 업무유형별 카드 4개
  "---------------------------------------------
  APPEND VALUE #( line =
    '<table class="cards"><tr>'
  ) TO lt_html.


  "재고 이동
  APPEND VALUE #( line =
    |<td><div class="card"><div class="label">재고 이동</div>|
  ) TO lt_html.

  APPEND VALUE #( line =
    |<div class="num">{ gv_cnt_stock }<span class="unit">건</span></div></div></td>|
  ) TO lt_html.


  "매입/매출
  APPEND VALUE #( line =
    |<td><div class="card"><div class="label">매입·매출</div>|
  ) TO lt_html.

  APPEND VALUE #( line =
    |<div class="num">{ gv_cnt_invoice }<span class="unit">건</span></div></div></td>|
  ) TO lt_html.


  "수금/지급
  APPEND VALUE #( line =
    |<td><div class="card"><div class="label">수금·지급</div>|
  ) TO lt_html.

  APPEND VALUE #( line =
    |<div class="num">{ gv_cnt_payment }<span class="unit">건</span></div></div></td>|
  ) TO lt_html.


  "기타 전표
  APPEND VALUE #( line =
    |<td><div class="card"><div class="label">기타 전표</div>|
  ) TO lt_html.

  APPEND VALUE #( line =
    |<div class="num">{ gv_cnt_other }<span class="unit">건</span></div></div></td>|
  ) TO lt_html.

  APPEND VALUE #( line =
    '</tr></table>'
  ) TO lt_html.


  "---------------------------------------------
  "4. 우측 하단 차대 불일치 표시
  "---------------------------------------------
  APPEND VALUE #( line =
    '<div class="status">'
  ) TO lt_html.


  APPEND VALUE #( line =
    |<div class="status-text">|
  ) TO lt_html.

  "LED 아이콘
  APPEND VALUE #( line =
    |<span style="color:{ lv_led_color };font-size:13px;">&#9679;</span>|
  ) TO lt_html.

  APPEND VALUE #( line =
    | 차대 불일치 <span class="status-num">{ gv_cnt_mismatch }건</span></div>|
  ) TO lt_html.

  APPEND VALUE #( line =
    '</div></body></html>'
  ) TO lt_html.


  "---------------------------------------------
  "5. HTML Viewer 갱신
  "---------------------------------------------
  go_html_viewer->load_data(
    EXPORTING
      type         = 'text'
      subtype      = 'html'
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html
    EXCEPTIONS
      OTHERS       = 1
  ).

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  go_html_viewer->show_url(
    EXPORTING
      url = lv_url
    EXCEPTIONS
      OTHERS = 1
  ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form REFRESH_ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv .

  go_alv->get_frontend_layout(
    IMPORTING
      es_layout = gs_layout
  ).

  gs_layout-grid_title = |전체 ({ lines( gt_accdoc_h ) })건|.

  go_alv->set_frontend_layout(
    EXPORTING
      is_layout = gs_layout
  ).

  go_alv->refresh_table_display( ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_ACCDOC_H_BUKRS
*&      --> GW_ACCDOC_H_BELNR
*&      --> GW_ACCDOC_H_GJAHR
*&---------------------------------------------------------------------*
FORM get_detail  USING    p_bukrs
                          p_belnr
                          p_gjahr
                 CHANGING p_result.

  p_result = abap_true.
  CLEAR: gs_detail_h, gt_detail_i, gw_detail_i.

  SELECT SINGLE h~*,
                c~butxt,
                t~ltext
    FROM z8fi_accdoc_h AS h LEFT JOIN z8company_m AS c ON h~bukrs = c~bukrs
                            LEFT JOIN t003t AS t ON t~blart = h~blart
                                                AND spras = @sy-langu

    INTO CORRESPONDING FIELDS OF @gs_detail_h
    WHERE h~bukrs = @p_bukrs
    AND h~belnr = @p_belnr
    AND h~gjahr = @p_gjahr.

  IF sy-subrc <> 0.
    p_result = abap_false.
    RETURN.
  ENDIF.

  SELECT i~*,
          b~name,
          v~name1 AS name1_v,
          g~txt20,
          c~name1 AS name1_c
    FROM z8fi_accdoc_i AS i
    LEFT JOIN z8branch_m AS b ON b~bukrs = i~bukrs AND b~branch = i~bupla
    LEFT JOIN z8vendor_m AS v ON v~lifnr = i~lifnr
    LEFT JOIN z8glacc_m AS g ON g~saknr = i~hkont
    LEFT JOIN z8customer_m AS c ON c~kunnr = i~kunnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_detail_i
    WHERE i~bukrs = @p_bukrs
      AND i~belnr = @p_belnr
      AND i~gjahr = @p_gjahr.

  IF sy-subrc <> 0.
    p_result = abap_true. "아이템이 없는 경우에도 Header 정보와 분개 누락 상태 확인할 수 있어야 함
  ENDIF.

  "전표 검증 계산
  PERFORM calc_detail_check.

  PERFORM set_detail_icon.


  LOOP AT gt_detail_i ASSIGNING FIELD-SYMBOL(<fs_i>) WHERE belnr = p_belnr AND bukrs = p_bukrs AND gjahr = p_gjahr.
    CLEAR: <fs_i>-debit, <fs_i>-credit.
    CASE <fs_i>-shkzg.
      WHEN 'S'."차변
        <fs_i>-wrbtr_txt = TEXT-008.
        <fs_i>-debit = <fs_i>-wrbtr.
      WHEN 'H'."대변
        <fs_i>-wrbtr_txt = TEXT-009.
        <fs_i>-credit = <fs_i>-wrbtr.
      WHEN OTHERS.
    ENDCASE.

  ENDLOOP.




ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object200 .
  CREATE OBJECT go_container200
    EXPORTING
      container_name              = 'CONTROL_AREA200'
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

  CREATE OBJECT go_alv200
    EXPORTING
      i_parent          = go_container200
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler200 .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout200 .
  gs_layout200-zebra = 'X'.
  gs_layout200-grid_title = TEXT-003. "분개 상세내역
  gs_layout200-no_toolbar = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fcat200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat200 .
  CLEAR gt_fcat200.


  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'KOSTL'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'PRCTR'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'KOSTL'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'BUKRS'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'WRBTR'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'BELNR'.
  gw_fcat200-col_pos = 1.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'BUZEI'.
  gw_fcat200-col_pos = 2.
  gw_fcat200-coltext = '항목'.
  APPEND gw_fcat200 TO gt_fcat200.


  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'HKONT'.
  gw_fcat200-coltext = 'G/L 계정'.
  gw_fcat200-col_pos = 3.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'TXT20'.
  gw_fcat200-coltext = '계정명'.
  gw_fcat200-col_pos = 4.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'SHKZG'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'KOART'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'GJAHR'.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'WRBTR_TXT'.
  gw_fcat200-coltext = '차대'.
  gw_fcat200-col_pos = 5.
  gw_fcat200-outputlen = 3.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'DEBIT'.
  gw_fcat200-coltext = '차변'.
  gw_fcat200-col_pos = 6.
  gw_fcat200-outputlen = 13.
  gw_fcat200-cfieldname = 'WAERS'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'CREDIT'.
  gw_fcat200-coltext = '대변'.
  gw_fcat200-col_pos = 7.
  gw_fcat200-outputlen = 13.
  gw_fcat200-cfieldname = 'WAERS'.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'WAERS'.
  gw_fcat200-coltext = '통화'.
  gw_fcat200-col_pos = 8.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'KUNNR'.
  gw_fcat200-coltext = '고객코드'.
  gw_fcat200-col_pos = 9.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'NAME1_C'.
  gw_fcat200-coltext = '고객명'.
  gw_fcat200-col_pos = 10.
  gw_fcat200-outputlen = 20.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'LIFNR'.
  gw_fcat200-coltext = '공급업체 코드'.
  gw_fcat200-col_pos = 11.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'NAME1_V'.
  gw_fcat200-coltext = '공급업체명'.
  gw_fcat200-col_pos = 12.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'BUPLA'.
  gw_fcat200-coltext = '지사'.
  gw_fcat200-col_pos = 13.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'NAME'.
  gw_fcat200-coltext = '지사명'.
  gw_fcat200-col_pos = 14.
  APPEND gw_fcat200 TO gt_fcat200.

  CLEAR gw_fcat200.
  gw_fcat200-fieldname = 'UMSKZ'.
  gw_fcat200-coltext = '특별 G/L 계정'.
  gw_fcat200-col_pos = 15.
  gw_fcat200-outputlen = 8.
  gw_fcat200-no_out = 'X'.
  APPEND gw_fcat200 TO gt_fcat200.

  LOOP AT gt_fcat200 INTO gw_fcat200.
    CASE gw_fcat200-fieldname.
      WHEN 'DEBIT' OR 'CREDIT'.
        gw_fcat200-no_zero = 'X'.
    ENDCASE.
    MODIFY gt_fcat200 FROM gw_fcat200.
  ENDLOOP.



*  CLEAR gw_fcat200.
*  gw_fcat-fieldname = 'WRBTR'.
*  gw_fcat-coltext = '금액'.
*APPEND gw_fcat200 TO gt_fcat200.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv200 .
  CALL METHOD go_alv200->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8FI_ACCDOC_I'
      is_layout                     = gs_layout200
    CHANGING
      it_outtab                     = gt_detail_i
      it_fieldcatalog               = gt_fcat200
*     it_sort                       =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form refresh_alv200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv200 .
  go_alv200->get_frontend_layout(
    IMPORTING
      es_layout = gs_layout200
  ).


  go_alv200->refresh_table_display( ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_detail_check
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM calc_detail_check.

  DATA: lv_invalid       TYPE abap_bool,
        lv_detail_debit  TYPE z8fi_accdoc_i-wrbtr,
        lv_detail_credit TYPE z8fi_accdoc_i-wrbtr,
        lv_detail_diff   TYPE z8fi_accdoc_i-wrbtr.

  CLEAR: gv_detail_debit_txt,
         gv_detail_credit_txt,
         gv_detail_diff_txt,
         gv_detail_msg,
         lv_invalid,
         lv_detail_debit,
         lv_detail_credit,
         lv_detail_diff.

  "분개 Item별 차변 / 대변 합산
  LOOP AT gt_detail_i ASSIGNING FIELD-SYMBOL(<fs_i>).

    CASE <fs_i>-shkzg.

      WHEN 'S'.
        lv_detail_debit += <fs_i>-wrbtr.

      WHEN 'H'.
        lv_detail_credit += <fs_i>-wrbtr.

      WHEN OTHERS.
        lv_invalid = abap_true.

    ENDCASE.


  ENDLOOP.

  "차액 계산
  lv_detail_diff = abs( lv_detail_debit
                      - lv_detail_credit ).

  "검증 결과
  IF gt_detail_i IS INITIAL.

    gv_detail_msg = TEXT-004.

  ELSEIF lv_invalid = abap_true.

    gv_detail_msg = TEXT-005.

  ELSEIF lv_detail_debit = lv_detail_credit.

    gv_detail_msg = TEXT-006.

  ELSE.

    gv_detail_msg = TEXT-007.

  ENDIF.

  WRITE lv_detail_debit TO gv_detail_debit_txt CURRENCY gs_detail_h-waers.

  WRITE lv_detail_credit TO gv_detail_credit_txt CURRENCY gs_detail_h-waers.

  WRITE lv_detail_diff  TO gv_detail_diff_txt CURRENCY gs_detail_h-waers.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_detail_icon
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_detail_icon .

  DATA lv_icon_name TYPE c LENGTH 30.

  CLEAR: gv_detail_icon, lv_icon_name.


  CASE gv_detail_msg.

    WHEN TEXT-006.
      lv_icon_name = 'ICON_LED_GREEN'.

    WHEN TEXT-007.
      lv_icon_name = 'ICON_LED_RED'.

    WHEN TEXT-004 OR TEXT-005.
      lv_icon_name = 'ICON_LED_YELLO'.

    WHEN OTHERS.
      RETURN.

  ENDCASE.


  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name                  = lv_icon_name
    IMPORTING
      result                = gv_detail_icon
    EXCEPTIONS
      icon_not_found        = 1
      outputfield_too_short = 2
      OTHERS                = 3.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form search_validation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_SEARCH_RESULT
*&---------------------------------------------------------------------*
FORM search_validation CHANGING p_date_result.
  p_date_result = abap_true.

  IF so_date-low IS INITIAL.
    MESSAGE s124(z8_msg) DISPLAY LIKE 'E'.
    p_date_result = abap_false.
    RETURN.
  ENDIF.

*  IF so_date-low IS INITIAL OR so_date-high IS INITIAL.
*    MESSAGE s046(z8_msg) DISPLAY LIKE 'E'.
*    p_date_result = abap_false.
*    RETURN.
*  ENDIF.

  IF so_date-low > sy-datum.
    MESSAGE s123(z8_msg) DISPLAY LIKE 'E'.
    p_date_result = abap_false.
    RETURN.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_cnt_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_cnt_html .
  CLEAR: gv_cnt_stock,
     gv_cnt_invoice,
     gv_cnt_payment,
     gv_cnt_other,
     gv_cnt_mismatch.

  LOOP AT gt_accdoc_h ASSIGNING FIELD-SYMBOL(<fs_sum>).

    CASE <fs_sum>-blart.

      WHEN 'WE' OR 'WL'.
        gv_cnt_stock += 1.

      WHEN 'DR' OR 'KR' OR 'RE'.
        gv_cnt_invoice += 1.

      WHEN 'DZ' OR 'KZ'.
        gv_cnt_payment += 1.

      WHEN OTHERS.
        gv_cnt_other += 1.

    ENDCASE.


    "차대 불일치 건수는 별도 집계
    IF <fs_sum>-status_f = '20'.
      gv_cnt_mismatch += 1.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_blart_txt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_blart_txt .
  CLEAR gv_blart.

  IF pa_blart IS NOT INITIAL.

    SELECT SINGLE ltext
      FROM t003t
      INTO gv_blart
      WHERE blart = pa_blart
      AND spras = sy-langu.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_blart
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f4_blart .
  DATA: lt_return TYPE TABLE OF ddshretval,
        lt_dynp   TYPE TABLE OF dynpread,
        ls_dynp   TYPE dynpread.


  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8FI_ACCDOC_H'
      fieldname   = 'BLART'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'PA_BLART'
    TABLES
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE lt_return INTO DATA(ls_return) INDEX 1. "선택한 전표유형 가져오기

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  pa_blart = ls_return-fieldval.


  PERFORM get_blart_txt.

  CLEAR lt_dynp.


  "전표유형 설명만 갱신
  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_BLART'.
  ls_dynp-fieldvalue = gv_blart.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname              = sy-repid
      dynumb              = sy-dynnr
    TABLES
      dynpfields          = lt_dynp
    EXCEPTIONS
      invalid_dynprofield = 2
      OTHERS              = 8.

  IF sy-subrc <> 0.

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
