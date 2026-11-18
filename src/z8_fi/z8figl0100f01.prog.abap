*&---------------------------------------------------------------------*
*& Include          Z8FIGL0100F01
*&---------------------------------------------------------------------*
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
*& Form refresh_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_100 .

  "최신 데이터 다시 조회
  PERFORM get_gldata_100.
  PERFORM make_alv_100.

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

  PERFORM display_html.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_gldata_100 .

  CLEAR: gt_gl_detail, gt_glacc.

  "회계전표 조회
  SELECT
         i~bukrs,
         i~bupla,
         i~belnr,
         i~gjahr,
         i~buzei,
         i~hkont,
         h~budat,
         h~monat,
         h~blart,
         h~xblnr,
         i~shkzg,
         i~wrbtr,
         i~waers
    FROM z8fi_accdoc_i AS i
    INNER JOIN z8fi_accdoc_h AS h
    ON h~bukrs = i~bukrs
    AND h~belnr = i~belnr
    AND h~gjahr = i~gjahr
    WHERE i~bukrs = @gc_bukrs
    AND i~gjahr = @pa_gjahr
    AND h~monat IN @so_monat
    AND i~bupla IN @so_bran
    AND i~hkont IN @so_saknr
    INTO TABLE @gt_gl_detail.
  "i~koart = 'S'를 넣을수도있음.. g/l 계정별 잔액이니까!

  SELECT *
    FROM z8glacc_m
    INTO TABLE gt_glacc.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_alv_100 .

  DATA lv_tabix TYPE sy-tabix.

  CLEAR:
  gt_alv_100,
  gv_bal_cnt , "잔액 보유 gl계정 수
  gv_used_cnt, "거래 발생 계정 수
  gv_dtotal, "차변 누계
  gv_ctotal, "대변 누계
  gv_waers. "통화

  "1. g/l 계정별 차변/대변 금액 집계
  LOOP AT gt_gl_detail INTO gs_gl_detail.

    "gl계정 없으면 제외
    IF gs_gl_detail-hkont IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR gs_alv_100.

    "이미 gt_alv에 생성된 계정인지 확인
    READ TABLE gt_alv_100 INTO gs_alv_100
    WITH KEY saknr = gs_gl_detail-hkont.

    IF sy-subrc = 0.
      lv_tabix = sy-tabix.
    ELSE.
      "처음 등장한 계정
      CLEAR gs_alv_100.

      gs_alv_100-saknr = gs_gl_detail-hkont.
      gs_alv_100-waers = gs_gl_detail-waers.

      "gl계정명 조회
      READ TABLE gt_glacc INTO gs_glacc
      WITH KEY saknr = gs_gl_detail-hkont.

      IF sy-subrc = 0.
        gs_alv_100-txt20 = gs_glacc-txt20.
      ENDIF.

      APPEND gs_alv_100 TO gt_alv_100.

      DESCRIBE TABLE gt_alv_100 LINES lv_tabix.

    ENDIF.
    "차/대변 누계
    IF gs_gl_detail-shkzg = 'S'.
      gs_alv_100-debit = gs_alv_100-debit + gs_gl_detail-wrbtr.
    ELSEIF gs_gl_detail-shkzg = 'H'.
      gs_alv_100-credit = gs_alv_100-credit + gs_gl_detail-wrbtr.
    ENDIF.

    MODIFY gt_alv_100 FROM gs_alv_100 INDEX lv_tabix.

  ENDLOOP.

  "2. 거래 발생 계정 수
  DESCRIBE TABLE gt_alv_100 LINES gv_used_cnt.

  "3. 계정별 잔액 + 전체 누계 계산
  LOOP AT gt_alv_100 INTO gs_alv_100.

    IF gs_alv_100-debit > gs_alv_100-credit. "차변 잔액
      gs_alv_100-shkzg = 'S'.
      gs_alv_100-bal_txt = '차변'.
      gs_alv_100-bal_amt = gs_alv_100-debit - gs_alv_100-credit.

      "차변 잔액 합계
      gv_dtotal = gv_dtotal + gs_alv_100-bal_amt.

    ELSEIF gs_alv_100-debit < gs_alv_100-credit. "대변 잔액
      gs_alv_100-shkzg = 'H'.
      gs_alv_100-bal_txt = '대변'.
      gs_alv_100-bal_amt = gs_alv_100-credit - gs_alv_100-debit.

      "대변 잔액 합계
      gv_ctotal = gv_ctotal + gs_alv_100-bal_amt.
    ELSE. "차=대
      CLEAR: gs_alv_100-shkzg, gs_alv_100-bal_txt.
      gs_alv_100-bal_amt = 0.
    ENDIF.

*    "html
*    gv_dtotal = gv_dtotal + gs_alv_100-debit."차변 누계
*    gv_ctotal = gv_ctotal + gs_alv_100-credit. "대변 누계

    "잔액이 남아있는 계정 수
    IF gs_alv_100-bal_amt <> 0.
      gv_bal_cnt = gv_bal_cnt + 1.
    ENDIF.

    IF gv_waers IS INITIAL.
      gv_waers = gs_alv_100-waers.
    ENDIF.

    MODIFY gt_alv_100 FROM gs_alv_100.

  ENDLOOP.

