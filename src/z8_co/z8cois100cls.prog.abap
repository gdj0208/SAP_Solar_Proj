*&---------------------------------------------------------------------*
*& Include          Z8COIS100CLS
*&---------------------------------------------------------------------*

CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS handle_link_click
      FOR EVENT link_click OF cl_gui_alv_tree
      IMPORTING fieldname node_key sender.
ENDCLASS.

CLASS lcl_event_receiver IMPLEMENTATION.
  METHOD handle_link_click.
    DATA: ls_data TYPE ty_profit_data.

    sender->get_outtab_line(
      EXPORTING i_node_key    = node_key
      IMPORTING e_outtab_line = ls_data
    ).

    " 1. 동적 검색 조건(RANGES) 할당
    DATA: lr_pro_id TYPE RANGE OF z8ps_project-pro_id,
          lr_branch TYPE RANGE OF z8ps_project-branch.

    IF ls_data-proj_id IS NOT INITIAL.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_data-proj_id ) TO lr_pro_id.
    ELSEIF ls_data-org_id IS NOT INITIAL.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_data-org_id ) TO lr_branch.
    ENDIF.

    " 2. 팝업용 통합 구조체 선언 (출력 순서에 맞춰 필드 재배치 및 신규 필드 추가)
    TYPES: BEGIN OF ty_popup,
             pro_id   TYPE z8ps_project-pro_id,
             vbeln    TYPE z8ps_project-vbeln,
             pernr    TYPE z8employee_m-pernr,
             ename    TYPE z8employee_m-ename,
             sga_cat  TYPE c LENGTH 20, " 신규: 판관비 항목
             sga_desc TYPE c LENGTH 50, " 신규: 상세 항목
             name     TYPE z8branch_m-name,
             amt      TYPE z8fi_accdoc_i-wrbtr,
             waers    TYPE z8fi_accdoc_i-waers,
             belnr    TYPE z8fi_accdoc_h-belnr,
             budat    TYPE z8fi_accdoc_h-budat,
             sdate_a  TYPE z8ps_project-sdate_a,
             edate_a  TYPE z8ps_project-edate_a,
           END OF ty_popup.
    DATA: lt_popup TYPE STANDARD TABLE OF ty_popup,
          lv_title TYPE string.

    " ---------------------------------------------------------
    " ★ 3. 클릭한 필드에 따른 개별 DB 조인 (기간 조건 포함)
    " ---------------------------------------------------------

*---------------------------------------------------------
* 수정일자 : 2026-11-10
* 수정 사유 : 단순 오타로 인한 수정
* - SALES_AMT -> SALES_TXT
*---------------------------------------------------------
    IF fieldname = 'SALES_TXT'.
      lv_title = '매출액'.
      SELECT p~pro_id, p~vbeln, br~name, i~wrbtr AS amt, i~waers,
             p~sdate_a, p~edate_a, h~belnr, h~budat
        INTO CORRESPONDING FIELDS OF TABLE @lt_popup
        FROM z8ps_project AS p
        LEFT OUTER JOIN z8branch_m AS br ON p~branch = br~branch
        INNER JOIN z8fi_accdoc_h AS h ON ( h~xblnr = p~pro_id OR h~xblnr = p~vbeln )
        INNER JOIN z8fi_accdoc_i AS i ON h~belnr = i~belnr
                             AND i~belnr = h~belnr
                             AND i~gjahr = h~gjahr
        WHERE p~pro_id IN @lr_pro_id
          AND p~branch IN @lr_branch
          AND h~budat  IN @s_date
          AND i~hkont  = '41000000'.


