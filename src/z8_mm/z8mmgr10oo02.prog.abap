*&---------------------------------------------------------------------*
*& Include          Z8MMGR10OO02
*&---------------------------------------------------------------------*


MODULE status_0200 OUTPUT.
  SET PF-STATUS 'S0200'.
  SET TITLEBAR 'T0200'.


  SELECT max( zeile )
    into gv_new_doc_no
    from z8mm_matdoc_i
    WHERE mblnr = ''.
ENDMODULE.

MODULE get_all_data OUTPUT.

  " 헤더, 아이템, 선택한 데이터 가져오기
  PERFORM get_po_h.
  PERFORM get_po_i.
  PERFORM get_datas.

  " 화면 변수 값 할당 (reset_meins 대체)
  "gv_mein0 = p_meins.
  gv_mein0 = 'EA'.
  gv_mein1 = gv_mein0.
  gv_mein2 = gv_mein0.
  gv_mein3 = gv_mein0.
ENDMODULE.

MODULE set_inactive OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'NCH'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
