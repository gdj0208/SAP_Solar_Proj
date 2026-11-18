*&---------------------------------------------------------------------*
*& Include          ZMMGR000F01
*&---------------------------------------------------------------------*


FORM get_plant_name .
  DATA:
    lt_return TYPE STANDARD TABLE OF ddshretval,
    ls_return TYPE ddshretval.

  " 1. 서치헬프 팝업 직접 호출
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8PLANT_M'
      fieldname   = 'WERKS'
      searchhelp  = 'Z8SH_PLANT'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_WERKS'
    TABLES
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.

  " 2. 사용자가 값을 선택하고 팝업을 닫았을 때
  IF sy-subrc = 0 AND lt_return[] IS NOT INITIAL.
    READ TABLE lt_return INTO ls_return INDEX 1.

    " 선택된 플랜트 코드로 이름 조회
    SELECT SINGLE name1
      INTO gv_pname
      FROM z8plant_m
     WHERE werks = ls_return-fieldval.

    " 3. 화면 변수(gv_pname)에 값을 즉시 반영 (화면 버퍼 업데이트)
    CLEAR gt_dynp.
    gs_dynp-fieldname  = 'P_WERKS'.
    gs_dynp-fieldvalue = ls_return-fieldval.
    APPEND gs_dynp TO gt_dynp.

    gs_dynp-fieldname  = 'GV_PNAME'.
    gs_dynp-fieldvalue = gv_pname.
    APPEND gs_dynp TO gt_dynp.

    CALL FUNCTION 'DYNP_VALUES_UPDATE'
      EXPORTING
        dyname     = sy-repid
        dynumb     = sy-dynnr
      TABLES
        dynpfields = gt_dynp
      EXCEPTIONS
        OTHERS     = 1.
  ENDIF.
ENDFORM.

FORM get_sup_name .
  DATA:
    lt_return TYPE STANDARD TABLE OF ddshretval,
    ls_return TYPE ddshretval.

  " 1. 서치헬프 팝업 직접 호출
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8VENDOR_M'
      fieldname   = 'LIFNR'
      searchhelp  = 'Z8SH_VENDOR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_LIFNR'
    TABLES
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.

  " 2. 사용자가 값을 선택하고 팝업을 닫았을 때
  IF sy-subrc = 0 AND lt_return[] IS NOT INITIAL.
    READ TABLE lt_return INTO ls_return INDEX 1.

    " 선택된 플랜트 코드로 이름 조회
    SELECT SINGLE name1
      INTO gv_sup_t
      FROM z8vendor_m
     WHERE lifnr = ls_return-fieldval.

    " 3. 화면 변수(gv_pname)에 값을 즉시 반영 (화면 버퍼 업데이트)
    CLEAR gt_dynp.

    gs_dynp-fieldname  = 'P_SUP'.
    gs_dynp-fieldvalue = ls_return-fieldval.
    APPEND gs_dynp TO gt_dynp.

    gs_dynp-fieldname  = 'GV_SUP_T'.
    gs_dynp-fieldvalue = gv_sup_t.
    APPEND gs_dynp TO gt_dynp.

    CALL FUNCTION 'DYNP_VALUES_UPDATE'
      EXPORTING
        dyname     = sy-repid
        dynumb     = sy-dynnr
      TABLES
        dynpfields = gt_dynp
      EXCEPTIONS
        OTHERS     = 1.
  ENDIF.
ENDFORM.


* --------------------------------------------------------

FORM get_header_data .
  DATA : est_delay TYPE z8route_m-est_transit_days.


  CLEAR gt_po_h.
  CLEAR gs_po_h.