*---------------------------------------------------------
* 수정일자 : 2026-11-10
* 수정 사유 : 단순 오타로 인한 수정
* - COGS_AMT -> COGS_TXT
*---------------------------------------------------------
    ELSEIF fieldname = 'COGS_TXT'.
      lv_title = '매출원가'.
      SELECT p~pro_id, p~vbeln, br~name, i~wrbtr AS amt, i~waers,
             p~sdate_a, p~edate_a, h~belnr, h~budat
        INTO CORRESPONDING FIELDS OF TABLE @lt_popup
        FROM z8ps_project AS p
        LEFT OUTER JOIN z8branch_m AS br ON p~branch = br~branch
        INNER JOIN z8sd_deliv_h AS d ON p~vbeln = d~vbeln_s
        INNER JOIN z8fi_accdoc_h AS h ON h~xblnr = d~vbeln_d
        INNER JOIN z8fi_accdoc_i AS i ON h~belnr = i~belnr
        WHERE p~pro_id IN @lr_pro_id
          AND p~branch IN @lr_branch
          AND h~budat  IN @s_date
          AND i~hkont  = '51000000'.

*---------------------------------------------------------
* 수정일자 : 2026-11-10
* 수정 사유 : 단순 오타로 인한 수정
* - SGA_AMT -> SGA_TXT
*---------------------------------------------------------
    ELSEIF fieldname = 'SGA_TXT'.
      IF ls_data-proj_id IS NOT INITIAL.
        RETURN.
      ENDIF.

      lv_title = '금액'. " 판관비 팝업의 컬럼명을 '금액'으로 통일

      SELECT e~pernr, e~ename, br~name, i~wrbtr AS amt, i~waers,
             h~belnr, h~budat
        INTO CORRESPONDING FIELDS OF TABLE @lt_popup
        FROM z8employee_m AS e
        LEFT OUTER JOIN z8branch_m AS br ON e~bupla = br~branch
        INNER JOIN z8fi_accdoc_h AS h ON h~xblnr = e~pernr
        INNER JOIN z8fi_accdoc_i AS i ON i~bukrs = h~bukrs
                                     AND i~belnr = h~belnr
                                     AND i~gjahr = h~gjahr
        WHERE e~bupla IN @lr_branch
          AND h~budat IN @s_date
          AND i~hkont BETWEEN '61100000' AND '61700000'
          AND i~shkzg = 'S'.

      " ★ 데이터 가공: 판관비 항목(급여) 및 상세 항목(사원명 + 월) 동적 생성
      LOOP AT lt_popup ASSIGNING FIELD-SYMBOL(<fs_popup>).
        <fs_popup>-sga_cat = '급여'.
        " 전기일(BUDAT)에서 월(Month)만 추출하여 정수형으로 변환 (예: '09' -> 9)
        DATA(lv_month) = CONV i( <fs_popup>-budat+4(2) ).
        <fs_popup>-sga_desc = |{ <fs_popup>-ename } { lv_month }월 급여|.
      ENDLOOP.

    ELSE.
      RETURN.
    ENDIF.

    IF lt_popup[] IS INITIAL.
      MESSAGE |조회 기간 내 { lv_title } 상세 정보(회계전표)가 없습니다.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF fieldname = 'SGA_AMT'.
      SORT lt_popup BY budat ASCENDING sga_desc ASCENDING.
    ELSE.
      SORT lt_popup BY budat ASCENDING pro_id ASCENDING belnr ASCENDING.
    ENDIF.

