*&---------------------------------------------------------------------*
*& Include          MZ8SDSO0700F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_container
    EXPORTING
      container_name = 'CONTROL_AREA'. "서브스크린의 Custom Control 연결

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_split
    EXPORTING
      parent  = go_container
      rows    = 2
      columns = 1.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CALL METHOD go_split->get_container
    EXPORTING
      row       = 1
      column    = 1
    RECEIVING
      container = go_container_h.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CALL METHOD go_split->get_container
    EXPORTING
      row       = 2
      column    = 1
    RECEIVING
      container = go_container_i.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_alv_h
    EXPORTING
      i_parent = go_container_h.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.

  CREATE OBJECT go_alv_i
    EXPORTING
      i_parent = go_container_i.

  IF sy-subrc <> 0.
    MESSAGE a012(z8_msg).
  ENDIF.
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
  CALL METHOD go_alv_h->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8SD_SO_H'
      is_layout                     = gs_layout_h
    CHANGING
      it_outtab                     = gt_so_h
      it_fieldcatalog               = gt_fcat_h
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE e012(z8_msg).
  ENDIF.

  CALL METHOD go_alv_i->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'Z8SD_SO_I'
      is_layout                     = gs_layout_i
    CHANGING
      it_outtab                     = gt_so_i
      it_fieldcatalog               = gt_fcat_i
      it_sort                       = gt_sort_i
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE e012(z8_msg).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form refresh_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv .
  CALL METHOD go_alv_h->refresh_table_display
    EXPORTING
      is_stable = gs_stable_h.


