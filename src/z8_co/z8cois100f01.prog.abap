*&---------------------------------------------------------------------*
*& Include          Z8COIS100F01
*&---------------------------------------------------------------------*

FORM create_alv.
  IF go_chart_container IS INITIAL.

    " 1. 전체 하단 도킹 컨테이너 생성 (비율 90%)
    CREATE OBJECT go_chart_container
      EXPORTING
        repid = sy-repid
        dynnr = sy-dynnr
        side  = cl_gui_docking_container=>dock_at_bottom
        ratio = 90.

    " 2. 스플리터 컨테이너 생성 (1행 2열)
    CREATE OBJECT go_split
      EXPORTING
        parent  = go_chart_container
        rows    = 2
        columns = 1.

    " 4. 상단 컨테이너 추출 (막대 그래프용)
    DATA(lo_left_container) = go_split->get_container(
      EXPORTING
          row    = 2
          column = 1
    ).

    " 5. 하단  컨테이너 추출 (Tree ALV용 - 스크린 페인터 불필요!)
    DATA(lo_right_container) = go_split->get_container(
      EXPORTING
          row    = 1
          column = 1
    ).

    " --- [A조각] 상단: 막대 그래프 생성 ---
    CREATE OBJECT go_chart
      EXPORTING
        parent = lo_left_container.

    CALL METHOD go_chart_container->set_visible( EXPORTING visible = abap_true ).
    go_ixml = cl_ixml=>create( ).
    go_ixml_sf = go_ixml->create_stream_factory( ).


    " --- [B조각] 하단: Tree ALV 생성 ---
    " 기존의 go_custom_container(SE51 연동) 대신 lo_right_container를 parent로 바로 전달합니다!
    CREATE OBJECT go_alv_tree
      EXPORTING
        parent              = lo_right_container  " ★ 핵심: 스플리터 우측 컨테이너 연결
        node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
        item_selection      = 'X'
        no_html_header      = 'X'
        no_toolbar          = 'X'.

    " 필드 카탈로그 및 레이아웃 세팅
    PERFORM change_field_catalog USING 'ty_matdoc_i'
        'LIGHT, ORG_NAME, GROSS_STATUS, SALES_TXT, COGS_TXT, GROSS_TXT, SGA_TXT, OP_TXT, WAERK'
        '상태, 지사, 수익성, 매출액, 매출 원가, 매출 총 이익, 판관비, 영업 이익, 통화'
      CHANGING gt_fcat.

    PERFORM build_layout         CHANGING gs_layout.

    "DATA: lt_empty_table TYPE STANDARD TABLE OF ty_profit_data.
    DATA: lv_hierarchy_header TYPE treev_hhdr.
    lv_hierarchy_header-heading = '조직 및 프로젝트'.
    lv_hierarchy_header-width   = 30.

    CALL METHOD go_alv_tree->set_table_for_first_display
      EXPORTING
        is_hierarchy_header = lv_hierarchy_header
      CHANGING
        it_outtab           = gt_outtab " lt_empty_table
        it_fieldcatalog     = gt_fcat.

    " 트리 노드 데이터 채우기
    PERFORM create_tree_nodes.

    " 이벤트 등록 (링크 클릭 등)
    DATA: lt_events TYPE cntl_simple_events,
          ls_event  TYPE cntl_simple_event.

    go_alv_tree->get_registered_events( IMPORTING events = lt_events ).
    ls_event-eventid = cl_gui_column_tree=>eventid_link_click.
    APPEND ls_event TO lt_events.
    go_alv_tree->set_registered_events( EXPORTING events = lt_events ).

    SET HANDLER lcl_event_receiver=>handle_link_click FOR go_alv_tree.

    CALL METHOD go_alv_tree->frontend_update.
  ENDIF.

  " --- 막대 그래프 데이터 렌더링 로직 (기존과 동일) ---

  " 1. s_date(YYYYMMDD)에서 시작/종료 연도 및 월 추출
  READ TABLE s_date INTO DATA(ls_date) INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  DATA(lv_start_year) = ls_date-low(4).
  DATA(lv_end_year)   = ls_date-high(4).

  " [핵심 수정 1] 일반 나눗셈(/) 대신 몫 연산자(DIV)를 사용하여 반올림 오류 방지
  " 예: 9월 -> (9 - 1) DIV 3 + 1 = 8 DIV 3 + 1 = 2 + 1 = 3분기 (정확함!)
  DATA(lv_start_month) = CONV i( ls_date-low+4(2) ).
  DATA(lv_end_month)   = CONV i( ls_date-high+4(2) ).
  DATA(lv_start_qtr)   = ( lv_start_month - 1 ) DIV 3 + 1.
  DATA(lv_end_qtr)     = ( lv_end_month - 1 ) DIV 3 + 1.

  " 2. 연도 범위로 1차 DB 데이터 넓게 조회
  CLEAR gt_sales_rev.
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE gt_sales_rev
    FROM z8co_sum_qtr
    WHERE gjahr BETWEEN lv_start_year AND lv_end_year.

  IF sy-subrc <> 0.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  " 시작 연도의 시작 분기 이전 데이터 삭제
  DELETE gt_sales_rev WHERE gjahr = lv_start_year AND quart < lv_start_qtr.

  " 종료 연도의 종료 분기 이후 데이터 삭제
  DELETE gt_sales_rev WHERE gjahr = lv_end_year   AND quart > lv_end_qtr.

  PERFORM create_xml.
  PERFORM create_chart.

  IF sy-subrc <> 0.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM create_customizing_xml.

  go_ostream = go_ixml_sf->create_ostream_xstring( xdata ).
  go_ixml_data_doc->render( ostream = go_ostream ).
  go_chart->set_customizing( xdata = gv_cust_xml ).
  go_chart->set_data( xdata = xdata ).
  go_chart->render( ).

  CALL METHOD cl_gui_cfw=>flush.
