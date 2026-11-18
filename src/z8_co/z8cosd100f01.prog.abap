*&---------------------------------------------------------------------*
*& Include          Z8COSD100F01
*&---------------------------------------------------------------------*

FORM get_data.
  DATA: lv_rate TYPE p LENGTH 8 DECIMALS 2,
        lv_prog TYPE i.

  " 1. KPI 일괄 집계
  WITH +bill AS (
      SELECT vgbel, MAX( zzpayst ) AS paystat
        FROM z8sd_billing_h
       GROUP BY vgbel )
  SELECT COUNT(*) AS total_cnt,
         SUM( CASE WHEN h~status = '20' AND b~paystat = '02'
                   THEN 1 ELSE 0 END ) AS won_cnt,
         SUM( CASE WHEN h~status IN ('30','40')
                     OR ( h~status = '20' AND b~paystat = '03' )
                   THEN 1 ELSE 0 END ) AS lost_cnt,
         SUM( CASE WHEN h~status IN ('30','40')
                     OR ( h~status = '20' AND b~paystat = '03' )
                   THEN h~netwr ELSE 0 END ) AS total_cost,
         MAX( h~waerk ) AS curr
    FROM z8sd_quotation_h AS h
      LEFT OUTER JOIN +bill AS b ON b~vgbel = h~vbeln_q
   WHERE h~guebg IN @s_guebg
     AND ( h~reject_reason = @gv_rej   OR @gv_rej   = '' )
     AND ( h~bupla         = @gv_bupla OR @gv_bupla = '' )
    INTO @DATA(ls_summary).

  " 2. 최대 거절 사유 (고객 거절 30만 사유 코드를 가짐 / 현재 화면 미출력)
  SELECT reject_reason, COUNT(*) AS cnt
    FROM z8sd_quotation_h
   WHERE guebg IN @s_guebg
     AND ( reject_reason = @gv_rej   OR @gv_rej   = '' )
     AND ( bupla         = @gv_bupla OR @gv_bupla = '' )
     AND status        = '30'
     AND reject_reason IS NOT INITIAL
   GROUP BY reject_reason
   ORDER BY cnt DESCENDING
    INTO TABLE @DATA(lt_top_reason)
      UP TO 1 ROWS.

  " 3. 120번 화면 필드 할당
  CLEAR: p_tcost, gv_curr, p_ttcnt, p_wocnt, p_ipcnt, p_locnt, p_lorat.

  IF ls_summary-total_cnt > 0.
    IF ls_summary-total_cost > 0.
      WRITE ls_summary-total_cost TO p_tcost CURRENCY ls_summary-curr.
      CONDENSE p_tcost.
    ENDIF.

    " 진행 = 전체 - 체결 - 미체결 (세 구분 합계가 항상 전체와 일치)
    lv_prog = ls_summary-total_cnt - ls_summary-won_cnt - ls_summary-lost_cnt.

    IF ls_summary-won_cnt  > 0. p_wocnt = ls_summary-won_cnt.  ENDIF.
    IF lv_prog             > 0. p_ipcnt = lv_prog.             ENDIF.
    IF ls_summary-lost_cnt > 0. p_locnt = ls_summary-lost_cnt. ENDIF.

    gv_curr = ls_summary-curr.
    p_ttcnt = ls_summary-total_cnt.

    " 미체결 비율 = 미체결 ÷ 전체 × 100 (지사 ALV PEND_RATE와 같은 기준)
    lv_rate = CONV f( ls_summary-lost_cnt ) / ls_summary-total_cnt * 100.

    IF line_exists( lt_top_reason[ 1 ] ).
      DATA(lv_top_rej_code) = lt_top_reason[ 1 ]-reject_reason.
      SELECT SINGLE ddtext
        INTO @DATA(lv_top_rej_text)
        FROM dd07t
       WHERE domname    = 'Z8D_REJECT_CODE'
         AND ddlanguage = @sy-langu
         AND domvalue_l = @lv_top_rej_code.
    ENDIF.

    CONDENSE: p_ttcnt, p_wocnt, p_ipcnt, p_locnt.

    IF lv_rate = 0.
      CLEAR p_lorat.
    ELSE.
      p_lorat = |{ lv_rate }|.
    ENDIF.
  ENDIF.

ENDFORM.

FORM align_right .
  p_tcost = |{ p_tcost WIDTH = 20 ALIGN = RIGHT }|.
  p_ttcnt = |{ p_ttcnt WIDTH = 10 ALIGN = RIGHT }|.
  p_wocnt = |{ p_wocnt WIDTH = 10 ALIGN = RIGHT }|.

  p_ipcnt = |{ p_ipcnt  WIDTH = 10 ALIGN = RIGHT }|.
  p_locnt = |{ p_locnt WIDTH = 10 ALIGN = RIGHT }|.
  p_lorat = |{ p_lorat WIDTH = 10 ALIGN = RIGHT }|.

ENDFORM.