*  CALL METHOD go_alv_h->set_frontend_layout
*    EXPORTING
*      is_layout = gs_layout_h.

  CALL METHOD go_alv_i->refresh_table_display
    EXPORTING
      is_stable = gs_stable_i.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_fcat1300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat .
  CLEAR: gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'STATUS_S'.
  gw_fcat_h-col_pos = 1.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VKORG'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'SO_TXT'.
  gw_fcat_h-coltext = '판매조직'.
  gw_fcat_h-col_pos = 9.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'DC_TXT'.
  gw_fcat_h-coltext = '유통채널'.
  gw_fcat_h-col_pos = 10.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'KUNNR'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VTWEG'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'STATUS_P'.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'BUPLA'.
  gw_fcat_h-coltext = '지사'.
  gw_fcat_h-col_pos = 11.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'WERKS'.
  gw_fcat_h-coltext = '플랜트'.
  gw_fcat_h-col_pos = 13.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'STATUS_TXT'.
  gw_fcat_h-coltext = 'SO 진행상태'.
  gw_fcat_h-col_pos = 1.
  gw_fcat_h-no_out = 'X'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'PROJECT_STATUS_TXT'.
  gw_fcat_h-coltext = '진행 상태'.
  gw_fcat_h-col_pos = 2.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VBELN_S'.
  gw_fcat_h-coltext = 'SO 번호'.
  gw_fcat_h-col_pos = 3.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VBELN_Q'.
  gw_fcat_h-coltext = '견적 번호'.
  gw_fcat_h-col_pos = 3.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'PRO_ID'.
  gw_fcat_h-coltext = '프로젝트'.
  gw_fcat_h-col_pos = 4.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'NAME1'.
  gw_fcat_h-col_pos = 5.
  gw_fcat_h-outputlen = 15.
  gw_fcat_h-coltext = '고객명'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'BRANCH_TXT'.
  gw_fcat_h-coltext = '지사명'.
  gw_fcat_h-col_pos = 6.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'PLANT_TXT'.
  gw_fcat_h-coltext = '플랜트명'.
  gw_fcat_h-col_pos = 7.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'AUDAT'.
  gw_fcat_h-col_pos = 8.
  gw_fcat_h-just = 'C'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'VDATU'.
  gw_fcat_h-coltext = '희망착공일'.
  gw_fcat_h-col_pos = 9.
  gw_fcat_h-just = 'C'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'SDATE'.
  gw_fcat_h-coltext = '공사시작일'.
  gw_fcat_h-col_pos = 10.
  gw_fcat_h-just = 'C'.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'NETWR'.
  gw_fcat_h-coltext = '총 금액'.
  gw_fcat_h-col_pos = 11.
  gw_fcat_h-outputlen = 13.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'WAERK'.
  gw_fcat_h-coltext = '통화'.
  gw_fcat_h-col_pos = 12.
  APPEND gw_fcat_h TO gt_fcat_h.

  CLEAR gw_fcat_h.
  gw_fcat_h-fieldname = 'BTN_TXT'.
  gw_fcat_h-coltext = '인력 현황'.
  gw_fcat_h-col_pos = 13.
  gw_fcat_h-outputlen = 7.
  gw_fcat_h-just = 'C'.
  APPEND gw_fcat_h TO gt_fcat_h.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fcat1300_i
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat_i .
  CLEAR: gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VERPR'.
  gw_fcat_i-no_out = 'X'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VBELN_S'.
  gw_fcat_i-coltext = 'SO 번호'.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'POSNR'.
  gw_fcat_i-coltext = '품목'.
  gw_fcat_i-outputlen = 5.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'MATNR'.
  gw_fcat_i-coltext = '자재'.
  gw_fcat_i-outputlen = 15.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'ARKTX'.
  gw_fcat_i-coltext = '자재명'.
  gw_fcat_i-outputlen = 15.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'PLACE_TYPE'.
  gw_fcat_i-coltext = '설치 장소'.
  gw_fcat_i-outputlen = 15.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'NETPR'.
  gw_fcat_i-coltext = '단가'.
  gw_fcat_i-col_pos = 7.
  gw_fcat_i-outputlen = 13.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'WAERS'.
  gw_fcat_i-coltext = '통화'.
  gw_fcat_i-col_pos = 8.
  gw_fcat_i-outputlen = 10.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'KWMENG'.
  gw_fcat_i-coltext = '수량'.
  gw_fcat_i-outputlen = 5.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'VRKME'.
  gw_fcat_i-coltext = '단위'.
  gw_fcat_i-outputlen = 6.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'NETWR'.
  gw_fcat_i-coltext = '자재 총액'.
  gw_fcat_i-col_pos = 12.
  gw_fcat_i-outputlen = 13.
  APPEND gw_fcat_i TO gt_fcat_i.

  CLEAR gw_fcat_i.
  gw_fcat_i-fieldname = 'WAERS1'.
  gw_fcat_i-coltext = '통화'.
  gw_fcat_i-col_pos = 13.
  gw_fcat_i-outputlen = 10.
  APPEND gw_fcat_i TO gt_fcat_i.


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
  CLEAR gs_layout_h.

  gs_layout_h-zebra = 'X'.
  gs_layout_h-sel_mode = 'B'.
  gs_layout_h-stylefname = 'CT'. "ALV가 CT 필드 안에 셀별 스타일 정보가 있구나 하고 읽을 수 있음
  gs_layout_h-no_toolbar = 'X'.

  gs_layout_i-zebra = 'X'.
  gs_layout_i-no_toolbar = 'X'.

*  gs_layout_i-cwidth_opt = 'X'.

  CLEAR gs_sort_i.
  gs_sort_i-spos      = 1.
  gs_sort_i-fieldname = 'VBELN_S'.  " SO 번호
  APPEND gs_sort_i TO gt_sort_i.
*
  CLEAR gs_sort_i.
  gs_sort_i-spos      = 2.
  gs_sort_i-fieldname = 'POSNR'.    " 품목 번호
  gs_sort_i-up        = 'X'.
  APPEND gs_sort_i TO gt_sort_i.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_INIT_FLAG
