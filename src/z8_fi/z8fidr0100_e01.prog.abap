*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.
  CLEAR lv_init_result.

INITIALIZATION.

PERFORM authority_check.

  PERFORM set_default_date.


AT SELECTION-SCREEN.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_blart.
  PERFORM f4_blart.




AT SELECTION-SCREEN OUTPUT.

  SET TITLEBAR 'T1000'.

  PERFORM get_blart_txt.


START-OF-SELECTION.

  DATA: lv_search_result TYPE abap_bool.

  CLEAR lv_search_result.

*  PERFORM set_default_date.

  PERFORM search_validation CHANGING lv_search_result.

  IF lv_search_result = abap_false.
    RETURN.
  ENDIF.

  PERFORM get_data CHANGING lv_init_result.


  IF lv_init_result = abap_true.
    CALL SCREEN 1100.
  ENDIF.
