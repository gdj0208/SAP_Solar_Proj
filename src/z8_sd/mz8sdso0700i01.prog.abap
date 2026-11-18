*&---------------------------------------------------------------------*
*& Include          MZ8SDSO0700I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.
  DATA: lv_val TYPE abap_bool.
  CLEAR: lv_val, gv_sel_line_flag.

  CASE ok_code.
    WHEN 'REFR'.

      PERFORM get_selected_line CHANGING lv_val.

      PERFORM get_data.

    WHEN 'CREA'.
      gv_sel_line_flag = abap_true.

      PERFORM create_so.

      PERFORM get_selected_line CHANGING lv_val.

    WHEN 'PLAN'.
      gv_sel_line_flag = abap_true.

      PERFORM set_sdate.

    WHEN 'ALLO'.
      gv_sel_line_flag = abap_true.

      PERFORM get_selected_line CHANGING lv_val.

      PERFORM alloc_validate CHANGING lv_val.

      IF lv_val = abap_true.
        PERFORM open_fiori_project USING gw_so_h-pro_id.
      ENDIF.

    WHEN 'SEARCH'.
      IF gv_audat_from IS INITIAL.
        MESSAGE s124(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gv_audat_to IS NOT INITIAL AND gv_audat_from > gv_audat_to.
        MESSAGE s047(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      PERFORM get_data.

    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO TRANSACTION 'SESSION_MANAGER'.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_CUSTOMER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_customer INPUT.
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8CUSTOMER_M'
      fieldname   = 'KUNNR'
      searchhelp  = 'Z8SH_CUSTOMER'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'GV_CUSTOMER'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1010  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1010 INPUT.
  DATA: lv_answer.
  CLEAR: lv_answer.
  CASE ok_code.

    WHEN 'CANCEL'.
      LEAVE TO SCREEN 0.

    WHEN 'CONFIRM'.
      DATA: lv_question_txt TYPE char60.
      CLEAR lv_question_txt.

      IF gw_date-sdate < sy-datum.
        MESSAGE i212(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gw_so_h-status_s = '10'.
        lv_question_txt = '공사 시작일을 확정하시겠습니까?'.
      ELSEIF gw_so_h-status_s = '20'.
        lv_question_txt = '공사 시작일을 변경하시겠습니까?'.
      ENDIF.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = '설치 일정 수립'
          text_question         = lv_question_txt
          text_button_1         = '예'
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = '아니오'
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '1'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer.
      IF lv_answer = 1.
      ELSE.
        MESSAGE i030(z8_msg).
        RETURN.
      ENDIF.

      PERFORM save_date. "설치일정 저장

  ENDCASE.

  CLEAR gw_date.

ENDMODULE.
