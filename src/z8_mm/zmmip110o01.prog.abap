*&---------------------------------------------------------------------*
*& Include          ZMMGR030O01
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.

  GET PARAMETER ID 'WERKS' FIELD gv_werks.
  GET PARAMETER ID 'INV_SEL' FIELD gv_inv_sel.

  IMPORT mem_date = s_date[] FROM MEMORY ID 'Z_DATE_RANGE'.
  "GET PARAMETER ID 'SUP' FIELD gv_sup.
  FREE MEMORY ID 'Z_DATE_RANGE'.
ENDMODULE.


MODULE create_alv OUTPUT.
  IF go_cont IS INITIAL.
    " 1. 컨테이너 생성
    CREATE OBJECT go_cont
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_top
        extension = 1500.

    " 2. ALV 생성
    CREATE OBJECT go_alv
      EXPORTING
        i_parent = go_cont.

    " 3. 카탈로그 변경
PERFORM change_field_catalog USING 'Z8V_UNB_INV'
            'LIGHT, STAT_TXT, EBELN, INV_NO, LIFNR, NAME1, BEDAT, ESDAT, NETWR, WAERS'
            '상태, 상태명, 구매오더 번호, 청구서 번호, 구매처 코드, 구매처, 구매일자, 입고일자, 청구가격, 화폐'
          CHANGING gt_fcat_h.

    " 4. 구매오더 레이아웃 설정
    CLEAR gs_layout.
    gs_layout-grid_title = ''. "청구서 미수령 구매 오더 목록
    gs_layout-sel_mode = 'B'.
    gs_layout-zebra = 'X'.
    gs_layout-excp_fname = 'LIGHT'.
    gs_layout-excp_led ='X'.
    gs_layout-no_toolbar = 'X'.

    " 5. 구매오더 ALV 그리기
    CALL METHOD go_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_unb_inv
        it_fieldcatalog = gt_fcat_h.

  ELSE.
    go_alv->refresh_table_display( ).

  ENDIF.
ENDMODULE.

MODULE get_data OUTPUT.
  PERFORM get_data.
ENDMODULE.

MODULE show_done_msg OUTPUT.
  IF gv_done_ebeln IS NOT INITIAL.
    MESSAGE s218(z8_msg) WITH gv_done_ebeln.   " 문구는 SE91에서 확인
    " (선택) 목록에 남아 있으면 해당 행 선택
    READ TABLE gt_unb_inv TRANSPORTING NO FIELDS WITH KEY ebeln = gv_done_ebeln.
    IF sy-subrc = 0.
      DATA(lt_idx) = VALUE lvc_t_row( ( index = sy-tabix ) ).
      go_alv->set_selected_rows( it_index_rows = lt_idx ).
    ENDIF.
    CLEAR gv_done_ebeln.
  ENDIF.
ENDMODULE.
