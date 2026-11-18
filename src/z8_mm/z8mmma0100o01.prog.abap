*&---------------------------------------------------------------------*
*& Include          Z8MMMA0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
CLEAR gt_ex_list.
APPEND 'CREA' TO gt_ex_list.
SET PF-STATUS 'S0100' EXCLUDING gt_ex_list.
  SET TITLEBAR 'T0100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0100 OUTPUT.
  IF go_cont_100 IS NOT BOUND.
    PERFORM create_objects.
    PERFORM set_event_handler.
    PERFORM set_alv_layout_100.
    PERFORM set_field_catalog_100.
*    PERFORM modify_field_catalog.

    PERFORM display_alv.
  ELSE.
    go_alv_100->refresh_table_display( ).
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
CLEAR gt_ex_list.
APPEND 'CREA' TO gt_ex_list.
SET PF-STATUS 'S0200' EXCLUDING gt_ex_list.
  SET TITLEBAR 'T0200'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0200 OUTPUT.
  IF go_cont_200 IS NOT BOUND.
    PERFORM create_objects_200.
    PERFORM set_event_handler_200.
    PERFORM set_alv_layout_200.
    PERFORM set_field_catalog_200.
*    PERFORM modify_field_catalog.

    PERFORM display_alv_200.
  ELSE.
    gs_layout_200-grid_title = |공급업체 목록 ({ lines( gt_vend_list ) }건)|.
    go_alv_200->set_frontend_layout( is_layout = gs_layout_200 ).
    go_alv_200->refresh_table_display( ).
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  CLEAR gt_excl.
  IF gv_mode = 'D'.
    gv_excl = 'SAVE'.                    " 조회 모드에서는 저장 버튼 숨김
  ELSE.
    gv_excl = 'EDIT'.                    " 수정, 신규에서는 수정 버튼 숨김
  ENDIF.
  APPEND gv_excl TO gt_excl.
  SET PF-STATUS 'S0300' EXCLUDING gt_excl.

  IF gv_mode = 'N'.
    SET TITLEBAR 'T0300' WITH ' 신규 등록'.
  ELSE.
    SET TITLEBAR 'T0300' WITH ' 상세내역'.
  ENDIF.

  IF gv_screen_init IS INITIAL.
    gv_screen_init = 'X'.
    "조회 모드.
    "1) 자재+자재명 데이터
    IF gv_mode = 'D'.
      SELECT SINGLE * FROM z8material_m
        INTO CORRESPONDING FIELDS OF z8s_mat_detail
        WHERE matnr = gv_matnr_sel.
      SELECT SINGLE maktx FROM z8material_txt_m
        INTO z8s_mat_detail-maktx
        WHERE matnr = gv_matnr_sel AND spras = '3'.
      "2) 플랜트 정보 데이터
      SELECT * FROM z8matplant_m
  INTO TABLE gt_plant
  WHERE matnr = gv_matnr_sel.
        "3) 자재평가 데이터
      SELECT * FROM z8material_val_m
        INTO TABLE gt_val
        WHERE matnr = gv_matnr_sel.
        "4) 현재재고
       SELECT * FROM z8material_stk_m
        INTO TABLE gt_stk
        WHERE matnr = gv_matnr_sel.
    ELSE.
      "신규 모드.
      CLEAR z8s_mat_detail.
      z8s_mat_detail-mstae = '01'.
      CLEAR: gt_plant, gt_val, gt_stk.
    ENDIF.
    PERFORM build_plant_rows.
  ENDIF.

    gv_cd = z8s_mat_detail-mtart.
  PERFORM mtart_to_text.
  gv_mtart_txt = gv_tx.

  gv_cd = z8s_mat_detail-mstae.
  PERFORM mstae_to_text.
  gv_mstae_txt = gv_tx.
  "자재코드 신규면 입력가능, 조회면 입력불가.
    LOOP AT SCREEN.
    IF screen-name = 'Z8S_MAT_DETAIL-MATNR'.
      IF gv_mode = 'N'.
        screen-input = 1.
      ELSE.
        screen-input = 0.                " 자재코드는 신규에서만 입력 가능
      ENDIF.
      MODIFY SCREEN.
    ELSEIF screen-name CP 'Z8S_MAT_DETAIL-*'.
      IF gv_mode = 'D'.
        screen-input = 0.                " 조회 모드: 나머지 입력칸 잠김
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_ALV_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0300 OUTPUT.
  PERFORM show_alv_plant.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0400 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0400 OUTPUT.
  CLEAR gt_excl.
  IF gv_mode_v = 'D'.
    gv_excl = 'SAVE'.
  ELSE.
    gv_excl = 'EDIT'.
  ENDIF.
  APPEND gv_excl TO gt_excl.
  SET PF-STATUS 'S0400' EXCLUDING gt_excl.

IF gv_mode_v = 'N'.
  SET TITLEBAR 'T0400' WITH '등록'.
ELSE.
  SET TITLEBAR 'T0400' WITH '조회'.
ENDIF.

IF gv_screen_init_v IS INITIAL.
  gv_screen_init_v = 'X'.
  IF gv_mode_v = 'D'.
    SELECT SINGLE * FROM z8vendor_m
      INTO CORRESPONDING FIELDS OF Z8S_VEND_DETAIL
      WHERE lifnr = gv_lifnr_sel.
   ELSE.
     CLEAR Z8S_VEND_DETAIL.
     Z8S_VEND_DETAIL-land1 = 'KR'.
   ENDIF.
   PERFORM build_vmat_rows.
    ENDIF.

  LOOP AT SCREEN.
    IF screen-name = 'Z8S_VEND_DETAIL-LIFNR'.
      IF gv_mode_v = 'N'.
        screen-input = 1.
      ELSE.
        screen-input = 0.                 " 업체코드는 신규에서만 입력 가능
      ENDIF.
      MODIFY SCREEN.
    ELSEIF screen-name CP 'Z8S_VEND_DETAIL-*'.
      IF gv_mode_v = 'D'.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_ALV_0400 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_alv_0400 OUTPUT.
  PERFORM show_alv_vmat.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Form show_alv_vmat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_alv_vmat .
  DATA lv_input TYPE i.

  IF gv_mode_v = 'D'.
    lv_input = 0.
  ELSE.
    lv_input = 1.
  ENDIF.

  IF go_cont_vmat IS INITIAL.
    CREATE OBJECT go_cont_vmat
      EXPORTING container_name = 'VE_ALV'.
    CREATE OBJECT go_alv_vmat
      EXPORTING i_parent = go_cont_vmat.

    PERFORM set_field_catalog_vmat.
    gs_layout_vmat-zebra      = 'X'.
    gs_layout_vmat-cwidth_opt = 'X'.
    gs_layout_vmat-no_toolbar = 'X'.

    CALL METHOD go_alv_vmat->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout_vmat
      CHANGING
        it_outtab       = gt_vmat_row
        it_fieldcatalog = gt_fcat_vmat.
    CALL METHOD go_alv_vmat->set_ready_for_input
      EXPORTING i_ready_for_input = lv_input.
  ELSE.
    CALL METHOD go_alv_vmat->set_ready_for_input
      EXPORTING i_ready_for_input = lv_input.
    CALL METHOD go_alv_vmat->refresh_table_display.
  ENDIF.

ENDFORM.