*&---------------------------------------------------------------------*
FORM get_data.
  DATA: ls_ct    TYPE lvc_s_styl,
        lv_index TYPE lvc_s_row-index.

  DATA: lv_vbeln_s TYPE string.

  CLEAR:gt_so_h,
        gt_so_i,
        gw_so_h,
        gw_so_i,
        lv_index,
        lv_vbeln_s.

  IF gv_search_so IS NOT INITIAL.
    lv_vbeln_s = |%{ gv_search_so }%|.
  ENDIF.

  SELECT h~*,
         b~name AS branch_txt,
         p~name1 AS plant_txt,
         s~vtext AS so_txt,
         d~vtext AS dc_txt,
         pr~sdate,
         pr~pro_id,
         pr~status_p,
         so~status_s,
         so~vbeln_s,
         so~ernam_so, "SO 생성자 이름
         c~name1,
         r~req_start_date,
         h~work_days
    FROM z8sd_quotation_h AS h LEFT JOIN z8branch_m       AS b    ON h~bupla = b~branch
                              INNER JOIN z8sd_quot_req    AS r    ON r~request_id = h~request_id
                               LEFT JOIN z8plant_m        AS p    ON h~werks = p~werks
                               LEFT JOIN z8sales_org_m    AS s    ON h~vkorg = s~vkorg
                               LEFT JOIN z8dc_m           AS d    ON h~vtweg = d~vtweg
                               INNER JOIN z8sd_billing_h AS bill ON h~vbeln_q = bill~vgbel
                                                         AND bill~fkart = 'F1'
                                                         AND zzpayst = '02'
                               LEFT JOIN z8sd_so_h       AS so ON so~vbeln_q = h~vbeln_q
                               LEFT JOIN z8ps_project    AS pr ON so~vbeln_s = pr~vbeln
                               LEFT JOIN z8customer_m AS c ON c~kunnr = h~kunnr
    WHERE ( ( @gv_audat_to IS INITIAL AND h~audat = @gv_audat_from )
          OR ( @gv_audat_to IS NOT INITIAL AND h~audat BETWEEN @gv_audat_from AND @gv_audat_to ) )
      AND ( @gv_customer IS INITIAL OR h~kunnr = @gv_customer )
      AND ( h~status = '20' ) "견적서의 상태가 승인완료인 건
      AND ( @gv_status IS INITIAL OR pr~status_p = @gv_status )
      AND ( @gv_search_so IS INITIAL OR so~vbeln_s LIKE @lv_vbeln_s )
      AND ( @gv_bupla IS INITIAL OR b~branch = @gv_bupla )
    INTO CORRESPONDING FIELDS OF TABLE @gt_so_h.

  IF sy-subrc <> 0.
    MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
    PERFORM refresh_alv.
    RETURN.
  ENDIF.

  LOOP AT gt_so_h ASSIGNING FIELD-SYMBOL(<fs_so_h>).
    IF <fs_so_h>-status_s IS NOT INITIAL.
      CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
        EXPORTING
          iv_domname    = 'Z8D_SO_STATUS'
          iv_value      = <fs_so_h>-status_s
        IMPORTING
          ev_value_text = <fs_so_h>-status_txt.

      CALL FUNCTION 'STF4_GET_DOMAIN_VALUE_TEXT'
        EXPORTING
          iv_domname    = 'Z8D_PROJ_STATUS'
          iv_value      = <fs_so_h>-status_p
        IMPORTING
          ev_value_text = <fs_so_h>-project_status_txt.
    ENDIF.

    IF <fs_so_h>-status_s = '30'.
      CLEAR ls_ct.
      ls_ct-fieldname = 'BTN_TXT'.
