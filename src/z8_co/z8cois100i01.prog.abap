*&---------------------------------------------------------------------*
*& Include          Z8COIS100I01
*&---------------------------------------------------------------------*

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      LEAVE TO SCREEN 0.

    WHEN 'SRCH'.
      IF p_f_yr IS INITIAL OR p_f_qt IS INITIAL OR
         p_t_yr IS INITIAL OR p_t_qt IS INITIAL.
        MESSAGE s226(z8_msg) DISPLAY LIKE 'E'.
        RETURN. " 로직을 더 이상 진행하지 않고 화면으로 돌아감
      ENDIF.

      " 논리적 오류 검증 (시작 분기가 종료 분기보다 미래인지 체크)
      IF |{ p_f_yr }{ p_f_qt }| > |{ p_t_yr }{ p_t_qt }|.
        MESSAGE s227(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      " 1. 입력된 분기를 s_date(실제 DB 조회용 일자 Range)로 변환
      CLEAR s_date[].
      s_date-sign   = 'I'.
      s_date-option = 'BT'.

      " 시작일(LOW) 세팅
      CASE p_f_qt.
        WHEN '1'. s_date-low = p_f_yr && '0101'.
        WHEN '2'. s_date-low = p_f_yr && '0401'.
        WHEN '3'. s_date-low = p_f_yr && '0701'.
        WHEN '4'. s_date-low = p_f_yr && '1001'.
      ENDCASE.

      " 종료일(HIGH) 세팅
      CASE p_t_qt.
        WHEN '1'. s_date-high = p_t_yr && '0331'.
        WHEN '2'. s_date-high = p_t_yr && '0630'.
        WHEN '3'. s_date-high = p_t_yr && '0930'.
        WHEN '4'. s_date-high = p_t_yr && '1231'.
      ENDCASE.
      APPEND s_date.

      " 1825일(5년) 초과 검색 방지 로직 유지
      DATA(lv_diff) = s_date-high - s_date-low.
      IF lv_diff > 1825.
        MESSAGE s205(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      " 입력 기간에 대한 프로젝트 존재 여부 체크
      SELECT *
        INTO TABLE @DATA(lt_project)
        FROM z8ps_project
       WHERE sdate IN @s_date.

      " 2. Tree ALV 갱신 처리
      IF lt_project[] IS INITIAL.
        MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
        EXIT.
      ELSE.
        PERFORM create_alv.
        PERFORM get_tree_data.

        IF go_alv_tree IS NOT INITIAL.
          go_alv_tree->delete_all_nodes( ).
          PERFORM create_tree_nodes.
          go_alv_tree->frontend_update( ).
          PERFORM expand_default_nodes.
        ENDIF.

        CALL METHOD cl_gui_cfw=>flush.
      ENDIF.
  ENDCASE.
ENDMODULE.
