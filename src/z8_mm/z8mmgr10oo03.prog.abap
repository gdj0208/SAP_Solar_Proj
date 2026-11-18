*&---------------------------------------------------------------------*
*& Include          Z8MMGR10OO03
*&---------------------------------------------------------------------*

MODULE status_0300 OUTPUT.
  SET PF-STATUS 'S300'.
  SET TITLEBAR 'T0300'.

  CLEAR ok_code.
ENDMODULE.

MODULE create_conf_alv OUTPUT.

  " 1. 자재 검증 확정 내역 불러오기
  PERFORM get_mat_data.

  IF go_conf_cont IS INITIAL.
    "IMPORT p_matdoc_i = tmpt_matdoc_i  FROM MEMORY ID 'MATDOC_I'.

    " 1. 컨테이너 생성
    CREATE OBJECT go_conf_cont
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_top
        extension = 900.

    " 2. ALV 생성
    CREATE OBJECT go_conf_alv
      EXPORTING
        i_parent = go_conf_cont.

    " 3. 카탈로그 변경
    PERFORM change_field_catalog USING 'ty_matdoc_i'
                                       'ZEILE,MATNR,MAKTX,SUP_NAME,PLANT_NAME,MENGE,MEINS, inv_ret'
                                       '번호,자재코드,자재이름,공급처,입고 플랜트,이동수량,단위, 입고/반품'
                                 CHANGING gt_conf_fcat_h.

    " 4. 레이아웃 설정
    CLEAR gs_conf_layout.
    gs_conf_layout-grid_title = ''. "입고 및 반품 확정 항목
    gs_conf_layout-sel_mode = 'B'.
    gs_conf_layout-zebra = 'X'.
    gs_conf_layout-no_toolbar = 'X'.

    " 5. ALV 그리기
    CALL METHOD go_conf_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_conf_layout
      CHANGING
        it_filter       = gt_filter
        it_outtab       = gt_matdoc_i
        it_fieldcatalog = gt_conf_fcat_h.

  ELSE.
    go_conf_alv->refresh_table_display( ).

  ENDIF.
ENDMODULE.
