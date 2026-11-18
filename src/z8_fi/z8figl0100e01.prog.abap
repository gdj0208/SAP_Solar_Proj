*&---------------------------------------------------------------------*
*& Include          Z8FIGL0100E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.

INITIALIZATION.

PERFORM authority_check .
PERFORM set_default_data.

SET CURSOR FIELD 'SO_BRAN-LOW'.

"회사코드 텍스트
*PERFORM get_text.

AT SELECTION-SCREEN.

  PERFORM check_obligatory.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_saknr-low.


AT SELECTION-SCREEN OUTPUT.
  "회사 코드는 입력 불가
  LOOP AT SCREEN.
    IF screen-name = 'PA_BUKRS'.
      screen-input = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.
  PERFORM get_gldata_100.

  IF gt_gl_detail IS INITIAL AND cb_unuse IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "gl계정별 집계
  PERFORM make_alv_100.
  IF gt_alv_100 IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL SCREEN '0100'.
