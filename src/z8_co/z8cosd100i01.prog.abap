*&---------------------------------------------------------------------*
*& Include          Z8COSD100I01
*&---------------------------------------------------------------------*

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'SRCH' OR 'SHOW'.
      IF s_guebg IS INITIAL. MESSAGE s121(z8_msg) WITH |조회기간| DISPLAY LIKE 'E'. RETURN. ENDIF.

      READ TABLE s_guebg INTO DATA(ls_date) INDEX 1.
      IF sy-subrc = 0.

        " 3. 시작일은 비어있는데 종료일(High)만 입력된 경우 차단
        IF s_guebg-low IS INITIAL AND ls_date-high IS NOT INITIAL.
          MESSAGE '시작일 없이 종료일만 단독으로 입력할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " 4. 시작일이 종료일보다 늦은 경우 차단
        IF ls_date-low IS NOT INITIAL AND ls_date-high IS NOT INITIAL.
          IF ls_date-low > ls_date-high.
            MESSAGE '시작일이 종료일보다 늦을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.
        ENDIF.

      ENDIF.

      IF sy-ucomm = 'SHOW'.
        PERFORM show_popup_alv .
        RETURN.
      ENDIF.

      IF sy-ucomm = 'SRCH'.
        CLEAR : gt_pend, gt_branch, gt_quot_det.
        CLEAR : gs_pend, gs_branch, gs_quot_det.
      endif.

      PERFORM get_data.
      PERFORM align_right.
      PERFORM get_alv_data.   " ALV 상단

    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      LEAVE PROGRAM.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
