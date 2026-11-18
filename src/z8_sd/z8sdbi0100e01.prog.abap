*&---------------------------------------------------------------------*
*& Include          Z8SDBI0100E01
*&---------------------------------------------------------------------*
INITIALIZATION.

  authority-check object 'Z8SD_AUTH'
  id 'ACTVT' field '16'. " 16: Execute (실행)
  IF sy-subrc <> 0.

    MESSAGE A200(z8_msg) WITH 'SD'. " 권한이 없으면 E(Error) 메시지를 띄워 화면 진입 자체를 차단
  ENDIF.

  PERFORM set_default_date.

AT SELECTION-SCREEN.
  PERFORM check_required.

START-OF-SELECTION.
  IF  p_detail IS NOT INITIAL.
    gv_detail_vbeln = p_detail.
    "청구서 조회
    PERFORM show_billing.
    RETURN.
  ENDIF.
IF p_r1 = 'X'.          "선수금  조회- 견적
  PERFORM get_data_quot.

  IF gt_quot IS INITIAL.
    MESSAGE '조회된 견적이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CALL SCREEN 0100.
ELSE.                     "잔금 조회- SO
  PERFORM get_data_so.

    IF gt_so IS INITIAL.
      MESSAGE '조회된 SO가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    CALL SCREEN 0110.
ENDIF.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    "잔금이면 견적 조건 숨김
    IF screen-group1 = 'QUO' AND p_r2 = 'X'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.

    "선수금이면 SO 조건 숨김
    IF screen-group1 = 'SO' AND p_r1 = 'X'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
