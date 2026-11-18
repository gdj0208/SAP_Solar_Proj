*&---------------------------------------------------------------------*
*& Include          Z8MMDS0100I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE ok_code..
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'TAB1' OR 'TAB2' OR 'TAB3'.
      PERFORM free_alv_list.
      ts_main-activetab = ok_code.
*    WHEN 'MATSEL'.                           " 드롭다운에서 자재 선택
    WHEN 'MVSRCH'.
      PERFORM check_day_move.
      IF gv_day_err IS INITIAL.               "검사 통과했을 때만 조회.
        gv_kind_sel  = '전체'.
        gv_mv_reload = 'X'.                    " 탭3. 조회: DB에서 다시 읽기
     ENDIF.
    WHEN 'KINDSEL'.
      gv_mv_filter = 'X'.          " 유형 선택: 이미 읽은 데이터만 다시 거르기
  ENDCASE.

ENDMODULE.
