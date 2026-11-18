*&---------------------------------------------------------------------*
*& Include          Z8COSD100F02
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


    IF lv_field = 'NAME' OR lv_field = 'WAERK' OR lv_field = 'VBELN_Q' OR lv_field = 'REJ_TEXT' OR lv_field = 'NAME1' OR lv_field = 'ORG_NAME' OR lv_field = 'PROD_NAME'.
      ls_fcat-just = 'L'.

      " 2. 그 외의 금액, 비율, 건수 등 숫자형 데이터는 모두 오른쪽 정렬(R)
    ELSE.
      ls_fcat-just = 'R'.
    ENDIF.


    " 2-6. 날짜 필드를 날짜로 인식시키기
    IF lv_field = 'ESDAT' OR lv_field = 'BEDAT' OR lv_field = 'GUEBG' OR lv_field = 'GUEEN'.
      ls_fcat-datatype = 'DATS'.
      ls_fcat-just = 'C'.
    ENDIF.

    "2-7. 숫자 표현 시 소숫점은 버리기
    IF lv_field = 'MENGE' OR lv_field = 'IN_AMT'OR lv_field = 'PROG_AMT' OR lv_field = 'YET_AMT'.
      " lv_field = 'NETPR' OR
      ls_fcat-decimals_o = '0'.
      ls_fcat-datatype   = 'DEC'.
    ENDIF.

    IF lv_field = 'NETWR' .
      ls_fcat-cfieldname = 'WAERk'.  " 출력 인터널 테이블 내의 통화키 필드명
      ls_fcat-datatype   = 'CURR'.   " 데이터 타입을 통화(CURR)로 명시
    ENDIF.

    " 2-8. 컬럼 최소 출력 길이 강제 고정 [추가]
    ls_fcat-outputlen = 15.

    IF lv_field = 'PROCSTAT'.
      ls_fcat-no_out = 'X'.
    ENDIF.

    "ls_fcat-just = 'R'.

    " 3. Field Catalog 테이블에 데이터 추가
    APPEND ls_fcat TO pt_fcat.

  ENDLOOP.

ENDFORM.

FORM get_detail_data USING pv_index TYPE lvc_index.

  DATA(lv_txt_quo) = CONV ddtext( TEXT-t01 ).  " 견적 기한 만료
  DATA(lv_txt_nor) = CONV ddtext( TEXT-t02 ).  " 사유 미입력
  DATA(lv_txt_bil) = CONV ddtext( TEXT-t03 ).  " 청구 기한 만료

  IF pv_index <= 0.
    RETURN.
  ENDIF.

  READ TABLE gt_branch INTO gs_branch INDEX pv_index.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 청구 별칭은 지사(b)와 겹치지 않게 bl 사용
  WITH +bill AS (
      SELECT vgbel, MAX( zzpayst ) AS paystat
        FROM z8sd_billing_h
       GROUP BY vgbel )
  SELECT h~*,
         b~*,
         v~*,
         q~*,
         " 만료 구분 우선 → 사유 코드 → 사유 미입력
         CASE
           WHEN h~status = '40'           THEN @lv_txt_quo
           WHEN h~status = '20'           THEN @lv_txt_bil
           WHEN h~reject_reason <> @space THEN t~ddtext
           ELSE                                @lv_txt_nor
         END AS rej_text
    FROM z8sd_quotation_h AS h
      INNER JOIN z8sd_quot_req AS q ON h~request_id = q~request_id
      LEFT OUTER JOIN z8branch_m AS b ON b~branch = h~bupla
      LEFT OUTER JOIN z8plant_m AS v  ON v~werks = h~werks AND v~bupla = h~bupla
      LEFT OUTER JOIN +bill AS bl     ON bl~vgbel = h~vbeln_q
      LEFT OUTER JOIN dd07t AS t
        ON  t~domname    = 'Z8D_REJECT_CODE'
        AND t~ddlanguage = @sy-langu
        AND t~as4local   = 'A'
        AND t~domvalue_l = h~reject_reason
   WHERE ( h~reject_reason = @gv_rej OR @gv_rej = '' )
     AND h~guebg IN @s_guebg
     AND (    h~status IN ('30', '40')
           OR ( h~status = '20' AND bl~paystat = '03' ) )
     AND h~bupla = @gs_branch-bupla
    INTO CORRESPONDING FIELDS OF TABLE @gt_quot_det.

  IF sy-subrc <> 0.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    " RETURN 하지 않음: 0건이어도 하단을 비워 이전 지사 내역이 남지 않게 함
  ENDIF.

  CLEAR: gs_branch, gs_pend.

  go_alv_bot->refresh_table_display( ).

ENDFORM.

*FORM get_detail_data USING pv_index TYPE lvc_index.
*
*  DATA(lv_txt_exp) = CONV ddtext( TEXT-t01 ).  " 기한 만료
*  DATA(lv_txt_nor) = CONV ddtext( TEXT-t02 ).  " 사유 미입력
*
*
*  " 안전 장치: 유효하지 않은 행(헤더 등)을 클릭했을 경우 종료
*  IF pv_index <= 0.
*    RETURN.
*  ENDIF.
*
*  " 지사별 검색
*  READ TABLE gt_branch INTO gs_branch INDEX pv_index.
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*  SELECT h~*,
*         b~*,
*         v~*,
*         q~*,
*         CASE
*           WHEN h~reject_reason <> @space  THEN t~ddtext
*           WHEN h~gueen < @sy-datum        THEN @lv_txt_exp
*           ELSE                                 @lv_txt_nor
*         END AS rej_text
*    FROM z8sd_quotation_h AS h
*      INNER JOIN z8sd_quot_req AS q ON h~request_id = q~request_id
*      LEFT OUTER JOIN z8branch_m AS b ON b~branch = h~bupla
*      LEFT OUTER JOIN z8plant_m AS v  ON v~werks = h~werks AND v~bupla = h~bupla
*      LEFT OUTER JOIN dd07t AS t
*        ON  t~domname    = 'Z8D_REJECT_CODE'
*        AND t~ddlanguage = @sy-langu
*        AND t~as4local   = 'A'
*        AND t~domvalue_l = h~reject_reason
*   WHERE ( h~reject_reason = @gv_rej OR @gv_rej = '' )
*     AND h~guebg IN @s_guebg
*     AND ( h~gueen < @sy-datum OR h~status = '30' OR h~status = '40' )  " 현행 유지
*     AND h~bupla = @gs_branch-bupla
*    INTO CORRESPONDING FIELDS OF TABLE @gt_quot_det.
*  IF sy-subrc <> 0. MESSAGE s050(z8_msg) DISPLAY LIKE 'E'. RETURN. ENDIF.
*
*  CLEAR :
*    gs_branch, gs_pend.
*
*  go_alv_bot->refresh_table_display( ).
*  IF sy-subrc <> 0.
*    MESSAGE e022(z8_msg).
*  ENDIF.
*
*ENDFORM.

"
