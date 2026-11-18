*&---------------------------------------------------------------------*
*& Include          Z8FIRP0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_objects_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_100 .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_100
    EXPORTING
      container_name              = 'CONTROL_AREA_100'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_100
    EXPORTING
      i_parent          = go_cont_100 "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_100 .

  gs_layout_100-zebra = 'X'.
  gs_layout_100-sel_mode = 'B'.

  "신호등
  gs_layout_100-excp_fname = 'LIGHT'.
  gs_layout_100-excp_led   = 'X'.

*  "정렬
*  CLEAR gs_sort_100.
*  gs_sort_100-fieldname = 'KUNNR'.
*  gs_sort_100-spos = 1.
*  gs_sort_100-up = 'X'.
*  APPEND gs_sort_100 TO gt_sort_100.

*  gs_layout_100-no_merging = 'X'.

  PERFORM set_grid_title_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_100 .

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'LIGHT'.
  gs_fcat_100-coltext = '상태'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'STATT'.
  gs_fcat_100-coltext = '채권상태'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'KUNNR'.
  gs_fcat_100-coltext = '고객번호'.
  gs_fcat_100-hotspot = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'CNAME'.
  gs_fcat_100-coltext = '고객명'.
  gs_fcat_100-col_opt = 'X'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BUPLA'.
  gs_fcat_100-coltext = '지사'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BNAME'.
  gs_fcat_100-coltext = '지사명'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'TOT_AMT'.
  gs_fcat_100-coltext = '채권발생액'.
  gs_fcat_100-ref_field = 'TOT_AMT'.
  gs_fcat_100-cfieldname = 'WAERS'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-do_sum = 'X'.
  gs_fcat_100-outputlen = 16.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'COL_AMT'.
  gs_fcat_100-coltext = '회수액'.
  gs_fcat_100-ref_field = 'COL_AMT'.
  gs_fcat_100-cfieldname = 'WAERS'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-do_sum = 'X'.
  gs_fcat_100-outputlen = 16.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'BAL_AMT'.
  gs_fcat_100-coltext = '현재 채권잔액'.
  gs_fcat_100-ref_field = 'BAL_AMT'.
  gs_fcat_100-cfieldname = 'WAERS'.
  gs_fcat_100-emphasize = 'C311'.
  gs_fcat_100-do_sum = 'X'.
  gs_fcat_100-outputlen = 16.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'WAERS'.
  gs_fcat_100-coltext = '통화'.
  gs_fcat_100-emphasize = 'C311'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'TOT_CNT'.
  gs_fcat_100-coltext = '발생건수'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'COL_CNT'.
  gs_fcat_100-coltext = '반제완료건수'.
  APPEND gs_fcat_100 TO gt_fcat_100.

  CLEAR gs_fcat_100.
  gs_fcat_100-fieldname = 'OPEN_CNT'.
  gs_fcat_100-coltext = '미결건수'.
  APPEND gs_fcat_100 TO gt_fcat_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_100 .

  CALL METHOD go_alv_100->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_100
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_ar_100
      it_fieldcatalog               = gt_fcat_100
      it_sort                       = gt_sort_100
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_ar_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_ar_data .

  CLEAR gt_ar_200.

  SELECT *
    FROM z8fi_c_aritem
    WHERE companycode = @gc_bukrs
    AND branch IN @s_cbupla
    AND receivabledate IN @s_cbudat
    AND customer IN @s_kunnr
    INTO TABLE @gt_ar_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_ar_sum
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_ar_sum .

  DATA lv_tabix TYPE sy-tabix.

  CLEAR gt_ar_100.

  LOOP AT gt_ar_detail INTO gs_ar_detail.

    CLEAR gs_ar_100.

    READ TABLE gt_ar_100 INTO gs_ar_100
    WITH KEY bukrs = gs_ar_detail-companycode
                     bupla = gs_ar_detail-branch
                     kunnr = gs_ar_detail-customer
                     waers = gs_ar_detail-currency.

    IF sy-subrc = 0.

      lv_tabix = sy-tabix.

      "총 채권 발생액
      gs_ar_100-tot_amt = gs_ar_100-tot_amt + gs_ar_detail-receivableamount.

      "발생건수
      gs_ar_100-tot_cnt = gs_ar_100-tot_cnt + 1.

      "반제 안된거
      IF gs_ar_detail-collectiondocument IS INITIAL.
        gs_ar_100-bal_amt = gs_ar_100-bal_amt + gs_ar_detail-receivableamount.
        gs_ar_100-open_cnt = gs_ar_100-open_cnt + 1.
      ELSE. "반제된거
        gs_ar_100-col_amt = gs_ar_100-col_amt + gs_ar_detail-receivableamount.
        gs_ar_100-col_cnt = gs_ar_100-col_cnt + 1.
      ENDIF.

      MODIFY gt_ar_100 FROM gs_ar_100 INDEX lv_tabix.

    ELSE.
      "고객+지사 1건만 존재
      CLEAR gs_ar_100.

      gs_ar_100-bukrs = gs_ar_detail-companycode.
      gs_ar_100-bupla = gs_ar_detail-branch.
      gs_ar_100-bname = gs_ar_detail-branchname.
      gs_ar_100-kunnr = gs_ar_detail-customer.
      gs_ar_100-cname = gs_ar_detail-customername.
      gs_ar_100-waers = gs_ar_detail-currency.

      "채권발생
      gs_ar_100-tot_amt = gs_ar_detail-receivableamount.
      gs_ar_100-tot_cnt = 1.

      IF gs_ar_detail-collectiondocument IS INITIAL. "반제 x
        gs_ar_100-bal_amt = gs_ar_detail-receivableamount.
        gs_ar_100-open_cnt = 1.
      ELSE.
        "반제 된거
        gs_ar_100-col_amt = gs_ar_detail-receivableamount.
        gs_ar_100-col_cnt = 1.
      ENDIF.

      APPEND gs_ar_100 TO gt_ar_100.

    ENDIF.

  ENDLOOP.

  SORT gt_ar_100 BY light ASCENDING
                                 bal_amt DESCENDING
                                 open_cnt DESCENDING
                                 kunnr ASCENDING
                                 bupla ASCENDING.

  "신호등
  LOOP AT gt_ar_100 INTO gs_ar_100.

    IF gs_ar_100-bal_amt = 0.
      "전체회수
      gs_ar_100-light = '3'.
      gs_ar_100-statt = '반제완료'.
    ELSE. "IF gs_ar_100-col_amt > 0.
      "일부 회수
      gs_ar_100-light = '2'.
      gs_ar_100-statt = '미결'.
