*&---------------------------------------------------------------------*
*& Include          Z8SDQ0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form set_excel_btn
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_toolbar.
  DATA: lv_dyntxt TYPE smp_dyntxt. "버튼을 꾸밀 수 있는 스트럭처 SMP_DYNTXT
  CLEAR lv_dyntxt.
  lv_dyntxt-icon_id = icon_xls.
  lv_dyntxt-icon_text = TEXT-exl.
  sscrfields-functxt_01 = lv_dyntxt.

  CLEAR lv_dyntxt.
  lv_dyntxt-icon_id = icon_select_detail.
  lv_dyntxt-icon_text = TEXT-req.
  sscrfields-functxt_02 = lv_dyntxt.

  CLEAR lv_dyntxt.
  lv_dyntxt-icon_id = icon_select_detail.
  lv_dyntxt-icon_text = TEXT-all.
  sscrfields-functxt_03 = lv_dyntxt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_excel_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_excel_data.
  DATA lv_posnr TYPE z8sd_quotation_i-posnr.
  CLEAR: gs_excel_head, gs_excel_item, gt_excel_item.

  DATA lt_excel TYPE TABLE OF alsmex_tabline.
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = pa_file
      i_begin_col             = 1
      i_begin_row             = 2
      i_end_col               = 30
      i_end_row               = 500
    TABLES
      intern                  = lt_excel
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.

  IF sy-subrc <> 0.
    MESSAGE s028(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

* 엑셀 헤더 데이터 읽어오기
  LOOP AT lt_excel INTO DATA(ls_excel_h).

    CASE ls_excel_h-row.

      WHEN 4.
        CASE ls_excel_h-col.
          WHEN 2.
            gs_excel_head-request_id = ls_excel_h-value.
        ENDCASE.

      WHEN 10.
        IF ls_excel_h-col = 2.
          gs_excel_head-total_area = ls_excel_h-value.
        ENDIF.
    ENDCASE.
  ENDLOOP.
**********************************************************************
* 엑셀 아이템 데이터 읽어오기
  lv_posnr = 0.
  LOOP AT lt_excel INTO DATA(ls_excel)
    WHERE row >= 14.

    CASE ls_excel-col.

      WHEN 1.
        gs_excel_item-matnr = ls_excel-value.

      WHEN 3.
        gs_excel_item-kwmeng = ls_excel-value.

      WHEN 4.
        gs_excel_item-vrkme = ls_excel-value.

      WHEN 5.
        gs_excel_item-place_type = ls_excel-value.

    ENDCASE.

*    ASSIGN COMPONENT ls_excel-col OF STRUCTURE gs_excel_item TO FIELD-SYMBOL(<fs_field>).

*    IF sy-subrc = 0.
*      <fs_field> = ls_excel-value.
*    ENDIF.

    AT END OF row.

      IF gs_excel_item-matnr      IS NOT INITIAL
        OR gs_excel_item-kwmeng     IS NOT INITIAL
        OR gs_excel_item-vrkme      IS NOT INITIAL
        OR gs_excel_item-place_type IS NOT INITIAL.

        lv_posnr = lv_posnr + 10.
        gs_excel_item-posnr = lv_posnr.


        SELECT SINGLE maktx AS arktx
          FROM z8material_txt_m
          INTO gs_excel_item-arktx
          WHERE matnr = gs_excel_item-matnr.


        APPEND gs_excel_item TO gt_excel_item.
      ENDIF.
      CLEAR gs_excel_item.
    ENDAT.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_dom_val
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_STATUS_TXT
*&      <-- LV_STATUS_TXT
*&---------------------------------------------------------------------*
FORM get_dom_val.
  DATA lv_status_txt TYPE dd07t-ddtext.

  SELECT SINGLE status
    FROM z8sd_quot_req
    INTO @DATA(lv_status)
    WHERE request_id = @pa_reqid.

  IF sy-subrc = 0.
    CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
      EXPORTING
        iv_domname    = 'Z8D_REQ_STAT'
        iv_value      = lv_status
      IMPORTING
        ev_value_text = lv_status_txt.

    gv_txt1 = lv_status_txt.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_search_help
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_search_help .
  DATA: lt_return TYPE TABLE OF ddshretval.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname           = 'Z8SD_QUOT_REQ'
      fieldname         = 'REQUEST_ID'
      searchhelp        = 'Z8SH_REQ'
      dynpprog          = sy-repid
      dynpnr            = sy-dynnr
*     dynprofield       = 'PA_FIELD'
      dynprofield       = 'PA_REQID'
    TABLES
      return_tab        = lt_return
    EXCEPTIONS
      field_not_found   = 1
      no_help_for_field = 2
      inconsistent_help = 3
      no_values_found   = 4
      OTHERS            = 5.


  READ TABLE lt_return INTO DATA(ls_return) INDEX 1.

  IF sy-subrc = 0.
    pa_reqid = ls_return-fieldval. "F4 Help에서 선택 한 값을 parameter에 넣어줌

    PERFORM get_dom_val.

    CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
      EXPORTING
        functioncode = '='.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form excel_download
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM excel_download .
  DATA lv_status TYPE dd07t-ddtext.

  DATA: lv_file_filter       TYPE string VALUE 'Excel File(*.xlsx)|*.xlsx', "저장 시 파일 형식
        lv_filename          TYPE string, "파일명
        lv_initial_directory TYPE string VALUE 'C:\Users\User\Downloads', "저장 할 디렉토리 위치
        lv_path              TYPE string, "저장 시 경로
        lv_fullpath          TYPE string, "저장 시 경로 + 파일명.확장자
        lv_dest              TYPE localfile,
        ls_key               TYPE wwwdatatab,
        lv_subrc             TYPE sy-subrc.

  lv_filename = |{ pa_reqid }_현장실사 템플릿|.

***************************** 템플릿에 담을 데이터 취득 **************************
  "요청 ID 검증
  PERFORM check_reqid.

  SELECT SINGLE region_text
    FROM z8region_m
    INTO @DATA(lv_region)
    WHERE region_code = @gs_req-region_code.

  CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
    EXPORTING
      iv_domname    = 'Z8D_REQ_STAT'
      iv_value      = gs_req-status
    IMPORTING
      ev_value_text = lv_status.

****************************** 템플릿 다운로드 *******************************
  "저장할 파일명/경로를 사용자가 선택하도록 창을 띄우는 메서드
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_file_name         = lv_filename
      file_filter               = lv_file_filter
      initial_directory         = lv_initial_directory
    CHANGING
      filename                  = lv_filename
      path                      = lv_path
      fullpath                  = lv_fullpath
    EXCEPTIONS
      cntl_error                = 1
      error_no_gui              = 2
      not_supported_by_gui      = 3
      invalid_default_file_name = 4
      OTHERS                    = 5.

  IF sy-subrc <> 0 OR lv_fullpath IS INITIAL.
    RETURN.
  ENDIF.

  " SAP에 등록된 웹 오브젝트를 조회 -> ls_key에 가져옴
  SELECT SINGLE *
    FROM wwwdata
    INTO CORRESPONDING FIELDS OF @ls_key
    WHERE objid = 'ZSD_QUOT_EXCEL_TEMPLATE'.

  IF sy-subrc <> 0.
    MESSAGE s003(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.

  "실제 다운로드 메서드
  lv_dest = lv_fullpath.
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = ls_key " MIZSD_QUOT_EXCEL_TEMPLATE
      destination = lv_dest "lv_fullpath (타입이 다르기 때문에 한 번 변환해줌)
    IMPORTING
      rc          = lv_subrc.

  IF lv_subrc <> 0.
    MESSAGE i000(z8_msg).
    RETURN.
  ENDIF.

***********************Excel 템플릿에 견적 요청 정보 세팅****************************
  PERFORM set_excel_data USING lv_fullpath
                               lv_region.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form select_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- PA_FILE
*&---------------------------------------------------------------------*
FORM select_file  CHANGING p_file.
  "Excel 파일 선택
  CALL FUNCTION 'WS_FILENAME_GET'
    IMPORTING
      filename         = p_file "선택한 파일의 이름을 밭아서 p_file -> pa_file로 받음
    EXCEPTIONS
      inv_winsys       = 1
      no_batch         = 2
      selection_cancel = 3
      selection_error  = 4
      OTHERS           = 5.
  IF sy-subrc = 0 OR sy-subrc = 3.
  ELSE.
    MESSAGE e003(z8_msg).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_quot_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_quot_list .
  DATA: lv_reason  TYPE dd07t-ddtext,
        lv_status  TYPE dd07t-ddtext,
        lt_billing TYPE TABLE OF z8sd_billing_h,
        lv_vbeln_q TYPE string,
        ls_ct      TYPE lvc_s_styl,
        lv_cnt.

  CLEAR: gt_quot_list,
         lv_status,
         lt_billing,
         lv_vbeln_q,
         lv_cnt.

  IF gv_vbeln_q IS NOT INITIAL.
    lv_vbeln_q = |%{ gv_vbeln_q }%|.
  ENDIF.


  CASE gv_req_mode.
    WHEN 'R'. "요청번호에 대한 견적 조회
      SELECT h~*,
             s~vtext AS vkorg_txt,
             d~vtext AS vtweg_txt,
             b~name AS bupla_txt,
             p~name1 AS werks_txt,
             req~request_date,
             req~email,
             r~region_text AS region_txt,
             req~name1 AS kunnr_txt
         FROM z8sd_quotation_h AS h
          INNER JOIN z8sd_quot_req AS req ON h~request_id = req~request_id
          LEFT JOIN z8sales_org_m AS s ON h~vkorg = s~vkorg
          LEFT JOIN z8dc_m AS d ON h~vtweg = d~vtweg
          LEFT JOIN z8branch_m AS b ON h~bupla = b~branch
          LEFT JOIN z8plant_m AS p ON h~werks = p~werks
          LEFT JOIN z8region_m AS r ON r~region_code = req~region_code
      INTO CORRESPONDING FIELDS OF TABLE @gt_quot_list
      WHERE h~request_id = @gv_1300_reqid.

    WHEN 'A'. "전체 견적 조회
      SELECT h~*,
           s~vtext AS vkorg_txt,
           d~vtext AS vtweg_txt,
           b~name AS bupla_txt,
           p~name1 AS werks_txt,
           req~request_date,
           req~email,
           req~name1 AS kunnr_txt,
        r~region_text AS region_txt
       FROM z8sd_quotation_h AS h
        INNER JOIN z8sd_quot_req AS req ON h~request_id = req~request_id
        LEFT JOIN z8sales_org_m AS s ON h~vkorg = s~vkorg
        LEFT JOIN z8dc_m AS d ON h~vtweg = d~vtweg
        LEFT JOIN z8branch_m AS b ON h~bupla = b~branch
        LEFT JOIN z8plant_m AS p ON h~werks = p~werks
        LEFT JOIN z8region_m AS r ON r~region_code = req~region_code
      WHERE ( ( @gv_audat_to IS INITIAL AND  h~audat = @gv_audat_from )
              OR ( @gv_audat_to IS NOT INITIAL AND h~audat BETWEEN @gv_audat_from AND @gv_audat_to
              ) )
        AND ( @gv_search_status IS INITIAL OR h~status  = @gv_search_status )
        AND ( @gv_vbeln_q IS INITIAL OR h~vbeln_q LIKE @lv_vbeln_q )
        AND ( @gv_bupla_search IS INITIAL OR h~bupla = @gv_bupla_search )
        INTO CORRESPONDING FIELDS OF TABLE @gt_quot_list.

  ENDCASE.

  IF sy-subrc <> 0.
    MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT * FROM z8sd_billing_h
    INTO TABLE @lt_billing
    FOR ALL ENTRIES IN @gt_quot_list
    WHERE vgbel = @gt_quot_list-vbeln_q AND fkart = 'F1'.

  LOOP AT gt_quot_list ASSIGNING FIELD-SYMBOL(<fs_quot_h>).

    READ TABLE lt_billing INTO DATA(ls_billing) WITH KEY vgbel = <fs_quot_h>-vbeln_q
                                                          fkart = 'F1'.
    IF sy-subrc = 0.
      <fs_quot_h>-zzpayst = ls_billing-zzpayst.


      IF sy-subrc = 0.
        CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
          EXPORTING
            iv_domname    = 'Z8D_PAY_STATUS'
            iv_value      = ls_billing-zzpayst
          IMPORTING
            ev_value_text = <fs_quot_h>-pay_status_txt.
      ENDIF.
    ENDIF.



    "만료된 견적 상태 업데이트
    IF <fs_quot_h>-gueen IS NOT INITIAL AND <fs_quot_h>-gueen < sy-datum
                                        AND <fs_quot_h>-status = '10'.

      UPDATE z8sd_quotation_h
        SET status = '40'
        WHERE vbeln_q = <fs_quot_h>-vbeln_q
          AND status = '10'.

      IF sy-subrc = 0.
        <fs_quot_h>-status = '40'.
      ELSE.
        MESSAGE s125(z8_msg) DISPLAY LIKE 'E'.
      ENDIF.
    ENDIF.

    CASE <fs_quot_h>-status.
      WHEN '10' . "고객 승인 대기
        <fs_quot_h>-light = '2'.
        <fs_quot_h>-send_btn = '메일 발송'.

        IF <fs_quot_h>-is_sent = abap_false. "승인 대기 상태면서 메일을 보낸 이력이 없으면 메일 발송 버튼 추가
          CLEAR ls_ct.

          ls_ct-fieldname = 'SEND_BTN'.

          ls_ct-style = cl_gui_alv_grid=>mc_style_button.

          INSERT ls_ct INTO TABLE <fs_quot_h>-ct.
        ENDIF.

      WHEN '20'. "승인
        <fs_quot_h>-light = '3'.
      WHEN '30' OR '40'. "거절
        <fs_quot_h>-light = '1'.
    ENDCASE.

    IF <fs_quot_h>-zzpayst = '03'. "입금기한 만료
      <fs_quot_h>-light = '1'.
    ENDIF.

    IF <fs_quot_h>-is_sent = abap_true.
      <fs_quot_h>-send_btn = icon_checked.
    ENDIF.

  ENDLOOP.

  SORT gt_quot_list BY audat DESCENDING vbeln_q DESCENDING.

  LOOP AT gt_quot_list ASSIGNING FIELD-SYMBOL(<fs_quot>).

    CLEAR: lv_reason, lv_status.

    PERFORM get_reason_text USING <fs_quot>-reject_reason
                            CHANGING lv_reason.

    PERFORM get_status_text USING <fs_quot>-status
                            CHANGING lv_status.

    <fs_quot>-reject_reason_txt = lv_reason.
    <fs_quot>-status_txt = lv_status.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_upload
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_exec_val CHANGING lv_result.
  DATA: lv_zzpayst TYPE z8sd_billing_h-zzpayst.
  CLEAR: gt_quot_list, gw_quot_list, lv_result, lv_zzpayst.

  lv_result = abap_true.

  SELECT * FROM z8sd_quotation_h
    INTO CORRESPONDING FIELDS OF TABLE @gt_quot_list
    WHERE request_id = @gs_excel_head-request_id.

* 1. request_id에 대해 견적이 있는 경우 견적 리스트 중 가장 최신 견적 조회
* 2. 최신 견적이 승인대기/승인완료인 경우 실행 불가
* 2. 견적이 없거나 / 기간만료인 경우 신규 견적 생성 가능 -> 실행 ㅇ
  IF gt_quot_list IS NOT INITIAL.
    "1. 최신 견적 조회
    SORT gt_quot_list BY audat DESCENDING vbeln_q DESCENDING.

    READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.

    CASE gw_quot_list-status.
      WHEN '10'. "승인대기
        IF gw_quot_list-gueen < sy-datum. "유효기간이 만료된 경우
          "재견적 가능
        ELSE.
          MESSAGE s005(z8_msg) DISPLAY LIKE 'E'.
          lv_result = abap_false.
          RETURN.
        ENDIF.
      WHEN '20'. "승인완료
        SELECT SINGLE zzpayst FROM z8sd_billing_h INTO @lv_zzpayst WHERE vgbel = @gw_quot_list-vbeln_q AND fkart = 'F1'.
        IF lv_zzpayst = '03'.
          "재견적 가능
        ELSE. "승인완료이면서 미입금 상태 or 입금완료이면 견적 생성 불가

          MESSAGE s049(z8_msg) DISPLAY LIKE 'E'.
          lv_result = abap_false.
          RETURN.
        ENDIF.
      WHEN '30'. "고객 거절
      WHEN '40'. "기한 만료
    ENDCASE.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_reqid
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_reqid.
  CLEAR gs_req.

  SELECT SINGLE *
      FROM z8sd_quot_req
      INTO @gs_req
      WHERE request_id = @pa_reqid.

  IF sy-subrc <> 0.
    MESSAGE e002(z8_msg).
    RETURN.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form validate_excel_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM validate_excel_data CHANGING lv_result TYPE abap_bool.
  CLEAR gs_req.
  lv_result = abap_true.

  IF gs_excel_head-request_id IS INITIAL.
    MESSAGE s008(z8_msg) DISPLAY LIKE 'E'.
    lv_result = abap_false.
    RETURN.
  ELSE.
    SELECT SINGLE *
      FROM z8sd_quot_req
      INTO @gs_req
      WHERE request_id = @gs_excel_head-request_id.

    IF sy-subrc <> 0.
      MESSAGE s002(z8_msg) DISPLAY LIKE 'E'.
      lv_result = abap_false.
      RETURN.
    ENDIF.

    SELECT SINGLE region_text
     FROM z8region_m
     INTO @gv_region_text
     WHERE region_code = @gs_req-region_code.
  ENDIF.

  IF gs_excel_head-total_area IS INITIAL.
    MESSAGE s009(z8_msg) DISPLAY LIKE 'E'.
    lv_result = abap_false.
    RETURN.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form prepare_quote_data.
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM valid_excel_item.

  SELECT matnr, meins
      FROM z8material_m
      INTO TABLE @DATA(lt_mat_m).

  LOOP AT gt_excel_item ASSIGNING FIELD-SYMBOL(<ls_item>).
    CLEAR: <ls_item>-light, <ls_item>-result, <ls_item>-message.

    " 자재코드 필수
    IF <ls_item>-matnr IS INITIAL.
      <ls_item>-light   = '1'.
      <ls_item>-result  = '오류'.
      <ls_item>-message = '자재코드를 입력하세요'.
      CONTINUE.
    ENDIF.

    READ TABLE lt_mat_m INTO DATA(ls_mat_m) WITH KEY matnr = <ls_item>-matnr.

*    " 자재 존재 여부
*    SELECT SINGLE matnr, meins
*      FROM z8material_m
*      INTO @DATA(ls_mat)
*      WHERE matnr = @<ls_item>-matnr.

    IF sy-subrc <> 0.
      <ls_item>-light   = '1'.
      <ls_item>-result  = '오류'.
      <ls_item>-message = '존재하지 않는 자재코드입니다'.
      CONTINUE.
    ENDIF.

    " 수량
    IF <ls_item>-vrkme IS INITIAL.
      <ls_item>-light   = '1'.
      <ls_item>-result  = '오류'.
      <ls_item>-message = '단위를 입력하세요'.
      CONTINUE.
    ENDIF.

    IF <ls_item>-vrkme <> ls_mat_m-meins.
      <ls_item>-light   = '1'.
      <ls_item>-result  = '오류'.
      <ls_item>-message = '자재 기본단위와 일치하지 않습니다'.
      CONTINUE.
    ENDIF.

    IF <ls_item>-place_type IS INITIAL.
      <ls_item>-light   = '1'.
      <ls_item>-result  = '오류'.
      <ls_item>-message = '설치 장소를 입력해주세요'.
      CONTINUE.
    ENDIF.

    IF <ls_item>-light = '1'.

    ENDIF.

    " 정상
    <ls_item>-light   = '3'.
    <ls_item>-result  = '정상'.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL METHOD go_alv->set_table_for_first_display
    EXPORTING
*     i_structure_name              = 'SCARR'
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_excel_item
      it_fieldcatalog               = gt_fcat
*     it_sort                       = gt_sort
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a014(zmsg_136).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  gs_layout-zebra = 'X'.


  gs_layout-excp_fname = 'LIGHT'.
  gs_layout-excp_led = 'X'. "신호등 1구

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_excel_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_excel_data USING lv_fullpath
                          lv_region.
  DATA: lo_excel  TYPE ole2_object,
        lo_books  TYPE ole2_object,
        lo_book   TYPE ole2_object,
        lo_sheets TYPE ole2_object,
        lo_sheet  TYPE ole2_object,
        lo_cell   TYPE ole2_object.

  CREATE OBJECT lo_excel 'EXCEL.APPLICATION'.

  IF sy-subrc <> 0.
    MESSAGE 'Excel 실행 실패' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 테스트 중에는 Excel을 화면에 표시
  SET PROPERTY OF lo_excel 'VISIBLE' = 1.

  GET PROPERTY OF lo_excel 'WORKBOOKS' = lo_books. "Workbooks의 객체 가져오기

  CALL METHOD OF lo_books 'OPEN' "방금 다운로드한 파일 열기 Open은 Method
    EXPORTING
      #1 = lv_fullpath.

  GET PROPERTY OF lo_excel 'ACTIVEWORKBOOK' = lo_book. "현재 열린 Workbook

  " 현재 활성 Sheet
  GET PROPERTY OF lo_excel 'ACTIVESHEET' = lo_sheet.


  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
    EXPORTING
      #1 = 5
      #2 = 2.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-request_id.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
   EXPORTING
     #1 = 5
     #2 = 5.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-kunnr.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
   EXPORTING
     #1 = 5
     #2 = 7.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-req_start_date.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
    EXPORTING
      #1 = 6
      #2 = 2.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-name1.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
   EXPORTING
     #1 = 6
     #2 = 5.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-request_date.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
 EXPORTING
   #1 = 6
   #2 = 7.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-email.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
   EXPORTING
     #1 = 7
     #2 = 2.
  SET PROPERTY OF lo_cell 'VALUE' = gs_req-install_address.

  GET PROPERTY OF lo_sheet 'CELLS' = lo_cell
     EXPORTING
       #1 = 7
       #2 = 5.
  SET PROPERTY OF lo_cell 'VALUE' = lv_region.



  CALL METHOD OF lo_book 'SAVE'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form quot_validation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM quot_validation .
  DATA lv_error TYPE abap_bool.

  LOOP AT gt_excel_item INTO gs_excel_item.
    IF gs_excel_item-light = '1'.
      lv_error = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF lv_error = abap_true.
    MESSAGE e011(z8_msg).
  ELSE.
    PERFORM set_quot_data.
*    CALL SCREEN '1200'.
    LEAVE TO SCREEN 1200.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_quot_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_quot_data .
  CLEAR: gs_quot_h, gt_quot_i, gw_quot_i.

* 1. 담당 Plant/지사 배정
  PERFORM arr_plant_branch.
* 1200번 화면 상단에는 요청번호, 고객, 설치주소, 설치지역 <- (gs_req에 담겨있는 정보 gs_req는 견적 요청서의 정보를 담고있음), 담당 지사, 담당 플랜트가 들어감

* 2. 기본 정보 세팅
  gs_quot_h-request_id = gs_req-request_id.
  gs_quot_h-kunnr      = gs_req-kunnr.
  gs_quot_h-total_area = gs_excel_head-total_area.
  gs_quot_h-vkorg = '1000'.
  gs_quot_h-vtweg = '10'.
  gs_quot_h-audat = sy-datum.
  gs_quot_h-guebg = sy-datum.
  gs_quot_h-gueen = sy-datum + 30.
  gs_quot_h-ernam = sy-uname.
  gs_quot_h-vdatu = gs_req-req_start_date.
  gs_quot_h-status = '10'.

  SELECT SINGLE name FROM z8branch_m INTO gs_quot_h-bupla_txt WHERE branch = gs_quot_h-bupla.
  SELECT SINGLE name1 FROM z8plant_m INTO gs_quot_h-plant_txt WHERE werks = gs_quot_h-werks.

* 4. 1200번 ALV 아이템 /헤더 데이터 세팅
  PERFORM set_quot_item_data.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form arr_plant_branch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM arr_plant_branch .
  CLEAR: gt_plant, gs_quot_h-werks, gs_quot_h-bupla.

  DATA lv_install_region TYPE z8sd_quot_req-region_code.

       lv_install_region = gs_req-region_code. "견적요청서의 설치지역

  SELECT werks, region_code, bupla
    FROM z8plant_m
    INTO TABLE @DATA(lt_plant).

  IF sy-subrc <> 0.
    MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '플랜트 설치지역'. "플랜트 설치지역 조회에 실패했습니다
    RETURN.
  ENDIF.

  SELECT est_transit_days, from_region, to_region
    FROM z8route_m
    INTO TABLE @DATA(lt_route)
    WHERE use_yn = 'Y'.

  IF sy-subrc <> 0.
    MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '운송일수'. "운송일수 조회에 실패했습니다
    RETURN.
  ENDIF.

   SELECT kbetr, waers, region_code, werks
     FROM z8distance_m
     INTO TABLE @DATA(lt_distance).

   IF sy-subrc <> 0.
    MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '운송비'. "운송비 조회에 실패했습니다
    RETURN.
  ENDIF.

  LOOP AT lt_plant INTO DATA(ls_plant).
    CLEAR gw_plant.

    gw_plant-werks = ls_plant-werks.
    gw_plant-region_code = ls_plant-region_code.
    gw_plant-bupla = ls_plant-bupla.

    READ TABLE lt_route INTO DATA(ls_route) WITH KEY from_region = ls_plant-region_code
                                                     to_region = lv_install_region.

    IF sy-subrc <> 0.
      MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '운송일수'. "운송일수 조회에 실패했습니다
      RETURN.
    ELSE.
      gw_plant-transit_days = ls_route-est_transit_days.
    ENDIF.

    READ TABLE lt_distance INTO DATA(ls_distance) WITH KEY werks = ls_plant-werks
                                                           region_code = lv_install_region.

    IF sy-subrc <> 0.
      MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '운송비'. "운송비 조회에 실패했습니다
      RETURN.
    ELSE.
      gw_plant-trans_cost = ls_distance-kbetr.
      gw_plant-waers = ls_distance-waers.
    ENDIF.

    APPEND gw_plant TO gt_plant.
  ENDLOOP.

  SORT gt_plant BY transit_days ASCENDING
                   trans_cost ASCENDING.

  READ TABLE gt_plant INTO gw_plant INDEX 1. "최적 플랜트 결정

  IF sy-subrc <> 0.
    MESSAGE e013(z8_msg). "배정 가능한 플랜트가 없습니다.
  ENDIF.

  gs_quot_h-werks = gw_plant-werks. "견적서 헤더에 들어갈 플랜트 세팅
  gs_quot_h-bupla = gw_plant-bupla. "지사 정보 세팅
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object1200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object1200 .
  CREATE OBJECT go_container1200
    EXPORTING
      container_name              = 'CONTROL_AREA1200'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE a014(zmsg_136).
  ENDIF.

  CREATE OBJECT go_alv1200
    EXPORTING
      i_parent          = go_container1200
*     o_common_hub      =
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout1200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout1200 .
  gs_layout1200-zebra = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv1200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv1200 .
  CALL METHOD go_alv1200->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout1200
    CHANGING
      it_outtab                     = gt_quot_i
      it_fieldcatalog               = gt_fcat1200
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog1200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog1200 .

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'POSNR'.
  gw_fcat1200-coltext = '항목'.
  gw_fcat1200-col_pos = 1.
  gw_fcat1200-outputlen = 6.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'PLACE_TYPE'.
  gw_fcat1200-coltext = '설치장소'.
  gw_fcat1200-col_pos = 2.
  gw_fcat1200-outputlen = 12.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'MATNR'.
  gw_fcat1200-coltext = '자재'.
  gw_fcat1200-col_pos = 3.
  gw_fcat1200-outputlen = 13.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'ARKTX'.
  gw_fcat1200-coltext = '자재명'.
  gw_fcat1200-col_pos = 4.
  gw_fcat1200-outputlen = 20.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'KWMENG'.
  gw_fcat1200-coltext = '수량'.
  gw_fcat1200-col_pos = 4.
  gw_fcat1200-outputlen = 7.
  gw_fcat1200-qfieldname = 'VRKME'.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'VRKME'.
  gw_fcat1200-coltext = '단위'.
  gw_fcat1200-col_pos = 5.
  gw_fcat1200-outputlen = 5.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'NETPR'.
  gw_fcat1200-coltext = '단가'.
  gw_fcat1200-col_pos = 6.
  gw_fcat1200-outputlen = 13.
  gw_fcat1200-cfieldname = 'WAERS'.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'WAERS'.
  gw_fcat1200-coltext = '통화'.
  gw_fcat1200-col_pos = 7.
  gw_fcat1200-outputlen = 6.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'NETWR'.
  gw_fcat1200-coltext = '자재 총 금액'.
  gw_fcat1200-col_pos = 8.
  gw_fcat1200-outputlen = 13.
  gw_fcat1200-cfieldname = 'WAERS'.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'WAERS'.
  gw_fcat1200-coltext = '통화'.
  gw_fcat1200-col_pos = 9.
  gw_fcat1200-outputlen = 6.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'STOCK'.
  gw_fcat1200-coltext = '가용재고'.
  gw_fcat1200-col_pos = 10.
  gw_fcat1200-outputlen = 6.
  gw_fcat1200-qfieldname = 'MEINS'.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'MEINS'.
  gw_fcat1200-coltext = '단위'.
  gw_fcat1200-col_pos = 11.
  gw_fcat1200-outputlen = 5.
  APPEND gw_fcat1200 TO gt_fcat1200.

  CLEAR gw_fcat1200.
  gw_fcat1200-fieldname = 'MESSAGE'.
  gw_fcat1200-coltext = '메시지'.
  gw_fcat1200-col_pos = 12.
  gw_fcat1200-outputlen = 50.
  APPEND gw_fcat1200 TO gt_fcat1200.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_quot_item_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_quot_item_data .
  DATA: lv_total TYPE z8sd_quotation_h-netwr.

  " 자재 조회용
  DATA: BEGIN OF lw_material,
          matnr    TYPE z8material_m-matnr,
          maktx    TYPE z8material_txt_m-maktx,
          stock    TYPE z8material_stk_m-labst,
          zzrsvqty TYPE z8material_stk_m-zzrsvqty,
          meins    TYPE z8material_stk_m-meins,
          netpr    TYPE z8sd_price_m-netpr,
          waers    TYPE z8sd_price_m-waers,
          eisbe    TYPE z8matplant_m-eisbe,
        END OF lw_material.

  DATA: lt_material LIKE TABLE OF lw_material,
        lr_matnr    TYPE RANGE OF z8material_m-matnr.

  CLEAR: lv_total, gt_quot_i.

  " 엑셀에 있는 자재번호만 조회
  LOOP AT gt_excel_item INTO gs_excel_item.
    APPEND VALUE #(
      sign   = 'I'
      option = 'EQ'
      low    = gs_excel_item-matnr
    ) TO lr_matnr.
  ENDLOOP.

  IF lr_matnr IS NOT INITIAL.

    SELECT m~matnr,
           t~maktx,
           stk~labst AS stock,
           stk~zzrsvqty,
           stk~meins,
           pri~netpr,
           pri~waers,
           mt~eisbe
      FROM z8material_m AS m
      LEFT JOIN z8material_txt_m AS t ON t~matnr = m~matnr
      LEFT JOIN z8material_stk_m AS stk ON stk~matnr = m~matnr
                                       AND stk~werks = @gs_quot_h-werks
      LEFT JOIN z8sd_price_m AS pri ON pri~matnr = m~matnr
                                    AND pri~use_yn = 'Y'
      LEFT JOIN z8matplant_m AS mt ON mt~matnr = m~matnr
                                  AND mt~werks = @gs_quot_h-werks
      WHERE m~matnr IN @lr_matnr
      INTO TABLE @lt_material.

  ENDIF.

  LOOP AT gt_excel_item INTO gs_excel_item.

    CLEAR: gw_quot_i, lw_material.

    " 엑셀 데이터
    gw_quot_i-posnr      = gs_excel_item-posnr.
    gw_quot_i-place_type = gs_excel_item-place_type.
    gw_quot_i-matnr      = gs_excel_item-matnr.
    gw_quot_i-kwmeng     = gs_excel_item-kwmeng.
    gw_quot_i-vrkme      = gs_excel_item-vrkme.

    " 미리 조회한 자재정보 읽기
    READ TABLE lt_material INTO lw_material WITH KEY matnr = gs_excel_item-matnr.

    IF sy-subrc = 0.

      gw_quot_i-arktx = lw_material-maktx.
      gw_quot_i-stock = lw_material-stock.
      gw_quot_i-meins = lw_material-meins.
      gw_quot_i-netpr = lw_material-netpr.
      gw_quot_i-waers = lw_material-waers.

      " 품목 금액 계산
      gw_quot_i-netwr = gw_quot_i-netpr * gw_quot_i-kwmeng.

      " 자재비 누적
      lv_total += gw_quot_i-netwr.

      gw_quot_i-stock = lw_material-stock - lw_material-zzrsvqty - lw_material-eisbe.

    ENDIF.

    " 재고 부족 메시지
    IF gw_quot_i-stock < gw_quot_i-kwmeng.

      gw_quot_i-message =
        |{ gs_quot_h-werks } Plant의 재고가 부족합니다. 주문 확정 후 재고를 확보해주세요.|.

    ENDIF.

    APPEND gw_quot_i TO gt_quot_i.

  ENDLOOP.

  " 운송비
  SELECT SINGLE kbetr FROM z8distance_m INTO @gs_quot_h-transit_cost WHERE werks = @gs_quot_h-werks AND region_code = @gs_req-region_code.

  " 설치비 & 면적 별 기본 작업일수 -> SO 생성 후 인력 배정에 따라 WORK_DAYS 재산정
  SELECT SINGLE kbetr, work_days
    FROM z8install_m
    INTO (@gs_quot_h-install_cost, @gs_quot_h-work_days)
    WHERE from_m2 < @gs_quot_h-total_area AND to_m2 >= @gs_quot_h-total_area.

  IF sy-subrc <> 0.
    MESSAGE s044(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.


  gs_quot_h-netwr = gs_quot_h-install_cost + gs_quot_h-transit_cost + lv_total. "견적 헤더 총액

  "화면용 -> item은 ALV가 출력(얘도 필드카탈로그에서 통화 매핑 해줬어야 함), Header는 Dynpro 필드가 직접 출력하기 때문에 포맷팅을 안 해줌
  gs_quot_h-waerk = 'KRW'.
  WRITE lv_total TO gv_mat_total_disp CURRENCY gs_quot_h-waerk.
  WRITE gs_quot_h-transit_cost TO gv_transit_cost_disp CURRENCY gs_quot_h-waerk.
  WRITE gs_quot_h-install_cost TO gv_install_cost_disp CURRENCY gs_quot_h-waerk.
  WRITE gs_quot_h-netwr TO gv_netwr_disp CURRENCY gs_quot_h-waerk.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_quotation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_quotation .

  DATA: lv_number TYPE n LENGTH 9,
        lv_answer TYPE c LENGTH 1,
        lv_result TYPE abap_bool.

  PERFORM check_exec_val CHANGING lv_result.

  IF lv_result = abap_false.
    RETURN.
  ENDIF.

  " 2. DB 저장 전에 사용자 확인
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '견적 생성'
      text_question         = '견적을 생성하시겠습니까?'
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
*    MESSAGE '사용자가 요청을 취소했습니다' TYPE 'I'.
    MESSAGE s030(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  " 3. 견적번호 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8SD_QUOT'
    IMPORTING
      number                  = lv_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    MESSAGE e014(z8_msg).
    RETURN.
  ENDIF.

  gs_quot_h-vbeln_q = |Q{ lv_number }|.

  " 4. 아이템에 견적번호 세팅
  LOOP AT gt_quot_i INTO gw_quot_i.
    gw_quot_i-vbeln_q = gs_quot_h-vbeln_q.
    MODIFY gt_quot_i FROM gw_quot_i.
  ENDLOOP.

  " 5. 헤더 저장
  INSERT z8sd_quotation_h FROM gs_quot_h.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e015(z8_msg).
    RETURN.
  ENDIF.

  " 6. 아이템 저장
  DATA: gt_quot_i_db TYPE TABLE OF z8sd_quotation_i,
        gs_quot_i_db TYPE z8sd_quotation_i.

  LOOP AT gt_quot_i INTO gw_quot_i.

    CLEAR gs_quot_i_db.

    SELECT SINGLE maktx FROM z8material_txt_m INTO gw_quot_i-arktx WHERE matnr = gw_quot_i-matnr.

    MOVE-CORRESPONDING gw_quot_i TO gs_quot_i_db.

    APPEND gs_quot_i_db TO gt_quot_i_db.
  ENDLOOP.

  INSERT z8sd_quotation_i FROM TABLE gt_quot_i_db.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e016(z8_msg).
    RETURN.
  ENDIF.

  " 7. 요청 상태 변경
  UPDATE z8sd_quot_req
    SET status = '20'
    WHERE request_id = @gs_quot_h-request_id.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE e017(z8_msg).
    RETURN.
  ENDIF.

  COMMIT WORK.


  CALL FUNCTION 'DEQUEUE_EZ8_QUOTATION'
    EXPORTING
      mode_z8sd_quot_req = 'E'
      request_id         = gs_quot_h-request_id.


  CLEAR lv_answer.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '견적 생성 완료'
      text_question         = |견적 { gs_quot_h-vbeln_q } 생성 완료. 견적 목록을 조회하시겠습니까?|
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '1'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer = '1'.
    gv_req_mode    = 'R'.
    gv_1300_reqid  = gs_quot_h-request_id.
    gv_selected_id = gs_quot_h-vbeln_q.

    PERFORM get_quot_list. "업데이트 된 DB 재조회
    PERFORM get_quot_item USING gv_selected_id. "방금 생성 된 견적의 item 조회

    CALL SCREEN '1300'.
    PERFORM quot_list_refresh.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object1300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object1300 .
  CREATE OBJECT go_docking_container
    EXPORTING
      repid     = sy-repid
      dynnr     = sy-dynnr
      side      = cl_gui_docking_container=>dock_at_bottom
      extension = 380.  " 픽셀 단위, 화면 크기 조정 가능
  CREATE OBJECT go_split
    EXPORTING
      parent            = go_docking_container
      rows              = 2
      columns           = 1
    EXCEPTIONS
      cntl_error        = 1
      cntl_system_error = 2
      OTHERS            = 6.

  CALL METHOD go_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_container1300_h.

  CALL METHOD go_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_container1300_i.

  CREATE OBJECT go_alv1300_h
    EXPORTING
      i_parent = go_container1300_h.

  CREATE OBJECT go_alv1300_i
    EXPORTING
      i_parent = go_container1300_i.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_header_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_header_alv .
  CALL METHOD go_alv1300_h->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8SD_QUOTATION_H'
      is_layout                     = gs_layout1300
    CHANGING
      it_outtab                     = gt_quot_list
      it_fieldcatalog               = gt_fcat1300
*     it_sort                       = gt_sort1300
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_item_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_item_alv .
  CALL METHOD go_alv1300_i->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8SD_QUOTATION_I'
      is_layout                     = gs_layout1300_i
    CHANGING
      it_outtab                     = gt_quot_item
      it_fieldcatalog               = gt_fcat1300_i
      it_sort                       = gt_sort1300_i
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form popup_create_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM popup_create_quot .
  CLEAR gv_answer.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '안내'
      text_question         = '견적서가 없습니다. 견적서를 생성하시겠습니까?'
      text_button_1         = '네'
      text_button_2         = '아니오'
      display_cancel_button = space
    IMPORTING
      answer                = gv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_constrol_resource
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_constrol_resource.

  IF go_alv1300_h IS BOUND.
    go_alv1300_h->free( ).
  ENDIF.

  IF go_alv1300_i IS BOUND.
    go_alv1300_i->free( ).
  ENDIF.

  IF go_split IS BOUND.
    go_split->free( ).
  ENDIF.

  IF go_custom1301 IS BOUND.
    go_custom1301->free( ).
  ENDIF.

  CLEAR:
    go_alv1300_h,
    go_alv1300_i,
    go_container1300_h,
    go_container1300_i,
    go_split,
    go_custom1301.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_quot_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_quot_item USING VALUE(p_vbeln_q).
  CLEAR gt_quot_item.

  IF p_vbeln_q IS INITIAL.
    MESSAGE S050(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT *
    FROM z8sd_quotation_i
    INTO TABLE @gt_quot_item
    WHERE vbeln_q = @p_vbeln_q.

  IF sy-subrc <> 0.
    MESSAGE s127(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_quot_item ASSIGNING FIELD-SYMBOL(<fs_item>).
    <fs_item>-waers1 = 'KRW'.
  ENDLOOP.

ENDFORM.

FORM select_row1300 USING VALUE(p_vbeln_q).
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  CLEAR: lt_rows, ls_row.

  IF gt_quot_list IS INITIAL.
    CLEAR gv_selected_id.
    RETURN.
  ENDIF.


  "2. 마지막으로 선택했던 견적번호 검색 (gv_selected_id 가 전달 됨)
  READ TABLE gt_quot_list INTO gw_quot_list WITH KEY vbeln_q = p_vbeln_q.

  IF sy-subrc = 0.
    ls_row-index = sy-tabix.
  ELSE.
    ls_row-index = 1. "기존 견적이 조회 목록에 없으면 첫 번째 행 선택

    READ TABLE gt_quot_list INTO gw_quot_list INDEX 1.
  ENDIF.


  "3. 실제 선택된 견적번호 기억
  gv_selected_id = gw_quot_list-vbeln_q.

  APPEND ls_row TO lt_rows.

  "4. 선택 행 하이라이트
  go_alv1300_h->set_selected_rows(
    EXPORTING
      it_index_rows = lt_rows
  ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler .
  SET HANDLER lcl_handler=>on_double_click FOR go_alv1300_h.
  SET HANDLER lcl_handler=>on_hotspot FOR go_alv1300_h.
  SET HANDLER lcl_handler=>on_row_select FOR go_alv1300_h.
  SET HANDLER lcl_handler=>on_button_click FOR go_alv1300_h.

  CALL METHOD go_alv1300_h->register_delayed_event
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_delayed_change_select.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv1300_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv1300_layout .
  gs_layout1300-sel_mode = 'B'.
  gs_layout1300-no_toolbar = 'X'.
  "gs_layout1300-cwidth_opt = 'X'.
  gs_layout1300-excp_fname = 'LIGHT'.
  gs_layout1300-excp_led = 'X'. "신호등 1구
  gs_layout1300-stylefname = 'CT'.
  gs_layout1300-zebra = 'X'.


*&---------------------------------------------------------------------*
* 2026.11.10 SESAC-136 전체 견적 탭 전환 시 건수 오류로 주석 처리
*&---------------------------------------------------------------------*
*  gs_layout1300-grid_title = |전체 ({ lines( gt_quot_list ) })건|.



  gs_layout1300_i-no_toolbar = 'X'.
  gs_layout1300_i-zebra = 'X'.


  CLEAR gw_sort1300_i.
  gw_sort1300_i-spos      = 1.
  gw_sort1300_i-fieldname = 'VBELN_Q'.  " SO 번호
  gw_sort1300_i-up        = 'X'.
  APPEND gw_sort1300_i TO gt_sort1300_i.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_quot_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM update_quot_status .
  DATA: ls_selected_quot TYPE z8sd_quotation_h,
        lv_answer        TYPE c LENGTH 1,
        lv_quot_status   TYPE z8sd_quotation_h-status,
        lv_text          TYPE c LENGTH 40.
  DATA: lv_reject_reason TYPE z8sd_quotation_h-reject_reason,
        lt_dom_values    TYPE TABLE OF dd07v,
        lt_return        TYPE TABLE OF ddshretval.
  DATA lv_action TYPE sy-ucomm.
  DATA ls_customer TYPE z8customer_m.

  CLEAR: ls_selected_quot, ls_customer.
  lv_action = sy-ucomm.

  PERFORM get_selected_quot USING abap_true
                            CHANGING ls_selected_quot.

  IF ls_selected_quot-vbeln_q IS INITIAL.
    RETURN.
  ENDIF.
*******************************예외 처리************************************
  CASE ls_selected_quot-status.
    WHEN '20' OR '30'.
      MESSAGE s033(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    WHEN '40'.
      MESSAGE s034(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
  ENDCASE.

******************************상태 변경 및 DB 반영*************************************
  CASE lv_action.
    WHEN 'ACCE'.
      lv_quot_status = '20'.
      lv_text = | { ls_selected_quot-vbeln_q } 을 고객 승인 처리 하시겠습니까? |.

    WHEN 'DENY'.
      CLEAR: lt_dom_values,
         lt_return,
         gt_reject,
         lv_reject_reason.
      CALL FUNCTION 'DD_DOMVALUES_GET'
        EXPORTING
          domname   = 'Z8D_REJECT_CODE'
          text      = 'X'
        TABLES
          dd07v_tab = lt_dom_values.

      LOOP AT lt_dom_values INTO DATA(ls_dom).
        CLEAR gs_reject.
        gs_reject-code = ls_dom-domvalue_l.
        gs_reject-text = ls_dom-ddtext.

        APPEND gs_reject TO gt_reject.
      ENDLOOP.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield        = 'CODE' "=> CODE 값을 반환해달라는 뜻
          value_org       = 'S' "Structure -> 구조체 기반의 인터널 테이블이므로
        TABLES
          value_tab       = gt_reject "두 컬럼짜리 테이블
          return_tab      = lt_return
        EXCEPTIONS
          parameter_error = 1
          no_values_found = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.

      READ TABLE lt_return INTO DATA(ls_return) INDEX 1.
      IF sy-subrc <> 0 OR ls_return-fieldval IS INITIAL.
        RETURN.
      ENDIF.
      lv_reject_reason = ls_return-fieldval.


      lv_quot_status = '30'.
      lv_text = | { ls_selected_quot-vbeln_q } 을 고객 거절 처리 하시겠습니까? |.

  ENDCASE.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '견적 상태 변경'
      text_question         = lv_text
      text_button_1         = '예'
      text_button_2         = '아니오'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    MESSAGE s030(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "견적 헤더 업데이트
  CASE lv_action.
    WHEN 'DENY'.
      UPDATE z8sd_quotation_h SET status = @lv_quot_status,
                                  reject_reason = @lv_reject_reason
                              WHERE vbeln_q = @ls_selected_quot-vbeln_q.

      IF sy-subrc <> 0.
        ROLLBACK WORK.
        MESSAGE s035(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

    WHEN 'ACCE'.
      UPDATE z8sd_quotation_h SET status = @lv_quot_status WHERE vbeln_q = @ls_selected_quot-vbeln_q.

      IF sy-subrc <> 0.
        ROLLBACK WORK.
        MESSAGE s036(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      SELECT SINGLE kunnr FROM z8customer_m INTO @DATA(lv_kunnr) WHERE kunnr = @ls_selected_quot-kunnr.

      IF sy-subrc <> 0.
        SELECT SINGLE *
          FROM z8sd_quot_req
          INTO CORRESPONDING FIELDS OF @ls_customer
          WHERE request_id = @ls_selected_quot-request_id.

        IF sy-subrc <> 0.
          ROLLBACK WORK.
          MESSAGE s037(z8_msg) DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        ls_customer-saknr = '11010000'.
        INSERT z8customer_m FROM ls_customer.

        IF sy-subrc <> 0.
          ROLLBACK WORK.
          MESSAGE s038(z8_msg) DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.
  ENDCASE.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  IF lv_action = 'DENY'. "요청서 상태 변경
    UPDATE z8sd_quot_req SET status = '10' WHERE request_id = ls_selected_quot-request_id.

    IF sy-subrc <> 0.
      MESSAGE s040(z8_msg) DISPLAY LIKE 'E'.
      ROLLBACK WORK.
      RETURN.
    ENDIF.
  ENDIF.

  READ TABLE gt_quot_list ASSIGNING FIELD-SYMBOL(<fs_quot>) WITH KEY vbeln_q = ls_selected_quot-vbeln_q.

  IF sy-subrc = 0.

    "상태 코드 및 텍스트 변경
    <fs_quot>-status = lv_quot_status.

    PERFORM get_status_text USING <fs_quot>-status
                            CHANGING <fs_quot>-status_txt.

    IF lv_action = 'DENY'.
      <fs_quot>-reject_reason = lv_reject_reason.
      PERFORM get_reason_text
        USING    <fs_quot>-reject_reason
        CHANGING <fs_quot>-reject_reason_txt.
    ENDIF.
  ENDIF.

  COMMIT WORK.

  gv_selected_id = ls_selected_quot-vbeln_q.

  MESSAGE i039(z8_msg).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form quot_list_refresh
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM quot_list_refresh .
  gs_stable1300-row = 'X'.
  gs_stable1300-col = 'X'.

  IF go_alv1300_h IS BOUND.
    go_alv1300_h->refresh_table_display(
      EXPORTING
        is_stable = gs_stable1300 ).
  ENDIF.

  IF go_alv1300_i IS BOUND.
    go_alv1300_i->refresh_table_display( ).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form print_quotation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM print_quotation .
  DATA: ls_selected_quot      TYPE z8sd_quotation_h,
        ls_req                TYPE z8sd_quot_req,
        lt_item               TYPE TABLE OF z8sd_quotation_i,
        ls_item               TYPE z8sd_quotation_i,

        lv_material_total     TYPE z8sd_quotation_h-netwr,
        lv_material_total_txt TYPE char30,

        lv_fnam               TYPE rs38l_fnam,

        lv_bupla_txt          TYPE z8branch_m-name,
        lv_werks_txt          TYPE z8plant_m-name1,
        lv_region_txt         TYPE char60.



  PERFORM get_selected_quot USING abap_true
                            CHANGING ls_selected_quot.

  IF ls_selected_quot-vbeln_q IS INITIAL.
    MESSAGE s040(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT SINGLE name INTO lv_bupla_txt FROM z8branch_m WHERE branch = ls_selected_quot-bupla.

  IF ls_selected_quot-vbeln_q IS INITIAL.
    MESSAGE s043(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT SINGLE name1 INTO lv_werks_txt FROM z8plant_m WHERE werks = ls_selected_quot-werks.

  IF ls_selected_quot-vbeln_q IS INITIAL.
    MESSAGE s043(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT SINGLE region_text
    INTO lv_region_txt
    FROM z8sd_quot_req AS req INNER JOIN z8region_m AS r ON req~region_code = r~region_code
    WHERE req~request_id = ls_selected_quot-request_id.

  IF ls_selected_quot-vbeln_q IS INITIAL.
    MESSAGE s043(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  SELECT SINGLE * FROM z8sd_quot_req INTO ls_req WHERE request_id = ls_selected_quot-request_id.


  IF sy-subrc <> 0.
    MESSAGE s037(z8_msg) DISPLAY LIKE 'E'. " 견적 요청 정보를 찾을 수 없습니다
    RETURN.
  ENDIF.


  SELECT * FROM z8sd_quotation_i INTO TABLE lt_item WHERE vbeln_q = ls_selected_quot-vbeln_q.

  IF lt_item IS INITIAL.
    MESSAGE s041(z8_msg) DISPLAY LIKE 'E'. "견적 품목이 없습니다
    RETURN.
  ENDIF.

  LOOP AT lt_item INTO ls_item.
    lv_material_total += ls_item-netwr.
  ENDLOOP.

  WRITE lv_material_total TO lv_material_total_txt CURRENCY 'KRW'.
  CONDENSE lv_material_total_txt.

  "Smart Form의 함수명 취득
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'Z8SD_QUOTATION'
    IMPORTING
      fm_name            = lv_fnam
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE s042(z8_msg) DISPLAY LIKE 'E'.
*    MESSAGE 'Smart Form을 호출할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.


  CALL FUNCTION lv_fnam
    EXPORTING
      is_header             = ls_selected_quot
      is_req                = ls_req
      it_item               = lt_item
      iv_material_total     = lv_material_total
      iv_material_total_txt = lv_material_total_txt
      iv_bupla_txt          = lv_bupla_txt
      iv_werks_txt          = lv_werks_txt
      iv_region_txt         = lv_region_txt
    EXCEPTIONS
      formatting_error      = 1
      internal_error        = 2
      send_error            = 3
      user_canceled         = 4
      OTHERS                = 5.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_quot_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_ROW_ID_INDEX
*&---------------------------------------------------------------------*
FORM get_quot_detail  USING VALUE(p_index).
  DATA: lv_status TYPE dd07t-ddtext,
        lv_reason TYPE dd07t-ddtext,
        lv_trans  TYPE z8sd_quotation_h-transit_cost,
        lv_inst   TYPE z8sd_quotation_h-install_cost,
        lv_total  TYPE z8sd_quotation_h-netwr.


  CLEAR: gs_quot_detail, gw_quot_list, lv_status, lv_trans, lv_inst, lv_total, gv_status, lv_reason, gv_mat_total, gv_tot, gv_trans, gv_inst, gv_reject_message.

  READ TABLE gt_quot_list INTO gw_quot_list INDEX p_index.
  IF sy-subrc <> 0.
    MESSAGE s043(z8_msg) DISPLAY LIKE 'E'. "견적 정보를 불러오지 못했습니다
    RETURN.
  ENDIF.

  IF sy-subrc = 0.
    SELECT SINGLE *
      FROM z8v_quotation
      INTO gs_quot_detail
      WHERE vbeln_q = gw_quot_list-vbeln_q.


      IF sy-subrc <> 0.
        MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '견적 상세'. "견적 상세 조회에 실패했습니다
      ENDIF.
  ENDIF.

  SELECT SINGLE region_code
    FROM z8sd_quot_req
    INTO @DATA(lv_region)
    WHERE request_id = @gw_quot_list-request_id.

    IF sy-subrc <> 0.
      MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '설치지역'. "설치지역 조회에 실패했습니다
    ENDIF.

  SELECT SUM( netwr ) FROM z8sd_quotation_i INTO lv_total WHERE vbeln_q = gw_quot_list-vbeln_q.
  WRITE lv_total TO gv_mat_total CURRENCY 'KRW'.

  SELECT SINGLE region_text
    FROM z8region_m
    INTO @gv_region_txt
    WHERE region_code = @lv_region.

  IF sy-subrc <> 0.
    MESSAGE S230(z8_msg) DISPLAY LIKE 'E' WITH '설치지역명'. "설치지역명 조회에 실패했습니다
  ENDIF.

  "금액 필드 변환
  WRITE gs_quot_detail-transit_cost TO gv_trans CURRENCY 'KRW' RIGHT-JUSTIFIED.
  WRITE gs_quot_detail-install_cost TO gv_inst CURRENCY 'KRW' RIGHT-JUSTIFIED.
  WRITE gs_quot_detail-netwr TO gv_tot CURRENCY 'KRW' RIGHT-JUSTIFIED.


  CONDENSE: gv_trans, gv_inst, gv_tot, gv_mat_total. "불필요한 공백 줄이는 로직



  IF gw_quot_list-status = '30' AND gs_quot_detail-reject_reason IS NOT INITIAL.
    PERFORM get_reason_text USING gs_quot_detail-reject_reason
                            CHANGING lv_reason.

    gv_reject_message = |(거절 사유: { lv_reason })|.
    IF sy-subrc <> 0.
      CLEAR gv_reject_message.
    ENDIF.
  ENDIF.

  PERFORM get_status_text USING gw_quot_list-status
                          CHANGING lv_status.

  gv_status = lv_status.




ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fcat1300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat1300 .
  CLEAR: gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'LIGHT'.
  gw_fcat1300-coltext = '상태'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'KUNNR'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'VKORG'.
  gw_fcat1300-coltext = '영업조직'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'VTWEG'.
  gw_fcat1300-coltext = '유통채널'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'STATUS'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'REJECT_REASON'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'VKORG_TXT'.
  gw_fcat1300-coltext = '영업조직'.
  gw_fcat1300-col_pos = 5.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'VTWEG_TXT'.
  gw_fcat1300-coltext = '유통채널'.
  gw_fcat1300-col_pos = 6.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'BUPLA'.
  gw_fcat1300-col_pos = 7.
  gw_fcat1300-coltext = '지사'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'WERKS'.
  gw_fcat1300-coltext = '플랜트'.
  gw_fcat1300-col_pos = 9.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'IS_SENT'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'STATUS_TXT'.
  gw_fcat1300-coltext = '견적 상태'.
  gw_fcat1300-col_pos = 1.
  gw_fcat1300-outputlen = 8.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'PAY_STATUS_TXT'.
  gw_fcat1300-coltext = '후속 진행상태'.
  gw_fcat1300-col_pos = 2.
  gw_fcat1300-outputlen = 9.
  APPEND gw_fcat1300 TO gt_fcat1300.


  CLEAR: gw_fcat1300.
  gw_fcat1300-fieldname = 'VBELN_Q'.
  gw_fcat1300-coltext = '견적 번호'.
  gw_fcat1300-hotspot = 'X'.
  gw_fcat1300-col_pos = 3.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'REQUEST_ID'.
  gw_fcat1300-coltext = '견적 요청 번호'.
  gw_fcat1300-col_pos = 4.
  gw_fcat1300-outputlen = 10.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'KUNNR_TXT'.
  gw_fcat1300-coltext = '고객명'.
  gw_fcat1300-col_pos = 5.
  gw_fcat1300-outputlen = 15.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'BUPLA_TXT'.
  gw_fcat1300-coltext = '지사명'.
  gw_fcat1300-col_pos = 6.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'WERKS_TXT'.
  gw_fcat1300-coltext = '플랜트명'.
  gw_fcat1300-col_pos = 7.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'AUDAT'.
  gw_fcat1300-col_pos = 8.
  gw_fcat1300-just = 'C'.
  gw_fcat1300-coltext = '견적 작성일'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'GUEBG'.
  gw_fcat1300-col_pos = 9.
  gw_fcat1300-just = 'C'.
  gw_fcat1300-no_out = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'GUEEN'.
  gw_fcat1300-coltext = '견적 종료일'.
  gw_fcat1300-col_pos = 10.
  gw_fcat1300-just = 'C'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'REQUEST_DATE'.
  gw_fcat1300-coltext = '요청접수일'.
  gw_fcat1300-outputlen = 10.
  gw_fcat1300-col_pos = 11.
  gw_fcat1300-just = 'C'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'VDATU'.
  gw_fcat1300-coltext = '희망착공일'.
  gw_fcat1300-col_pos = 12.
  gw_fcat1300-just = 'C'.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'TOTAL_AREA'.
  gw_fcat1300-coltext = '면적(M2)'.
  gw_fcat1300-col_pos = 13.
  gw_fcat1300-outputlen = 8.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'WORK_DAYS'.
  gw_fcat1300-coltext = '예상 작업일수'.
  gw_fcat1300-col_pos = 14.
  gw_fcat1300-outputlen = 10.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'TRANSIT_COST'.
  gw_fcat1300-col_pos = 15.
  gw_fcat1300-outputlen = 10.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'INSTALL_COST'.
  gw_fcat1300-col_pos = 16.
  gw_fcat1300-outputlen = 10.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'NETWR'.
  gw_fcat1300-coltext = '총 견적금액'.
  gw_fcat1300-col_pos = 17.
  gw_fcat1300-outputlen = 11.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'WAERK'.
  gw_fcat1300-coltext = '통화'.
  gw_fcat1300-col_pos = 18.
  gw_fcat1300-outputlen = 5.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'REJECT_REASON_TXT'.
  gw_fcat1300-coltext = '거절 사유'.
  gw_fcat1300-col_pos = 19.
  gw_fcat1300-outputlen = 8.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'ERNAM'.
  gw_fcat1300-coltext = '담당자'.
  gw_fcat1300-col_pos = 20.
  gw_fcat1300-outputlen = 7.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'EMAIL'.
  gw_fcat1300-coltext = '고객 이메일'.
  gw_fcat1300-col_pos = 21.
  gw_fcat1300-outputlen = 25.
  APPEND gw_fcat1300 TO gt_fcat1300.

  CLEAR gw_fcat1300.
  gw_fcat1300-fieldname = 'SEND_BTN'.
  gw_fcat1300-coltext = '견적서 발송'.
  gw_fcat1300-col_pos = 22.
  gw_fcat1300-outputlen = 10.
  gw_fcat1300-icon = 'X'.
  APPEND gw_fcat1300 TO gt_fcat1300.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_alv1301
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_alv1301 .
  CREATE OBJECT go_custom1301
    EXPORTING
      container_name = 'CONTROL_AREA1'. "서브스크린의 Custom Control 연결

  "2. Header / Item용 Splitter
  CREATE OBJECT go_split
    EXPORTING
      parent  = go_custom1301
      rows    = 2
      columns = 1.

  "3. 위쪽 Header 영역
  CALL METHOD go_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_container1300_h.

  "4. 아래쪽 Item 영역
  CALL METHOD go_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_container1300_i.

  CALL METHOD go_split->set_row_height
    EXPORTING
      id     = 1
      height = 50. "비율 (%)

  CALL METHOD go_split->set_row_height
    EXPORTING
      id     = 2
      height = 50. "비율 (%)

  "5. ALV 생성
  CREATE OBJECT go_alv1300_h
    EXPORTING
      i_parent = go_container1300_h.

  CREATE OBJECT go_alv1300_i
    EXPORTING
      i_parent = go_container1300_i.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_reason_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_QUOT_DETAIL_REJECT_REASON
*&      <-- GV_REASON
*&---------------------------------------------------------------------*
FORM get_reason_text  USING    p_reject_code
                      CHANGING p_reason_text.
  CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
    EXPORTING
      iv_domname      = 'Z8D_REJECT_CODE'
      iv_value        = p_reject_code
    IMPORTING
      ev_value_text   = p_reason_text
    EXCEPTIONS
      value_not_found = 1
      OTHERS          = 2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_status_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_QUOT_LIST_STATUS
*&      <-- LV_STATUS
*&---------------------------------------------------------------------*
FORM get_status_text  USING  VALUE(p_status_code)
                      CHANGING p_status_text.

  CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
    EXPORTING
      iv_domname      = 'Z8D_QUOT_STATUS'
      iv_value        = p_status_code
    IMPORTING
      ev_value_text   = p_status_text
    EXCEPTIONS
      value_not_found = 1
      OTHERS          = 2.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fcat1300_i
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat1300_i .
  CLEAR gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'VBELN_Q'.
  gw_fcat1300_i-coltext = '견적 번호'.
  gw_fcat1300_i-col_pos = 1.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'POSNR'.
  gw_fcat1300_i-coltext = '품목'.
  gw_fcat1300_i-outputlen = 3.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'MATNR'.
  gw_fcat1300_i-coltext = '자재'.
  gw_fcat1300_i-outputlen = 15.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'ARKTX'.
  gw_fcat1300_i-coltext = '자재명'.
  gw_fcat1300_i-outputlen = 15.
  gw_fcat1300_i-col_pos = 5.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'PLACE_TYPE'.
  gw_fcat1300_i-coltext = '설치 장소'.
  gw_fcat1300_i-outputlen = 15.
  gw_fcat1300_i-col_pos = 6.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'NETPR'.
  gw_fcat1300_i-coltext = '단가'.
  gw_fcat1300_i-col_pos = 8.
  gw_fcat1300_i-outputlen = 10.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'WAERS'.
  gw_fcat1300_i-coltext = '통화'.
  gw_fcat1300_i-outputlen = 5.
  gw_fcat1300_i-col_pos = 9.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'KWMENG'.
  gw_fcat1300_i-coltext = '수량'.
  gw_fcat1300_i-outputlen = 5.
  gw_fcat1300_i-col_pos = 10.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'VRKME'.
  gw_fcat1300_i-coltext = '단위'.
  gw_fcat1300_i-outputlen = 5.
  gw_fcat1300_i-col_pos = 11.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'NETWR'.
  gw_fcat1300_i-coltext = '자재 총액'.
  gw_fcat1300_i-col_pos = 12.
  gw_fcat1300_i-outputlen = 10.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.

  CLEAR gw_fcat1300_i.
  gw_fcat1300_i-fieldname = 'WAERS1'.
  gw_fcat1300_i-coltext = '통화'.
  gw_fcat1300_i-outputlen = 5.
  gw_fcat1300_i-col_pos = 13.
  APPEND gw_fcat1300_i TO gt_fcat1300_i.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form init_search_condition
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM init_search_condition .
  "최초 1회 기간 30일 세팅
  IF gv_init_flag IS INITIAL.
    CLEAR gv_init_flag.
    gv_audat_from = sy-datum - 30.
    gv_audat_to = sy-datum.

    gv_init_flag = abap_true.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_expired_quotation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM update_expired_quotation .
  UPDATE z8sd_quotation_h SET status = '40' WHERE status = '10'
                                            AND gueen < @sy-datum.

  IF sy-subrc = 0.
    COMMIT WORK.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_email_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_QUOT_LIST
*&---------------------------------------------------------------------*

FORM set_email_html USING VALUE(p_quot_list) LIKE gw_quot_list
                    CHANGING pt_html TYPE soli_tab.

  DATA: lv_price TYPE char20,
        lv_total TYPE char20,
        lv_qty   TYPE char20.

  CLEAR pt_html.

  APPEND VALUE #(
    line = '<!DOCTYPE html><html><head>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<meta charset="UTF-8">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '</head>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<body style="margin:0;padding:0;'
        && 'background:#f1f4f8;font-family:Arial,sans-serif;">'
  ) TO pt_html.

  "전체 배경
  APPEND VALUE #(
    line = '<table width="100%" cellpadding="0" cellspacing="0"'
  ) TO pt_html.

  APPEND VALUE #(
    line = ' style="width:100%;background:#f1f4f8;border:0;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<tr><td align="center" style="padding:30px 10px;">'
  ) TO pt_html.

  "메일 컨테이너 1050px
  APPEND VALUE #(
    line = '<table width="1050" cellpadding="0" cellspacing="0"'
  ) TO pt_html.

  APPEND VALUE #(
    line = ' style="width:100%;max-width:1050px;'
        && 'background:#ffffff;border:0;">'
  ) TO pt_html.

  "2. 상단 네이비 헤더
  APPEND VALUE #(
    line = '<tr><td style="background:#183d65;padding:30px;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="color:#bcd1e6;font-size:12px;margin:0;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '태양광 설치 견적서</p>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<h1 style="color:#fff;font-size:26px;margin:12px 0;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ p_quot_list-kunnr_txt } 견적서 송부 안내</h1>|
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="color:#d8e4f2;font-size:13px;margin:0;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '고객님의 견적 요청에 대한 안내입니다.</p>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '</td></tr>'
  ) TO pt_html.

  "3. 인사말
  APPEND VALUE #(
    line = '<tr><td style="padding:30px;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="font-size:15px;color:#333;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |안녕하세요, { p_quot_list-kunnr_txt } 담당자님.</p>|
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="font-size:14px;color:#555;line-height:1.8;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '요청하신 견적 내용을 아래와 같이 안내드립니다.</p>'
  ) TO pt_html.

  "4. 견적 기본정보
  APPEND VALUE #(
    line = '<h3 style="color:#183d65;margin-top:30px;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '01. 견적 기본정보</h3>'
  ) TO pt_html.

  "테이블 시작
  APPEND VALUE #(
    line = '<table width="100%" cellspacing="0" cellpadding="0"'
  ) TO pt_html.

  APPEND VALUE #(
    line = ' style="width:100%;table-layout:fixed;'
        && 'border-collapse:collapse;font-size:13px;">'
  ) TO pt_html.

  "열 비율 30:70
  APPEND VALUE #(
    line = '<colgroup><col width="30%"><col width="70%"></colgroup>'
  ) TO pt_html.

  "견적번호
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th width="30%" style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">견적번호</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td width="70%" style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = p_quot_list-vbeln_q
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "고객명
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">고객명</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = p_quot_list-kunnr_txt
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "견적일
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">견적일</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ p_quot_list-audat DATE = ISO }|
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "유효기간
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">유효기간</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ p_quot_list-guebg DATE = ISO } ~ |
        && |{ p_quot_list-gueen DATE = ISO }|
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "기본정보 테이블 종료
  APPEND VALUE #( line = '</table>' ) TO pt_html.

  "5. 견적 요청정보
  APPEND VALUE #(
    line = '<h3 style="color:#183d65;margin-top:35px;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '02. 견적 요청정보</h3>'
  ) TO pt_html.

  "테이블 시작
  APPEND VALUE #(
    line = '<table width="100%" cellspacing="0" cellpadding="0"'
  ) TO pt_html.

  APPEND VALUE #(
    line = ' style="width:100%;table-layout:fixed;'
        && 'border-collapse:collapse;font-size:13px;">'
  ) TO pt_html.

  "기본정보와 동일한 30:70 비율
  APPEND VALUE #(
    line = '<colgroup><col width="30%"><col width="70%"></colgroup>'
  ) TO pt_html.

  "설치 주소
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th width="30%" style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">설치 주소</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td width="70%" style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = gs_quot_detail-install_address
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "설치 면적
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">설치 면적</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ gs_quot_detail-total_area } M2|
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "실사 방문일
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">실사 방문일</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ gs_quot_detail-visit_date DATE = ISO }|
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "희망 착공일
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">희망 착공일</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ gs_quot_detail-req_start_date DATE = ISO }|
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "예상 공사기간
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">예상 공사기간</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = |{ gs_quot_detail-work_days }|
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "설치 장소
  APPEND VALUE #( line = '<tr>' ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="background:#eef3f8;'
        && 'border:1px solid #ddd;padding:12px;'
        && 'text-align:center;">설치 장소</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<td style="border:1px solid #ddd;'
        && 'padding:12px;text-align:left;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = gs_quot_detail-place_type
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "요청정보 테이블 종료
  APPEND VALUE #( line = '</table>' ) TO pt_html.


  "6. 견적 품목 내역
  APPEND VALUE #(
    line = '<h3 style="color:#183d65;margin-top:35px;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '03. 견적 품목 내역</h3>'
  ) TO pt_html.

  "품목 테이블 시작
  APPEND VALUE #(
    line = '<table width="100%" cellpadding="0" cellspacing="0"'
  ) TO pt_html.

  APPEND VALUE #(
    line = ' style="width:100%;table-layout:fixed;'
        && 'border-collapse:collapse;font-size:12px;">'
  ) TO pt_html.

  "9개 컬럼 너비 설정
  APPEND VALUE #(
    line = '<colgroup>'
  ) TO pt_html.

  APPEND VALUE #( line = '<col width="12%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="18%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="13%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="12%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="7%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="8%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="6%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="16%">' ) TO pt_html.
  APPEND VALUE #( line = '<col width="8%">' ) TO pt_html.

  APPEND VALUE #(
    line = '</colgroup>'
  ) TO pt_html.

  "품목 헤더
  APPEND VALUE #(
    line = '<tr style="background:#183d65;color:#fff;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">자재</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">자재명</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">설치 장소</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">단가</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">통화</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">수량</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">단위</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">자재 총액</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<th style="padding:12px 5px;">통화</th>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '</tr>'
  ) TO pt_html.

  "7. 견적 아이템
  LOOP AT gt_quot_item INTO DATA(ls_item).

    WRITE ls_item-netpr TO lv_price CURRENCY 'KRW'.
    WRITE ls_item-netwr TO lv_total CURRENCY 'KRW'.
    WRITE ls_item-kwmeng TO lv_qty DECIMALS 0.

    CONDENSE: lv_price, lv_total, lv_qty.

    APPEND VALUE #(
      line = '<tr style="background:#fff;">'
    ) TO pt_html.


    "자재코드
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:left;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = ls_item-matnr
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "자재명
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:left;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = ls_item-arktx
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "설치 장소
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:left;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = ls_item-place_type
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "단가
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:right;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = lv_price
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "단가 통화
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:center;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = ls_item-waers1
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "수량
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:right;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = |{ lv_qty }|
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "단위
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:center;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = ls_item-vrkme
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.


    "자재 총액
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:right;'
          && 'font-weight:bold;">'
    ) TO pt_html.


    APPEND VALUE #(
      line = |{ lv_total }|
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.

    "총액 통화
    APPEND VALUE #(
      line = '<td style="border:1px solid #ddd;'
          && 'padding:10px 6px;text-align:center;">'
    ) TO pt_html.

    APPEND VALUE #(
      line = ls_item-waers1
    ) TO pt_html.

    APPEND VALUE #( line = '</td>' ) TO pt_html.

    "품목 행 종료
    APPEND VALUE #( line = '</tr>' ) TO pt_html.

  ENDLOOP.

  "품목 테이블 종료
  APPEND VALUE #( line = '</table>' ) TO pt_html.

  "8. 하단 안내 문구
  APPEND VALUE #(
    line = '<p style="margin-top:35px;font-size:14px;'
        && 'color:#555;line-height:1.8;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '견적 내용과 관련하여 문의사항이 있으시면'
  ) TO pt_html.

  APPEND VALUE #(
    line = ' 본 메일로 회신 부탁드립니다.</p>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="font-size:14px;color:#333;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '감사합니다.</p>'
  ) TO pt_html.

  "본문 셀 종료
  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "9. 하단 푸터
  APPEND VALUE #(
    line = '<tr><td style="background:#eef3f8;padding:20px;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="font-size:12px;color:#66788a;margin:0;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = 'SAP 견적 관리 시스템</p>'
  ) TO pt_html.

  APPEND VALUE #(
    line = '<p style="font-size:11px;color:#8898a8;margin:8px 0 0;">'
  ) TO pt_html.

  APPEND VALUE #(
    line = '본 메일은 견적 안내를 위해 발송되었습니다.</p>'
  ) TO pt_html.

  APPEND VALUE #( line = '</td></tr>' ) TO pt_html.

  "10. HTML 종료
  APPEND VALUE #(
    line = '</table></td></tr></table></body></html>'
  ) TO pt_html.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form send_quotation_mail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_QUOT_LIST_EMAIL