*  "4. 조회 범위 내 전체 g/l계정 수
*  LOOP AT gt_glacc INTO gs_glacc.
*
*    IF gs_glacc-saknr IN so_saknr.
*      gv_al_cnt = gv_al_cnt + 1.
*    ENDIF.
*
*  ENDLOOP.

  "5. 체크 박스
  IF cb_unuse = 'X'.

    "거래 없는 계정도 추가
    LOOP AT gt_glacc INTO gs_glacc.

      IF gs_glacc-saknr NOT IN so_saknr.
        CONTINUE.
      ENDIF.

      READ TABLE gt_alv_100 WITH KEY saknr = gs_glacc-saknr
      TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.

        CLEAR gs_alv_100.

        gs_alv_100-saknr = gs_glacc-saknr.
        gs_alv_100-txt20 = gs_glacc-txt20.
        gs_alv_100-waers = gv_waers.

        APPEND gs_alv_100 TO gt_alv_100.

      ENDIF.

    ENDLOOP.

  ENDIF.

  SORT gt_alv_100 BY saknr.

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
      container_name              = 'CC_MAIN'
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

  "2. 상 하 분할
  CREATE OBJECT go_split_100
    EXPORTING
*     link_dynnr        =
*     link_repid        =
*     shellstyle        =
*     left    =
*     top     =
*     width   =
*     height  =
*     metric  = cntl_metric_dynpro
*     align   = 15
      parent  = go_cont_100
      rows    = 2
      columns = 1
*     no_autodef_progid_dynnr =
*     name    =
*    EXCEPTIONS
*     cntl_error        = 1
*     cntl_system_error = 2
*     others  = 3
    .
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "3. 상단 HTML영역
  CALL METHOD go_split_100->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_cont_html.

  "4. 하단 ALV 컨테이너
  CALL METHOD go_split_100->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_cont_alv_100.

  "5. html 뷰어 생성
  CREATE OBJECT go_html_viewer
    EXPORTING
*     shellstyle         =
      parent = go_cont_html
*     lifetime           = LIFETIME_DEFAULT
*     saphtmlp           =
*     uiflag =
*     end_session_with_browser = 0
*     name   =
*     saphttp            =
*     query_table_disabled = ''
*    EXCEPTIONS
*     cntl_error         = 1
*     cntl_install_error = 2
*     dp_install_error   = 3
*     dp_error           = 4
*     others = 5
    .
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "6. alv 생성하기
  CREATE OBJECT go_alv_100
    EXPORTING
      i_parent          = go_cont_alv_100 "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "상단 영역 높이 조절
  CALL METHOD go_split_100->set_row_height
    EXPORTING
      id     = 1
      height = 22
*    IMPORTING
*     result =
*    EXCEPTIONS
*     cntl_error        = 1
*     cntl_system_error = 2
*     others = 3
    .
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
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
FORM set_evt_handler_100.

  SET HANDLER:
                lcl_handler=>on_hotspot_click FOR go_alv_100.

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

  PERFORM set_grid_title_100.

*  "정렬
*  CLEAR gs_sort.
*  gs_sort-fieldname = 'VBELN'.
*  gs_sort-spos = 1.
*  gs_sort-up = 'X'.
*  INSERT gs_sort INTO TABLE gt_sort.

*  "신호등
*  gs_layout_100-excp_fname = 'LIGHT'.
*  gs_layout_100-excp_led   = 'X'.

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
  gs_fcat_100-fieldname = 'SAKNR'. "예외 컬럼 이름
  gs_fcat_100-coltext = 'G/L 계정'.
  gs_fcat_100-hotspot = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
*  gs_fcat-fieldname = 'ZZPAYST'.
  gs_fcat_100-fieldname = 'TXT20'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '계정명'.
  gs_fcat_100-outputlen = 13.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'DEBIT'.
  gs_fcat_100-coltext = '차변 누계금액'.
  gs_fcat_100-ref_field = 'DEBIT'.
  gs_fcat_100-cfieldname = 'WAERS'.
*  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 15.
  gs_fcat_100-do_sum = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'CREDIT'.
  gs_fcat_100-coltext = '대변 누계금액'.
  gs_fcat_100-ref_field = 'CREDIT'.
  gs_fcat_100-cfieldname = 'WAERS'.
*  gs_fcat_100-emphasize = 'C600'. "빨강
*  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 15.
  gs_fcat_100-do_sum = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'WAERS'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '통화'.
  gs_fcat_100-ref_field = 'WAERS'.
*  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 7.
  APPEND gs_fcat_100 TO gt_fcat_100.


  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BAL_TXT'.
*  gs_fcat_100-key = 'X'.
  gs_fcat_100-coltext = '잔액 구분'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BAL_AMT'.
  gs_fcat_100-coltext = '잔액'.
  gs_fcat_100-ref_field = 'BAL_AMT'.
  gs_fcat_100-cfieldname = 'WAERS'.
*  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 15.
*  gs_fcat_100-do_sum = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'WAERS'.
*  gs_fcat_top-key = 'X'.
  gs_fcat_100-coltext = '통화'.
  gs_fcat_100-ref_field = 'WAERS'.