* 1. 입력 조건에 맞는 구매오더 헤더들 불러오기
  SELECT h~procstat, b~name, h~ebeln, v~name1,h~bsart, h~bedat, i~lfdat
  FROM z8mm_po_h AS h
    INNER JOIN z8mm_po_i AS i ON h~ebeln = i~ebeln
    INNER JOIN z8vendor_m AS v ON h~lifnr       = v~lifnr
    INNER JOIN z8plant_m  AS p ON i~werks       = p~werks
    INNER JOIN z8branch_m AS b ON h~bupla = b~branch
  WHERE ( h~lifnr = @gv_sup OR @gv_sup = '')
      AND ( i~werks = @gv_werks OR @gv_werks = '' )
      AND i~loekz = ''
      AND i~lfdat IN @s_date
    GROUP BY h~procstat, b~name, h~ebeln, v~name1,h~bsart, h~bedat, i~lfdat
    INTO CORRESPONDING FIELDS OF TABLE @gt_po_h.

  " 2. 각 구매오더 헤더별로 데이터 추가 할당
  LOOP AT gt_po_h ASSIGNING FIELD-SYMBOL(<fs_po>).

    " 2-1. 이동 유형
    CASE <fs_po>-bsart.
      WHEN 'NB' OR 'nb'.
        <fs_po>-bsart_txt = '구매오더'.
*      WHEN 'UB' OR 'ub'.
*        <fs_po>-bsart_txt = '플랜트간 이동'.
    ENDCASE.

    " 2-2. 진행 상태
    CASE <fs_po>-procstat.
      WHEN '10'.
        <fs_po>-light = '1'.
        <fs_po>-status_txt = '입고 안됨'.
      WHEN '15'.
        <fs_po>-light = '2'.
        <fs_po>-status_txt = '입고중'.
      WHEN '20' OR '25'.
        <fs_po>-light = '3'.
        <fs_po>-status_txt = '입고 완료'.
    ENDCASE.

  ENDLOOP.
ENDFORM.

FORM change_field_catalog USING    pv_structure   TYPE csequence
                                   pv_keep_fields TYPE csequence
                                   pv_coltexts    TYPE csequence  " 컬럼 텍스트용 인자 추가
                          CHANGING pt_fcat        TYPE lvc_t_fcat.

  DATA: lt_fields TYPE TABLE OF string,
        lt_texts  TYPE TABLE OF string,
        lv_field  TYPE string,
        lv_text   TYPE string,
        lv_tabix  TYPE sy-tabix,
        ls_fcat   TYPE lvc_s_fcat.

  " 1. 입력받은 필드명과 컬럼 텍스트를 콤마(,)를 기준으로 분리하여 배열(Internal Table)에 저장
  SPLIT pv_keep_fields AT ',' INTO TABLE lt_fields.
  SPLIT pv_coltexts    AT ',' INTO TABLE lt_texts.

  " 2. 분리된 필드명 테이블을 기준으로 LOOP를 돌며 필드 카탈로그 구성
  LOOP AT lt_fields INTO lv_field.
    lv_tabix = sy-tabix.

    CLEAR ls_fcat.

    " 2-1. Field Name (공백 제거)
    CONDENSE lv_field NO-GAPS.
    ls_fcat-fieldname = lv_field.

    " 2-2. Reference Table
    ls_fcat-ref_table = pv_structure.

    " 2-3. Reference Field (구조체-필드명 형태로 연결)
    "ls_fcat-ref_field = |{ pv_structure }-{ lv_field }|.
    ls_fcat-ref_field = lv_field.

    " 2-4. Column Text (순번에 맞춰 텍스트를 가져오되, 부족할 경우 필드명을 그대로 사용)
    READ TABLE lt_texts INTO lv_text INDEX lv_tabix.
    IF sy-subrc = 0.
      CONDENSE lv_text NO-GAPS. " 양옆 공백이 있을 수 있으므로 제거
      ls_fcat-coltext = lv_text.
      ls_fcat-reptext   = lv_text.