ENDFORM.

FORM build_layout  CHANGING p_gs_layout TYPE lvc_s_layo.
  CLEAR p_gs_layout.
  p_gs_layout-grid_title = '손익 계산서'.
  p_gs_layout-sel_mode = 'D'.
  p_gs_layout-zebra = 'X'.
  p_gs_layout-excp_fname = 'LIGHT'.
  p_gs_layout-excp_led = 'X'.
ENDFORM.

FORM create_xml .
  " 1. 기존 XML 문서 및 스트림 초기화 (이전 차트의 잔상 및 메모리 누적 방지)
  CLEAR: go_ixml_data_doc, go_ostream, go_encoding.

  " 2. XML 문자열 및 전역 노드 변수 초기화
  CLEAR: xdata, root, categories, sales_amt, gross_prof, buis_prof.

  " 3. 새로운 빈 XML 생성
  go_ixml_data_doc = go_ixml->create_document( ).

  " 4. XML 인코딩 타입 설정
  go_encoding = go_ixml->create_encoding(
    byte_order = if_ixml_encoding=>co_little_endian
    character_set = 'utf_8'
  ).
  go_ixml_data_doc->set_encoding( go_encoding ).
ENDFORM.

FORM create_chart .
  root = go_ixml_data_doc->create_simple_element(
           name      = 'ChartData'
           parent    = go_ixml_data_doc
         ).

  categories = go_ixml_data_doc->create_simple_element(
           name      = 'Categories'
           parent    = root
         ).

  sales_amt = go_ixml_data_doc->create_simple_element(
           name      = 'Series'
           parent    = root
         ).

  gross_prof = go_ixml_data_doc->create_simple_element(
           name      = 'Series'
           parent    = root
         ).

  buis_prof = go_ixml_data_doc->create_simple_element(
           name      = 'Series'
           parent    = root
         ).

  sales_amt->set_attribute( name = 'label' value = |매출 총액| ).
  sales_amt->set_attribute( name = 'customizing' value = 'Series1' ).

  gross_prof->set_attribute( name = 'label' value = |매출 총이익| ).
  gross_prof->set_attribute( name = 'customizing' value = 'Series2' ).

  buis_prof->set_attribute( name = 'label' value = |영업 이익| ).
  buis_prof->set_attribute( name = 'customizing' value = 'Series3' ).
ENDFORM.

