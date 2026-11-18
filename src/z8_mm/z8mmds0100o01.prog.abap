*&---------------------------------------------------------------------*
*& Include          Z8MMDS0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
SET PF-STATUS 'S0100'.
 SET TITLEBAR 'T0100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_SUBSCREEN OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_subscreen OUTPUT.
  CASE ts_main-activetab.
    WHEN 'TAB1'.
      gv_dynnr = '0110'.
    WHEN 'TAB2'.
      gv_dynnr = '0120'.
    WHEN 'TAB3'.
      gv_dynnr = '0130'.
    WHEN OTHERS.
      ts_main-activetab = 'TAB1'.
      gv_dynnr = '0110'.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_LIST_0110 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0110 OUTPUT.
  IF go_grid_list IS INITIAL.
    CLEAR: gv_node_key, gv_status.        " 이전 선택 초기화
    PERFORM create_objects_list.
    PERFORM set_tree_nodes.
    PERFORM create_objects_tree.
    PERFORM set_event_handler_tree.
    PERFORM set_kpi_html USING '전체'.
    PERFORM set_layout_list.
    PERFORM set_fieldcat_list.
    PERFORM display_alv_list.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_MOVE_0130 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_move_0130 OUTPUT.
  IF go_grid_move IS INITIAL.
    gv_budat_to = sy-datum.
    gv_budat_fr = sy-datum - 30.                       " 기본: 최근 30일
    gv_kind_sel  = '전체'.
    gv_mv_reload = 'X'.
    PERFORM create_objects_move.
    PERFORM create_html_mvf.   "HTML
    PERFORM set_layout_move.
    PERFORM set_fieldcat_move.
    PERFORM set_event_handler_move.
    PERFORM display_alv_move.
  ENDIF.

    IF gv_mv_reload = 'X'.
    PERFORM set_move_data.                     " DB에서 다시 읽기
    gv_mv_filter = 'X'.
    CLEAR gv_mv_reload.
  ENDIF.

*  PERFORM set_kind_dropdown.                 "드롭다운은 PBO마다 값세팅.
  IF gv_mv_filter = 'X'.
    PERFORM filter_move.
    PERFORM set_mv_html.          "HTML
    PERFORM set_grid_title_move.
    go_grid_move->refresh_table_display( ).
    CLEAR gv_mv_filter.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_TABSTRIP OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_tabstrip OUTPUT.
    "탭스트립
  LOOP AT SCREEN.
    IF screen-group1 = 'MOV'.                   " 기간·조회 버튼 묶음
      CASE ts_main-activetab.
        WHEN 'TAB3'.
          screen-active = 1.                    " 탭 3에서만 보인다
        WHEN OTHERS.
          screen-active = 0.
      ENDCASE.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
