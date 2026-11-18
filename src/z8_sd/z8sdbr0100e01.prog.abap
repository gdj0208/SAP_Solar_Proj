*&---------------------------------------------------------------------*
*& Include          Z8SDBR0100E01
*&---------------------------------------------------------------------*

* 초기값: 견적일 최근 3개월
INITIALIZATION.
  authority-check object 'Z8SD_AUTH'
  id 'ACTVT' field '16'. " 16: Execute (실행)
  IF sy-subrc <> 0.

    MESSAGE A200(z8_msg) WITH 'SD'. " 권한이 없으면 E(Error) 메시지를 띄워 화면 진입 자체를 차단
  ENDIF.
  PERFORM set_default_date.

AT SELECTION-SCREEN.
  "필수값 체크
    PERFORM check_required.

* 실행
START-OF-SELECTION.
*IF p_detail IS NOT INITIAL.
*  gv_detail_vbeln = p_detail.
*  PERFORM show_billing.
*  RETURN.
*ENDIF.
  PERFORM get_data_contract.

  IF gt_contract IS INITIAL.
    MESSAGE '조회된 계약이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL SCREEN 0100.