*      ls_fcat-scrtext_l = lv_text. " 롱 텍스트 추가 (길이가 긴 헤더 보존)
*      ls_fcat-scrtext_m = lv_text.
*      ls_fcat-scrtext_s = lv_text.
    ELSE.
      ls_fcat-coltext = lv_field.
    ENDIF.
    " ls_fcat-col_opt = 'X'.

    " 2-5. Column Position (순번)
    ls_fcat-col_pos = lv_tabix.

    " 2-6. 날짜 필드를 날짜로 인식시키기
    IF lv_field = 'ESDAT' OR lv_field = 'LFDAT' OR lv_field = 'BEDAT'.
      ls_fcat-datatype = 'DATS'.
    ENDIF.

    "2-7. 숫자 표현 시 소숫점은 버리기
    IF lv_field = 'MENGE' OR lv_field = 'IN_AMT'OR lv_field = 'PROG_AMT' OR lv_field = 'YET_AMT'.
      " lv_field = 'NETPR' OR
      ls_fcat-decimals_o = '0'.
      ls_fcat-datatype   = 'DEC'.
    ENDIF.

    IF lv_field = 'NETPR' OR lv_field = 'WRBTR' OR lv_field = 'RMWWR' OR lv_field = 'WMWST1'.
      ls_fcat-cfieldname = 'WAERS'.  " 출력 인터널 테이블 내의 통화키 필드명
      ls_fcat-datatype   = 'CURR'.   " 데이터 타입을 통화(CURR)로 명시
    ENDIF.

    " 2-8. 컬럼 최소 출력 길이 강제 고정 [추가]
    ls_fcat-outputlen = 12.

    IF lv_field = 'PROCSTAT'.
      ls_fcat-no_out = 'X'.
    ENDIF.

    " 3. Field Catalog 테이블에 데이터 추가
    APPEND ls_fcat TO pt_fcat.

  ENDLOOP.

ENDFORM.

FORM get_item_data  USING    p_ebeln.
  DATA :
    lv_inv  TYPE z8mm_matdoc_i-menge,
    lv_prog TYPE z8mm_matdoc_i-menge.

  "CLEAR gt_po_i.
  "CLEAR gs_po_i.

  " 선택한 구매오더의 PO 번호에 해당되는 poi 전부 불러오기
  SELECT *
  FROM   z8mm_po_i
  INTO CORRESPONDING FIELDS OF TABLE gt_po_i
  WHERE ebeln = p_ebeln.


  LOOP AT gt_po_i INTO gs_po_i.
    DATA(lv_zetc) = |{ gs_po_i-ebelp ALPHA = OUT }|.

    " 1. 입고된 수량
    SELECT SUM( menge  )
      FROM @gt_matdoc_i AS itab
      WHERE matnr    = @gs_po_i-matnr
           AND werks = @gs_po_i-werks
        AND zzrefdoc = @gs_po_i-ebeln
        and zetc = @lv_zetc
        AND bwart    = '105'
      INTO @lv_prog.

    " 2. 검증 진행 수량
    SELECT  SUM( menge )
      FROM z8mm_matdoc_i
      WHERE matnr    = @gs_po_i-matnr
           AND werks = @gs_po_i-werks
        AND zzrefdoc = @gs_po_i-ebeln
        and zetc = @lv_zetc
        AND bwart    = '105'
      INTO @lv_inv .

    IF gs_po_i-elikz = 'X'.
      gs_po_i-light = '3'.
      gs_po_i-status_txt = '검수 완료'.
    ELSE.
      IF lv_inv <> 0.
        gs_po_i-light = '2'.
        gs_po_i-status_txt = '검수중'.
      ELSE.
        gs_po_i-light = '1'.
        gs_po_i-status_txt = '검수 대기'.
      ENDIF.
    ENDIF.

    gs_po_i-in_amt = lv_inv .
    gs_po_i-prog_amt = lv_prog.
    gs_po_i-yet_amt = gs_po_i-menge - lv_inv - lv_prog.

    MODIFY gt_po_i FROM gs_po_i.
  ENDLOOP.
ENDFORM.