*  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-outputlen = 7.
  APPEND gs_fcat_100 TO gt_fcat_100.

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
      it_outtab                     = gt_alv_100
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
*& Form create_objects_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_html .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_100
    EXPORTING
      container_name              = 'CC_MAIN'
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

  "2. HTML 뷰어 생성하기
  CREATE OBJECT go_html_viewer
    EXPORTING
*     shellstyle         =
      parent = go_cont_html
*     lifetime           = LIFETIME_DEFAULT
*     saphtmlp           =
*     uiflag =
*     end_session_with_browser = 0
*     name   =
*     saphttp            =
*     query_table_disabled = ''
*    EXCEPTIONS
*     cntl_error         = 1
*     cntl_install_error = 2
*     dp_install_error   = 3
*     dp_error           = 4
*     OTHERS = 5.
    .
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.

    MESSAGE a017(zmsg_139).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_html .

  DATA:
    lt_html       TYPE soli_tab,
    lv_url        TYPE c LENGTH 255,
    lv_dbal_total TYPE c LENGTH 30,
    lv_cbal_total TYPE c LENGTH 30.


  IF go_html_viewer IS NOT BOUND.
    RETURN.
  ENDIF.


  "--------------------------------------------------
  " 금액 포맷
  "--------------------------------------------------
  WRITE gv_dtotal TO lv_dbal_total CURRENCY gv_waers.
  WRITE gv_ctotal TO lv_cbal_total CURRENCY gv_waers.

  CONDENSE lv_dbal_total.
  CONDENSE lv_cbal_total.


  "--------------------------------------------------
  " HTML 시작
  "--------------------------------------------------
  APPEND '<html><head>' TO lt_html.
  APPEND '<style>' TO lt_html.

  APPEND
    'html,body{margin:0;padding:0;overflow:hidden;background:#FFFFFF;}'
    TO lt_html.

  APPEND
    'body{font-family:Malgun Gothic,Arial,sans-serif;}'
    TO lt_html.

  APPEND '</style></head>' TO lt_html.
  APPEND '<body>' TO lt_html.


  "--------------------------------------------------
  " 제목
  "--------------------------------------------------
  APPEND
    '<div style="margin-left:20px;margin-top:8px;margin-bottom:5px;'
    TO lt_html.

  APPEND
    'font-size:14px;font-weight:bold;color:#263547;">G/L 계정 잔액 요약</div>'
    TO lt_html.


  "--------------------------------------------------
  " 카드 4개 - 왼쪽 정렬
  "--------------------------------------------------
  APPEND
    '<table border="0" cellspacing="8" cellpadding="0" style="margin-left:15px;">'
    TO lt_html.

  APPEND '<tr>' TO lt_html.


  "--------------------------------------------------
  " 1. 거래발생 계정
  "--------------------------------------------------
  APPEND '<td>' TO lt_html.

  APPEND
    '<div style="width:170px;height:65px;border:1px solid #DAE0E7;'
    TO lt_html.

  APPEND
    'border-radius:8px;background:#FFFFFF;text-align:center;overflow:hidden;">'
    TO lt_html.

  APPEND
    '<div style="font-size:12px;color:#738198;line-height:19px;">거래발생 계정</div>'
    TO lt_html.

  APPEND
    |<div style="font-size:20px;font-weight:bold;color:#263547;line-height:26px;">{ gv_used_cnt } 개</div>|
    TO lt_html.

  APPEND
    '<div style="font-size:10px;color:#98A2B3;line-height:14px;">전표 발생 기준</div>'
    TO lt_html.

  APPEND '</div></td>' TO lt_html.


  "--------------------------------------------------
  " 2. 잔액보유 계정
  "--------------------------------------------------
  APPEND '<td>' TO lt_html.

  APPEND
    '<div style="width:170px;height:65px;border:1px solid #DAE0E7;'
    TO lt_html.

  APPEND
    'border-radius:8px;background:#FFFFFF;text-align:center;overflow:hidden;">'
    TO lt_html.

  APPEND
    '<div style="font-size:12px;color:#738198;line-height:19px;">잔액보유 계정</div>'
    TO lt_html.

  APPEND
    |<div style="font-size:20px;font-weight:bold;color:#263547;line-height:26px;">{ gv_bal_cnt } 개</div>|
    TO lt_html.

  APPEND
    '<div style="font-size:10px;color:#98A2B3;line-height:14px;">현재잔액 존재</div>'
    TO lt_html.

  APPEND '</div></td>' TO lt_html.


  "--------------------------------------------------
  " 3. 차변잔액 합계
  "--------------------------------------------------
  APPEND '<td>' TO lt_html.

  APPEND
    '<div style="width:210px;height:65px;border:1px solid #AFC7E8;'
    TO lt_html.

  APPEND
    'border-radius:8px;background:#EEF5FC;text-align:center;overflow:hidden;">'
    TO lt_html.

  APPEND
    '<div style="font-size:12px;color:#5B7394;line-height:19px;">차변잔액 합계</div>'
    TO lt_html.

  APPEND
    |<div style="font-size:18px;font-weight:bold;color:#355C8A;line-height:26px;">{ lv_dbal_total }</div>|
    TO lt_html.

  APPEND
    |<div style="font-size:10px;color:#7890AC;line-height:14px;">{ gv_waers }</div>|
    TO lt_html.

  APPEND '</div></td>' TO lt_html.


  "--------------------------------------------------
  " 4. 대변잔액 합계
  "--------------------------------------------------
  APPEND '<td>' TO lt_html.