FORM get_data .
  " 1. 데이터를 합산하여 담을 임시 인터널 테이블과 워크에어리어 선언
  DATA: lt_sum_rev LIKE gt_sales_rev,
        ls_sum_rev LIKE gs_sales_rev.
  CLEAR lt_sum_rev.

  " 3. 분기별 데이터 합산 (COLLECT 활용)
  LOOP AT gt_sales_rev INTO gs_sales_rev.
    CLEAR ls_sum_rev.

    " 합산의 기준이 될 키(Key) 필드만 옮겨 담습니다. (BUPLA는 제외)
    ls_sum_rev-gjahr = gs_sales_rev-gjahr.
    ls_sum_rev-quart = gs_sales_rev-quart.

    " 합산할 금액 필드를 옮겨 담습니다.
    ls_sum_rev-sales_amt = gs_sales_rev-sales_amt.
    ls_sum_rev-gross_prof  = gs_sales_rev-gross_prof.
    ls_sum_rev-buis_prof  = gs_sales_rev-buis_prof.

    IF gs_sales_rev-waers = 'KRW'.
      " 한화 보정 x100.
      ls_sum_rev-sales_amt *= 100.
      ls_sum_rev-gross_prof  *= 100.
      ls_sum_rev-buis_prof  *= 100.
    ELSE.

    ENDIF.

    " COLLECT: 키(gjahr, quart)가 같으면 금액 필드들을 자동으로 누적 합산(SUM)합니다.
    COLLECT ls_sum_rev INTO lt_sum_rev.
  ENDLOOP.

  SORT lt_sum_rev BY gjahr ASCENDING quart ASCENDING.

  " 4. 합산이 완료된 임시 테이블(lt_sum_rev)을 기준으로 차트 XML 생성 루프 실행
  LOOP AT lt_sum_rev INTO gs_sales_rev.

    " 1. X축 값 넣기
    category = go_ixml_data_doc->create_simple_element(
           name   = 'Category'
           parent = categories
         ).
    category->if_ixml_node~set_value( |{ gs_sales_rev-gjahr }년{ gs_sales_rev-quart } 분기| ).

    " 2. Y축 값 넣기 (총 매출액)
    CLEAR point.
    CLEAR value.
    point = go_ixml_data_doc->create_simple_element(
           name   = 'Point'
           parent = sales_amt
         ).
    value = go_ixml_data_doc->create_simple_element(
           name   = 'Value'
           parent = point
         ).
    value->set_attribute( name = 'type' value = 'y' ).
    value->if_ixml_node~set_value( |{ gs_sales_rev-sales_amt }| ).

    " 3. Y축 값 넣기 (매출 원가)
    CLEAR point.
    CLEAR value.
    point = go_ixml_data_doc->create_simple_element(
           name   = 'Point'
           parent = gross_prof
         ).
    value = go_ixml_data_doc->create_simple_element(
           name   = 'Value'
           parent = point
         ).
    value->set_attribute( name = 'type' value = 'y' ).
    value->if_ixml_node~set_value( |{ gs_sales_rev-gross_prof }| ).

    " 4. Y축 값 넣기 (판관비)
    CLEAR point.
    CLEAR value.
    point = go_ixml_data_doc->create_simple_element(
           name   = 'Point'
           parent = buis_prof
         ).
    value = go_ixml_data_doc->create_simple_element(
           name   = 'Value'
           parent = point
         ).
    value->set_attribute( name = 'type' value = 'y' ).
    value->if_ixml_node~set_value( |{ gs_sales_rev-buis_prof }| ).

  ENDLOOP.
ENDFORM.

FORM create_customizing_xml.
  DATA: lv_cust_str TYPE string.

  lv_cust_str =
    |<?xml version="1.0" encoding="utf-8"?>| &&
    |<ChartCustomizing>| &&
    |  <GlobalSettings>| &&
    |    <ChartType>Column</ChartType>| &&
    |  </GlobalSettings>| &&
    |  <Elements>| &&
    |    <ChartElement id="Title">| &&               " ★ 예약된 고정 ID 'Title' 사용
    |      <Caption>분기별 영업 이익 리포트</Caption>| &&
    |    </ChartElement>| &&
    |    <ChartElement id="Series1">| &&
    |      <DataLabel>| &&
    |        <Visibility>true</Visibility>| &&
    |      </DataLabel>| &&
    |    </ChartElement>| &&
    |    <ChartElement id="Series2">| &&
    |      <DataLabel>| &&
    |        <Visibility>true</Visibility>| &&
    |      </DataLabel>| &&
    |    </ChartElement>| &&
    |    <ChartElement id="Series3">| &&
    |      <DataLabel>| &&
    |        <Visibility>true</Visibility>| &&
    |      </DataLabel>| &&
    |    </ChartElement>| &&
    |  </Elements>| &&
    |</ChartCustomizing>|.

  CLEAR gv_cust_xml.

  CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
    EXPORTING
      text     = lv_cust_str
      encoding = '4110'
    IMPORTING
      buffer   = gv_cust_xml.