FORM get_alv_data .

  WITH
    +bill AS (
      SELECT vgbel, MAX( zzpayst ) AS paystat
        FROM z8sd_billing_h
       GROUP BY vgbel ),
    +quot AS (
      SELECT h~bupla,
             h~waerk,
             " 미체결 금액 (견적 총액 기준)
             SUM( CASE WHEN h~status IN ('30','40')
                         OR ( h~status = '20' AND b~paystat = '03' )
                       THEN h~netwr ELSE 0 END ) AS netwr,
             " 미체결 건수
             SUM( CASE WHEN h~status IN ('30','40')
                         OR ( h~status = '20' AND b~paystat = '03' )
                       THEN 1 ELSE 0 END ) AS pend_num,
             " 체결 건수
             SUM( CASE WHEN h~status = '20' AND b~paystat = '02'
                       THEN 1 ELSE 0 END ) AS ord_num,
             " 전체 건수
             COUNT( * ) AS total_num
        FROM z8sd_quotation_h AS h
          LEFT OUTER JOIN +bill AS b ON b~vgbel = h~vbeln_q
       WHERE ( h~reject_reason = @gv_rej OR @gv_rej = '' )
         AND h~guebg IN @s_guebg
       GROUP BY h~bupla, h~waerk )
  SELECT m~name,
         m~branch AS bupla,
         coalesce( q~netwr, 0 )     AS netwr,
         coalesce( q~waerk, 'KRW' ) AS waerk,
         coalesce( q~pend_num, 0 )  AS pend_num,
         coalesce( q~ord_num, 0 )   AS ord_num,
         coalesce( q~total_num, 0 ) AS total_num
    FROM z8branch_m AS m
      LEFT OUTER JOIN +quot AS q ON q~bupla = m~branch
   WHERE ( m~branch = @gv_bupla OR @gv_bupla = '' )
    INTO CORRESPONDING FIELDS OF TABLE @gt_branch.

  LOOP AT gt_branch ASSIGNING FIELD-SYMBOL(<fs_branch>).
    " 진행 = 전체 - 체결 - 미체결
    <fs_branch>-prog_num = <fs_branch>-total_num
                         - <fs_branch>-ord_num
                         - <fs_branch>-pend_num.

    IF <fs_branch>-total_num > 0.
      <fs_branch>-pend_rate = <fs_branch>-pend_num / <fs_branch>-total_num * 100.
      <fs_branch>-ord_rate  = <fs_branch>-ord_num  / <fs_branch>-total_num * 100.
    ELSE.
      <fs_branch>-pend_rate = 0.
      <fs_branch>-ord_rate  = 0.
    ENDIF.
  ENDLOOP.

ENDFORM.