*  "빨강
*  APPEND
*    '<div style="width:210px;height:65px;border:1px solid #E2B8B8;'
*    TO lt_html.
*
*  APPEND
*    'border-radius:8px;background:#FCF0F0;text-align:center;overflow:hidden;">'
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:12px;color:#936060;line-height:19px;">대변잔액 합계</div>'
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:18px;font-weight:bold;color:#9A4444;line-height:26px;">{ lv_cbal_total }</div>|
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:10px;color:#A97A7A;line-height:14px;">{ gv_waers }</div>|
*    TO lt_html.
*
*  APPEND '</div></td>' TO lt_html.

  "주황
  APPEND
  '<div style="width:210px;height:65px;border:1px solid #E3C98B;'
  TO lt_html.

  APPEND
    'border-radius:8px;background:#FFF8E8;text-align:center;overflow:hidden;">'
    TO lt_html.

  APPEND
    '<div style="font-size:12px;color:#8A6A2F;line-height:19px;">대변잔액 합계</div>'
    TO lt_html.

  APPEND
    |<div style="font-size:18px;font-weight:bold;color:#9A6A14;line-height:26px;">{ lv_cbal_total }</div>|
    TO lt_html.

  APPEND
    |<div style="font-size:10px;color:#A88A51;line-height:14px;">{ gv_waers }</div>|
    TO lt_html.

  APPEND '</tr></table>' TO lt_html.
  APPEND '</body></html>' TO lt_html.


  "--------------------------------------------------
  " HTML 데이터 등록
  "--------------------------------------------------
  CALL METHOD go_html_viewer->load_data
    EXPORTING
      type         = 'text'
      subtype      = 'html'
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html.


  IF sy-subrc <> 0.
    RETURN.
  ENDIF.


  "--------------------------------------------------
  " HTML 출력
  "--------------------------------------------------
  CALL METHOD go_html_viewer->show_url
    EXPORTING
      url = lv_url.