*    IF fieldname = 'SGA_AMT'.
*      SORT lt_popup BY sga_desc ASCENDING budat ASCENDING.
*    ELSE.
*      SORT lt_popup BY pro_id ASCENDING belnr ASCENDING.
*    ENDIF.

    " ---------------------------------------------------------
    " 4. 팝업 ALV 출력부 (동적 컬럼 제어)
    " ---------------------------------------------------------
    DATA: lo_salv TYPE REF TO cl_salv_table.
    TRY.
        cl_salv_table=>factory(
          IMPORTING r_salv_table = lo_salv
          CHANGING  t_table      = lt_popup ).

        " 1. 제브라(Zebra) 패턴 적용
        DATA(lo_display) = lo_salv->get_display_settings( ).
        lo_display->set_striped_pattern( abap_true ).

        " 2. 우측 하단 프린트 버튼 제거
        DATA(lo_functions) = lo_salv->get_functions( ).
        lo_functions->set_print( abap_false ).

        " 3. 필드 넓이 자동 최적화
        DATA(lo_cols) = lo_salv->get_columns( ).
        lo_cols->set_optimize( abap_true ).

        " 공통 컬럼 설정
        lo_cols->get_column( 'NAME' )->set_long_text( '종사업장' ).
        lo_cols->get_column( 'WAERS' )->set_long_text( '통화' ).
        lo_cols->get_column( 'BELNR' )->set_long_text( '회계전표번호' ).
        lo_cols->get_column( 'BUDAT' )->set_long_text( '전기일' ).

        " 금액 컬럼 셋업
        DATA: lo_col_amt TYPE REF TO cl_salv_column_table.
        lo_col_amt ?= lo_cols->get_column( 'AMT' ).
        lo_col_amt->set_long_text( CONV #( lv_title ) ).
        lo_col_amt->set_currency_column( 'WAERS' ).

        DATA(lo_aggrs) = lo_salv->get_aggregations( ).
        lo_aggrs->add_aggregation( 'AMT' ).

        " ★ 항목별 컬럼 숨김(Technical) 및 표시 처리
*---------------------------------------------------------
* 수정일자 : 2026-11-10
* 수정 사유 : 단순 오타로 인한 수정
* - SGA_AMT -> SGA_TXT
*---------------------------------------------------------
        IF fieldname = 'SGA_TXT'.
          " 판관비 팝업: 불필요한 원본 사원/프로젝트 필드 완전 숨김
          lo_cols->get_column( 'PRO_ID' )->set_technical( abap_true ).
          lo_cols->get_column( 'VBELN' )->set_technical( abap_true ).
          lo_cols->get_column( 'SDATE_A' )->set_technical( abap_true ).
          lo_cols->get_column( 'EDATE_A' )->set_technical( abap_true ).
          lo_cols->get_column( 'PERNR' )->set_technical( abap_true ).
          lo_cols->get_column( 'ENAME' )->set_technical( abap_true ).

          " 신규 조합 필드 표시
          lo_cols->get_column( 'SGA_CAT' )->set_long_text( '판관비 항목' ).
          lo_cols->get_column( 'SGA_DESC' )->set_long_text( '상세 항목' ).

          lo_cols->get_column( 'SGA_CAT' )->set_output_length( 10 ).
          lo_cols->get_column( 'SGA_DESC' )->set_output_length( 15 ).
          lo_cols->get_column( 'NAME' )->set_output_length( 10 ). " 종사업장
          lo_cols->get_column( 'AMT' )->set_output_length( 15 ). " 금액
        ELSE.
          " 매출/원가 팝업: 판관비 전용 필드 숨김
          lo_cols->get_column( 'SGA_CAT' )->set_technical( abap_true ).
          lo_cols->get_column( 'SGA_DESC' )->set_technical( abap_true ).
          lo_cols->get_column( 'PERNR' )->set_technical( abap_true ).
          lo_cols->get_column( 'ENAME' )->set_technical( abap_true ).

          " 프로젝트 관련 필드 표시
          lo_cols->get_column( 'PRO_ID' )->set_long_text( '프로젝트 ID' ).
          lo_cols->get_column( 'VBELN' )->set_long_text( 'SO 번호' ).
          lo_cols->get_column( 'PRO_ID' )->set_output_length( 20 ).
          lo_cols->get_column( 'VBELN' )->set_output_length( 20 ).
          lo_cols->get_column( 'SDATE_A' )->set_long_text( '공사 시작일' ).
          lo_cols->get_column( 'EDATE_A' )->set_long_text( '공사 종료일' ).
        ENDIF.

        lo_salv->set_screen_popup(
          start_column = 15 end_column = 100
          start_line   = 5  end_line   = 20 ).

        lo_salv->display( ).
      CATCH cx_salv_error.
        MESSAGE '상세 화면 출력 중 오류가 발생했습니다.' TYPE 'E'.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