FORM show_popup_alv .

  TYPES: BEGIN OF ty_popup,
           rej_code  TYPE c LENGTH 10,              " 숨김 컬럼
           rej_text  TYPE dd07t-ddtext,
           pend_case TYPE i,
           netwr     TYPE z8sd_quotation_h-netwr,
           waerk     TYPE z8sd_quotation_h-waerk,
           pend_rate TYPE p LENGTH 5 DECIMALS 2,
         END OF ty_popup.

  CONSTANTS: lc_code_quo TYPE c LENGTH 10 VALUE '#QUO',   " 견적 기한 만료
             lc_code_bil TYPE c LENGTH 10 VALUE '#BIL',   " 청구 기한 만료
             lc_code_nor TYPE c LENGTH 10 VALUE '#NOR'.   " 사유 미입력

  DATA: lt_popup TYPE STANDARD TABLE OF ty_popup WITH EMPTY KEY,
        lo_salv  TYPE REF TO cl_salv_table,
        lv_key   TYPE c LENGTH 10.

  " 1. 뼈대: 도메인 고정값 전체 + 만료 2종 + 사유 미입력
  SELECT domvalue_l AS rej_code,
         ddtext     AS rej_text
    FROM dd07t
   WHERE domname    = 'Z8D_REJECT_CODE'
     AND ddlanguage = @sy-langu
     AND as4local   = 'A'
    INTO CORRESPONDING FIELDS OF TABLE @lt_popup.

  APPEND VALUE #( rej_code = lc_code_quo rej_text = TEXT-t01 ) TO lt_popup.
  APPEND VALUE #( rej_code = lc_code_bil rej_text = TEXT-t03 ) TO lt_popup.
  APPEND VALUE #( rej_code = lc_code_nor rej_text = TEXT-t02 ) TO lt_popup.

  " 2. 미체결 견적 집계 (사유 + 견적 상태 단위)
  WITH +bill AS (
      SELECT vgbel, MAX( zzpayst ) AS paystat
        FROM z8sd_billing_h
       GROUP BY vgbel )
  SELECT h~reject_reason,
         h~status,
         COUNT( * )     AS cnt,
         SUM( h~netwr ) AS netwr,
         MAX( h~waerk ) AS waerk
    FROM z8sd_quotation_h AS h
      LEFT OUTER JOIN +bill AS b ON b~vgbel = h~vbeln_q
   WHERE (    h~status IN ('30', '40')
           OR ( h~status = '20' AND b~paystat = '03' ) )
     AND ( h~reject_reason = @gv_rej   OR @gv_rej   = '' )
     AND ( h~bupla         = @gv_bupla OR @gv_bupla = '' )
     AND h~guebg IN @s_guebg
   GROUP BY h~reject_reason, h~status
    INTO TABLE @DATA(lt_agg).

  " 3. 뼈대에 누적 + 총 미체결 건수
  CLEAR gv_total.

  LOOP AT lt_agg INTO DATA(ls_agg).

    " 만료 구분 우선 → 사유 코드 → 사유 미입력
    " (WHERE 조건상 STATUS 20은 청구 입금상태 03인 건만 들어옴)
    lv_key = COND #( WHEN ls_agg-status = '40'               THEN lc_code_quo
                     WHEN ls_agg-status = '20'               THEN lc_code_bil
                     WHEN ls_agg-reject_reason IS NOT INITIAL THEN ls_agg-reject_reason
                     ELSE                                         lc_code_nor ).

    READ TABLE lt_popup ASSIGNING FIELD-SYMBOL(<ls_popup>)
         WITH KEY rej_code = lv_key.
    IF sy-subrc <> 0.
      APPEND VALUE #( rej_code = lv_key rej_text = lv_key ) TO lt_popup
             ASSIGNING <ls_popup>.
    ENDIF.

    <ls_popup>-pend_case = <ls_popup>-pend_case + ls_agg-cnt.
    <ls_popup>-netwr     = <ls_popup>-netwr     + ls_agg-netwr.
    <ls_popup>-waerk     = ls_agg-waerk.

    gv_total = gv_total + ls_agg-cnt.
  ENDLOOP.

  DELETE lt_popup WHERE rej_code = lc_code_nor AND pend_case = 0.

  " 4. 기본 통화 및 건수 비율
  LOOP AT lt_popup ASSIGNING <ls_popup>.
    IF <ls_popup>-waerk IS INITIAL.
      <ls_popup>-waerk = 'KRW'.
    ENDIF.

    IF gv_total > 0.
      <ls_popup>-pend_rate = <ls_popup>-pend_case * 100 / gv_total.
    ENDIF.
  ENDLOOP.

  " 5. SALV 팝업
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = lt_popup ).

      lo_salv->get_display_settings( )->set_striped_pattern( abap_true ).

      DATA(lo_functions) = lo_salv->get_functions( ).
      lo_functions->set_print( abap_false ).
      lo_functions->set_print_preview( abap_false ).

      lo_salv->set_screen_popup(
        start_column = 10
        end_column   = 100
        start_line   = 5
        end_line     = 15 ).

      DATA(lo_columns) = lo_salv->get_columns( ).
      DATA lo_column TYPE REF TO cl_salv_column.

      lo_column = lo_columns->get_column( 'REJ_CODE' ).
      lo_column->set_visible( abap_false ).

      lo_column = lo_columns->get_column( 'REJ_TEXT' ).
      lo_column->set_long_text( '거절 사유' ).
      lo_column->set_medium_text( '거절 사유' ).
      lo_column->set_short_text( '거절사유' ).
      lo_column->set_output_length( 20 ).

      lo_column = lo_columns->get_column( 'PEND_CASE' ).
      lo_column->set_long_text( '미체결 건수' ).
      lo_column->set_medium_text( '미체결 건수' ).
      lo_column->set_short_text( '미결건수' ).
      lo_column->set_output_length( 10 ).

      lo_column = lo_columns->get_column( 'NETWR' ).
      lo_column->set_long_text( '금액' ).
      lo_column->set_medium_text( '금액' ).
      lo_column->set_short_text( '금액' ).
      lo_column->set_output_length( 15 ).
      lo_column->set_currency_column( 'WAERK' ).

      lo_column = lo_columns->get_column( 'WAERK' ).
      lo_column->set_long_text( '통화' ).
      lo_column->set_medium_text( '통화' ).
      lo_column->set_short_text( '통화' ).

      lo_column = lo_columns->get_column( 'PEND_RATE' ).
      lo_column->set_long_text( '미체결 비율(%)' ).
      lo_column->set_medium_text( '미체결 비율(%)' ).
      lo_column->set_short_text( '미결비율(%)' ).

      DATA(lo_sorts) = lo_salv->get_sorts( ).
      lo_sorts->add_sort( columnname = 'PEND_CASE'
                          sequence   = if_salv_c_sort=>sort_down ).
      lo_sorts->add_sort( columnname = 'NETWR'
                          sequence   = if_salv_c_sort=>sort_down ).

      lo_salv->display( ).

    CATCH cx_salv_not_found cx_salv_existing cx_salv_data_error cx_salv_msg.
      MESSAGE s022(z8_msg) DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.