*ENDFORM.
*
*  DATA:
*    lt_html   TYPE soli_tab,
*    lv_url    TYPE c LENGTH 255,
*    lv_dtotal TYPE c LENGTH 30,
*    lv_ctotal TYPE c LENGTH 30.
*
*
*  "HTML Viewer가 생성되지 않은 경우
*  IF go_html_viewer IS NOT BOUND.
*    RETURN.
*  ENDIF.
*
*
*  "--------------------------------------------------
*  " 금액 포맷
*  "--------------------------------------------------
*  WRITE gv_dtotal TO lv_dtotal CURRENCY gv_waers.
*  WRITE gv_ctotal TO lv_ctotal CURRENCY gv_waers.
*
*  CONDENSE lv_dtotal.
*  CONDENSE lv_ctotal.
*
*
*  "--------------------------------------------------
*  " HTML 시작
*  "--------------------------------------------------
*  APPEND '<html><head>' TO lt_html.
*
*  APPEND '<style>' TO lt_html.
*
*  APPEND
*    'html,body{margin:0;padding:0;overflow:hidden;background:#FFFFFF;}'
*    TO lt_html.
*
*  APPEND
*    'body{font-family:Malgun Gothic,Arial,sans-serif;}'
*    TO lt_html.
*
*  APPEND '</style></head>' TO lt_html.
*
*  APPEND '<body>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " 카드 4개 배치
*  "--------------------------------------------------
*  APPEND
**    '<table border="0" align="center" cellspacing="10" cellpadding="0">'
**    TO lt_html.
**  '<table width="100%" border="0" cellspacing="5" cellpadding="0">'
**  TO lt_html.
*  '<table border="0" cellspacing="10" cellpadding="0" style="margin-left:20px;">'
*  TO lt_html.
*
*  APPEND '<tr>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " 1. 전체 G/L 계정
*  "--------------------------------------------------
*  APPEND '<td>' TO lt_html.
**  APPEND '<td width="25%" align="center">' TO lt_html.
*
**  APPEND
**    '<div style="width:140px;height:70px;border:1px solid #DAE0E7;'
**    TO lt_html.
*
*  APPEND
*  '<div style="width:220px;height:70px;border:1px solid #DAE0E7;'
*  TO lt_html.
*
*  APPEND
*    'border-radius:10px;background:#FFFFFF;text-align:center;overflow:hidden;">'
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:12px;color:#738198;line-height:20px;">전체 G/L 계정</div>'
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:20px;font-weight:bold;color:#263547;line-height:27px;">{ gv_al_cnt } 개</div>|
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:10px;color:#98A2B3;line-height:15px;">조회 대상 계정</div>'
*    TO lt_html.
*
*  APPEND '</div></td>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " 2. 거래발생 계정
*  "--------------------------------------------------
*  APPEND '<td>' TO lt_html.
**  APPEND '<td width="25%" align="center">' TO lt_html.
*
**  APPEND
**    '<div style="width:140px;height:70px;border:1px solid #DAE0E7;'
**    TO lt_html.
*
*  APPEND
*  '<div style="width:220px;height:70px;border:1px solid #DAE0E7;'
*  TO lt_html.
*
*  APPEND
*    'border-radius:10px;background:#FFFFFF;text-align:center;overflow:hidden;">'
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:12px;color:#738198;line-height:20px;">거래발생 계정</div>'
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:20px;font-weight:bold;color:#263547;line-height:27px;">{ gv_used_cnt } 개</div>|
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:10px;color:#98A2B3;line-height:15px;">전표 발생 계정</div>'
*    TO lt_html.
*
*  APPEND '</div></td>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " 3. 차변 누계
*  "--------------------------------------------------
*  APPEND '<td>' TO lt_html.
**  APPEND '<td width="25%" align="center">' TO lt_html.
*
**  APPEND
**    '<div style="width:170px;height:70px;border:1px solid #DAE0E7;'
**    TO lt_html.
*
**  "색 없는 버전
**  APPEND
**  '<div style="width:220px;height:70px;border:1px solid #DAE0E7;'
**  TO lt_html.
**
**  APPEND
**    'border-radius:10px;background:#FFFFFF;text-align:center;overflow:hidden;">'
**    TO lt_html.
*
*  APPEND
*    '<div style="width:210px;height:70px;border:1px solid #B8CCE4;'
*    TO lt_html.
*
*  APPEND
*    'border-radius:10px;background:#EEF5FC;text-align:center;overflow:hidden;">'
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:12px;color:#738198;line-height:20px;">차변 누계</div>'
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:18px;font-weight:bold;color:#263547;line-height:27px;">{ lv_dtotal }</div>|
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:10px;color:#98A2B3;line-height:15px;">{ gv_waers }</div>|
*    TO lt_html.
*
*  APPEND '</div></td>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " 4. 대변 누계
*  "--------------------------------------------------
*  APPEND '<td>' TO lt_html.
**  APPEND '<td width="25%" align="center">' TO lt_html.
*
**  APPEND
**    '<div style="width:170px;height:70px;border:1px solid #DAE0E7;'
**    TO lt_html.
*
**  "색 없는 버전
**  APPEND
**  '<div style="width:220px;height:70px;border:1px solid #DAE0E7;'
**  TO lt_html.
**
**  APPEND
**    'border-radius:10px;background:#FFFFFF;text-align:center;overflow:hidden;">'
**    TO lt_html.
*
*  APPEND
*  '<div style="width:210px;height:70px;border:1px solid #E4B8B8;'
*  TO lt_html.
*
*  APPEND
*    'border-radius:10px;background:#FCF0F0;text-align:center;overflow:hidden;">'
*    TO lt_html.
*
*  APPEND
*    '<div style="font-size:12px;color:#738198;line-height:20px;">대변 누계</div>'
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:18px;font-weight:bold;color:#263547;line-height:27px;">{ lv_ctotal }</div>|
*    TO lt_html.
*
*  APPEND
*    |<div style="font-size:10px;color:#98A2B3;line-height:15px;">{ gv_waers }</div>|
*    TO lt_html.
*
*  APPEND '</div></td>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " HTML 종료
*  "--------------------------------------------------
*  APPEND '</tr></table>' TO lt_html.
*  APPEND '</body></html>' TO lt_html.
*
*
*  "--------------------------------------------------
*  " HTML 데이터 등록
*  "--------------------------------------------------
*  go_html_viewer->load_data(
*    EXPORTING
*      type         = 'text'
*      subtype      = 'html'
*    IMPORTING
*      assigned_url = lv_url
*    CHANGING
*      data_table   = lt_html
*  ).
*
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*
*  "--------------------------------------------------
*  " HTML 출력
*  "--------------------------------------------------
*  go_html_viewer->show_url(
*    EXPORTING
*      url = lv_url
*  ).
*

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

  DESCRIBE TABLE gt_alv_100 LINES lv_count.

  gs_layout_100-grid_title = |계정별 잔액 현황 - 전체 ({ lv_count }건)|.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_alv_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_alv_200 .

  DATA lv_bal TYPE z8fi_accdoc_i-wrbtr.

  CLEAR: gt_alv_200[], gs_alv_200, lv_bal.

  SORT gt_gl_detail BY budat belnr buzei.

  LOOP AT gt_gl_detail INTO gs_gl_detail WHERE hkont = gs_gl_sel-saknr.

    "전기일자 조회조건
    IF gv_budat_fr IS NOT INITIAL AND gv_budat_to IS INITIAL.
      IF gs_gl_detail-budat <> gv_budat_fr.
        CONTINUE.
      ENDIF.
    ELSEIF gv_budat_fr IS NOT INITIAL AND gv_budat_to IS NOT INITIAL.
      IF gs_gl_detail-budat < gv_budat_fr OR gs_gl_detail-budat > gv_budat_to.
        CONTINUE.
      ENDIF.
    ENDIF.


    "전표유형
    IF gv_blart IS NOT INITIAL
      AND gs_gl_detail-blart <> gv_blart.
      CONTINUE.
    ENDIF.

    "지사 조회조건
    IF gv_bupla IS NOT INITIAL AND gs_gl_detail-bupla <> gv_bupla.
        CONTINUE.
    ENDIF.