*&      --> LT_MAIL_HTML
*&      <-- LV_SENT
*&---------------------------------------------------------------------*

FORM send_quotation_mail USING    p_email     TYPE z8sd_quot_req-email
                                  pt_html     TYPE soli_tab
                         CHANGING pv_sent     TYPE abap_bool.

  DATA: lo_send_request TYPE REF TO cl_bcs,
        lo_document     TYPE REF TO cl_document_bcs,
        lo_recipient    TYPE REF TO if_recipient_bcs,
        lv_subject      TYPE so_obj_des,
        lv_result       TYPE os_boolean.

  CLEAR pv_sent.

  TRY.

      "1. 메일 발송 객체 생성
      lo_send_request = cl_bcs=>create_persistent( ).

      "2. 메일 제목
      lv_subject = '(주)인피니티솔라 - 태양광 설치 관련 견적서 송부 안내'.

      "3. HTML 메일 문서 생성
      lo_document = cl_document_bcs=>create_document(
        i_type    = 'HTM'
        i_text    = pt_html
        i_subject = lv_subject
      ).

      "PDF 첨부 로직 추가 위치
      "lo_document->add_attachment( ... ).

      "4. 발송 객체에 문서 지정
      lo_send_request->set_document( lo_document ).

      "5. 수신자 이메일 설정
      lo_recipient = cl_cam_address_bcs=>create_internet_address(
                      i_address_string = p_email
                      ).

      lo_send_request->add_recipient(
        i_recipient = lo_recipient
      ).

      "6. 발송 요청
      lv_result = lo_send_request->send(
        i_with_error_screen = abap_false
      ).

      IF lv_result = abap_true.

        COMMIT WORK AND WAIT.
        pv_sent = abap_true.

      ENDIF.

    CATCH cx_bcs INTO DATA(lx_bcs).

      MESSAGE lx_bcs->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

      pv_sent = abap_false.

  ENDTRY.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_selected_quot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ABAP_FALSE
*&      <-- LS_QUOT
*&---------------------------------------------------------------------*
FORM get_selected_quot USING p_check TYPE abap_bool
                       CHANGING p_quot TYPE z8sd_quotation_h.

  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  CLEAR p_quot.

  go_alv1300_h->get_selected_rows(
    IMPORTING
      et_index_rows = lt_rows
  ).

  IF lt_rows IS INITIAL AND p_check = abap_true.
    MESSAGE s031(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lines( lt_rows ) > 1 AND p_check = abap_true.
    MESSAGE s032(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE gt_quot_list ASSIGNING FIELD-SYMBOL(<fs_quot>) INDEX ls_row-index.

  IF sy-subrc = 0.
    MOVE-CORRESPONDING <fs_quot> TO p_quot.
  ENDIF.

ENDFORM.
