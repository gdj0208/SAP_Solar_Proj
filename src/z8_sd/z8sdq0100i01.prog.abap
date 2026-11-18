*&---------------------------------------------------------------------*
*& Include          Z8SDQ0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1100 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      CALL FUNCTION 'DEQUEUE_EZ8_QUOTATION'
        EXPORTING
          mode_z8sd_quot_req = 'E'
          request_id         = gs_quot_h-request_id.
      LEAVE TO SCREEN 0.
    WHEN 'WRIT'.
      PERFORM quot_validation.

  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1200 INPUT.
  CASE ok_code.
      DATA: lv_answer TYPE abap_bool.
      CLEAR lv_answer.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = '종료 확인'
          text_question         = '기존 작성 내역이 사라집니다. 종료하시겠습니까?'
          text_button_1         = '예'
          text_button_2         = '아니오'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer.

      IF lv_answer = '1'.
        LEAVE TO SCREEN 0.
      ENDIF.
    WHEN 'SAVE'.
      PERFORM save_quotation.
    WHEN 'MOVE'.
*      CALL SCREEN 1300.
      LEAVE TO SCREEN 1300.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1300 INPUT.
  CASE ok_code.

    WHEN 'EXIT' OR 'CANCEL' OR 'BACK'.

      CLEAR: ok_code,
             gv_search_status,
             gv_bupla_search.

      PERFORM free_constrol_resource.
      LEAVE TO SCREEN 0.


    WHEN 'REFR'.
      DATA: ls_selected TYPE z8sd_quotation_h.

      CLEAR ls_selected.

      PERFORM get_selected_quot USING abap_false
                            CHANGING ls_selected.

      IF ls_selected-vbeln_q IS NOT INITIAL.
        gv_selected_id = ls_selected-vbeln_q.
      ENDIF.

      PERFORM get_quot_list.
      PERFORM get_quot_item USING gv_selected_id.
      PERFORM quot_list_refresh.
      PERFORM select_row1300 USING gv_selected_id.
      CLEAR ok_code.

    WHEN 'PRIN'.

      PERFORM print_quotation.
      CLEAR ok_code.

    WHEN 'DENY' OR 'ACCE'.
      PERFORM update_quot_status.
      PERFORM get_quot_list.
      PERFORM quot_list_refresh.
      PERFORM get_quot_item USING gv_selected_id.
      PERFORM select_row1300 USING gv_selected_id.
      CLEAR ok_code.

    WHEN 'SEARCH'.

      IF gv_audat_from IS INITIAL.

        MESSAGE s124(z8_msg) DISPLAY LIKE 'E'.

        RETURN.

      ENDIF.

      IF gv_audat_from > sy-datum.

        MESSAGE s123(z8_msg) DISPLAY LIKE 'E'.

        RETURN.

      ENDIF.

      PERFORM get_quot_list.

      READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.

      IF sy-subrc = 0.

        PERFORM get_quot_item USING gw_quot_list-vbeln_q.

      ELSE.

        PERFORM get_quot_item USING ' '.

      ENDIF.

      PERFORM quot_list_refresh.

      PERFORM select_row1300 USING gw_quot_list-vbeln_q.

    WHEN 'TAB1'.
      gv_req_mode = 'R'.
      tabstrip1300-activetab = 'TAB1'.

      PERFORM get_quot_list.

      CLEAR: gw_quot_list, gv_selected_id, gt_quot_item.

      IF gv_selected_id IS INITIAL.
        READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.
      ELSE.
        READ TABLE gt_quot_list INTO gw_quot_list WITH KEY vbeln_q = gv_selected_id.
      ENDIF.

      IF sy-subrc <> 0.
        MESSAGE s103(z8_msg) DISPLAY LIKE 'E'.
      ENDIF.

      gv_selected_id = gw_quot_list-vbeln_q.
      PERFORM get_quot_item USING gv_selected_id.

      PERFORM quot_list_refresh.

      IF gt_quot_list IS NOT INITIAL.
        PERFORM select_row1300 USING gv_selected_id.
      ENDIF.

    WHEN 'TAB2'.
      CLEAR: gw_quot_list, gv_selected_id, gt_quot_item.

      gv_req_mode = 'A'.
      tabstrip1300-activetab = 'TAB2'.

      PERFORM init_search_condition.
      PERFORM get_quot_list.

      IF gv_selected_id IS INITIAL.
        READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.
      ELSE.
        READ TABLE gt_quot_list INTO gw_quot_list WITH KEY vbeln_q = gv_selected_id.
      ENDIF.

      IF sy-subrc <> 0.
        MESSAGE s103(z8_msg) DISPLAY LIKE 'E'.
      ENDIF.

      gv_selected_id = gw_quot_list-vbeln_q.
      PERFORM get_quot_item USING gv_selected_id.

      PERFORM quot_list_refresh.

      IF gt_quot_list IS NOT INITIAL.
        PERFORM select_row1300 USING gv_selected_id.
      ENDIF.

  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1310  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1310 INPUT.
  CASE ok_code.
    WHEN 'CONTINUE' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_KUNNR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_kunnr INPUT.
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8SD_QUOTATION_H'
      fieldname   = 'KUNNR'
      searchhelp  = 'Z8SH_CUSTOMER'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'GV_CUSTOMER'. "선택한 값 할당
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1320  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1320 INPUT.
  CASE ok_code.
    WHEN 'CANCEL'.
      MESSAGE s030(z8_msg) DISPLAY LIKE 'E'.

      LEAVE TO SCREEN 0.
    WHEN 'SEND'.
      DATA: lt_mail_html  TYPE soli_tab,
            lv_answer1320 TYPE c LENGTH 1,
            lv_sent       TYPE abap_bool,
            lv_test_email TYPE adr6-smtp_addr.

      "수신자 이메일 확인
      IF gw_quot_list-email IS INITIAL.
        MESSAGE s130(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      "발송 확인 팝업
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = '견적서 메일 발송'
          text_question         = '해당 주소로 견적서를 보내시겠습니까?'
          text_button_1         = '예'
          text_button_2         = '아니오'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer1320.

      IF lv_answer1320 <> '1'.
        MESSAGE s030(z8_msg) DISPLAY LIKE 'E'.
        LEAVE TO SCREEN 0.
      ENDIF.

      "HTML 본문 생성
      PERFORM set_email_html USING gw_quot_list
                          CHANGING lt_mail_html.


*      lv_test_email = 'jiupark25@gmail.com'. "테스트 이메일 주소

      "메일 발송
      PERFORM send_quotation_mail USING gw_quot_list-email
                                        lt_mail_html
                               CHANGING lv_sent.

      IF lv_sent = abap_true.

        "메일 발송 대상 견적번호
        DATA(lv_vbeln_q) = gw_quot_list-vbeln_q.

        "DB 업데이트
        UPDATE z8sd_quotation_h
          SET is_sent = @abap_true
          WHERE vbeln_q = @lv_vbeln_q.

        IF sy-subrc = 0.

          COMMIT WORK AND WAIT.

          gv_selected_id = lv_vbeln_q.

          "DB 재조회
          PERFORM get_quot_list.

          "ALV 갱신
          PERFORM quot_list_refresh.

          "기존 선택 행 유지
          PERFORM select_row1300 USING lv_vbeln_q.

          MESSAGE s128(z8_msg).

          LEAVE TO SCREEN 0.

        ELSE.

          ROLLBACK WORK.
          MESSAGE s129(z8_msg) DISPLAY LIKE 'E'.

        ENDIF.

      ELSE.

        MESSAGE s129(z8_msg) DISPLAY LIKE 'E'.

      ENDIF.
  ENDCASE.
ENDMODULE.
