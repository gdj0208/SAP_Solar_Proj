*&---------------------------------------------------------------------*
*& Include          Z8FIDP0100CK01
*&---------------------------------------------------------------------*

"클래스 정의부
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
  "핫스팟 이벤트 등록
  CLASS-METHODS on_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING E_COLUMN_ID ES_ROW_NO.
*  "더블 클릭 이벤트 등록
*    CLASS-METHODS on_double_click
*        FOR EVENT double_click OF cl_gui_alv_grid
*        IMPORTING ES_ROW_NO. "라인 정보만 받겠다.

ENDCLASS.
*
"클래스 구현부
CLASS lcl_handler IMPLEMENTATION.
  METHOD on_hotspot_click.

    CASE E_COLUMN_ID.
      WHEN 'BELNR'.
        READ TABLE gt_bill INTO gs_bill INDEX ES_ROW_NO-row_id.

        IF sy-subrc <> 0.
          RETURN.
        ENDIF.

        "전표번호 x -> 처리하지 x
        IF gs_bill-belnr IS INITIAL.
          RETURN.
        ENDIF.

        "FI 상세조회 프로그램에 원전표 키 전달
        EXPORT bukrs = gs_bill-bukrs
               belnr = gs_bill-belnr
               gjahr = gs_bill-gjahr
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
