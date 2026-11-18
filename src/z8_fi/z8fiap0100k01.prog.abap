*&---------------------------------------------------------------------*
*& Include          Z8FIAP0100K01
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
      WHEN 'BELNR'. "원전표
        READ TABLE gt_vendor INTO gs_vendor INDEX es_row_no-row_id.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_vendor-belnr IS INITIAL.
          RETURN.
        ENDIF.

*        "test용
*        MESSAGE |회사코드 { gs_vendor-bukrs } / 전표번호 { gs_vendor-belnr } / 회계연도 { gs_vendor-gjahr }| TYPE 'S'.
        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_vendor-bukrs
               belnr = gs_vendor-belnr
               gjahr = gs_vendor-gjahr
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.
      WHEN 'AUGBL'. "반제전표
        READ TABLE gt_vendor INTO gs_vendor INDEX es_row_no-row_id.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_vendor-augbl IS INITIAL.
          RETURN.
        ENDIF.

*        "test용
*        MESSAGE |회사코드 { gs_vendor-bukrs } / 전표번호 { gs_vendor-augbl } / 회계연도 { gs_vendor-auggj }| TYPE 'S'.
        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_vendor-bukrs
               belnr = gs_vendor-augbl
               gjahr = gs_vendor-auggj
          TO MEMORY ID 'Z8FI_DETAIL_1200'.

        "FI 회계전표 상세조회
        CALL TRANSACTION 'Z8FIDR1200'.

        "Memory 정리
        FREE MEMORY ID 'Z8FI_DETAIL_1200'.

    ENDCASE.

*METHOD on_double_click.
*
*    READ TABLE gt_bill INTO gs_bill INDEX es_row_no-row_id.
*
*    IF sy-subrc <> 0.
*      RETURN.
*    ENDIF.
*
*    IF gs_bill-zzpayst = '02'..
*      MESSAGE '이미 입금처리가 완료된 청구서입니다.' TYPE 'S' DISPLAY LIKE 'E'.
*      RETURN.
*    ENDIF.
*
*      gv_vbeln = gs_bill-vbeln.
*      gv_bupla = gs_bill-bupla.
*      gv_kunnr = gs_bill-kunnr.
*      gv_netwr = gs_bill-netwr.
*      gv_waerk = gs_bill-waerk.
*      gv_date = sy-datum.
*      gv_pay = gs_bill-netwr.
*
*      WRITE gv_netwr TO gv_netwr_txt CURRENCY gv_waerk.
*      WRITE gv_pay TO gv_pay_txt CURRENCY gv_waerk.
*
*      "화면 갱신을 위해 PAI/PBO 발생
*      cl_gui_cfw=>set_new_ok_code(
*        new_code = 'DCLK'
*      ).
*
  ENDMETHOD.

ENDCLASS.
