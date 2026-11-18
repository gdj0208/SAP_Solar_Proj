*&---------------------------------------------------------------------*
*& Include          Z8SDQ0100E01
*&---------------------------------------------------------------------*
INITIALIZATION.


  AUTHORITY-CHECK OBJECT 'Z8SD_AUTH'
  ID 'ACTVT' FIELD '16'. " 16: Execute (실행)
  IF sy-subrc <> 0.

    MESSAGE e200(z8_msg) WITH 'SD'. " 권한이 없으면 E(Error) 메시지를 띄워 화면 진입 자체를 차단
  ENDIF.

  PERFORM set_toolbar.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_reqid. "F4 Help를 코드로 구현
  PERFORM set_search_help.

AT SELECTION-SCREEN.

*  IF sy-dynnr = '1330'.
*    RETURN.
*  ENDIF.

  IF pa_reqid IS INITIAL.
    CLEAR gv_txt1.
  ELSE.
    PERFORM get_dom_val.
  ENDIF.

  CASE sy-ucomm.
    WHEN 'FC01'. "견적 템플릿 다운로드

      PERFORM check_reqid.
      PERFORM excel_download.

    WHEN 'FC02'.

      CLEAR gv_1300_reqid.
      PERFORM check_reqid. "해당 요청번호가 있는지 확인하는 로직
      gv_req_mode = 'R'.
      gv_1300_reqid = pa_reqid.

      PERFORM get_quot_list.

      READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.

      IF sy-subrc = 0.
        gv_selected_id    = gw_quot_list-vbeln_q.
        PERFORM get_quot_item USING gv_selected_id.
      ELSE.
        MESSAGE s045(z8_msg) DISPLAY LIKE 'E'. "견적 조회 실패
        RETURN.
      ENDIF.


      CALL SCREEN '1300'.

    WHEN 'FC03'.
      CLEAR: gv_1300_reqid, gv_req_mode, gv_customer.
      gv_req_mode = 'A'.
      PERFORM init_search_condition. "최초 1회 전체 견적 조회 기간 30일 세팅

      PERFORM get_quot_list.

      READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.

      IF sy-subrc = 0.
        gv_selected_id    = gw_quot_list-vbeln_q.
        PERFORM get_quot_item USING gv_selected_id.

      ELSE.
        MESSAGE s045(z8_msg) DISPLAY LIKE 'E'. "견적 조회 실패
        RETURN.
      ENDIF.

      CALL SCREEN '1300'.

  ENDCASE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_file. "F4 이벤트를 직접 처리해서 파일 선택창 띄움 -> select_file
  PERFORM select_file CHANGING pa_file.

AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.
  DATA lv_result TYPE abap_bool.

* 1. 엑셀 데이터 읽기
  IF pa_file IS INITIAL.
    MESSAGE s007(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM get_excel_data.

* 2. 데이터 검증
  PERFORM validate_excel_data CHANGING lv_result. "엑셀 데이터 필수값 확인 및 데이터 검증

  IF lv_result EQ abap_false.
    RETURN.
  ENDIF.

  PERFORM valid_excel_item. "엑셀 데이터 -> ALV

  PERFORM update_expired_quotation. "승인대기 & 기한 만료된 견적 확인하여 상태 업데이트

  PERFORM check_exec_val CHANGING lv_result. "견적 생성 가능 여부 확인

  IF lv_result EQ abap_true.
    CALL FUNCTION 'ENQUEUE_EZ8_QUOTATION'
      EXPORTING
        mode_z8sd_quot_req = 'E'
        request_id         = gs_req-request_id
      EXCEPTIONS
        foreign_lock       = 1
        system_failure     = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
      MESSAGE S228(z8_msg) DISPLAY LIKE 'E'. "다른 사용자가 해당 요청의 견적을 생성 중입니다
      RETURN.
    ENDIF.

    CALL SCREEN 1100.
  ENDIF.

* 3. 견적서 관련하여 가용재고 조회 / 지사 배정 등의 정보 세팅
* 4. 확정 견적 생성 시 해당 견적 번호에 대한 견적서 업데이트 / req-status 변경

END-OF-SELECTION.
