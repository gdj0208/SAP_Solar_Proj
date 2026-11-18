*&---------------------------------------------------------------------*
*& Include          Z8FIAP0100E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.

INITIALIZATION.
PERFORM authority_check .
PERFORM set_default_data.

*"회사코드 텍스트
*PERFORM get_text.

AT SELECTION-SCREEN.

  PERFORM check_obligatory.
  PERFORM comment_clear.

  AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_bran.
  PERFORM f4_bupla.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_lifnr.
  PERFORM f4_lifnr.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_invno.
  PERFORM f4_pa_invno.

AT SELECTION-SCREEN OUTPUT.
  "회사 코드는 입력 불가
  LOOP AT SCREEN.
    IF screen-name = 'PA_BUKRS'.
      screen-input = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

  PERFORM get_comment_text.

START-OF-SELECTION.
  PERFORM get_data_100.
  PERFORM set_cell_style_100.

  IF gt_vendor IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CALL SCREEN '0100'.
