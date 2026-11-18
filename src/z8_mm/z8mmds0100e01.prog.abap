*&---------------------------------------------------------------------*
*& Include          Z8MMDS0100E01
*&---------------------------------------------------------------------*
INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.
  ENDIF.

START-OF-SELECTION.
"탭1 목록ALV
  SELECT * FROM z8mm_c_matstock
    WHERE werks IN @s_werks
      AND matnr IN @s_matnr
      AND mtart IN @s_mtart
    INTO CORRESPONDING FIELDS OF TABLE @gt_list.

  IF p_warn = 'X'.
    DELETE gt_list WHERE status  <> 'R'.
  ELSEIF p_short = 'X'.
    DELETE gt_list WHERE status <> 'Y'.
  ENDIF.
    IF gt_list IS INITIAL.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<ls_list>).
    CASE <ls_list>-status.
      WHEN 'R'. <ls_list>-light = '1'.
      WHEN 'Y'. <ls_list>-light = '2'.
      WHEN OTHERS. <ls_list>-light = '3'.
    ENDCASE.
  ENDLOOP.
  "부족한 건이 위로 오도록.
  SORT gt_list BY light level_pct matnr werks.     " 빨강 → 노랑 → 초록, 같은 색은 수준이 낮은 것부터

*  IF gt_stock IS INITIAL.
*    MESSAGE '조회된 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'W'.
*    RETURN.
*  ENDIF.

ts_main-activetab = 'TAB1'.
CALL SCREEN 0100.
