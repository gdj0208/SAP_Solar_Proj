*&---------------------------------------------------------------------*
*& Include          Z8FIGL0100K01
*&---------------------------------------------------------------------*
"클래스 정의부
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    "핫스팟 이벤트 등록
    CLASS-METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id es_row_no.

   CLASS-METHODS on_hotspot_200
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id es_row_no.

ENDCLASS.
*
"클래스 구현부
CLASS lcl_handler IMPLEMENTATION.
  METHOD on_hotspot_click.

    CASE e_column_id.
      WHEN 'SAKNR'. "gl계정

        CLEAR gs_gl_sel.

        READ TABLE gt_alv_100 INTO gs_gl_sel INDEX es_row_no-row_id."e_row-index.

        IF sy-subrc = 0.
          PERFORM init_condition_200.
          PERFORM set_org_condition_200.
          PERFORM make_alv_200.
          PERFORM set_cell_style_200.

          IF gt_alv_200 IS INITIAL.
            MESSAGE s109(z8_msg) DISPLAY LIKE 'E' WITH 'G/L계정' '원장'. "'G/L계정의 원장'내역이 없습니다.'
          ELSE.
            CALL SCREEN 200.
          ENDIF.

        ENDIF.
      ENDCASE.
     ENDMETHOD.
     METHOD on_hotspot_200.
       CASE e_column_id.
         WHEN 'BELNR'. "회계전표번호

        CLEAR gs_alv_200.

        READ TABLE gt_alv_200 INTO gs_alv_200
          INDEX es_row_no-row_id.

        IF sy-subrc = 0.

          "FI 상세조회 프로그램에 전표 키 전달
          EXPORT bukrs = gs_alv_200-bukrs
                 belnr = gs_alv_200-belnr
                 gjahr = gs_alv_200-gjahr
            TO MEMORY ID 'Z8FI_DETAIL_1200'.

          "FI 회계전표 상세조회
          CALL TRANSACTION 'Z8FIDR1200'.

          "Memory 정리
          FREE MEMORY ID 'Z8FI_DETAIL_1200'.

        ENDIF.

    ENDCASE.
  ENDMETHOD.

ENDCLASS.