*    "전기일자 조회조건
*    IF gv_budat_fr IS NOT INITIAL AND gv_budat_to IS INITIAL.
*      IF gs_gl_detail-budat <> gv_budat_fr.
*        CONTINUE.
*      ENDIF.
*    ELSEIF gv_budat_fr IS NOT INITIAL AND gv_budat_to IS NOT INITIAL.
*      IF gs_gl_detail-budat < gv_budat_fr OR gs_gl_detail-budat > gv_budat_to.
*        CONTINUE.
*      ENDIF.
*    ENDIF.

    CLEAR gs_alv_200.

    gs_alv_200-bukrs = gs_gl_detail-bukrs.
    gs_alv_200-gjahr = gs_gl_detail-gjahr.
    gs_alv_200-budat = gs_gl_detail-budat.
    gs_alv_200-belnr = gs_gl_detail-belnr.
    gs_alv_200-blart = gs_gl_detail-blart.
    gs_alv_200-xblnr = gs_gl_detail-xblnr.
    gs_alv_200-bupla = gs_gl_detail-bupla.
    gs_alv_200-shkzg = gs_gl_detail-shkzg.
    gs_alv_200-waers = gs_gl_detail-waers.

    SELECT SINGLE ltext
      FROM t003t
      INTO gs_alv_200-blart_txt
      WHERE spras = sy-langu
      AND blart = gs_gl_detail-blart.

      IF sy-subrc <> 0.
        CLEAR gs_alv_200-blart_txt.
      ENDIF.

    SELECT SINGLE name
      FROM z8branch_m
      INTO gs_alv_200-bupla_txt
      WHERE bukrs = gc_bukrs
      AND branch = gs_gl_detail-bupla.

    IF sy-subrc <> 0.
      CLEAR gs_alv_200-bupla_txt.
    ENDIF.

    IF gs_gl_detail-shkzg = 'S'.
      gs_alv_200-shkzg_txt = '차변'.
      gs_alv_200-debit = gs_gl_detail-wrbtr.
      CLEAR gs_alv_200-credit.
      "차변 금액은 증가
      lv_bal = lv_bal + gs_gl_detail-wrbtr.
    ELSEIF gs_gl_detail-shkzg = 'H'.
      gs_alv_200-shkzg_txt = '대변'.
      gs_alv_200-credit = gs_gl_detail-wrbtr.
      CLEAR gs_alv_200-debit.
      "대변 금액은 감소
      lv_bal = lv_bal - gs_gl_detail-wrbtr.
    ENDIF.

    "누적 잔액
    gs_alv_200-bal_amt = lv_bal.

    CLEAR gs_alv_200-bal_txt.

    WRITE lv_bal TO gs_alv_200-bal_txt CURRENCY gs_gl_detail-waers.

    CALL FUNCTION 'CLOI_PUT_SIGN_IN_FRONT'
      CHANGING
        value         = gs_alv_200-bal_txt.

    APPEND gs_alv_200 TO gt_alv_200.

  ENDLOOP.

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
      container_name              = 'CC_200'
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

  gs_layout_200-zebra = 'X'.
  gs_layout_200-stylefname = 'CT'.

  PERFORM set_grid_title_200.

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
  gs_fcat_200-fieldname = 'BUDAT'.
  gs_fcat_200-coltext = '전기일자'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BELNR'.
  gs_fcat_200-coltext = '전표번호'.
*  gs_fcat_200-hotspot = 'X'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BLART'.
  gs_fcat_200-coltext = '전표유형'.
  gs_fcat_200-outputlen = 5.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BLART_TXT'.
  gs_fcat_200-coltext = '전표유형명'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'XBLNR'.
  gs_fcat_200-coltext = '참조번호'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BUPLA'.
  gs_fcat_200-coltext = '지사'.
  gs_fcat_200-outputlen = 6.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BUPLA_TXT'.
  gs_fcat_200-coltext = '지사명'.
  APPEND gs_fcat_200 TO gt_fcat_200.

*  CLEAR gs_fcat_200.
*  gs_fcat_200-fieldname = 'BNAME'.
*  gs_fcat_200-coltext = '지사명'.
*  INSERT gs_fcat_200 INTO TABLE gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'SHKZG_TXT'.
  gs_fcat_200-coltext = '차/대'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'DEBIT'.
  gs_fcat_200-coltext = '차변금액'.
  gs_fcat_200-ref_field = 'DEBIT'.
  gs_fcat_200-cfieldname = 'WAERS'.
*  gs_fcat_200-emphasize = 'C311'.
  gs_fcat_200-do_sum = 'X'.
  gs_fcat_200-outputlen = 16.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'CREDIT'.
  gs_fcat_200-coltext = '대변금액'.
  gs_fcat_200-ref_field = 'CREDIT'.
  gs_fcat_200-cfieldname = 'WAERS'.
*  gs_fcat_200-emphasize = 'C311'.
  gs_fcat_200-do_sum = 'X'.
  gs_fcat_200-outputlen = 16.
  APPEND gs_fcat_200 TO gt_fcat_200.

