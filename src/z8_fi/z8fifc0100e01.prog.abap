*&---------------------------------------------------------------------*
*& Include          Z8FIFC0100E01
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
AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_kunnr.
  PERFORM f4_kunnr.

AT SELECTION-SCREEN OUTPUT. "1000번 화면의 PBO로직

  "회사 코드는 입력 불가
  LOOP AT SCREEN.
    IF screen-name = 'PA_BUKRS'.
      screen-input = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

  PERFORM get_comment_text.

START-OF-SELECTION.
  PERFORM update_due_status.
  PERFORM get_data_100. "ALV에 출력할 데이터 취득
  PERFORM set_cell_style_100.

  IF gt_bill IS INITIAL.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CALL SCREEN '100'. "ALV 화면 띄우기
