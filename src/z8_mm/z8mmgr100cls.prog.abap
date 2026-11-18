*&---------------------------------------------------------------------*
*& Include          Z8MMGR100CLS
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* 헤더 ALV 더블클릭 : 선택한 PO의 품목 목록 조회
*---------------------------------------------------------------------*
CLASS lcl_header_event DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column sender.
ENDCLASS.

CLASS lcl_header_event IMPLEMENTATION.
  METHOD handle_double_click.
    " 소계·그룹 행 등 일반 데이터 행이 아니면 무시
    IF e_row-rowtype IS NOT INITIAL. RETURN. ENDIF.

    " 1. 선택한 PO 헤더
    READ TABLE gt_po_h INTO gs_po_h INDEX e_row-index.
    IF sy-subrc <> 0. RETURN. ENDIF.

    CLEAR gs_po_i.
    gv_ebeln = gs_po_h-ebeln.

    " 2. PO_I ALV 데이터 채우기
    PERFORM get_item_data USING gs_po_h-ebeln.

    " 3. PO_I ALV 새로고침
    go_item_alv->refresh_table_display( ).
  ENDMETHOD.
ENDCLASS.


*---------------------------------------------------------------------*
* 품목 ALV 더블클릭 : PO Lock 후 200번(검증 수량 입력) 진입
*---------------------------------------------------------------------*
CLASS lcl_item_event DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column sender.
ENDCLASS.

CLASS lcl_item_event IMPLEMENTATION.
  METHOD handle_double_click.
    DATA : lv_subrc TYPE sy-subrc,
           lv_elikz TYPE z8mm_po_i-elikz.

    IF e_row-rowtype IS NOT INITIAL. RETURN. ENDIF.

    " 1. 선택한 품목
    READ TABLE gt_po_i INTO gs_po_i INDEX e_row-index.
    IF sy-subrc <> 0. RETURN. ENDIF.

    gv_ebeln = gs_po_i-ebeln.
    gv_ebelp = gs_po_i-ebelp.

    " 2. PO Lock (다른 사용자가 처리 중이면 진입 차단)
    PERFORM lock_po USING gv_ebeln CHANGING lv_subrc.
    IF lv_subrc <> 0. RETURN. ENDIF.

    " 3. Lock 이후 DB 기준으로 납품완료 여부 재확인
    CLEAR lv_elikz.
    SELECT SINGLE elikz INTO @lv_elikz
      FROM z8mm_po_i
     WHERE ebeln = @gv_ebeln
       AND ebelp = @gv_ebelp.
    IF lv_elikz = 'X'.
      PERFORM unlock_po_if_no_pending USING gv_ebeln.
      MESSAGE s202(z8_msg) WITH gv_ebelp DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 4. 200번 초기화(+ 대기 내역 복원) 후 진입
    PERFORM init_screen_200.
    CALL SELECTION-SCREEN 200.

    " 5. 대기 내역이 없으면 Lock 해제, 있으면 300번 확정까지 유지
    PERFORM unlock_po_if_no_pending USING gv_ebeln.

    " 6. 화면 재조회
    PERFORM get_header_data.
    go_header_alv->refresh_table_display( ).

    PERFORM get_item_data USING gs_po_i-ebeln.
    go_item_alv->refresh_table_display( ).
  ENDMETHOD.
ENDCLASS.
