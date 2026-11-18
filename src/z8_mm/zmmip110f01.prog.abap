*&---------------------------------------------------------------------*
*& Include          ZMMGR030F01
*&---------------------------------------------------------------------*

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
    TRANSLATE lv_field TO UPPER CASE.
    ls_fcat-fieldname = lv_field.

    " 2-2. Reference Table
    ls_fcat-ref_table = pv_structure.
    TRANSLATE ls_fcat-ref_table TO UPPER CASE.

    " 2-3. Reference Field (구조체-필드명 형태로 연결)
    "ls_fcat-ref_field = |{ pv_structure }-{ lv_field }|.
    ls_fcat-ref_field = lv_field.

    " 2-4. Column Text (순번에 맞춰 텍스트를 가져오되, 부족할 경우 필드명을 그대로 사용)
    READ TABLE lt_texts INTO lv_text INDEX lv_tabix.
    IF sy-subrc = 0.
      " CONDENSE lv_text NO-GAPS. " 양옆 공백이 있을 수 있으므로 제거
      ls_fcat-coltext = lv_text.
      ls_fcat-reptext   = lv_text.
    ELSE.
      ls_fcat-coltext = lv_field.
    ENDIF.


    " 2-5. Column Position (순번)
    ls_fcat-col_pos = lv_tabix.

    " 날짜 레이아웃
    IF lv_field = 'ESDAT' OR lv_field = 'BEDAT'.
      ls_fcat-datatype = 'DATS'.
      ls_fcat-just = 'C'.
    ENDIF.

    IF lv_field = 'NETWR' OR lv_field = 'NETPR' OR lv_field = 'TOTAL_PRICE'.
      " 방법 A: 출력 인터널 테이블에 WAERS 필드가 있고 값이 채워져 있다면 아래 줄 사용
      ls_fcat-cfieldname = 'WAERS'.
    ENDIF.

    "2-6 숫자 표현 시 소숫점은 버리기
    IF lv_field = 'MENGE'.
      ls_fcat-decimals_o = '0'.
      ls_fcat-datatype   = 'DEC'.
    ENDIF.

    " 2-8. 컬럼 최소 출력 길이 강제 고정 [추가]
    ls_fcat-outputlen = 15.


     IF lv_field = 'STAT_TXT'.
    ls_fcat-outputlen = 5.
    ENDIF.

    " 3. Field Catalog 테이블에 데이터 추가
    APPEND ls_fcat TO pt_fcat.
  ENDLOOP.

ENDFORM.

FORM get_data .
  DATA: est_delay TYPE z8route_m-est_transit_days.

  " 1. 조건을 담을 Range 변수 선언
  DATA: lr_proc  TYPE RANGE OF z8v_unb_inv-procstat,
        lr_werks TYPE RANGE OF z8v_unb_inv-werks.


  " 2. 청구서 수신 상태 조건 설정 (procstat)
  IF gv_inv_sel = 'A'.
    " '전체'일 경우 20, 25 두 가지 상태만 포함되도록 2개의 행을 추가
    lr_proc = VALUE #( ( sign = 'I' option = 'EQ' low = '20' )
                       ( sign = 'I' option = 'EQ' low = '25' ) ).
  ELSEIF gv_inv_sel = 'Y'.
    lr_proc = VALUE #( ( sign = 'I' option = 'EQ' low = '25' ) ).

  ELSEIF gv_inv_sel = 'N'.
    lr_proc = VALUE #( ( sign = 'I' option = 'EQ' low = '20' ) ).

  ENDIF.


  " 3. 지사 조건 설정 (werks)
  IF gv_werks IS NOT INITIAL. lr_werks = VALUE #( ( sign = 'I' option = 'EQ' low = gv_werks ) ). ENDIF.


  " 4. 메인 데이터 조회 (단일 쿼리)
  SELECT ebeln, lifnr, name1, bedat, SUM( netwr ) AS netwr, waers, werks, procstat, lfdat AS esdat
  FROM z8v_unb_inv
  WHERE procstat IN @lr_proc
        AND werks = @gv_werks"   IN @lr_werks
          AND bedat    IN @s_date
  GROUP BY ebeln, lifnr, name1, bedat, esdat, waers, werks, procstat, lfdat
  INTO CORRESPONDING FIELDS OF TABLE @gt_unb_inv.
  IF sy-subrc <> 0.
     IF gv_done_ebeln IS INITIAL.
       MESSAGE s214(z8_msg) WITH |조회할 구매오더| DISPLAY LIKE 'E'.
     ENDIF.
    RETURN.
    "LEAVE PROGRAM.
  ENDIF.


  " 5. 필터링 루프
  LOOP AT gt_unb_inv INTO gs_unb_inv.

    " [추가] 청구서 번호 (INV_NO) 취득
    SELECT SINGLE inv_no
      INTO @gs_unb_inv-inv_no
      FROM z8mm_inv_h
     WHERE zzrefdoc = @gs_unb_inv-ebeln
       AND loekz = ' '.
      MODIFY gt_unb_inv FROM gs_unb_inv INDEX sy-tabix TRANSPORTING light inv_no.

    IF gs_unb_inv-procstat = '20'.
      gs_unb_inv-light = '1'.  " 빨간불 (Red)
      gs_unb_inv-stat_txt = '미검증'.
    ELSEIF gs_unb_inv-procstat = '25'.
      gs_unb_inv-light = '3'.  " 초록불 (Green)
      gs_unb_inv-stat_txt = '검증'.
    ENDIF.

    " 계산된 esdat이 조회 조건(s_date)에 맞지 않으면 인터널 테이블에서 즉시 삭제
    MODIFY gt_unb_inv FROM gs_unb_inv INDEX sy-tabix TRANSPORTING light stat_txt.

  ENDLOOP.
ENDFORM.

FORM has_inv  CHANGING  p_invno p_ebeln.
  SELECT SINGLE inv_no
    INTO p_invno
  FROM z8mm_inv_h
  WHERE zzrefdoc = p_ebeln
      AND LOekz = ' '.

  IF sy-subrc <> 0.
    CLEAR p_invno.
  ENDIF.
ENDFORM.
