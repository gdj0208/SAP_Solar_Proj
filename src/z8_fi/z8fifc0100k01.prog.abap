*&---------------------------------------------------------------------*
*& Include          Z8FIFC0100K01
*&---------------------------------------------------------------------*
"클래스 정의부
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    "핫스팟 이벤트 등록
    CLASS-METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id es_row_no.

ENDCLASS.
*
"클래스 구현부
CLASS lcl_handler IMPLEMENTATION.
  METHOD on_hotspot_click.

    CASE e_column_id.
      WHEN 'AR_BELNR'. "원전표
        READ TABLE gt_bill INTO gs_bill INDEX es_row_no-row_id.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_bill-ar_belnr IS INITIAL.
          RETURN.
        ENDIF.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_bill-bukrs
               belnr = gs_bill-ar_belnr
               gjahr = gs_bill-ar_gjahr
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.

      WHEN 'AUGBL'. "반제전표
        READ TABLE gt_bill INTO gs_bill INDEX es_row_no-row_id.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_bill-augbl IS INITIAL.
          RETURN.
        ENDIF.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_bill-bukrs
               belnr = gs_bill-augbl
               gjahr = gs_bill-auggj
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
