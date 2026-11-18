*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1100 INPUT.
  CASE ok_code.
    WHEN 'SEARCH' OR 'REFR'.
      DATA: lv_val_result TYPE abap_bool.

      CLEAR lv_val_result.

      PERFORM search_validation CHANGING lv_val_result.


      PERFORM get_data CHANGING lv_val_result.


      IF lv_val_result = abap_true.
        PERFORM refresh_alv.
        PERFORM display_summary.
      ENDIF.

    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.



  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1200 INPUT.
  DATA: lv_res TYPE abap_bool.

  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.

    WHEN 'REFR'.
      PERFORM get_detail USING gw_accdoc_h-bukrs
                               gw_accdoc_h-belnr
                               gw_accdoc_h-gjahr
                          CHANGING lv_res.

  ENDCASE.
ENDMODULE.
