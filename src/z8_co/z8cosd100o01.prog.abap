*&---------------------------------------------------------------------*
*& Include          Z8COSD100O01
*&---------------------------------------------------------------------*


MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE status_0200 OUTPUT.
 SET PF-STATUS 'S0200'.
 SET TITLEBAR 'T0200'.
ENDMODULE.

MODULE clear_data INPUT.
  CLEAR : gt_pend, gt_branch, gt_quot_det.
  CLEAR : gs_pend, gs_branch, gs_quot_det.
ENDMODULE.

MODULE check_date OUTPUT.
  IF s_guebg IS INITIAL.
    MESSAGE S206(Z8_MSG) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
ENDMODULE.