*  CLEAR gs_fcat_200.
*  gs_fcat_200-fieldname = 'BAL_TXT'.
*  gs_fcat_200-coltext = '잔액 구분'.
*  INSERT gs_fcat_200 INTO TABLE gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BAL_TXT'.
  gs_fcat_200-coltext = '누적잔액'.
  gs_fcat_200-outputlen = 16.
  gs_fcat_200-just = 'R'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'WAERS'.
  gs_fcat_200-coltext = '통화'.
*  gs_fcat_200-emphasize = 'C311'.
  APPEND gs_fcat_200 TO gt_fcat_200.

*  CLEAR gs_fcat_200.
*  gs_fcat_200-fieldname = 'AUGDT'.
*  gs_fcat_200-coltext = '반제일자'.
*  gs_fcat_200-do_sum = 'X'.
*  INSERT gs_fcat_200 INTO TABLE gt_fcat_200.
*
*  CLEAR gs_fcat_200.
*  gs_fcat_200-fieldname = 'AUGBL'.
*  gs_fcat_200-coltext = '반제전표번호'.
*  gs_fcat_200-hotspot = 'X'.
*  INSERT gs_fcat_200 INTO TABLE gt_fcat_200.

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
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
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
      it_outtab                     = gt_alv_200
      it_fieldcatalog               = gt_fcat_200
*     it_sort                       = gt_sort
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

  CLEAR: go_alv_200, go_cont_200, gt_alv_200[], gs_alv_200. "clear 대신 free써도 됨

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_200 .

  "alv 그리드 제목
  DATA lv_count TYPE i.

  DESCRIBE TABLE gt_alv_200 LINES lv_count.

  gs_layout_200-grid_title = |{ gs_gl_sel-saknr } { gs_gl_sel-txt20 } 원장 상세 - 전체  ({ lv_count }건)|.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form init_condition_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_condition_200 .

  CLEAR:
*  gv_bupla_fr,
*  gv_bupla_to,
*  gv_bupla_fix,
  gv_bupla,
  gv_buplat,
  gv_budat_fr,
  gv_budat_to,
  gv_blart.

  DATA:
    lv_monat_fr TYPE z8fi_accdoc_h-monat,
    lv_monat_to TYPE z8fi_accdoc_h-monat,
    lv_lastday  TYPE sy-datum.

  "전기 일자에 대한 내용
  READ TABLE so_monat INDEX 1.

  IF sy-subrc = 0.

    "회계월 단일값
    IF so_monat-sign = 'I'
      AND so_monat-option = 'EQ'.

      lv_monat_fr = so_monat-low.
      lv_monat_to = so_monat-low.

      "회계월 범위
    ELSEIF so_monat-sign = 'I'
      AND so_monat-option = 'BT'.

      lv_monat_fr = so_monat-low.
      lv_monat_to = so_monat-high.

    ENDIF.

    "시작일 = 시작월 1일
    CONCATENATE pa_gjahr
                lv_monat_fr
                '01'
           INTO gv_budat_fr.


    "종료월이 현재 연도/현재 월이면 오늘 날짜
    IF pa_gjahr = sy-datum+0(4)
      AND lv_monat_to = sy-datum+4(2).

      gv_budat_to = sy-datum.

    ELSE.

      "과거 월이면 해당 월의 마지막 일자
      CONCATENATE pa_gjahr
                  lv_monat_to
                  '01'
             INTO lv_lastday.

      CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
        EXPORTING
          day_in            = lv_lastday
        IMPORTING
          last_day_of_month = gv_budat_to.

    ENDIF.

  ENDIF.