ENDFORM.

FORM change_field_catalog USING    pv_structure   TYPE csequence
                                   pv_keep_fields TYPE csequence
                                   pv_coltexts    TYPE csequence
                          CHANGING pt_fcat        TYPE lvc_t_fcat.

  DATA: lt_fields TYPE TABLE OF string,
        lt_texts  TYPE TABLE OF string,
        lv_field  TYPE string,
        lv_text   TYPE string,
        lv_tabix  TYPE sy-tabix,
        ls_fcat   TYPE lvc_s_fcat.

  SPLIT pv_keep_fields AT ',' INTO TABLE lt_fields.
  SPLIT pv_coltexts    AT ',' INTO TABLE lt_texts.

  LOOP AT lt_fields INTO lv_field.
    lv_tabix = sy-tabix.
    CLEAR ls_fcat.

    " 1) Field Name (공백 제거)
    CONDENSE lv_field NO-GAPS.
    ls_fcat-fieldname = lv_field.

    " 2) Reference & Texts 처리 (기존 코드와 동일)
    ls_fcat-ref_table = pv_structure.
    ls_fcat-ref_field = |{ pv_structure }-{ lv_field }|.

    READ TABLE lt_texts INTO lv_text INDEX lv_tabix.
    IF sy-subrc = 0.
      CONDENSE lv_text NO-GAPS.
      ls_fcat-coltext = lv_text.
      ls_fcat-reptext = lv_text.
    ELSE.
      ls_fcat-coltext = lv_field.
    ENDIF.

    ls_fcat-col_pos = lv_tabix.

    " 3) 데이터 타입 및 포맷
    IF lv_field = 'MENGE' OR lv_field = 'PO_AMT'.
      ls_fcat-decimals_o = '0'.
      ls_fcat-datatype   = 'DEC'.
    ENDIF.

    ls_fcat-outputlen = 20.

    " 키(Key) 필드 화면 숨김 처리
    IF lv_field = 'ORG_ID' OR lv_field = 'PROD_ID' OR lv_field = 'ORG_NAME' OR lv_field = 'PROD_NAME'.
      ls_fcat-no_out = 'X'.
    ENDIF.

    IF lv_field = 'GROSS_STATUS'.
      ls_fcat-outputlen = 8.    " 수익성 컬럼 길이 축소
    ELSEIF lv_field = 'LIGHT'.
      ls_fcat-outputlen = 6.    " 신호등 컬럼 길이 설정
      ls_fcat-icon = 'X'.
      ls_fcat-just = 'C'.
    ELSE.
      ls_fcat-outputlen = 20.   " 나머지 금액 필드 등
    ENDIF.

    " 금액 필드들은 금액(CURR) 형태로 지정 (필요 시)
    IF lv_field = 'SALES_AMT' OR lv_field = 'COGS_AMT' OR lv_field = 'SGA_AMT' OR lv_field = 'OP_PROFIT' OR lv_field = 'GROSS_PR'.
      ls_fcat-datatype = 'CURR'.
      ls_fcat-cfieldname = 'WAERK'. " 통화 키 필드가 있다면 연결 (생략 가능)
      ls_fcat-convexit = 'RE_SET_SIGN'.
      ls_fcat-edit_mask = '==RE_SET_SIGN'.
      ls_fcat-no_zero = 'X'.
    ENDIF.

    IF lv_field CP '*_TXT'.
      ls_fcat-just = 'R'.                                 " 오른쪽 정렬
      CLEAR: ls_fcat-ref_table, ls_fcat-ref_field.
    ENDIF.

    IF lv_field = 'LIGHT'.
      ls_fcat-outputlen = 10.
      ls_fcat-icon = 'X'. " 문자를 아이콘으로 변환하여 출력
      ls_fcat-just = 'C'. " 가운데 정렬하여 예쁘게 배치
    ENDIF.

    APPEND ls_fcat TO pt_fcat.
  ENDLOOP.

ENDFORM.