*    ELSE.
*      "회수된 채권 x
*      gs_ar_100-light = '2'.
*      gs_ar_100-statt = '미회수'.
    ENDIF.

    MODIFY gt_ar_100 FROM gs_ar_100 INDEX sy-tabix.
  ENDLOOP.

  "상태 조건
  IF rb_arop = 'X'.
    DELETE gt_ar_100
    WHERE bal_amt = 0.
  ELSEIF rb_arcl = 'X'.
    DELETE gt_ar_100
    WHERE bal_amt <> 0.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_100 .

*  CLEAR :
*  gv_tot_cnt,
*  gv_op_cnt,
*  gv_cl_cnt.
*
*  LOOP AT gt_ar_100 INTO gs_ar_100.
*
*    gv_tot_cnt = gv_tot_cnt + 1.
*
*    IF gs_ar_100-bal_amt = 0.
*      gv_cl_cnt = gv_cl_cnt + 1.
*    ELSE.
*      gv_dp_cnt = gv_dp_cnt + 1.
*    ENDIF.
*
*  ENDLOOP.

  "alv 그리드 제목
  DATA lv_count TYPE i.

  DESCRIBE TABLE gt_ar_100 LINES lv_count.

  IF rb_arall = 'X'.
    gs_layout_100-grid_title = |전체 ({ lv_count }건)|.
  ELSEIF rb_arop = 'X'.
    gs_layout_100-grid_title = |미결 ({ lv_count }건)|.
  ELSEIF rb_arcl = 'X'.
    gs_layout_100-grid_title = |반제 완료 ({ lv_count }건)|.
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
FORM set_evt_handler_100.

  SET HANDLER:
                lcl_handler=>on_hotspot_ar FOR go_alv_100.
*               lcl_handler=>on_double_click FOR go_alv_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_ar_detail_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_ar_detail_200 .

  DATA:
    lt_ar_detail TYPE STANDARD TABLE OF z8fi_c_aritem,
    ls_ar_detail TYPE z8fi_c_aritem,
    lr_bupla     TYPE RANGE OF z8fi_c_aritem-branch,
    ls_bupla     LIKE LINE OF lr_bupla.

  CLEAR: lr_bupla, ls_bupla.

  IF gv_ar_all_branch = 'X'.
    "전체 지사 조회
    lr_bupla[] = s_cbupla[].
  ELSE.
    "선택한 지사만 조회
    ls_bupla-sign = 'I'.
    ls_bupla-option = 'EQ'.
    ls_bupla-low = gs_ar_sel-bupla.
    APPEND ls_bupla TO lr_bupla.

  ENDIF.

  CLEAR: gt_ar_200, gs_ar_200, gs_ar_sp, gv_tot_amt, gv_col_amt, gv_bal_amt.

  "지사 상관 없이 고객의 전체 채권 조회
  SELECT *
    FROM z8fi_c_aritem
    WHERE companycode = @gs_ar_sel-bukrs
    AND customer = @gs_ar_sel-kunnr
    AND currency = @gs_ar_sel-waers
    AND branch IN @lr_bupla
    AND receivabledate IN @s_cbudat
    INTO TABLE @lt_ar_detail.

  IF sy-subrc <> 0.
    CLEAR lt_ar_detail.
    RETURN.
  ENDIF.

  "1000번 지급상태 조건 유지
  IF rb_arop = 'X'.
    DELETE lt_ar_detail WHERE collectiondocument IS NOT INITIAL.
    IF lt_ar_detail IS INITIAL.
       RETURN.
    ENDIF.
  ELSEIF rb_arcl = 'X'.
    DELETE lt_ar_detail WHERE collectiondocument IS INITIAL.
    IF lt_ar_detail IS INITIAL.
       RETURN.
    ENDIF.
  ENDIF.

  SELECT SINGLE stcd2, telf1, ort01, stras
    FROM z8customer_m
    WHERE kunnr = @gs_ar_sel-kunnr
    INTO CORRESPONDING FIELDS OF @gs_ar_sp.

  CONCATENATE gs_ar_sp-ort01 gs_ar_sp-stras INTO gs_ar_sp-gv_add SEPARATED BY space.

  "스크린 페인터
  gs_ar_sp-bukrs = gs_ar_sel-bukrs.
  gs_ar_sp-kunnr = gs_ar_sel-kunnr.
  gs_ar_sp-cname = gs_ar_sel-cname.
  gs_ar_sp-waers = gs_ar_sel-waers.

  IF gv_ar_all_branch IS INITIAL.
    gs_ar_sp-bupla = gs_ar_sel-bupla.
    CLEAR ls_ar_detail.

    READ TABLE lt_ar_detail INTO ls_ar_detail INDEX 1.
    IF sy-subrc = 0.
      gs_ar_sp-buplat = ls_ar_detail-branchname.
    ELSE.
      CLEAR gs_ap_sp-buplat.
    ENDIF.
  ELSE.
    CLEAR gs_ar_sp-bupla.
    gs_ar_sp-buplat = '전체 지사'.
  ENDIF.

  "상세 내역 + 전체 채권
  LOOP AT lt_ar_detail INTO ls_ar_detail.

    CLEAR gs_ar_200.

    gs_ar_200-bukrs = ls_ar_detail-companycode.
    " 지사
    gs_ar_200-bupla = ls_ar_detail-branch.
    gs_ar_200-bname = ls_ar_detail-branchname.

    " 프로젝트
    gs_ar_200-pro_id = ls_ar_detail-projectid.


    " 채권 발생전표
    gs_ar_200-belnr = ls_ar_detail-accountingdocument.
    gs_ar_200-gjahr = ls_ar_detail-fiscalyear.


    " 채권 발생정보
    gs_ar_200-budat  = ls_ar_detail-receivabledate.
    gs_ar_200-ar_amt = ls_ar_detail-receivableamount.


