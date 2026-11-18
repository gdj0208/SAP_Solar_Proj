*&---------------------------------------------------------------------*
*& Include          Z8MMMA0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'CREA'.
      CLEAR gv_matnr_sel.
      gv_mode = 'N'.
      CLEAR gv_screen_init.
      CALL SCREEN 300.
      PERFORM get_material_list.
      go_alv_100->refresh_table_display( ).
    WHEN 'STOP'.
      PERFORM deactivate_material.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'CREA'.
      CLEAR gv_lifnr_sel.
      gv_mode_v = 'N'.
      CLEAR gv_screen_init_v.
      CALL SCREEN 0400.
      PERFORM get_vendor_list.
      CALL METHOD go_alv_200->refresh_table_display.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  DATA gv_code TYPE sy-ucomm.
  gv_code = ok_code.
  CASE ok_code.
    WHEN 'EDIT'.
      CALL FUNCTION 'ENQUEUE_EZ8MATERIAL'
        EXPORTING
          matnr          = z8s_mat_detail-matnr
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
        gv_locked = 'X'.
        gv_mode   = 'E'.
      ELSEIF sy-subrc = 1.
        CONCATENATE '다른 사용자(' sy-msgv1 ')가 수정 중입니다'
               INTO gv_msg.
        MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
      ELSE.
        MESSAGE '잠금 처리 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.
    WHEN 'SAVE'.
      "변경된 데이터 불러오기. 읽기전에 불러오기.
      CALL METHOD go_alv_plant->check_changed_data.
      PERFORM save_material.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0300 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      IF gv_mode <> 'D'.                       " 조회 모드가 아니면 확인
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = '확인'
            text_question         = '수정 중인 내용은 저장되지 않습니다. 나가시겠습니까?'
            text_button_1         = '나가기'
            text_button_2         = '계속 수정'
            default_button        = '2'
            display_cancel_button = space
          IMPORTING
            answer                = gv_ans2.
        IF gv_ans2 <> '1'.
          CLEAR ok_code.
          RETURN.                              " 계속 수정: 화면에 남음
        ENDIF.
      ENDIF.

      CLEAR: ok_code, gv_screen_init.
      PERFORM free_alv_plant.
      PERFORM unlock_material.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0400 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.

      IF gv_mode_v <> 'D'.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = '확인'
            text_question         = '수정 중인 내용은 저장되지 않습니다. 나가시겠습니까?'
            text_button_1         = '나가기'
            text_button_2         = '계속 수정'
            default_button        = '2'
            display_cancel_button = space
          IMPORTING
            answer                = gv_ans2.
        IF gv_ans2 <> '1'.
          CLEAR ok_code.
          RETURN.
        ENDIF.
      ENDIF.

      CLEAR: ok_code, gv_screen_init_v.
      PERFORM unlock_vendor.
      PERFORM free_alv_vmat.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0400 INPUT.
  CASE ok_code.
    WHEN 'EDIT'.
      CALL FUNCTION 'ENQUEUE_EZ8VENDOR'
        EXPORTING
          lifnr          = z8s_vend_detail-lifnr
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
        gv_locked_v = 'X'.
        gv_mode_v   = 'E'.
      ELSEIF sy-subrc = 1.
        CONCATENATE '다른 사용자(' sy-msgv1 ')가 수정 중입니다'
               INTO gv_msg.
        MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
      ELSE.
        MESSAGE '잠금 처리 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.
    WHEN 'SAVE'.
      "사용자가 입력한 값을 읽을 수 있도록 함.
      CALL METHOD go_alv_vmat->check_changed_data.
      PERFORM save_vendor.

   ENDCASE.

ENDMODULE.
