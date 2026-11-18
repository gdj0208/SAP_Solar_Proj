*&---------------------------------------------------------------------*
*& Include          Z8COSD100O02
*&---------------------------------------------------------------------*


MODULE create_alv OUTPUT.

  IF s_guebg IS INITIAL.
    MESSAGE S206(Z8_MSG) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  IF go_dock IS INITIAL.

    " 1. 도킹 컨테이너 생성
    CREATE OBJECT go_dock
      EXPORTING
        container_name = 'CC_ALV'.

    CREATE OBJECT go_split
      EXPORTING
        parent  = go_dock
        rows    = 2
        columns = 1.

    go_cont_top = go_split->get_container( row = 1 column = 1 ).
    go_cont_bot = go_split->get_container( row = 2 column = 1 ).


    " 상하 비율 4 : 6
    go_split->set_row_height(
      EXPORTING
        id     = 1
        height = 40
    ).
    go_split->set_row_height(
      EXPORTING
        id     = 2
        height = 60
    ).

    " 2-1. 상단(Top) 영역에 ALV 2개 생성
    CREATE OBJECT go_alv_rej EXPORTING i_parent = go_cont_top.
    CREATE OBJECT go_alv_bup EXPORTING i_parent = go_cont_top.

    go_alv_rej->set_visible( abap_false ).

    " 2-2. 하단(Bottom) 영역에 상세 ALV 생성
    CREATE OBJECT go_alv_bot EXPORTING i_parent = go_cont_bot.


    " 3. 카탈로그 변경

PERFORM change_field_catalog USING 'ty_branch'
                                       'NAME, NETWR, WAERK, ORD_RATE, PEND_RATE, ORD_NUM, PEND_NUM, PROG_NUM, TOTAL_NUM'
                                       '지사, 수주기회손실총액, 통화, 체결 비율(%), 미체결 비율(%), 체결 건수, 미체결 건수, 진행 중 견적, 전체견적건수'
                               CHANGING gt_branch_fcat.

    PERFORM change_field_catalog USING 'ty_quot_det'
                                     'NAME, VBELN_Q, REJ_TEXT,  NAME1, NETWR, WAERK, GUEBG, GUEEN'
                                     '지사, 계약 번호, 거절 사유, 고객, 금액, 통화, 견적 유효 시작일, 견적 유효 종료일'
                               CHANGING gt_det_fcat.

    " 4. 레이아웃 변경
    CLEAR gs_branch_layo.
    gs_branch_layo-grid_title = '지사별 실주 분석'.
    gs_branch_layo-zebra = 'X'.
    "gs_branch_layo-sel_mode = 'D'.
    gs_branch_layo-no_toolbar = 'X'.
    gs_branch_layo-no_merging = 'X'.

    CLEAR gs_det_layo.
    gs_det_layo-grid_title = '지사별 상세 미체결 계약 내역'.
    gs_det_layo-zebra = 'X'.
    "gs_det_layo-sel_mode = 'D'.
    gs_det_layo-no_toolbar = 'X'.
    gs_det_layo-no_merging = 'X'.

    " 5. 정렬
    CLEAR gs_branch_sort.
    gs_branch_sort-spos = 1.
    gs_branch_sort-fieldname = 'NETWR'.
    gs_branch_sort-down = 'X'.
    APPEND gs_branch_sort TO gt_branch_sort.

    CLEAR gs_det_sort.
    gs_det_sort-spos = 1.
    gs_det_sort-fieldname = 'VBELN_Q'.
    gs_det_sort-up = 'X'.
    APPEND gs_det_sort TO gt_det_sort.



    " 6. ALV 그리기
    CALL METHOD go_alv_bup->set_table_for_first_display
      EXPORTING
        is_layout       = gs_branch_layo
      CHANGING
        it_outtab       = gt_branch
        it_fieldcatalog = gt_branch_fcat
        it_sort         = gt_branch_sort.
    IF sy-subrc <> 0. MESSAGE s120(z8_msg) DISPLAY LIKE 'E'. ENDIF.

    CALL METHOD go_alv_bot->set_table_for_first_display
      EXPORTING
        is_layout       = gs_det_layo
      CHANGING
        it_outtab       = gt_quot_det
        it_fieldcatalog = gt_det_fcat
        it_sort         = gt_det_sort.
    IF sy-subrc <> 0. MESSAGE s120(z8_msg) DISPLAY LIKE 'E'. ENDIF.


    " 7. 이벤트 핸들러
    SET HANDLER lcl_event_receiver=>handle_double_click FOR go_alv_bup.

  ELSE.
    go_alv_bup->refresh_table_display( ).
    go_alv_bot->refresh_table_display( ).

  ENDIF.
ENDMODULE.