*    " 잔금 청구정보
*    gs_ar_200-bill_no   = ls_ar_detail-billingdocument.
*    gs_ar_200-bill_date = ls_ar_detail-billingdate.
*    gs_ar_200-due_date  = ls_ar_detail-duedate.


    " 회수정보
    gs_ar_200-augdt = ls_ar_detail-collectiondate.
    gs_ar_200-augbl = ls_ar_detail-collectiondocument.
    gs_ar_200-auggj = ls_ar_detail-collectionfiscalyear.

    gs_ar_200-waers = ls_ar_detail-currency.


    "--------------------------------------------------------*
    " 전체 채권 발생액 / 발생건수
    "--------------------------------------------------------*
    gs_ar_sp-tot_amt = gs_ar_sp-tot_amt + ls_ar_detail-receivableamount.

    gs_ar_sp-tot_cnt = gs_ar_sp-tot_cnt + 1.


    "--------------------------------------------------------*
    " 회수 여부
    "--------------------------------------------------------*
    IF ls_ar_detail-collectiondocument IS INITIAL.

      " 회수 미완료
      gs_ar_200-light = '2'.
      gs_ar_200-statt = '미결'.

      gs_ar_200-col_amt = 0.
      gs_ar_200-bal_amt = ls_ar_detail-receivableamount.

      gs_ar_sp-bal_amt =
        gs_ar_sp-bal_amt + ls_ar_detail-receivableamount.

      gs_ar_sp-open_cnt =
       gs_ar_sp-open_cnt + 1.

    ELSE.

      " 회수 완료
      gs_ar_200-light = '3'.
      gs_ar_200-statt = '반제완료'.

      gs_ar_200-col_amt = ls_ar_detail-receivableamount.
      gs_ar_200-bal_amt = 0.

      gs_ar_sp-col_amt =
        gs_ar_sp-col_amt + ls_ar_detail-receivableamount.

      gs_ar_sp-col_cnt =
        gs_ar_sp-col_cnt + 1.

    ENDIF.


    APPEND gs_ar_200 TO gt_ar_200.

  ENDLOOP.


  " 지사 → 채권발생일 → 전표번호 순
  SORT gt_ar_200 BY budat DESCENDING belnr DESCENDING.


  gv_waers1 = gs_ar_sp-waers.
  gv_waers2 = gs_ar_sp-waers.
  gv_waers3 = gs_ar_sp-waers.

  WRITE gs_ar_sp-tot_amt TO gv_tot_amt CURRENCY gv_waers1.
  CONDENSE gv_tot_amt.
  WRITE gs_ar_sp-col_amt TO gv_col_amt CURRENCY gv_waers2.
  CONDENSE gv_col_amt.
  WRITE gs_ar_sp-bal_amt TO gv_bal_amt CURRENCY gv_waers3.
  CONDENSE gv_bal_amt.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_200 .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_200
    EXPORTING
      container_name              = 'CONTROL_AREA_200'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_200
    EXPORTING
      i_parent          = go_cont_200 "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_200 .

  gs_layout_200-grid_title = '채권 발생 및 회수 상세 내역'.
  gs_layout_200-zebra = 'X'.
  gs_layout_200-no_toolbar = 'X'.
  gs_layout_200-stylefname = 'CT'. "핫스팟
*  gs_layout_200-sel_mode = 'A'.

  "신호등
  gs_layout_200-excp_fname = 'LIGHT'.
  gs_layout_200-excp_led   = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_200 .

  CLEAR: gt_fcat_200, gs_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'LIGHT'.
  gs_fcat_200-coltext = '상태'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'STATT'.
  gs_fcat_200-coltext = '채권상태'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BUPLA'.
  gs_fcat_200-coltext = '지사'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BNAME'.
  gs_fcat_200-coltext = '지사명'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'PRO_ID'.
  gs_fcat_200-coltext = '프로젝트번호'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BUDAT'.
  gs_fcat_200-coltext = '채권발생일'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BELNR'.
  gs_fcat_200-coltext = '발생전표번호'.
  gs_fcat_200-hotspot = 'X'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'AR_AMT'.
  gs_fcat_200-coltext = '채권금액'.
  gs_fcat_200-ref_field = 'AR_AMT'.
  gs_fcat_200-cfieldname = 'WAERS'.
  gs_fcat_200-emphasize = 'C311'.
  gs_fcat_200-do_sum = 'X'.
  gs_fcat_200-outputlen = 16.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'AUGDT'.
  gs_fcat_200-coltext = '반제일자'.
  gs_fcat_200-do_sum = 'X'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'AUGBL'.
  gs_fcat_200-coltext = '반제전표번호'.
*  gs_fcat_200-hotspot = 'X'.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'COL_AMT'.
  gs_fcat_200-coltext = '회수액'.
  gs_fcat_200-ref_field = 'COL_AMT'.
  gs_fcat_200-cfieldname = 'WAERS'.
  gs_fcat_200-emphasize = 'C311'.
  gs_fcat_200-do_sum = 'X'.
  gs_fcat_200-outputlen = 16.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'BAL_AMT'.
  gs_fcat_200-coltext = '현재 채권잔액'.
  gs_fcat_200-ref_field = 'BAL_AMT'.
  gs_fcat_200-cfieldname = 'WAERS'.
  gs_fcat_200-emphasize = 'C311'.
  gs_fcat_200-do_sum = 'X'.
  gs_fcat_200-outputlen = 16.
  APPEND gs_fcat_200 TO gt_fcat_200.

  CLEAR gs_fcat_200.
  gs_fcat_200-fieldname = 'WAERS'.
  gs_fcat_200-coltext = '통화'.
  gs_fcat_200-emphasize = 'C311'.
  APPEND gs_fcat_200 TO gt_fcat_200.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_200 .

  CALL METHOD go_alv_200->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_200
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_ar_200
      it_fieldcatalog               = gt_fcat_200
*     it_sort                       = gt_sort
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_200 .

  "1. alv 파괴
  IF go_alv_200 IS BOUND.

    CALL METHOD go_alv_200->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

*  ---------------------------------------------------------------
  "2. 컨테이너 파괴
  IF go_cont_200 IS BOUND.

    CALL METHOD go_cont_200->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  CLEAR: go_alv_200, go_cont_200. "clear 대신 free써도 됨

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM get_text .

