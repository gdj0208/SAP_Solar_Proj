*&---------------------------------------------------------------------*
*& Include          MZ8SDSO0700O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_1000 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1000 OUTPUT.
  SET PF-STATUS 'G1000'.
  SET TITLEBAR 'T1000'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_PROCESSING OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_processing OUTPUT.
  IF go_container IS NOT BOUND.
    PERFORM create_object.
    PERFORM set_evt_handler.
    PERFORM set_alv_layout.
    PERFORM set_fcat.
    PERFORM set_fcat_i.
    PERFORM display_header_alv.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module CLEAR_OK_CODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.
  CLEAR ok_code.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_INIT_DATA OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_init_data OUTPUT.
  DATA: ls_color  TYPE lvc_s_col,
        lv_result TYPE abap_bool.

  IF gv_init_flag IS INITIAL.
    CLEAR: gv_init_flag, gv_audat_from, gv_audat_to.
    gv_audat_from = sy-datum - 30.
    gv_audat_to = sy-datum.

    PERFORM get_data.

    PERFORM get_selected_line CHANGING lv_result.


    gv_init_flag = abap_true.


    gs_layout_h-grid_title = |전체 ({ lines( gt_so_h ) })건|.

    go_alv_h->set_frontend_layout(
      EXPORTING
        is_layout = gs_layout_h
    ).

  ENDIF.






ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_1010 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_1010 OUTPUT.
  SET PF-STATUS 'G1010'.
  SET TITLEBAR 'T1010'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module CHECK_AUTHORITY OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE check_authority OUTPUT.
  AUTHORITY-CHECK OBJECT 'Z8SD_AUTH'
    ID 'ACTVT' FIELD '16'.   " Execute (실행)

  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'SD'.
  ENDIF.

ENDMODULE.