*      ls_ct-style = cl_gui_alv_grid=>mc_style_button.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.
      INSERT ls_ct INTO TABLE <fs_so_h>-ct.

      <fs_so_h>-btn_txt = TEXT-001.
    ENDIF.
  ENDLOOP.

  SORT gt_so_h BY req_start_date ASCENDING
                  sdate          ASCENDING.


  "이전에 선택한 견적번호가 있으면 해당 행 찾기
  IF gv_selected_vbeln_q IS NOT INITIAL.

    READ TABLE gt_so_h INTO gw_so_h WITH KEY vbeln_q = gv_selected_vbeln_q.

    IF sy-subrc = 0.
      lv_index = sy-tabix.
    ENDIF.

  ENDIF.

  IF lv_index = 0.

    READ TABLE gt_so_h INTO gw_so_h INDEX 1.

    IF sy-subrc = 0.
      lv_index = 1.
    ENDIF.

  ENDIF.

  gv_selected_vbeln_q = gw_so_h-vbeln_q.

  PERFORM get_data_item
    USING gw_so_h-vbeln_q
          gw_so_h-werks
          gw_so_h-vbeln_s.

  PERFORM refresh_alv.

  PERFORM set_selected_line USING lv_index.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_so.
  DATA: lv_answer      TYPE char1,
        lv_number      TYPE n LENGTH 9,
        lv_pro_number  TYPE n LENGTH 8,
        ls_so_h_db     TYPE z8sd_so_h,
        ls_so_i_db     TYPE z8sd_so_i,
        lt_so_i_db     TYPE TABLE OF z8sd_so_i,
        ls_project     TYPE z8ps_project,
        lv_capacity_kw TYPE z8ps_project-capacity_kwp,
        lv_ess_yn      TYPE z8ps_project-ess_yn,
        lv_line_val    TYPE abap_bool,
        lv_index       TYPE lvc_s_row-index.

  CLEAR: lv_number,
         lv_pro_number,
         lv_answer,
         gw_so_h,
         gw_so_i,
         ls_so_h_db,
         lt_so_i_db,
         ls_project,
         lv_capacity_kw,
         lv_ess_yn,
         lv_line_val.

  PERFORM get_selected_line CHANGING lv_line_val.

  IF lv_line_val = abap_false.
    RETURN.
  ENDIF.

  IF gw_so_h-vbeln_s IS INITIAL.   "SO가 없는 경우에만 생성 가능
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '판매오더 생성'
        text_question         = '판매오더를 생성하시겠습니까?'
        text_button_1         = '예'
        text_button_2         = '아니오'
        default_button        = '1'
        display_cancel_button = space
      IMPORTING
        answer                = lv_answer.

    IF lv_answer = 1.
    ELSE.
      MESSAGE s030(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    PERFORM get_so_number CHANGING lv_number.

    gw_so_h-vbeln_s = |S{ lv_number }|.
    gw_so_h-status_s = '10'.
    gw_so_h-ernam_so = sy-uname.

    LOOP AT gt_so_i ASSIGNING FIELD-SYMBOL(<fs_so_i>) WHERE vbeln_q = gw_so_h-vbeln_q.
      CLEAR ls_so_i_db.
      <fs_so_i>-vbeln_s = gw_so_h-vbeln_s.
      <fs_so_i>-waers = gw_so_h-waerk.

      IF <fs_so_i>-matnr CP 'PANEL*'.

        lv_capacity_kw = lv_capacity_kw
                                    + ( <fs_so_i>-kwmeng
                                    * <fs_so_i>-zzrtkpz
                                    / 1000 ).
      ENDIF.

      IF <fs_so_i>-matnr CP 'ESS*'.
        lv_ess_yn = abap_true.
      ENDIF.
      MOVE-CORRESPONDING <fs_so_i> TO ls_so_i_db.
      APPEND ls_so_i_db TO lt_so_i_db.
    ENDLOOP.

    SELECT SINGLE * INTO CORRESPONDING FIELDS OF ls_project
        FROM z8sd_quot_req AS req INNER JOIN z8sd_quotation_h AS h
                                          ON req~request_id = h~request_id
        WHERE h~vbeln_q = gw_so_h-vbeln_q.

    IF sy-subrc = 0.

      PERFORM get_pro_number CHANGING lv_pro_number.
      ls_project-pro_id = |PJ{ lv_pro_number }|.
      ls_project-vbeln = gw_so_h-vbeln_s.
      ls_project-branch = gw_so_h-bupla.
      ls_project-status_p = '10'.
      ls_project-capacity_kwp = lv_capacity_kw.
      ls_project-ess_yn = lv_ess_yn.
      ls_project-erdat = sy-datum.
      ls_project-ernam = sy-uname.

      MOVE-CORRESPONDING ls_project TO gw_proj_hist.
      gw_proj_hist-changed_by = sy-uname.
      gw_proj_hist-changed_date = sy-datum.
    ELSE.
      MESSAGE s060(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    MOVE-CORRESPONDING gw_so_h TO ls_so_h_db.

**************************************DB 저장********************************************************


    INSERT z8sd_so_h FROM ls_so_h_db.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s208(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    INSERT z8sd_so_i FROM TABLE lt_so_i_db.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s209(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    INSERT z8ps_project FROM ls_project.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s210(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    INSERT z8ps_proj_hist FROM gw_proj_hist.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s211(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    COMMIT WORK.

    IF sy-subrc = 0.
      MESSAGE '판매오더를 생성했습니다' TYPE 'I'.

      PERFORM get_data.
    ENDIF.

  ELSE. "생성된 SO가 있는 경우
    MESSAGE s059(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.




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
  SET HANDLER lcl_handler=>on_button_click FOR go_alv_h.
  SET HANDLER lcl_handler=>on_double_click FOR go_alv_h.
  SET HANDLER lcl_handler=>on_hotspot_click FOR go_alv_h.
  SET HANDLER lcl_handler=>on_row_select FOR go_alv_h.

  CALL METHOD go_alv_h->register_delayed_event
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_delayed_change_select.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_SO_H_VBELN_S
*&---------------------------------------------------------------------*
FORM get_data_item  USING VALUE(p_vbeln_q)
                          VALUE(p_werks)   LIKE gw_so_h-werks
                          VALUE(p_vbeln_s) LIKE gw_so_h-vbeln_s.


  SELECT q~*,
         p~netpr,
         p~waers AS waers1,
         m~zzrtkpz,
         v~verpr,
         i~vbeln_s
    FROM z8sd_quotation_i AS q LEFT JOIN z8material_m     AS m ON m~matnr = q~matnr
                               LEFT JOIN z8sd_so_i        AS i ON i~vbeln_s = @p_vbeln_s
                                                              AND i~posnr = q~posnr
                               LEFT JOIN z8sd_price_m AS p ON q~matnr = p~matnr
                               LEFT JOIN z8MATERIAL_val_m AS v ON v~matnr = q~matnr
                                     AND v~bwkey = @gw_so_h-werks
   WHERE vbeln_q = @p_vbeln_q
   ORDER BY i~posnr ASCENDING
   INTO CORRESPONDING FIELDS OF TABLE @gt_so_i.

  IF sy-subrc <> 0.
    MESSAGE s071(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_so_number
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_NUMBER
*&---------------------------------------------------------------------*
FORM get_so_number  CHANGING lv_number.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8SD_SO'
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
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_pro_number
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_PRO_NUMBER
*&---------------------------------------------------------------------*
FORM get_pro_number  CHANGING p_number.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8PS_PROJE'
    IMPORTING
      number                  = p_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_selected_line
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_ROWS
*&---------------------------------------------------------------------*
FORM get_selected_line CHANGING p_line_val.
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  CLEAR: lt_rows, ls_row, gw_so_h.

  p_line_val = abap_true.

  go_alv_h->get_selected_rows(
    IMPORTING
      et_index_rows = lt_rows
  ).
  IF ok_code = 'REFR'.
  ELSE.
    IF gv_sel_line_flag = abap_true.
      IF lines( lt_rows ) > 1.
        MESSAGE s058(z8_msg) DISPLAY LIKE 'E'.
        p_line_val = abap_false.
        RETURN.

      ELSEIF lt_rows IS INITIAL.
        MESSAGE s057(z8_msg) DISPLAY LIKE 'E'.
        p_line_val = abap_false.
        RETURN.
      ENDIF.
    ENDIF.
  ENDIF.


  READ TABLE lt_rows INTO ls_row INDEX 1.

  IF sy-subrc = 0.

    READ TABLE gt_so_h INTO gw_so_h INDEX ls_row-index.

    IF sy-subrc = 0.
      "현재 선택한 행 기억
      gv_selected_vbeln_q = gw_so_h-vbeln_q.

      PERFORM get_data_item USING gw_so_h-vbeln_q
                                  gw_so_h-werks
                                  gw_so_h-vbeln_s.

    ELSE.
      MESSAGE s232(z8_msg) DISPLAY LIKE 'E'. "선택한 행을 읽어오지 못했습니다

      p_line_val = abap_false.
      RETURN.
    ENDIF.

  ENDIF.
*  READ TABLE lt_rows INTO ls_row INDEX 1.
*
*  IF sy-subrc = 0.
*    READ TABLE gt_so_h INTO gw_so_h INDEX ls_row-index. "선택 된 라인 데이터 읽어오기
*    gv_selected_vbeln_q = gw_so_h-vbeln_q.
*
*    IF sy-subrc = 0.
*      PERFORM get_data_item
*        USING gw_so_h-vbeln_q
*              gw_so_h-werks
*              gw_so_h-vbeln_s.
*
*    ELSE.
*      MESSAGE '선택한 행을 읽어오지 못했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
*      p_line_val = abap_false.
*      RETURN.
*    ENDIF.
*  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_sdate
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_sdate .
  DATA: lv_line_val TYPE abap_bool,
        lv_answer   TYPE abap_bool,
        lv_index    TYPE lvc_s_row-index.

  CLEAR: lv_line_val, lv_answer.

  PERFORM get_selected_line CHANGING lv_line_val.

  IF lv_line_val = abap_false.
    RETURN.
  ENDIF.

  CASE gw_so_h-status_s.
    WHEN space.
      MESSAGE s233(z8_msg) DISPLAY LIKE 'E'. "SO를 먼저 생성해주세요
      RETURN.
    WHEN '10'. "일정 미수립인 경우 설치 일정 수립 팝업
      CALL SCREEN 1010 STARTING AT 55 5.
    WHEN '20'.
      CALL SCREEN 1010 STARTING AT 55 5.
    WHEN '30'.
      MESSAGE s234(z8_msg) DISPLAY LIKE 'E'. "인력배정이 완료된 건은 설치일정을 변경할 수 없습니다
      RETURN.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_date
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_date .
  DATA: ls_proj_hist TYPE z8ps_proj_hist,
        lv_index     TYPE lvc_s_row-index.
  CLEAR ls_proj_hist.

  gw_date-edate = gw_date-sdate + gw_so_h-work_days.

  UPDATE z8ps_project SET sdate = gw_date-sdate
                          edate = gw_date-edate
                          status_p = '20'
                    WHERE pro_id = gw_so_h-pro_id.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s060(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT SINGLE pro_id,
                sdate,
                edate
    INTO CORRESPONDING FIELDS OF @ls_proj_hist
    FROM z8ps_project
    WHERE pro_id = @gw_so_h-pro_id.

  IF sy-subrc <> 0.
    MESSAGE s213(z8_msg) DISPLAY LIKE 'E'. "프로젝트 조회에 실패했습니다
  ENDIF.

  SELECT MAX( seq_no )
   INTO @DATA(lv_seq)
   FROM z8ps_proj_hist
   WHERE pro_id = @gw_so_h-pro_id.

  lv_seq = lv_seq + 1.

  ls_proj_hist-seq_no = lv_seq.
  ls_proj_hist-status_p = '20'.
  ls_proj_hist-changed_by = sy-uname.
  ls_proj_hist-changed_date = sy-datum.

  INSERT z8ps_proj_hist FROM ls_proj_hist.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s060(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  UPDATE z8sd_so_h SET status_s = '20' WHERE vbeln_s = gw_so_h-vbeln_s.

  COMMIT WORK.

  MESSAGE '설치 일정을 확정했습니다.' TYPE 'I'.

  PERFORM get_data.

  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_selected_line
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_1
*&---------------------------------------------------------------------*

FORM set_selected_line USING VALUE(p_index).
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  ls_row-index = p_index.
  APPEND ls_row TO lt_rows.

  CALL METHOD go_alv_h->set_selected_rows
    EXPORTING
      it_index_rows = lt_rows.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form open_fiori_project
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_SO_H_VBELN_S
*&---------------------------------------------------------------------*
FORM open_fiori_project  USING VALUE(p_pro_id).
  DATA lv_url TYPE string.

  lv_url = |http://bgissap2.bgissap.co.kr:8000/sap/bc/ui5_ui5/sap/z8psf0100/index.html?sap-client=100#/Project('{ p_pro_id }')|.

  cl_gui_frontend_services=>execute(
  EXPORTING
    document = lv_url
  EXCEPTIONS
    OTHERS   = 1
).

  IF sy-subrc <> 0.
    MESSAGE s085(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form alloc_validate
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_VAL
*&---------------------------------------------------------------------*
FORM alloc_validate  CHANGING p_lv_val.

  CASE gw_so_h-status_s.

    WHEN space.

      MESSAGE s233(z8_msg) DISPLAY LIKE 'E'. "SO를 먼저 생성해주세요

      p_lv_val = abap_false.

      RETURN.

    WHEN '10'.

      MESSAGE s086(z8_msg) DISPLAY LIKE 'E'. "일정을 먼저 수립해주세요

      p_lv_val = abap_false.

      RETURN.

    WHEN '20'. "인력 배정 Fiori 화면으로 이동 (상태가 20인 건에 대해서만 인력 배정 가능)

    WHEN '30'.

      MESSAGE s087(z8_msg) DISPLAY LIKE 'E'. "이미 인력 배정이 완료되었습니다

      p_lv_val = abap_false.

      RETURN.

  ENDCASE.

ENDFORM.