*  IF p_cbukrs IS NOT INITIAL.
*    SELECT SINGLE butxt FROM z8company_m INTO gv_cbut
*      WHERE bukrs = p_cbukrs.
*    IF sy-subrc <> 0.
*      gv_cbut = 'error'.
*    ENDIF.
*  ELSE.
*    CLEAR gv_cbut.
*  ENDIF.
*
*  IF p_vbukrs IS NOT INITIAL.
*    SELECT SINGLE butxt FROM z8company_m INTO gv_vbut
*      WHERE bukrs = p_vbukrs.
*    IF sy-subrc <> 0.
*      gv_vbut = 'error'.
*    ENDIF.
*  ELSE.
*    CLEAR gv_vbut.
*  ENDIF.

*ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_100 .

  "최신 데이터 다시 조회
  PERFORM get_ar_data.
  PERFORM make_ar_sum.

  "alv 제목 재설정
  PERFORM set_grid_title_100.

  CALL METHOD go_alv_100->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_100-grid_title.

  gs_stable-row = 'X'.
  gs_stable-col = 'X'.

  CALL METHOD go_alv_100->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh = ' '
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
    MESSAGE s147(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler_200 .

  SET HANDLER:
                lcl_handler=>on_hotspot_ar FOR go_alv_200.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_ap_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_ap_data .

  CLEAR gt_ap_detail.

  SELECT
    a~bukrs,
    a~gjahr,
    a~belnr,
    a~bupla,
    a~lifnr,
    a~wrbtr,
    a~waers,
    a~bldat,
    a~budat,
    a~xblnr,
    a~augdt,
    a~augbl,
    a~auggj
    FROM z8fi_vendor AS a
    INNER JOIN z8fi_accdoc_h AS h
         ON h~bukrs = a~bukrs
       AND h~belnr = a~belnr
       AND h~gjahr = a~gjahr
      INNER JOIN z8fi_accdoc_i AS i
         ON i~bukrs = a~bukrs
       AND i~belnr = a~belnr
       AND i~gjahr = a~gjahr
       AND i~lifnr = a~lifnr
      AND i~koart = 'K'
    INTO CORRESPONDING FIELDS OF TABLE @gt_ap_detail
  WHERE a~bukrs = @gc_bukrs
       AND a~bupla IN @s_vbupla
       AND a~lifnr IN @s_lifnr
       AND a~budat IN @s_vbudat.

*  SELECT *
*    FROM z8fi_vendor
*    WHERE bukrs = @gc_bukrs
*    AND bupla IN @s_vbupla
*    AND budat IN @s_vbudat
*    AND lifnr IN @s_lifnr
*    INTO TABLE @gt_ap_detail.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_ap_sum
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_ap_sum .

  DATA lv_tabix TYPE sy-tabix.

  CLEAR gt_ap_300.

  LOOP AT gt_ap_detail INTO gs_ap_detail.

    CLEAR gs_ap_300.

    READ TABLE gt_ap_300 INTO gs_ap_300
    WITH KEY bukrs = gs_ap_detail-bukrs
                                 bupla = gs_ap_detail-bupla
                                 lifnr = gs_ap_detail-lifnr
                                 waers = gs_ap_detail-waers.

    IF sy-subrc = 0.

      lv_tabix = sy-tabix.

      "총 채무 발생액
      gs_ap_300-tot_amt = gs_ap_300-tot_amt + gs_ap_detail-wrbtr.

      "건수
      gs_ap_300-tot_cnt = gs_ap_300-tot_cnt + 1.

      "반제 안된거
      IF gs_ap_detail-augbl IS INITIAL.
        gs_ap_300-bal_amt = gs_ap_300-bal_amt + gs_ap_detail-wrbtr.
        gs_ap_300-open_cnt = gs_ap_300-open_cnt + 1.
      ELSE. "반제된거
        gs_ap_300-pay_amt = gs_ap_300-pay_amt + gs_ap_detail-wrbtr.
        gs_ap_300-clr_cnt = gs_ap_300-clr_cnt + 1.
      ENDIF.

      MODIFY gt_ap_300 FROM gs_ap_300 INDEX lv_tabix.

    ELSE.
      "공급업체 + 지사 1건만 존재
      CLEAR gs_ap_300.

      gs_ap_300-bukrs = gs_ap_detail-bukrs.
      gs_ap_300-bupla = gs_ap_detail-bupla.
      gs_ap_300-lifnr = gs_ap_detail-lifnr.
      gs_ap_300-waers = gs_ap_detail-waers.

      "공급업체명
      SELECT SINGLE name1 FROM z8vendor_m
      WHERE lifnr = @gs_ap_detail-lifnr
          INTO @gs_ap_300-vname.

      "지사명
      SELECT SINGLE name FROM z8branch_m
      WHERE branch = @gs_ap_detail-bupla
          INTO @gs_ap_300-bname.

      "채무발생
      gs_ap_300-tot_amt = gs_ap_detail-wrbtr.
      gs_ap_300-tot_cnt = 1.

      IF gs_ap_detail-augbl IS INITIAL.
        gs_ap_300-bal_amt = gs_ap_detail-wrbtr.
        gs_ap_300-open_cnt = 1.
      ELSE. "반제된거
        gs_ap_300-pay_amt = gs_ap_detail-wrbtr.
        gs_ap_300-clr_cnt = 1.
      ENDIF.

      APPEND gs_ap_300 TO gt_ap_300.

    ENDIF.

  ENDLOOP.

  SORT gt_ap_300 BY light ASCENDING
                                 open_cnt DESCENDING
                                 bal_amt DESCENDING
                                 lifnr ASCENDING
                                 bupla ASCENDING.

  "신호등
  LOOP AT gt_ap_300 INTO gs_ap_300.

    IF gs_ap_300-bal_amt = 0.
      "전체회수
      gs_ap_300-light = '3'.
      gs_ap_300-statt = '반제완료'.
    ELSE. "IF gs_ar_100-col_amt > 0.
      "일부 회수
      gs_ap_300-light = '2'.
      gs_ap_300-statt = '미결'.
*    ELSE.
*      "회수된 채권 x
*      gs_ar_100-light = '2'.
*      gs_ar_100-statt = '미회수'.
    ENDIF.

    MODIFY gt_ap_300 FROM gs_ap_300 INDEX sy-tabix.
  ENDLOOP.

  "상태 조건
  IF rb_apop = 'X'.
    DELETE gt_ap_300
    WHERE bal_amt = 0.
  ELSEIF rb_apcl = 'X'.
    DELETE gt_ap_300
    WHERE bal_amt <> 0.
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_300 .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_300
    EXPORTING
      container_name              = 'CONTROL_AREA_300'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_300
    EXPORTING
      i_parent          = go_cont_300 "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler_300 .

  SET HANDLER:
                lcl_handler=>on_hotspot_ap FOR go_alv_300.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_300 .

  gs_layout_300-zebra = 'X'.
  gs_layout_100-sel_mode = 'B'.

  "신호등
  gs_layout_300-excp_fname = 'LIGHT'.
  gs_layout_300-excp_led   = 'X'.

*  "정렬
*  CLEAR gs_sort_300.
*  gs_sort_300-fieldname = 'LIFNR'.
*  gs_sort_300-spos = 1.
*  gs_sort_300-up = 'X'.
*  APPEND gs_sort_300 TO gt_sort_300.
*
*  gs_layout_300-no_merging = 'X'.

  PERFORM set_grid_title_300.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_300 .

  CLEAR gs_fcat_100.
  gs_fcat_300-fieldname = 'LIGHT'.
  gs_fcat_300-coltext = '상태'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'STATT'.
  gs_fcat_300-coltext = '채무상태'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'LIFNR'.
  gs_fcat_300-coltext = '공급업체번호'.
  gs_fcat_300-hotspot = 'X'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'VNAME'.
  gs_fcat_300-coltext = '공급업체명'.
  gs_fcat_300-col_opt = 'X'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'BUPLA'.
  gs_fcat_300-coltext = '지사'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'BNAME'.
  gs_fcat_300-coltext = '지사명'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'TOT_AMT'.
  gs_fcat_300-coltext = '채무발생액'.
  gs_fcat_300-ref_field = 'TOT_AMT'.
  gs_fcat_300-cfieldname = 'WAERS'.
  gs_fcat_300-emphasize = 'C311'.
  gs_fcat_300-do_sum = 'X'.
*  gs_fcat_300-col_opt = 'X'.
  gs_fcat_300-outputlen = 16.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'PAY_AMT'.
  gs_fcat_300-coltext = '지급액'.
  gs_fcat_300-ref_field = 'PAY_AMT'.
  gs_fcat_300-cfieldname = 'WAERS'.
  gs_fcat_300-emphasize = 'C311'.
  gs_fcat_300-do_sum = 'X'.
*  gs_fcat_300-col_opt = 'X'.
  gs_fcat_300-outputlen = 16.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'BAL_AMT'.
  gs_fcat_300-coltext = '현재 채무잔액'.
  gs_fcat_300-ref_field = 'BAL_AMT'.
  gs_fcat_300-cfieldname = 'WAERS'.
  gs_fcat_300-emphasize = 'C311'.
  gs_fcat_300-do_sum = 'X'.
*  gs_fcat_300-col_opt = 'X'.
  gs_fcat_300-outputlen = 16.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'WAERS'.
  gs_fcat_300-coltext = '통화'.
  gs_fcat_300-emphasize = 'C311'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'TOT_CNT'.
  gs_fcat_300-coltext = '발생건수'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'CLR_CNT'.
  gs_fcat_300-coltext = '반제완료건수'.
  APPEND gs_fcat_300 TO gt_fcat_300.

  CLEAR gs_fcat_300.
  gs_fcat_300-fieldname = 'OPEN_CNT'.
  gs_fcat_300-coltext = '미결건수'.
  APPEND gs_fcat_300 TO gt_fcat_300.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_300 .

  CALL METHOD go_alv_300->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_300
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_ap_300
      it_fieldcatalog               = gt_fcat_300
      it_sort                       = gt_sort_300
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_300 .

  "alv 그리드 제목
  DATA lv_count TYPE i.

  DESCRIBE TABLE gt_ap_300 LINES lv_count.

  IF rb_apall = 'X'.
    gs_layout_300-grid_title = |전체 ({ lv_count }건)|.
  ELSEIF rb_apop = 'X'.
    gs_layout_300-grid_title = |미결 ({ lv_count }건)|.
  ELSEIF rb_apcl = 'X'.
    gs_layout_300-grid_title = |반제 완료 ({ lv_count }건)|.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_ap_detail_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_ap_detail_400 .

  DATA:
    lt_ap_detail TYPE STANDARD TABLE OF z8fi_vendor,
    ls_ap_detail TYPE z8fi_vendor,
    lt_branch    TYPE STANDARD TABLE OF z8branch_m,
    ls_branch    TYPE z8branch_m,
    lr_bupla     TYPE RANGE OF z8fi_vendor-bupla,
    ls_bupla     LIKE LINE OF lr_bupla.

  CLEAR: lr_bupla, ls_bupla.

  IF gv_ap_all_branch = 'X'.
    "전체 지사 조회
    lr_bupla[] = s_vbupla[].
  ELSE.
    "선택한 지사만 조회
    ls_bupla-sign = 'I'.
    ls_bupla-option = 'EQ'.
    ls_bupla-low = gs_ap_sel-bupla.
    APPEND ls_bupla TO lr_bupla.

  ENDIF.

  CLEAR: gt_ap_400, gs_ap_sp.

  SELECT
    a~bukrs,
    a~gjahr,
    a~belnr,
    a~bupla,
    a~lifnr,
    a~wrbtr,
    a~waers,
    a~bldat,
    a~budat,
    a~xblnr,
    a~augdt,
    a~augbl,
    a~auggj
    FROM z8fi_vendor AS a
    INNER JOIN z8fi_accdoc_h AS h
         ON h~bukrs = a~bukrs
       AND h~belnr = a~belnr
       AND h~gjahr = a~gjahr
      INNER JOIN z8fi_accdoc_i AS i
         ON i~bukrs = a~bukrs
       AND i~belnr = a~belnr
       AND i~gjahr = a~gjahr
       AND i~lifnr = a~lifnr
      AND i~koart = 'K'
    INTO CORRESPONDING FIELDS OF TABLE @lt_ap_detail
  WHERE a~bukrs = @gs_ap_sel-bukrs
       AND a~bupla IN @lr_bupla
       AND a~lifnr = @gs_ap_sel-lifnr
       AND a~budat IN @s_vbudat.

  "1000번 지급상태 조건 유지
  IF rb_apop = 'X'.
    DELETE lt_ap_detail WHERE augbl IS NOT INITIAL.
    IF lt_ap_detail IS INITIAL.
      RETURN.
    ENDIF.
  ELSEIF rb_apcl = 'X'.
    DELETE lt_ap_detail WHERE augbl IS INITIAL.
    IF lt_ap_detail IS INITIAL.
      RETURN.
    ENDIF.
  ENDIF.

  SELECT *
    FROM z8branch_m
    INTO TABLE lt_branch
    WHERE bukrs = gc_bukrs.

  IF sy-subrc <> 0.
    CLEAR lt_branch.
  ENDIF.

  "스크린 페인터
  IF gv_ap_all_branch IS INITIAL.
    gs_ap_sp-bupla = gs_ap_sel-bupla.
    CLEAR ls_branch.

    READ TABLE lt_branch INTO ls_branch WITH KEY bukrs = gs_ap_sel-bukrs
                                                                                branch = gs_ap_sel-bupla.
    IF sy-subrc = 0.
      gs_ap_sp-buplat = ls_branch-name.
    ELSE.
      CLEAR gs_ap_sp-buplat.
    ENDIF.
  ELSE.
    CLEAR gs_ap_sp-bupla.
    gs_ap_sp-buplat = '전체 지사'.
  ENDIF.


  SELECT SINGLE stcd2, telf1, ort01, stras
  FROM z8vendor_m
  WHERE lifnr = @gs_ap_sel-lifnr
  INTO CORRESPONDING FIELDS OF @gs_ap_sp.

  CONCATENATE gs_ap_sp-ort01 gs_ap_sp-stras INTO gs_ap_sp-gv_add SEPARATED BY space.

  "스크린 페인터
  gs_ap_sp-bukrs = gs_ap_sel-bukrs.
  gs_ap_sp-lifnr = gs_ap_sel-lifnr.
  gs_ap_sp-vname = gs_ap_sel-vname.
  gs_ap_sp-waers = gs_ap_sel-waers.

  "상세 내역 + 전체 채권
  LOOP AT lt_ap_detail INTO ls_ap_detail.

    CLEAR gs_ap_400.

    gs_ap_400-bukrs = ls_ap_detail-bukrs.

    " 지사
    gs_ap_400-bupla = ls_ap_detail-bupla.

    READ TABLE lt_branch INTO ls_branch WITH KEY branch = ls_ap_detail-bupla.
    IF sy-subrc = 0.
      gs_ap_400-bname = ls_branch-name.
    ENDIF.

    " 송장
    gs_ap_400-inv_no = ls_ap_detail-xblnr.

    " 채무 발생전표
    gs_ap_400-belnr = ls_ap_detail-belnr.
    gs_ap_400-gjahr = ls_ap_detail-gjahr.


    " 채무 발생정보
    gs_ap_400-budat  = ls_ap_detail-budat.
    gs_ap_400-ap_amt = ls_ap_detail-wrbtr.

    " 회수정보
    gs_ap_400-augdt = ls_ap_detail-augdt.
    gs_ap_400-augbl = ls_ap_detail-augbl.
    gs_ap_400-auggj = ls_ap_detail-auggj.

    gs_ap_400-waers = ls_ap_detail-waers.


    "--------------------------------------------------------*
    " 전체 채무발생액 / 발생건수
    "--------------------------------------------------------*
    gs_ap_sp-tot_amt = gs_ap_sp-tot_amt + ls_ap_detail-wrbtr.
    gs_ap_sp-tot_cnt = gs_ap_sp-tot_cnt + 1.

    "--------------------------------------------------------*
    " 회수 여부
    "--------------------------------------------------------*
    IF ls_ap_detail-augbl IS INITIAL.

      " 회수 미완료
      gs_ap_400-light = '2'.
      gs_ap_400-statt = '미결'.

      gs_ap_400-pay_amt = 0.
      gs_ap_400-bal_amt = ls_ap_detail-wrbtr.

      gs_ap_sp-bal_amt = gs_ap_sp-bal_amt + ls_ap_detail-wrbtr.

      gs_ap_sp-open_cnt = gs_ap_sp-open_cnt + 1.

    ELSE.

      " 회수 완료
      gs_ap_400-light = '3'.
      gs_ap_400-statt = '반제완료'.

      gs_ap_400-pay_amt = ls_ap_detail-wrbtr.
      gs_ap_400-bal_amt = 0.

      gs_ap_sp-pay_amt = gs_ap_sp-pay_amt + ls_ap_detail-wrbtr.

      gs_ap_sp-clr_cnt = gs_ap_sp-clr_cnt + 1.

    ENDIF.

    APPEND gs_ap_400 TO gt_ap_400.

  ENDLOOP.


  " 미결 -> 지사 -> 채무발생일 -> 전표번호 순
  SORT gt_ap_400 BY light ASCENDING
                                budat DESCENDING
                                belnr DESCENDING.


  gv_waers1 = gs_ap_sp-waers.
  gv_waers2 = gs_ap_sp-waers.
  gv_waers3 = gs_ap_sp-waers.

  WRITE gs_ap_sp-tot_amt TO gv_tot_amt CURRENCY gv_waers1.
  CONDENSE gv_tot_amt.
  WRITE gs_ap_sp-pay_amt TO gv_col_amt CURRENCY gv_waers2.
  CONDENSE gv_col_amt.
  WRITE gs_ap_sp-bal_amt TO gv_bal_amt CURRENCY gv_waers3.
  CONDENSE gv_bal_amt.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_400 .

  "1. alv 파괴
  IF go_alv_400 IS BOUND.

    CALL METHOD go_alv_400->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

*  ---------------------------------------------------------------
  "2. 컨테이너 파괴
  IF go_cont_400 IS BOUND.

    CALL METHOD go_cont_400->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a017(zmsg_139).
    ENDIF.

  ENDIF.

  CLEAR: go_alv_400, go_cont_400. "clear 대신 free써도 됨

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_400 .

  "1. 컨테이너 생성하기
  CREATE OBJECT go_cont_400
    EXPORTING
      container_name              = 'CONTROL_AREA_400'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

  "2. alv 생성하기
  CREATE OBJECT go_alv_400
    EXPORTING
      i_parent          = go_cont_400 "alv 담길 컨테이너 변수
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler_400 .

  SET HANDLER:
                lcl_handler=>on_hotspot_ap FOR go_alv_400.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_400 .

  gs_layout_400-grid_title = '채무 발생 및 회수 상세 내역'.
  gs_layout_400-zebra = 'X'.
  gs_layout_400-no_toolbar = 'X'.
  gs_layout_400-stylefname = 'CT'. "핫스팟
*  gs_layout_200-sel_mode = 'A'.

  "신호등
  gs_layout_400-excp_fname = 'LIGHT'.
  gs_layout_400-excp_led   = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_400 .

  CLEAR: gt_fcat_400, gs_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'LIGHT'.
  gs_fcat_400-coltext = '상태'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'STATT'.
  gs_fcat_400-coltext = '채무상태'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'BUPLA'.
  gs_fcat_400-coltext = '지사'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'BNAME'.
  gs_fcat_400-coltext = '지사명'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'INV_NO'.
  gs_fcat_400-coltext = '송장번호'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'BUDAT'.
  gs_fcat_400-coltext = '채무발생일'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'BELNR'.
  gs_fcat_400-coltext = '발생전표번호'.
  gs_fcat_400-hotspot = 'X'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'AP_AMT'.
  gs_fcat_400-coltext = '채무금액'.
  gs_fcat_400-ref_field = 'AP_AMT'.
  gs_fcat_400-cfieldname = 'WAERS'.
  gs_fcat_400-emphasize = 'C311'.
  gs_fcat_400-do_sum = 'X'.
*  gs_fcat_400-col_opt = 'X'.
  gs_fcat_400-outputlen = 16.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'AUGDT'.
  gs_fcat_400-coltext = '반제일자'.
  gs_fcat_400-do_sum = 'X'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'AUGBL'.
  gs_fcat_400-coltext = '반제전표번호'.
*  gs_fcat_400-hotspot = 'X'.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'PAY_AMT'.
  gs_fcat_400-coltext = '지급액'.
  gs_fcat_400-ref_field = 'PAY_AMT'.
  gs_fcat_400-cfieldname = 'WAERS'.
  gs_fcat_400-emphasize = 'C311'.
  gs_fcat_400-do_sum = 'X'.
*  gs_fcat_400-col_opt = 'X'.
  gs_fcat_400-outputlen = 16.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'BAL_AMT'.
  gs_fcat_400-coltext = '현재 채무잔액'.
  gs_fcat_400-ref_field = 'BAL_AMT'.
  gs_fcat_400-cfieldname = 'WAERS'.
  gs_fcat_400-emphasize = 'C311'.
  gs_fcat_400-do_sum = 'X'.
*  gs_fcat_400-col_opt = 'X'.
  gs_fcat_400-outputlen = 16.
  APPEND gs_fcat_400 TO gt_fcat_400.

  CLEAR gs_fcat_400.
  gs_fcat_400-fieldname = 'WAERS'.
  gs_fcat_400-coltext = '통화'.
  gs_fcat_400-emphasize = 'C311'.
  APPEND gs_fcat_400 TO gt_fcat_400.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_400 .

  CALL METHOD go_alv_400->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
*     i_structure_name              =
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_400
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_ap_400
      it_fieldcatalog               = gt_fcat_400
*     it_sort                       = gt_sort
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a017(zmsg_139).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_300 .

  DATA:
    ls_row  TYPE lvc_s_row,
    lt_rows TYPE lvc_t_row,
    ls_col  TYPE lvc_s_col.

  "최신 데이터 다시 조회
  PERFORM get_ap_data.
  PERFORM make_ap_sum.

  "alv 제목 재설정
  PERFORM set_grid_title_300.

  CALL METHOD go_alv_300->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_300-grid_title.

  gs_stable-row = 'X'.
  gs_stable-col = 'X'.

  CALL METHOD go_alv_300->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh = ' '
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
    MESSAGE s147(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_200 .

  DATA ls_ct TYPE lvc_s_styl.

  LOOP AT gt_ar_200 ASSIGNING FIELD-SYMBOL(<fs_alv>).

    CLEAR <fs_alv>-ct.

    "전표번호가 있는 셀만 Hotspot
    IF <fs_alv>-augbl IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'AUGBL'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.

      INSERT ls_ct INTO TABLE <fs_alv>-ct.

    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_400 .

  DATA ls_ct TYPE lvc_s_styl.

  LOOP AT gt_ap_400 ASSIGNING FIELD-SYMBOL(<fs_alv>).

    CLEAR <fs_alv>-ct.

    "전표번호가 있는 셀만 Hotspot
    IF <fs_alv>-augbl IS NOT INITIAL.

      CLEAR ls_ct.

      ls_ct-fieldname = 'AUGBL'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.

      INSERT ls_ct INTO TABLE <fs_alv>-ct.

    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_default_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_default_data .

  DATA lv_from TYPE sy-datum.

  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months  = -2
      olddate = sy-datum
    IMPORTING
      newdate = lv_from.

  "채권 발생일자
  s_cbudat-sign   = 'I'.
  s_cbudat-option = 'BT'.
  s_cbudat-low    = lv_from.
  s_cbudat-high   = sy-datum.
  APPEND s_cbudat.

  "채무 발생일자
  s_vbudat-sign   = 'I'.
  s_vbudat-option = 'BT'.
  s_vbudat-low    = lv_from.
  s_vbudat-high   = sy-datum.
  APPEND s_vbudat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_obligatory
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_obligatory .

  IF sscrfields-ucomm = 'ONLI'.
    "고객 채권
    IF rb_cust = 'X'.

      "날짜조건 자체가 없는 경우
      IF s_cbudat[] IS INITIAL.
        SET CURSOR FIELD 'S_CBUDAT-LOW'.
        MESSAGE e121(z8_msg)  WITH '채권 발생일자는'.
      ENDIF.

      "종료일만 입력한 경우
      IF s_cbudat-low IS INITIAL AND s_cbudat-high IS NOT INITIAL.
        SET CURSOR FIELD 'S_CBUDAT-LOW'.
        MESSAGE e124(z8_msg). "'시작일을 입력해주세요.'
      ENDIF.

      "기간 역전 확인
      IF s_cbudat-low IS NOT INITIAL
        AND s_cbudat-high IS NOT INITIAL
        AND s_cbudat-low > s_cbudat-high.

        SET CURSOR FIELD 'S_CBUDAT-LOW'.
        MESSAGE e126(z8_msg). "조회범위를 확인해주세요
      ENDIF.

      IF s_cbudat-low > sy-datum.
        SET CURSOR FIELD 'S_CBUDAT-LOW'.
        MESSAGE e123(z8_msg). "조회시작일은 현재 날짜보다 클 수 없습니다
      ENDIF.

      "공급업체 채무
    ELSEIF rb_vend = 'X'.

      "날짜조건 자체가 없는 경우
      IF s_vbudat[] IS INITIAL.
        SET CURSOR FIELD 'S_VBUDAT-LOW'.
        MESSAGE e121(z8_msg)  WITH '채무 발생일자는'.
      ENDIF.

      "종료일만 입력한 경우
      IF s_vbudat-low IS INITIAL AND s_vbudat-high IS NOT INITIAL.
        SET CURSOR FIELD 'S_VBUDAT-LOW'.
        MESSAGE e124(z8_msg). "'시작일을 입력해주세요.'
      ENDIF.

      "기간 역전 확인
      IF s_vbudat-low IS NOT INITIAL
        AND s_vbudat-high IS NOT INITIAL
        AND s_vbudat-low > s_vbudat-high.

        SET CURSOR FIELD 'S_VBUDAT-LOW'.
        MESSAGE e126(z8_msg). "조회범위를 확인해주세요
      ENDIF.

    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form authority_check
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM authority_check .

  AUTHORITY-CHECK OBJECT 'Z8FI_ADMIN'
    ID 'ACTVT' FIELD '16'.

  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'FI'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_400 .

  "선택/ 전체 지사 조건에 맞게 alv, 상단 요약 구성
  PERFORM make_ap_detail_400.
  PERFORM set_cell_style_400.

  gs_stable-row = 'X'.
  gs_stable-col = 'X'.

  CALL METHOD go_alv_400->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh = ' '
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
    MESSAGE s147(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_200 .

  "선택/ 전체 지사 조건에 맞게 alv, 상단 요약 구성
  PERFORM make_ar_detail_200.
  PERFORM set_cell_style_200.

  gs_stable-row = 'X'.
  gs_stable-col = 'X'.

  CALL METHOD go_alv_200->refresh_table_display
    EXPORTING
      is_stable = gs_stable
*     i_soft_refresh = ' '
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.

  IF sy-subrc <> 0.
    MESSAGE s147(z8_msg) DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_ar_branch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- GV_OTHER_BRANCH
*&---------------------------------------------------------------------*
FORM check_ar_branch  CHANGING cv_other_branch.

  DATA:
        lt_check TYPE STANDARD TABLE OF z8fi_c_aritem,
        ls_check TYPE z8fi_c_aritem.

  CLEAR: cv_other_branch, lt_check.

  "지사 상관 없이 고객의 전체 채권 조회
  SELECT *
    FROM z8fi_c_aritem
    INTO TABLE @lt_check
    WHERE companycode = @gs_ar_sel-bukrs
    AND customer = @gs_ar_sel-kunnr
    AND currency = @gs_ar_sel-waers
    AND branch IN @s_cbupla
    AND receivabledate IN @s_cbudat.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "1000번 지급상태 조건 유지
  IF rb_arop = 'X'.
    DELETE lt_check WHERE collectiondocument IS NOT INITIAL.
  ELSEIF rb_arcl = 'X'.
    DELETE lt_check WHERE collectiondocument IS INITIAL.
  ENDIF.

  LOOP AT lt_check INTO ls_check.
    IF ls_check-branch <> gs_ar_sel-bupla.
      cv_other_branch = 'X'.
      EXIT.
    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_ap_branch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- GV_OTHER_BRANCH
*&---------------------------------------------------------------------*
FORM check_ap_branch  CHANGING cv_other_branch.

  DATA:
    lt_check TYPE STANDARD TABLE OF z8fi_vendor,
    ls_check TYPE z8fi_vendor.

  CLEAR: cv_other_branch, lt_check, ls_check.

  " 현재 조회조건의 해당 공급업체 채무 조회
  SELECT
    a~bukrs,
    a~gjahr,
    a~belnr,
    a~bupla,
    a~lifnr,
    a~augbl
    FROM z8fi_vendor AS a
    INNER JOIN z8fi_accdoc_h AS h
      ON h~bukrs = a~bukrs
     AND h~belnr = a~belnr
     AND h~gjahr = a~gjahr
    INNER JOIN z8fi_accdoc_i AS i
      ON i~bukrs = a~bukrs
     AND i~belnr = a~belnr
     AND i~gjahr = a~gjahr
     AND i~lifnr = a~lifnr
     AND i~koart = 'K'
    INTO CORRESPONDING FIELDS OF TABLE @lt_check
    WHERE a~bukrs = @gs_ap_sel-bukrs
      AND a~lifnr = @gs_ap_sel-lifnr
      AND a~bupla IN @s_vbupla
      AND a~budat IN @s_vbudat.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 1000번 지급상태 조건 유지
  IF rb_apop = 'X'.
    "미결만
    DELETE lt_check WHERE augbl IS NOT INITIAL.
  ELSEIF rb_apcl = 'X'.
    "반제완료만
    DELETE lt_check WHERE augbl IS INITIAL.
  ENDIF.

  " 현재 선택한 지사 외의 데이터가 있는지 확인
  LOOP AT lt_check INTO ls_check.
    IF ls_check-bupla <> gs_ap_sel-bupla.
      cv_other_branch = 'X'.
      EXIT.
    ENDIF.

  ENDLOOP.

ENDFORM.
