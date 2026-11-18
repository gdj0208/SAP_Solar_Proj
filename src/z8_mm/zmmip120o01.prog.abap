*&---------------------------------------------------------------------*
*& Include          ZMMGR030O01
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.

  "GET PARAMETER ID 'WERKS' FIELD gv_werks.
  IF gv_ebeln IS INITIAL.
    GET PARAMETER ID 'EBELN' FIELD gv_ebeln.
    GET PARAMETER ID 'EBELP' FIELD gv_ebelp.
  ENDIF.
ENDMODULE.

MODULE lock_po_on_entry OUTPUT.
  CHECK gv_po_locked IS INITIAL.     " 화면이 다시 그려질 때는 건너뜀

  PERFORM lock_po USING gv_ebeln CHANGING gv_lock_rc gv_lock_user.
  IF gv_lock_rc <> 0.
    " 055 문구에 '&1 사용자가 처리 중입니다.' 형태로 인자 추가 권장
    " 화면을 닫고 나가므로 상태바(S)가 아닌 팝업(I)으로 알린다.
    MESSAGE i055(z8_msg) WITH gv_lock_user.
    LEAVE TO SCREEN 0.
  ENDIF.

  PERFORM check_po_state USING gv_ebeln CHANGING gv_state_ok.
  IF gv_state_ok IS INITIAL.
    PERFORM unlock_po.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDMODULE.

MODULE get_data OUTPUT.
  PERFORM get_data.
ENDMODULE.

MODULE create_alv OUTPUT.
  IF go_dock_cont1 IS INITIAL.
    " 1. 컨테이너 생성
    CREATE OBJECT go_dock_cont1
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_left
        extension = 1500.

    CREATE OBJECT go_split
      EXPORTING
        parent  = go_dock_cont1
        rows    = 2
        columns = 1.

    go_split->get_container(
       EXPORTING
         row       = 2
         column    =  1
       RECEIVING
         container = go_qunt_cont
     ).

    go_split->get_container(
       EXPORTING
         row       = 1
         column    =  1
       RECEIVING
         container = go_amnt_cont
     ).


    " 2. ALV 생성
    CREATE OBJECT go_amnt_alv
      EXPORTING
        i_parent = go_amnt_cont.

    CREATE OBJECT go_qunt_alv
      EXPORTING
        i_parent = go_qunt_cont.


    " 3. 카탈로그 변경
    PERFORM change_field_catalog USING 'ty_3comp'
                                       'AMNT_LIGHT, UNEQ,         EBELN,    MAKTX,  NAME1,  I_WRBTR, HIST_WRBTR, INV_WRBTR,  WAERS'
                                       '상태, 이상 여부,   구매오더,자재명 ,    플랜트,   구매액,   입고액,        청구서 금액, 통화'
                                 CHANGING gt_amnt_fcat.


    PERFORM change_field_catalog USING 'ty_3comp'
                                       'QUNT_LIGHT, UNEQ,         EBELN,    MAKTX,   NAME1, I_MENGE, HIST_MENGE, INV_MENGE,   MEINS'
                                       '상태, 이상 여부,   구매오더, 자재명,  플랜트, 구매량,    입고량,        청구서 수량,  수량'
                                 CHANGING gt_qunt_fcat.

    CLEAR gs_qunt_layout.
    gs_qunt_layout-grid_title = |PO : { gv_ebeln } - 수량 검증|.
    "gs_qunt_layout-sel_mode = 'D'.
    gs_qunt_layout-zebra = 'X'.
    gs_qunt_layout-excp_fname = 'QUNT_LIGHT'.
    gs_qunt_layout-excp_led = 'X'.
    gs_qunt_layout-no_toolbar = 'X'.

    CLEAR gs_amnt_layout.
    gs_amnt_layout-grid_title = |PO : { gv_ebeln } - 금액 검증|.
    "gs_amnt_layout-sel_mode = 'D'.
    gs_amnt_layout-zebra = 'X'.
    gs_amnt_layout-excp_fname = 'AMNT_LIGHT'.
    gs_amnt_layout-excp_led = 'X'.
    gs_amnt_layout-no_toolbar = 'X'.

    CALL METHOD go_amnt_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_amnt_layout
      CHANGING
        it_outtab       = gt_amnt_3comp
        it_fieldcatalog = gt_amnt_fcat.

    CALL METHOD go_qunt_alv->set_table_for_first_display
      EXPORTING
        is_layout       = gs_qunt_layout
      CHANGING
        it_outtab       = gt_qunt_3comp
        it_fieldcatalog = gt_qunt_fcat.


  ELSE.
    go_amnt_alv->refresh_table_display( ).
    go_qunt_alv->refresh_table_display( ).

  ENDIF.
ENDMODULE.

MODULE get_invo OUTPUT.
  DATA :
      lv_ans TYPE c.

  " 구매오더 번호를 기반으로 청구서 번호 조회
  PERFORM has_inv CHANGING gv_invno.

  " 청구서 번호가 없는 경우(= 청구서가 없는 경우) 청구서 불러오기
  IF gv_invno IS INITIAL.
*  IF gv_3cof = 'X'.
    "  IF gv_invno IS INITIAL.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         = |해당 구매오더의 청구서가 없습니다. \n청구서 불러오기 화면으로 이동하시겠습니까?|
        text_button_1         = '예'
        text_button_2         = '아니오'
        display_cancel_button = ' '
      IMPORTING
        answer                = lv_ans
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    IF lv_ans = 1.
      MESSAGE s068(z8_MSG).

      SET PARAMETER ID 'EBELN' FIELD gv_ebeln.
      CALL TRANSACTION 'ZMMIP130'.

      PERFORM get_data.
      go_amnt_alv->refresh_table_display( ).
      go_qunt_alv->refresh_table_display( ).
    ELSE.

    ENDIF.

  ENDIF.
ENDMODULE.