FORM create_tree_nodes.

  DATA: gv_org_key  TYPE lvc_nkey,
        gv_prod_key TYPE lvc_nkey.

  DATA: ls_grand_total TYPE ty_profit_data,
        ls_org_total   TYPE ty_profit_data.

  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi,
        ls_node_layout TYPE lvc_s_layn.

  SORT gt_raw_data BY org_id ASCENDING proj_id ASCENDING.

  " -------------------------------------------------------------------------
  " [1단계] 전사 총계(Grand Total) 집계 및 신호등 판별
  " -------------------------------------------------------------------------
  CLEAR: ls_grand_total.
  ls_grand_total-waerk = 'KRW'.

  LOOP AT gt_raw_data INTO DATA(ls_calc).
    ls_grand_total-sales_amt += ls_calc-sales_amt.
    ls_grand_total-cogs_amt  += ls_calc-cogs_amt.
    ls_grand_total-sga_amt   += ls_calc-sga_amt.
  ENDLOOP.

  ls_grand_total-gross_pr  = ls_grand_total-sales_amt - ls_grand_total-cogs_amt.
  ls_grand_total-op_profit = ls_grand_total-gross_pr  - ls_grand_total-sga_amt.

  " 영업이익(op_profit) 기준으로 전사 흑자/적자 정확히 판별
  IF ls_grand_total-op_profit >= 0.
    ls_grand_total-gross_status = '흑자'.
    ls_grand_total-light = '@5B\Q @'. " 녹색
  ELSE.
    ls_grand_total-gross_status = '적자'.
    ls_grand_total-light = '@5C\Q @'. " 적색
  ENDIF.

  CLEAR lt_item_layout.

  IF ls_grand_total-sales_amt IS NOT INITIAL.
    CLEAR ls_item_layout.
    ls_item_layout-fieldname = 'SALES_TXT'.
    ls_item_layout-class     = cl_gui_column_tree=>item_class_link.
    APPEND ls_item_layout TO lt_item_layout.
  ENDIF.

  IF ls_grand_total-cogs_amt IS NOT INITIAL.
    CLEAR ls_item_layout.
    ls_item_layout-fieldname = 'COGS_TXT'.
    ls_item_layout-class     = cl_gui_column_tree=>item_class_link.
    APPEND ls_item_layout TO lt_item_layout.
  ENDIF.

  IF ls_grand_total-sga_amt IS NOT INITIAL.
    CLEAR ls_item_layout.
    ls_item_layout-fieldname = 'SGA_TXT'.
    ls_item_layout-class     = cl_gui_column_tree=>item_class_link.
    APPEND ls_item_layout TO lt_item_layout.
  ENDIF.

  " [핵심 수정] 전사 총계가 적자일 경우 영업이익 셀을 빨간색으로 칠함
  IF ls_grand_total-op_profit < 0.
    CLEAR ls_item_layout.
    ls_item_layout-fieldname = 'OP_TXT'.
    ls_item_layout-style     = cl_gui_column_tree=>style_emphasized_negative.
    APPEND ls_item_layout TO lt_item_layout.
  ENDIF.

  IF ls_grand_total-gross_pr < 0.
    CLEAR ls_item_layout.
    ls_item_layout-fieldname = 'GROSS_TXT'.
    ls_item_layout-style     = cl_gui_column_tree=>style_emphasized_negative.
    APPEND ls_item_layout TO lt_item_layout.
  ENDIF.

  PERFORM fill_amt_txt CHANGING ls_grand_total.   " 전사 add_node 앞
  CALL METHOD go_alv_tree->add_node
    EXPORTING
      i_relat_node_key = ''
      i_relationship   = cl_gui_column_tree=>relat_last_child
      is_outtab_line   = ls_grand_total
      i_node_text      = '전사 총계'
      it_item_layout   = lt_item_layout
    IMPORTING
      e_new_node_key   = gv_root_key.

  " -------------------------------------------------------------------------
  " [2단계] 조직(지사) 단위 소계 및 신호등 판별
  " -------------------------------------------------------------------------
  LOOP AT gt_raw_data INTO DATA(ls_raw)
       GROUP BY ( org_id = ls_raw-org_id )
       ASSIGNING FIELD-SYMBOL(<group_org>).

    CLEAR: ls_org_total, ls_node_layout, lt_item_layout.
    ls_org_total-org_id = <group_org>-org_id.
    ls_org_total-waerk  = 'KRW'.

    " 1. 하위 데이터 합산만 먼저 순수하게 실행
    LOOP AT GROUP <group_org> ASSIGNING FIELD-SYMBOL(<fs_calc>).
      ls_org_total-sales_amt += <fs_calc>-sales_amt.
      ls_org_total-cogs_amt  += <fs_calc>-cogs_amt.
      ls_org_total-sga_amt   += <fs_calc>-sga_amt.
    ENDLOOP.

    " 2. 합산 완료 후 이익 계산 및 상태 세팅
    ls_org_total-gross_pr  = ls_org_total-sales_amt - ls_org_total-cogs_amt.
    ls_org_total-op_profit = ls_org_total-gross_pr  - ls_org_total-sga_amt.

    IF ls_org_total-op_profit >= 0.
      ls_org_total-gross_status = '흑자'.
      ls_org_total-light        = '@5B\Q @'.
    ELSE.
      ls_org_total-gross_status = '적자'.
      ls_org_total-light        = '@5C\Q @'.
    ENDIF.

    DATA(lv_org_text) = |지사: { <group_org>-org_id }|.

    " 3. ALV 그리드 핫스팟 세팅
    IF ls_org_total-sales_amt IS NOT INITIAL.
      CLEAR ls_item_layout.
      ls_item_layout-fieldname = 'SALES_TXT'.
      ls_item_layout-class     = cl_gui_column_tree=>item_class_link.
      APPEND ls_item_layout TO lt_item_layout.
    ENDIF.

    IF ls_org_total-cogs_amt IS NOT INITIAL.
      CLEAR ls_item_layout.
      ls_item_layout-fieldname = 'COGS_TXT'.
      ls_item_layout-class     = cl_gui_column_tree=>item_class_link.
      APPEND ls_item_layout TO lt_item_layout.
    ENDIF.

    IF ls_org_total-sga_amt IS NOT INITIAL.
      CLEAR ls_item_layout.
      ls_item_layout-fieldname = 'SGA_TXT'.
      ls_item_layout-class     = cl_gui_column_tree=>item_class_link.
      APPEND ls_item_layout TO lt_item_layout.
    ENDIF.

    " 4. 지사가 적자일 경우 영업이익만 빨갛게 칠함
    IF ls_org_total-op_profit < 0.
      CLEAR ls_item_layout.
      ls_item_layout-style     = cl_gui_column_tree=>style_emphasized_negative.
      ls_item_layout-fieldname = 'OP_TXT'.
      APPEND ls_item_layout TO lt_item_layout.
    ENDIF.

    IF ls_org_total-gross_pr < 0.
      CLEAR ls_item_layout.
      ls_item_layout-fieldname = 'GROSS_TXT'.
      ls_item_layout-style     = cl_gui_column_tree=>style_emphasized_negative.
      APPEND ls_item_layout TO lt_item_layout.
    ENDIF.

    PERFORM fill_amt_txt CHANGING ls_org_total.     " 지사 add_node 앞

    CALL METHOD go_alv_tree->add_node
      EXPORTING
        i_relat_node_key = gv_root_key
        i_relationship   = cl_gui_column_tree=>relat_last_child
        is_outtab_line   = ls_org_total
        i_node_text      = CONV #( lv_org_text )
        is_node_layout   = ls_node_layout
        it_item_layout   = lt_item_layout
      IMPORTING
        e_new_node_key   = gv_org_key.

    " -------------------------------------------------------------------------
    " [3단계] 하위 프로젝트 노드 추가
    " -------------------------------------------------------------------------
    LOOP AT GROUP <group_org> ASSIGNING FIELD-SYMBOL(<fs_member>).
      <fs_member>-waerk = 'KRW'.

      " 프로젝트 레벨에서는 상태(신호등), 수익성(흑자/적자) 텍스트를 숨김
      CLEAR: <fs_member>-gross_status,
             <fs_member>-light,
             <fs_member>-sga_amt,
             <fs_member>-op_profit.
      CLEAR lt_item_layout.

      IF <fs_member>-cogs_amt < 0.
        CLEAR ls_item_layout.
        ls_item_layout-fieldname = 'COGS_TXT'.
        ls_item_layout-style     = cl_gui_column_tree=>style_emphasized_negative.
        APPEND ls_item_layout TO lt_item_layout.
      ENDIF.

      IF <fs_member>-gross_pr < 0.
        CLEAR ls_item_layout.
        ls_item_layout-fieldname = 'GROSS_TXT'.
        ls_item_layout-style     = cl_gui_column_tree=>style_emphasized_negative.
        APPEND ls_item_layout TO lt_item_layout.
      ENDIF.

      PERFORM fill_amt_txt CHANGING <fs_member>.      " 프로젝트 add_node 앞 (CLEAR 다음)

      CALL METHOD go_alv_tree->add_node
        EXPORTING
          i_relat_node_key = gv_org_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          is_outtab_line   = <fs_member>
          i_node_text      = CONV #( <fs_member>-proj_id )
          it_item_layout   = lt_item_layout
        IMPORTING
          e_new_node_key   = gv_prod_key.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