*  "지사에 대한 내용
*  READ TABLE so_bran INDEX 1.
*
*  IF sy-subrc = 0.
*
*    "1000번에서 지사 1건만 조회
*    IF so_bran-sign = 'I' AND so_bran-option = 'EQ'.
*      gv_bupla_fr = so_bran-low.
*      gv_bupla_fix = 'X'.
*
*    ELSEIF so_bran-sign = 'I' AND so_bran-option = 'BT'.
*      gv_bupla_fr = so_bran-low.
*      gv_bupla_to = so_bran-high.
**      gv_bupla_fix = 'X'.
*
*    ENDIF.
*  ELSE.
*    "1000번에서 지사 입력 x -> 전체 지사 검색
*    gv_bupla_fr = 'B001'.
*    gv_bupla_to = 'B004'.
*
*  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_condition_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_condition_200 .

  CLEAR gv_error.

  "전기일자 범위 확인
  "1) 전기일자 미입력
  IF gv_budat_fr IS INITIAL AND gv_budat_to IS INITIAL.
    MESSAGE s121(z8_msg) DISPLAY LIKE 'E' WITH '전기일자는'. "필수 입력

    gv_error = 'X'.
    RETURN.
  ENDIF.

  "2) 종료값만 입력한 경우
  IF gv_budat_fr IS INITIAL AND gv_budat_to IS NOT INITIAL.
    MESSAGE s124(z8_msg) DISPLAY LIKE 'E'. "시작일을 입력해주세요

    gv_error = 'X'.
    RETURN.
  ENDIF.

  "3) 시작>종료
  IF gv_budat_fr IS NOT INITIAL
    AND gv_budat_to IS NOT INITIAL
    AND gv_budat_fr > gv_budat_to.
    MESSAGE s144(z8_msg) DISPLAY LIKE 'E' WITH '전기일자'. "'전기일자 조회 범위를 확인해주세요.'

    gv_error = 'X'.
    RETURN.
  ENDIF.

  "4) 최초 조회기간 밖의 날짜 입력 x
  IF gv_budat_fr IS NOT INITIAL AND gv_budat_fr < gv_org_budat_fr.
    MESSAGE s143(z8_msg) DISPLAY LIKE 'E' WITH '전기일자'. "기존의 조회범위를 벗어난

    gv_error = 'X'.
    RETURN.
  ENDIF.

  IF gv_budat_to IS NOT INITIAL AND gv_budat_to > gv_org_budat_to.
    MESSAGE s143(z8_msg) DISPLAY LIKE 'E' WITH '전기일자'. "기존의 조회범위를 벗어난

    gv_error = 'X'.
    RETURN.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_200 .

  "200번 조회조건으로 데이터 다시 조회
  PERFORM make_alv_200.
  PERFORM set_cell_style_200.

  "alv 제목 재설정
  PERFORM set_grid_title_200.

  CALL METHOD go_alv_200->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_200-grid_title.

  gs_stable-row = 'X'.
  gs_stable-col = 'X'.

  CALL METHOD go_alv_200->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh = ' '
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
    MESSAGE s147(Z8_MSG) DISPLAY LIKE 'E'. "데이터 갱신 중 오류 발생
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler_200 .

  SET HANDLER:
                lcl_handler=>on_hotspot_200 FOR go_alv_200.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_200 .

  DATA ls_ct TYPE lvc_s_styl.

  LOOP AT gt_alv_200 ASSIGNING FIELD-SYMBOL(<fs_alv>).

    CLEAR <fs_alv>-ct.

    "belnr이 있는 셀만 Hotspot
    IF <fs_alv>-belnr IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'BELNR'.
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
*& Form set_default_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_default_data .

  pa_gjahr = sy-datum+0(4).

  CLEAR so_monat.
  so_monat-sign = 'I'.
  so_monat-option = 'BT'.
  so_monat-low = '01'.
  so_monat-high = sy-datum+4(2).
  APPEND so_monat.

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

  DATA:
        lv_gjahr TYPE z8fi_accdoc_h-gjahr,
        lv_monat TYPE z8fi_accdoc_h-monat.

  lv_gjahr = sy-datum(4).
  lv_monat = sy-datum+4(2).

  IF sscrfields-ucomm = 'ONLI'.

    "회계월 조건 자체가 없는 경우
    IF so_monat[] IS INITIAL.
      SET CURSOR FIELD 'SO_MONAT-LOW'.
      MESSAGE e121(z8_msg) WITH '회계월은'.
    ENDIF.

    "종료월만 입력한 경우
    IF so_monat-low IS INITIAL
      AND so_monat-high IS NOT INITIAL.

      SET CURSOR FIELD 'SO_MONAT-LOW'.
      MESSAGE e124(z8_msg).    "시작일을 입력해주세요.
    ENDIF.

    "시작월 범위 확인
    IF so_monat-low IS NOT INITIAL
      AND ( so_monat-low < '01'
         OR so_monat-low > '12' ).

      SET CURSOR FIELD 'SO_MONAT-LOW'.
      MESSAGE e132(z8_msg)."'회계월은 01부터 12까지만 입력할 수 있습니다.'
    ENDIF.

    "종료월 범위 확인
    IF so_monat-high IS NOT INITIAL
      AND ( so_monat-high < '01'
         OR so_monat-high > '12' ).

      SET CURSOR FIELD 'SO_MONAT-HIGH'.
      MESSAGE e132(z8_msg)."'회계월은 01부터 12까지만 입력할 수 있습니다.'
    ENDIF.

    "미래 회계연도 입력 x
    IF pa_gjahr > lv_gjahr.
      SET CURSOR FIELD 'PA_GJAHR'.
      MESSAGE e144(Z8_MSG) WITH '회계연도'. "회계연도 조회 범위를 확인해주세요
    ENDIF.

    "현재 회계연도의 현재 월 이후 입력 x
    IF pa_gjahr = lv_gjahr.
      "시작월 확인
      IF so_monat-low > lv_monat.
        SET CURSOR FIELD 'SO_MONAT-LOW'.
        MESSAGE e144(Z8_MSG) WITH '회계월'. "회계월 조회 범위를 확인해주세요
      ENDIF.

      "종료월 확인
      IF so_monat-high IS NOT INITIAL AND so_monat-high > lv_monat.
        SET CURSOR FIELD 'SO_MONAT-HIGH'.
        MESSAGE e144(Z8_MSG) WITH '회계월'."회계월 조회 범위를 확인해주세요
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_org_condition_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_org_condition_200 .

  "전기일자 최초 범위
  gv_org_budat_fr = gv_budat_fr.
  gv_org_budat_to = gv_budat_to.


ENDFORM.
