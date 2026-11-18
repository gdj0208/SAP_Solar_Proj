*&---------------------------------------------------------------------*
*& Include          ZMMGR000I01
*&---------------------------------------------------------------------*


MODULE user_command_0100 INPUT.
  DATA: lt_rows  TYPE lvc_t_row,
        ls_row   TYPE lvc_s_row,
        lv_ebelp TYPE z8mm_po_i-ebelp.

  save_ok = ok_code.
  clear ok_code.

  CASE save_ok.
    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
        PERFORM unlock_all.
        CLEAR : gt_po_h, gt_po_i.
        CLEAR : gs_po_h, gs_po_i, gt_matdoc_h.
      LEAVE TO SCREEN 0.

    WHEN 'CONF'.
      " 검증 확정 화면으로 이동
      CALL SCREEN 300.

      PERFORM get_header_data.
      go_header_alv->refresh_table_display( ).
      "IF sy-subrc <> 0. MESSAGE e022(z8_msg). ENDIF.


      PERFORM get_item_data USING gs_po_i-ebeln.
      go_item_alv->refresh_table_display( ).
      "IF sy-subrc <> 0. MESSAGE e022(z8_msg). ENDIF.

    WHEN others.

  ENDCASE.
ENDMODULE.