FORM get_tree_data .
  DATA: lt_project TYPE STANDARD TABLE OF z8ps_project,
        lt_branch  TYPE STANDARD TABLE OF z8branch_m.

  " 지사(부서)별 판관비 집계를 위한 로컬 테이블
  TYPES: BEGIN OF ty_branch_sga,
           bupla   TYPE z8ps_project-branch,
           sga_amt TYPE z8fi_accdoc_i-wrbtr,
         END OF ty_branch_sga.
  DATA: lt_branch_sga TYPE TABLE OF ty_branch_sga.

  DATA: ls_raw TYPE ty_profit_data.

  CLEAR gt_raw_data.

  " 1. 모든 지사 마스터 조회
  SELECT * INTO TABLE @lt_branch FROM z8branch_m.

  " 2. 기준 정보 조회 (프로젝트)
  " [수정] 프로젝트가 없더라도 판관비만 발생한 지사를 보여줘야 하므로 RETURN 제거
  SELECT DISTINCT p~*
    INTO TABLE @lt_project
    FROM z8ps_project AS p
    LEFT OUTER JOIN z8sd_deliv_h AS d ON p~vbeln = d~vbeln_s
    INNER JOIN z8fi_accdoc_h AS h ON ( h~xblnr = p~pro_id OR h~xblnr = p~vbeln OR h~xblnr = d~vbeln_d )
   WHERE h~budat IN @s_date.

  " (참고: 7번 구간에서 Open SQL로 직접 집계하므로 기존의 3, 4, 5번 사전 조회 로직은 불필요하여 제거함)

  " 6. 인건비(판관비) DB 단일 집계 최적화
  " [핵심 수정] AND e~bupla = @ls_p-branch 조건을 제거하여 모든 지사의 판관비를 정상 집계
  SELECT e~bupla, SUM( i~wrbtr ) AS sga_amt
    INTO TABLE @lt_branch_sga
    FROM z8employee_m AS e
    INNER JOIN z8fi_accdoc_h AS h ON h~xblnr = e~pernr
    INNER JOIN z8fi_accdoc_i AS i ON i~bukrs = h~bukrs
                                 AND i~belnr = h~belnr
                                 AND i~gjahr = h~gjahr
    WHERE h~budat IN @s_date
      AND i~hkont BETWEEN '61100000' AND '61700000'
      AND i~shkzg = 'S'
    GROUP BY e~bupla.

  " -------------------------------------------------------------------------
  " 7. 데이터 조립 (gt_raw_data)
  " -------------------------------------------------------------------------
  LOOP AT lt_branch INTO DATA(ls_branch).
    DATA(lv_has_proj) = abap_false.

    " 7-1. 해당 지사에 속한 프로젝트가 있는 경우
    LOOP AT lt_project INTO DATA(ls_project) WHERE branch = ls_branch-branch.
      lv_has_proj = abap_true.
      CLEAR ls_raw.
      ls_raw-org_id  = ls_project-branch.
      ls_raw-proj_id = ls_project-pro_id.
      ls_raw-waerk   = 'KRW'. " 기본 통화 세팅

      " [매출액 집계]
      SELECT SUM( i~wrbtr ) AS sales_amt
        INTO @ls_raw-sales_amt
        FROM z8fi_accdoc_h AS h
       INNER JOIN z8fi_accdoc_i AS i
          ON i~bukrs = h~bukrs
         AND i~belnr = h~belnr
         AND i~gjahr = h~gjahr
       WHERE ( h~xblnr = @ls_project-pro_id OR h~xblnr = @ls_project-vbeln )
         AND h~budat IN @s_date
         AND i~hkont = '41000000'.

      " [매출원가 집계]
      SELECT SUM( i~wrbtr ) AS cogs_amt
        INTO @ls_raw-cogs_amt
        FROM z8sd_deliv_h AS d
       INNER JOIN z8fi_accdoc_h AS h
          ON h~xblnr = d~vbeln_d
       INNER JOIN z8fi_accdoc_i AS i
          ON i~bukrs = h~bukrs
         AND i~belnr = h~belnr
         AND i~gjahr = h~gjahr
       WHERE d~vbeln_s = @ls_project-vbeln
         AND h~budat   IN @s_date
         AND i~hkont   = '51000000'.

      " [판관비 할당] 지사 판관비를 첫 번째 프로젝트 행에 대표로 적재 (CREATE_TREE_NODES에서 지사 소계로 합산됨)
      READ TABLE lt_branch_sga ASSIGNING FIELD-SYMBOL(<fs_sga>) WITH KEY bupla = ls_branch-branch.
      IF sy-subrc = 0 AND <fs_sga>-sga_amt IS NOT INITIAL.
        ls_raw-sga_amt = <fs_sga>-sga_amt.
        CLEAR <fs_sga>-sga_amt. " 중복 합산 방지를 위해 첫 번째 프로젝트에 넣고 비움
      ENDIF.

      " 이익 계산 (줄바꿈으로 끊어졌던 마이너스 연산자 복구)
      ls_raw-gross_pr  = ls_raw-sales_amt - ls_raw-cogs_amt.
      ls_raw-op_profit = ls_raw-gross_pr  - ls_raw-sga_amt.

      APPEND ls_raw TO gt_raw_data.
    ENDLOOP.

    " 7-2. 해당 지사에 프로젝트가 아예 없는 경우 (판관비만 있거나 실적이 0인 지사)
    IF lv_has_proj = abap_false.
      CLEAR ls_raw.
      ls_raw-org_id = ls_branch-branch.
      ls_raw-waerk  = 'KRW'.

      READ TABLE lt_branch_sga ASSIGNING <fs_sga> WITH KEY bupla = ls_branch-branch.
      IF sy-subrc = 0.
        ls_raw-sga_amt = <fs_sga>-sga_amt.
      ENDIF.

      " 매출과 원가가 없으므로 판관비만큼 마이너스 영업이익 처리
      ls_raw-op_profit = - ls_raw-sga_amt.
      APPEND ls_raw TO gt_raw_data.
    ENDIF.

  ENDLOOP.

