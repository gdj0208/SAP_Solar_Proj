*&---------------------------------------------------------------------*
*& Include          Z8FIGL0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'REFR'.
      PERFORM refresh_alv_100.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

*  DATA lv_ok_code TYPE sy-ucomm.
*  CLEAR ok_code.

  CASE ok_code.
    WHEN 'BACK' OR 'CANCEL'.
      PERFORM free_control_200.
      CLEAR  ok_code.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      CLEAR  ok_code.
      LEAVE PROGRAM.
    WHEN 'SEARCH'.
      CLEAR  ok_code.
      PERFORM check_condition_200.

      IF gv_error = 'X'.
        RETURN.
      ENDIF.

      PERFORM refresh_alv_200.

      IF gt_alv_200 IS INITIAL.
        MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
      ENDIF.

  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  GET_BLARTT_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_blartt_0200 INPUT.

  CLEAR gv_blartt.

  IF gv_blart IS NOT INITIAL.

    SELECT SINGLE ltext
      FROM t003t
      INTO gv_blartt
      WHERE spras = sy-langu
        AND blart = gv_blart.

  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_BLART_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_blart_0200 INPUT.

  TYPES: BEGIN OF ty_blart,
           blart TYPE z8fi_accdoc_h-blart,
           ltext TYPE t003t-ltext,
         END OF ty_blart.

  DATA:
    lt_blart TYPE TABLE OF ty_blart,
    ls_blart TYPE ty_blart.

  CLEAR:
   lt_blart,
   gt_return,
   gs_return,
   gt_dynp,
   gs_dynp.

  "현재 선택한 gl계정에서 실제 발생한 blart만 추출
  LOOP AT gt_gl_detail INTO gs_gl_detail WHERE hkont = gs_gl_sel-saknr.

    READ TABLE lt_blart WITH KEY blart = gs_gl_detail-blart TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      CLEAR ls_blart.
      ls_blart-blart = gs_gl_detail-blart.

      SELECT SINGLE ltext
        FROM t003t
        INTO ls_blart-ltext
        WHERE spras = sy-langu
        AND blart = gs_gl_detail-blart.

      APPEND ls_blart TO lt_blart.
    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = ' '
      retfield        = 'BLART'
*     PVALKEY         = ' '
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GV_BLART'
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
*   IMPORTING
*     USER_RESET      =
    TABLES
      value_tab       = lt_blart
*     FIELD_TAB       =
      return_tab      = gt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "F4에서 선택한 전표유형
  READ TABLE gt_return INTO gs_return INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  gv_blart = gs_return-fieldval.

  "전표유형명 조회
  CLEAR gv_blartt.

  SELECT SINGLE ltext
    FROM t003t
    INTO gv_blartt
    WHERE spras = sy-langu
      AND blart = gv_blart.

  "화면 즉시 갱신
  CLEAR gt_dynp.

  "전표유형
  CLEAR gs_dynp.
  gs_dynp-fieldname  = 'GV_BLART'.
  gs_dynp-fieldvalue = gv_blart.
  APPEND gs_dynp TO gt_dynp.

  "전표유형명
  CLEAR gs_dynp.
  gs_dynp-fieldname  = 'GV_BLARTT'.
  gs_dynp-fieldvalue = gv_blartt.
  APPEND gs_dynp TO gt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = gt_dynp.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CLEAR_BLART_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE clear_blart_0200 INPUT.

  IF gv_blart IS INITIAL.
    CLEAR gv_blartt.

  ELSE.

    "직접 입력 시에도
    SELECT SINGLE ltext
      FROM t003t
      INTO gv_blartt
      WHERE spras = sy-langu
      AND blart = gv_blart.

    IF sy-subrc <> 0.
      CLEAR gv_blartt.
    ENDIF.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  GET_BUPLAT_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE clear_bupla_0200 INPUT.

  IF gv_bupla IS INITIAL.
    CLEAR gv_buplat.
  ELSE.

    "직접 입력 시에도
    SELECT SINGLE name
      FROM z8branch_m
      INTO gv_buplat
      WHERE branch = gv_bupla.

    IF sy-subrc <> 0.
      CLEAR gv_buplat.
    ENDIF.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_BUPLA_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_bupla_0200 INPUT.

  TYPES: BEGIN OF ty_bupla,
           bupla TYPE z8fi_accdoc_i-bupla,
           name  TYPE z8branch_m-name,
         END OF ty_bupla.

  DATA:
    lt_bupla  TYPE STANDARD TABLE OF ty_bupla.

  CLEAR:
   lt_bupla,
   gt_return,
   gs_return,
   gt_dynp,
   gs_dynp.

  SELECT branch AS bupla name
    FROM z8branch_m
    INTO TABLE lt_bupla
    WHERE bukrs = gc_bukrs
    AND branch IN so_bran.

  SORT lt_bupla BY bupla.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BUPLA'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GV_BUPLA'
      value_org       = 'S'
    TABLES
      value_tab       = lt_bupla
*     FIELD_TAB       =
      return_tab      = gt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "F4에서 선택한 지사
  READ TABLE gt_return INTO gs_return INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  gv_bupla = gs_return-fieldval.

  "지사명 조회
  CLEAR gv_buplat.

  READ TABLE lt_bupla INTO DATA(ls_bupla) WITH KEY bupla = gv_bupla.

  IF sy-subrc = 0.
    gv_buplat = ls_bupla-name.
  ENDIF.

    "화면 즉시 갱신
  CLEAR gt_dynp.

  CLEAR gs_dynp.
  gs_dynp-fieldname  = 'GV_BUPLA'.
  gs_dynp-fieldvalue = gv_bupla.
  APPEND gs_dynp TO gt_dynp.

  CLEAR gs_dynp.
  gs_dynp-fieldname  = 'GV_BUPLAT'.
  gs_dynp-fieldvalue = gv_buplat.
  APPEND gs_dynp TO gt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = gt_dynp.



ENDMODULE.
