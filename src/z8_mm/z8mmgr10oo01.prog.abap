*&---------------------------------------------------------------------*
*& Include          ZMMGR000O01
*&---------------------------------------------------------------------*


MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE get_header_datas OUTPUT.
  PERFORM get_header_data.
  IF gt_po_h is INITIAL. MESSAGE E022(Z8_MSG). ENDIF.
ENDMODULE.


MODULE create_alv_0100 OUTPUT.

  " ALV 그리기
  IF go_dock_cont1 IS INITIAL.

    " 1. 화면 영역
    "  구매 오더 헤더/아이템 ALV
    CREATE OBJECT go_dock_cont1
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_left
        extension = 1500.


    " 2. Split 컨테이너 생성 (2행 1열 - 위아래 분할)
    CREATE OBJECT go_split
      EXPORTING
        parent  = go_dock_cont1
        rows    = 2
        columns = 1.


    " 3. Split 컨테이너들에 대한 각 컨테이너 생성
    go_split->get_container(
      EXPORTING
        row       = 1
        column    =  1
      RECEIVING
        container = go_cont01
    ).

    go_split->get_container(
      EXPORTING
        row       = 2
        column    =  1
      RECEIVING
        container = go_cont02
    ).


    " 4. ALV 생성
    CREATE OBJECT go_header_alv
      EXPORTING
        i_parent = go_cont01.

    CREATE OBJECT go_item_alv
      EXPORTING
        i_parent = go_cont02.



*    " 5-1. 헤더 카탈로그 변경
    PERFORM change_field_catalog USING 'ty_po_h'
                                     'LIGHT, PROCSTAT, STATUS_TXT, NAME, EBELN, NAME1, BSART_TXT, BEDAT, LFDAT'
                                     '상태, 진행, 상태명, 지사, PO 번호, 공급사, 오더유형, 구매일자, 도착예정일자'
                            CHANGING gt_header_fcat_h.

*    " 5-1. 아이템 카탈로그 변경
    PERFORM change_field_catalog USING 'ty_po_i'
                                     'LIGHT,STATUS_TXT,EBELP,BANFN, MATNR,NETPR,WAERS,MENGE,IN_AMT,PROG_AMT,YET_AMT,MEINS'
                                     '상태,상태명, 품목 번호, PR 번호, 자재 코드, 자재단가,통화,총입고예정수량,입고된수량,검증진행수량,처리예정수량,수량단위'
                               CHANGING gt_item_fcat_h.


    " 6. 레이아웃 변경
    CLEAR gs_header_layout.
    gs_header_layout-grid_title = '구매 오더 목록'.
    gs_header_layout-zebra = 'X'.
    gs_header_layout-sel_mode = 'B'.
    gs_header_layout-excp_fname = 'LIGHT'.
    gs_header_layout-excp_led = 'X'.
    gs_header_layout-no_toolbar = 'X'.
    gs_header_layout-no_merging = 'X'.

    CLEAR gs_item_layout.
    gs_item_layout-grid_title = |{ gs_po_h-ebeln } 자재 품목|.
    gs_item_layout-zebra = 'X'.
    "gs_item_layout-cwidth_opt = 'X'.
    gs_item_layout-sel_mode = 'B'.
    gs_item_layout-excp_fname = 'LIGHT'.
    gs_item_layout-excp_led = 'X'.
    gs_item_layout-no_toolbar = 'X'.
    gs_item_layout-no_merging = 'X'.


    " 7. 정렬
    CLEAR gs_header_sort.
    gs_header_sort-spos = 1.
    gs_header_sort-fieldname = 'PROCSTAT'.
    gs_header_sort-up = 'X'.
    APPEND gs_header_sort TO gt_header_sort.

    CLEAR gs_item_sort.
    gs_item_sort-spos = 1.
    gs_item_sort-fieldname = 'LIGHT'.
    gs_item_sort-up = 'X'.
    APPEND gs_item_sort TO gt_item_sort.


    " 8. ALV 그리기
    CALL METHOD go_header_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_header_layout
      CHANGING
        it_outtab       = gt_po_h
        it_fieldcatalog = gt_header_fcat_h
        it_sort         = gt_header_sort.
    IF sy-subrc <> 0. MESSAGE E120(z8_msg) with |구매오더목록|. ENDIF.

    CALL METHOD go_item_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_item_layout
      CHANGING
        it_outtab       = gt_po_i
        it_fieldcatalog = gt_item_fcat_h
        it_sort         = gt_item_sort.
    IF sy-subrc <> 0. MESSAGE E120(z8_msg) with |자재 품목|. ENDIF.

    set HANDLER lcl_header_event=>handle_double_click for go_header_alv.
    set HANDLER lcl_item_event=>handle_double_click for go_item_alv.

  ELSE.

    go_header_alv->refresh_table_display( ).
    go_item_alv->refresh_table_display( ).
  ENDIF.
ENDMODULE.
