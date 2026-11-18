*&---------------------------------------------------------------------*
*& Include          Z8FIDR0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
    WHEN 'PAY'.
      PERFORM payment_process.
    WHEN 'REFR'.
      PERFORM refresh_alv_100.
  ENDCASE.

*  CASE sy-ucomm.
*    WHEN 'DCLK'.
*      "별도 처리 없음
*      "PBO를 다시 돌려 화면 값만 갱신
*
*    WHEN 'BACK'.
*      LEAVE TO SCREEN 0.
*
*  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code.
    WHEN 'BACK' OR 'CANCEL'.
      "락 풀기
      PERFORM unlock_billing.
      PERFORM free_control_200.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'POST'.
      "입금일자 필수 입력
      IF gv_date IS INITIAL.
        MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '입금일자'. "입력x
      ELSEIF gv_date > sy-datum.
        MESSAGE s074(z8_msg) DISPLAY LIKE 'E' WITH '입금일자'. "미래
      ELSEIF gv_date < gv_fkdat.
        MESSAGE s075(z8_msg) DISPLAY LIKE 'E' WITH '입금일자' '청구일자'. "청구일 이전
*      ELSEIF gv_date > gv_duedat.
*        MESSAGE s076(z8_msg) DISPLAY LIKE 'E'.
      ELSE.
        "팝업창 띄우기
        DATA lv_answer(1) TYPE c.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = '전표 생성 확인'
            text_question         = |청구번호 { gv_vbeln }의 입금 전표를 생성하시겠습니까?|
            text_button_1         = '예'(001)
            text_button_2         = '아니오'(002)
            display_cancel_button = space
            default_button        = '2'
          IMPORTING
            answer                = lv_answer.
*       EXCEPTIONS
*         TEXT_NOT_FOUND              = 1
*         OTHERS        = 2.
*
*      IF sy-subrc <> 0.
** Implement suitable error handling here
*      ENDIF.

        IF lv_answer = '1'.
          PERFORM create_accdoc.
          "방금 처리한 청구번호 기억
          gv_last_vbeln = gv_vbeln.
          "100번 화면 갱신
          gv_refresh_100 = 'X'.
          "락 풀기
          PERFORM unlock_billing.
          "200번 화면 파괴하고 100번 화면으로 돌아가기
          PERFORM free_control_200.
          LEAVE TO SCREEN 0.
        ELSE.
          MESSAGE '입금처리에 대한 회계전표 생성이 취소되었습니다.' TYPE 'S'.
        ENDIF.
      ENDIF.

  ENDCASE.

ENDMODULE.
