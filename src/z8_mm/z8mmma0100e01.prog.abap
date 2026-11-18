*&---------------------------------------------------------------------*
*& Include          Z8MMMA0100E01
*&---------------------------------------------------------------------*
INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.
  ENDIF.

  CLEAR gs_funct.
  gs_funct-icon_id   = icon_material.
  gs_funct-text      = '자재 신규 등록'.
  gs_funct-icon_text = '자재 신규 등록'.
  sscrfields-functxt_01 = gs_funct.

  CLEAR gs_funct.
  gs_funct-icon_id   = icon_supplier.
  gs_funct-text      = '공급업체 신규 등록'.
  gs_funct-icon_text = '공급업체 신규 등록'.
  sscrfields-functxt_02 = gs_funct.
*  PERFORM INIT_1000.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
      "실행 눌렀을 때만 검사
    WHEN 'ONLI'.
      PERFORM check_input.
    WHEN 'FC01'.                       " 자재 신규 등록
      CLEAR sscrfields-ucomm.
      CLEAR gv_matnr_sel.
      gv_mode = 'N'.
      CLEAR gv_screen_init.
      CALL SCREEN 0300.
    WHEN 'FC02'.                       " 공급업체 신규 등록
      CLEAR sscrfields-ucomm.
      CLEAR gv_lifnr_sel.
      gv_mode_v = 'N'.
      CLEAR gv_screen_init_v.
      CALL SCREEN 0400.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.
*  자재관리/공급업체 라디오버튼 선택시 활성화/비활성화 *
  LOOP AT SCREEN.
    IF screen-group1 = 'B2' AND p_vend = 'X'.      " 공급업체 관리면 자재 조건을 숨김
      screen-active = 0.
      screen-invisible = 1.
      MODIFY SCREEN.
    ENDIF.
    IF screen-group1 = 'B3' AND p_mat = 'X'.       " 자재 관리면 업체 조건을 숨김
      screen-active = 0.
      screen-invisible = 1. "
      MODIFY SCREEN.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.
  IF p_mat = 'X'.
    PERFORM get_material_list.
    IF gt_mat_list IS INITIAL.
      MESSAGE s149(z8_msg) DISPLAY LIKE 'E' WITH '자재'.
      LEAVE LIST-PROCESSING.
    ENDIF.
    CALL SCREEN 100.
  ELSE.
    PERFORM get_vendor_list.
    IF gt_vend_list IS INITIAL.
      MESSAGE s149(z8_msg) DISPLAY LIKE 'E' WITH '공급업체'.
      LEAVE LIST-PROCESSING.
    ENDIF.
    CALL SCREEN 200.
  ENDIF.
