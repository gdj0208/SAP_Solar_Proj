*&---------------------------------------------------------------------*
*& Include          Z8FICR0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form call_fiap_program
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_fidp_program .

  SUBMIT z8fidp0100
  WITH pa_bukrs = gc_bukrs
  WITH pa_bran = pa_bran
  WITH pa_kunnr = pa_kunnr
  WITH pa_vbeln = pa_vbeln
  WITH so_fkdat IN so_fkdat
  WITH pa_r3 = pa_r3
  WITH pa_r1 = pa_r1
  WITH pa_r2 = pa_r2
  WITH pa_r4 = pa_r4
  AND RETURN.

  "WITH 호출되는 프로그램 변수 = 호출하는 프로그램 변수

ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_fifc_program
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_fifc_program .

  SUBMIT z8fifc0100
  WITH pa_bukrs = gc_bukrs
  WITH pa_bran = pa_bran
  WITH pa_kunnr = pa_kunnr
  WITH pa_vbeln = pa_vbeln
  WITH so_fkdat IN so_fkdat
  WITH pa_r3 = pa_r3
  WITH pa_r1 = pa_r1
  WITH pa_r2 = pa_r2
  WITH pa_r4 = pa_r4
  AND RETURN.

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
