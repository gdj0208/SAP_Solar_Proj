*&---------------------------------------------------------------------*
*& Include          Z8FIRP0100K01
*&---------------------------------------------------------------------*
"클래스 정의부
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    "핫스팟 이벤트 등록
    CLASS-METHODS on_hotspot_ar
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id es_row_no.

    CLASS-METHODS on_hotspot_ap
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id es_row_no.

*    "더블 클릭 이벤트 등록
*    CLASS-METHODS on_double_click
*      FOR EVENT double_click OF cl_gui_alv_grid
*      IMPORTING e_row. "라인 정보만 받겠다.

ENDCLASS.
*
"클래스 구현부
CLASS lcl_handler IMPLEMENTATION.
  METHOD on_hotspot_ar.

    CASE e_column_id.
      WHEN 'KUNNR'.
        CLEAR gs_ar_sel.
        READ TABLE gt_ar_100 INTO gs_ar_sel INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "200번 진입 시 선택한 지사 기준
        CLEAR gv_ar_all_branch.

          PERFORM make_ar_detail_200.
          PERFORM set_cell_style_200.

          IF gt_ar_200 IS INITIAL.
            MESSAGE s109(z8_msg) DISPLAY LIKE 'E' WITH '고객' '채권'. "'고객의 채권 내역이 없습니다
          ELSE.
            CALL SCREEN 200.
          ENDIF.

      WHEN 'BELNR'.
        READ TABLE gt_ar_200 INTO gs_ar_200 INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_ar_200-belnr IS INITIAL.
          RETURN.
        ENDIF.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_ar_200-bukrs
               belnr = gs_ar_200-belnr
               gjahr = gs_ar_200-gjahr
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.

      WHEN 'AUGBL'.
        READ TABLE gt_ar_200 INTO gs_ar_200 INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_ar_200-augbl IS INITIAL.
          RETURN.
        ENDIF.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_ar_200-bukrs
               belnr = gs_ar_200-augbl
               gjahr = gs_ar_200-auggj
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.

    ENDCASE.
  ENDMETHOD.
**********************************************************************
  METHOD on_hotspot_ap.

    CASE e_column_id.
      WHEN 'LIFNR'.
        CLEAR gs_ap_sel.
        READ TABLE gt_ap_300 INTO gs_ap_sel INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "400번 진입 시 선택한 지사 기준
        CLEAR gv_ap_all_branch.

          PERFORM make_ap_detail_400.
          PERFORM set_cell_style_400.

          IF gt_ap_400 IS INITIAL.
            MESSAGE s109(z8_msg) DISPLAY LIKE 'E' WITH '공급업체' '채무'.
          ELSE.
            CALL SCREEN 400.
          ENDIF.

      WHEN 'BELNR'.
        READ TABLE gt_ap_400 INTO gs_ap_400 INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_ap_400-belnr IS INITIAL.
          RETURN.
        ENDIF.

*        "test용
*        MESSAGE |지사코드 { gs_ap_400-bupla } / 전표번호 { gs_ap_400-belnr } / 회계연도 { gs_ap_400-gjahr }| TYPE 'S'.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_ap_400-bukrs
               belnr = gs_ap_400-belnr
               gjahr = gs_ap_400-gjahr
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.

      WHEN 'AUGBL'.
        READ TABLE gt_ap_400 INTO gs_ap_400 INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_ap_400-augbl IS INITIAL.
          RETURN.
        ENDIF.

*        "test용
*        MESSAGE |지사코드 { gs_ap_400-bupla } / 전표번호 { gs_ap_400-augbl } / 회계연도 { gs_ap_400-auggj }| TYPE 'S'.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_ap_400-bukrs
               belnr = gs_ap_400-augbl
               gjahr = gs_ap_400-auggj
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.

    ENDCASE.


  ENDMETHOD.

ENDCLASS.
