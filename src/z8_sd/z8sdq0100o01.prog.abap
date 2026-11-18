
*&---------------------------------------------------------------------*
*& Include          Z8SDQ0100O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_1100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1100 OUTPUT.
  SET PF-STATUS 'G1100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing OUTPUT.
  IF go_container IS NOT BOUND.
    PERFORM create_object.

    PERFORM set_alv_layout.
*
    PERFORM set_field_catalog.
*
    PERFORM display_alv.
ELSE.
  PERFORM quot_list_refresh.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_container
    EXPORTING
      container_name              = 'CONTROL_AREA'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE a014(zmsg_136).
  ENDIF.

  CREATE OBJECT go_alv
    EXPORTING
      i_parent          = go_container
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE a014(z8_msg).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog .


  CLEAR gw_fcat.
  gw_fcat-fieldname = 'LIGHT'.
  gw_fcat-col_pos = 1.
  gw_fcat-coltext = '상태'.
  gw_fcat-icon    = 'X'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'POSNR'.
  gw_fcat-col_pos = 2.
  gw_fcat-coltext = '항목'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'MATNR'.
  gw_fcat-col_pos = 3.
  gw_fcat-coltext = '자재'.
  gw_fcat-outputlen = 20.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'ARKTX'.
  gw_fcat-col_pos = 4.
  gw_fcat-coltext = '자재명'.
  gw_fcat-outputlen = 20.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'KWMENG'.
  gw_fcat-col_pos = 5.
  gw_fcat-coltext = '수량'.
  gw_fcat-qfieldname = 'VRKME'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'VRKME'.
  gw_fcat-col_pos = 6.
  gw_fcat-coltext = '단위'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'PLACE_TYPE'.
  gw_fcat-col_pos = 7.
  gw_fcat-coltext = '설치장소'.
  APPEND gw_fcat TO gt_fcat.


  CLEAR gw_fcat.
  gw_fcat-fieldname = 'RESULT'.
  gw_fcat-col_pos = 8.
  gw_fcat-coltext = '결과'.
  APPEND gw_fcat TO gt_fcat.

  CLEAR gw_fcat.
  gw_fcat-fieldname = 'MESSAGE'.
  gw_fcat-col_pos = 9.
  gw_fcat-coltext = '메시지'.
  gw_fcat-outputlen = 40.
  APPEND gw_fcat TO gt_fcat.



ENDFORM.
*&---------------------------------------------------------------------*
*& Module STATUS_1200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1200 OUTPUT.
  SET PF-STATUS 'G1200'.
  SET TITLEBAR 'T1200'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING1200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing1200 OUTPUT.
  PERFORM create_object1200.

  PERFORM set_alv_layout1200.

  PERFORM set_field_catalog1200.

  PERFORM display_alv1200.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1300 OUTPUT.
  SET PF-STATUS 'G1300'.
  SET TITLEBAR 'T1300'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING1300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing1300 OUTPUT.
  IF go_container1300_H IS NOT BOUND AND go_container1300_I IS NOT BOUND.
    PERFORM create_object1300.

    PERFORM set_evt_handler.
*
*    PERFORM set_wh_evt_handler.
*
    PERFORM set_alv1300_layout.
*
    PERFORM set_fcat1300.
*    PERFORM set_item_fcat.
*
    PERFORM display_header_alv.
    PERFORM display_item_alv.

    PERFORM select_row1300 USING 1.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module MODIFY_SCREEN1300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE modify_screen1300 OUTPUT.
  tab1 = |{ gv_1300_reqid } 견적 조회|.
  tab2 = '전체 견적'.

  LOOP AT SCREEN.
    IF screen-group1 = 'ALL'.
      IF gv_1300_reqid IS INITIAL.
        screen-active = '0'.
      ELSE.
        screen-active = '1'.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    IF screen-group1 = 'SEA'.
      CASE gv_req_mode.
        WHEN 'R'.
          screen-active = 0.
        WHEN 'A'.
          screen-active = 1.
      ENDCASE.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1310 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1310 OUTPUT.
  SET PF-STATUS 'G1310'.
  SET TITLEBAR 'T1310'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_TABSCREEN1300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_tabscreen1300 OUTPUT.

  gv_subscreen = '1301'.

  IF gv_req_mode = 'A'.
    tabstrip1300-activetab = 'TAB2'.
  ELSE.
    tabstrip1300-activetab = 'TAB1'.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_1301 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_1301 OUTPUT.
  IF go_custom1301 IS NOT BOUND OR go_alv1300_h IS NOT BOUND OR go_alv1300_i IS NOT BOUND.
    PERFORM create_alv1301.
    PERFORM set_evt_handler.
    PERFORM set_alv1300_layout.
    PERFORM set_fcat1300.
    PERFORM set_fcat1300_i.
    PERFORM display_header_alv.
    PERFORM display_item_alv.

    PERFORM select_row1300 USING gv_selected_id.
*
*    "첫 행 선택
*    IF gt_quot_list IS NOT INITIAL.
*      PERFORM select_row1300 USING 1.
*    ENDIF.
**  ELSE.
**    PERFORM quot_list_refresh.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1320 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1320 OUTPUT.
 SET PF-STATUS 'G1320'.
 SET TITLEBAR 'T1320'.
ENDMODULE.
