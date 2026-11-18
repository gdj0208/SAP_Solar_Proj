*&---------------------------------------------------------------------*
*& Include          Z8SDD0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.
  DATA: lv_result    TYPE abap_bool,
        lv_answer(1) TYPE c.

  CLEAR: lv_result, lv_answer.

  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO TRANSACTION 'SESSION_MANAGER'.

    WHEN 'SEARCH'.

      IF gv_sdate IS INITIAL.
        MESSAGE S124(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      IF gv_edate IS NOT INITIAL AND gv_sdate > gv_edate.
        MESSAGE S047(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

     PERFORM get_data.

    WHEN 'REFR'.
*      CLEAR: gv_werks, gv_search_so, gv_status_d, gv_status_mat.

      PERFORM set_default_date.

      PERFORM get_data.

    WHEN 'CREA'.
      CLEAR: lv_result, lv_answer.

      PERFORM get_selected_line CHANGING lv_result.

      IF lv_result = abap_false.
        RETURN.
      ENDIF.

      PERFORM validation1 CHANGING lv_result. "검증 로직

      IF lv_result = abap_true.

        PERFORM enqueue_so CHANGING lv_result.

        IF lv_result = abap_false.
          RETURN.
        ENDIF.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = TEXT-010 "안내
            text_question         = TEXT-005
            text_button_1         = TEXT-003
            text_button_2         = TEXT-004
            display_cancel_button = space
          IMPORTING
            answer                = lv_answer.

        IF lv_answer <> '1'.
          MESSAGE S030(z8_msg) DISPLAY LIKE 'E'.
          PERFORM dequeue_so.
          RETURN.
        ENDIF.

        PERFORM create_delivery.

        PERFORM get_data. "성공 후 DB 재조회
      ENDIF.

    WHEN 'PICK'.
      CLEAR: lv_answer, lv_result.

      PERFORM get_selected_line CHANGING lv_result.

      IF lv_result = abap_false.
        RETURN.
      ENDIF.

      PERFORM validation2 CHANGING lv_result.

      IF lv_result = abap_false.
        RETURN.
      ENDIF.

      PERFORM enqueue_so CHANGING lv_result.

      IF lv_result = abap_false.
        RETURN.
      ENDIF.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = TEXT-010 "안내
          text_question         = TEXT-007
          text_button_1         = TEXT-003
          text_button_2         = TEXT-004
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer.

      IF lv_answer <> '1'.
        MESSAGE S030(z8_msg) DISPLAY LIKE 'E'.
        PERFORM dequeue_so.
        RETURN.
      ENDIF.

      PERFORM picking CHANGING lv_result.

      PERFORM get_data.

    WHEN 'GI'.
      PERFORM get_selected_line CHANGING lv_result.

      IF lv_result = abap_false.
        RETURN.
      ENDIF.

      PERFORM validation3 CHANGING lv_result.

      IF lv_result = abap_false.
        RETURN.
      ENDIF.

      PERFORM enqueue_so CHANGING lv_result.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = TEXT-010 "안내
          text_question         = TEXT-009
          text_button_1         = TEXT-003
          text_button_2         = TEXT-004
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer.

      IF lv_answer <> '1'.
        MESSAGE S030(z8_msg) DISPLAY LIKE 'E'.
        PERFORM dequeue_so.
        RETURN.
      ENDIF.

      PERFORM gi.


      PERFORM get_data.


* ZZRSVQTY (예약재고 감소) LABST (현재고 감소)
* 자재 문서, 회계전표 생성

  ENDCASE.
ENDMODULE.