ENDFORM.

FORM expand_default_nodes.
  CHECK gv_root_key IS NOT INITIAL.

  go_alv_tree->expand_node(
    EXPORTING i_node_key = gv_root_key
    EXCEPTIONS OTHERS    = 1 ).          " 데이터가 없어 자식이 없으면 예외 → 무시

  go_alv_tree->frontend_update( ).
ENDFORM.

FORM fill_amt_txt CHANGING cs_data TYPE ty_profit_data.
  CLEAR: cs_data-sales_txt, cs_data-cogs_txt, cs_data-gross_txt,
         cs_data-sga_txt,   cs_data-op_txt.

  IF cs_data-sales_amt <> 0.
    cs_data-sales_txt = |{ cs_data-sales_amt CURRENCY = cs_data-waerk NUMBER = USER SIGN = LEFT }|.
  ENDIF.
  IF cs_data-cogs_amt <> 0.
    cs_data-cogs_txt  = |{ cs_data-cogs_amt CURRENCY = cs_data-waerk NUMBER = USER SIGN = LEFT }|.
  ENDIF.
  IF cs_data-gross_pr <> 0.
    cs_data-gross_txt = |{ cs_data-gross_pr CURRENCY = cs_data-waerk NUMBER = USER SIGN = LEFT }|.
  ENDIF.
  IF cs_data-sga_amt <> 0.
    cs_data-sga_txt   = |{ cs_data-sga_amt CURRENCY = cs_data-waerk NUMBER = USER SIGN = LEFT }|.
  ENDIF.
  IF cs_data-op_profit <> 0.
    cs_data-op_txt    = |{ cs_data-op_profit CURRENCY = cs_data-waerk NUMBER = USER SIGN = LEFT }|.
  ENDIF.
ENDFORM.
