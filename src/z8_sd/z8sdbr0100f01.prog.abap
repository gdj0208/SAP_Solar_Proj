*&---------------------------------------------------------------------*
*& Include          Z8SDBR0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form set_default_date
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_default_date.

  DATA: lv_from TYPE sy-datum.

  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months  = -3
      olddate = sy-datum
    IMPORTING
      newdate = lv_from.

  CLEAR s_audat.
  s_audat-sign   = 'I'.
  s_audat-option = 'BT'.
  s_audat-low    = lv_from.
  s_audat-high   = sy-datum.
  APPEND s_audat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_contract .
  DATA: lv_lines TYPE i.

*  CLEAR gt_contract_all..
  CLEAR gt_contract.

  SELECT q~vbeln_q, q~audat, q~kunnr, q~bupla, q~netwr, q~waerk,
        q~transit_cost AS transit,
        q~install_cost AS install,
         c~name1,
         r~name     AS branch_nm,
         d~vbeln    AS dp_vbeln,
         d~netwr    AS dp_amt,
         d~zzpayst  AS dp_payst,
         d~zduedat  AS dp_duedat,
         d~fkdat      AS dp_fkdat,
         d~zpaydat  AS dp_paydat,
         d~belnr    AS dp_belnr,
         d~gjahr    AS dp_gjahr,
         s~vbeln_s,
         s~audat AS so_audat,
         p~status_p,
         b~vbeln    AS bal_vbeln,
         b~netwr    AS bal_amt,
         b~zzpayst  AS bal_payst,
         b~zduedat  AS bal_duedat,
         b~fkdat    AS bal_fkdat,
         b~zpaydat  AS bal_paydat,
         b~belnr    AS bal_belnr,
         b~gjahr    AS bal_gjahr
    FROM z8sd_quotation_h AS q
    LEFT OUTER JOIN z8sd_billing_h AS d          " 선수금
      ON  d~vgbel = q~vbeln_q
      AND d~fkart = 'F1'
    LEFT OUTER JOIN z8sd_so_h AS s               " SO
      ON  s~vbeln_q = q~vbeln_q
    LEFT OUTER JOIN z8ps_project AS p            " 프로젝트
      ON  p~vbeln = s~vbeln_s
    LEFT OUTER JOIN z8sd_billing_h AS b          " 잔금
      ON  b~vgbel = s~vbeln_s
      AND b~fkart = 'F2'
    LEFT OUTER JOIN z8customer_m AS c          "고객번호
      ON  c~kunnr = q~kunnr
    LEFT OUTER JOIN z8branch_m AS r              "지사
      ON  r~branch = q~bupla
      AND r~bukrs  = '1000'
    WHERE q~status  = '20'
      AND q~vbeln_q IN @s_vbelnq
      AND q~audat   IN @s_audat
      AND s~vbeln_s IN @s_vbelns
      AND q~kunnr   IN @s_kunnr
      AND q~bupla   IN @s_bupla
    INTO CORRESPONDING FIELDS OF TABLE @gt_contract.

  "1. 줄마다 단계 판단
  LOOP AT gt_contract INTO gs_contract.
    PERFORM set_stage. " 입금누계/ 미수금 계산.
    MODIFY gt_contract FROM gs_contract.
  ENDLOOP.

  "2. 폐기 건 제외 (견적 재생성으로 대체됨)
  DELETE gt_contract WHERE light = '4'.

  "3. 거르기 전에 상태별 건수 세기.
  PERFORM count_contract.

  "4. 진행상태 조건
  IF p_r2 = 'X'.
    DELETE gt_contract WHERE light <> '1'.
  ELSEIF p_r3 = 'X'.
    DELETE gt_contract WHERE light <> '2'.
  ELSEIF p_r4 = 'X'.
    DELETE gt_contract WHERE light <> '3'.
  ENDIF.

  "5. 정렬: 상태 → 기한 빠른 순 → 견적일 최신
  SORT gt_contract BY light ASCENDING sort_due ASCENDING audat DESCENDING.

*   "버튼 건수 + 현재 보기로 거르기
*  PERFORM set_button_text.
*  PERFORM filter_contract.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_stage
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_stage .
  DATA: lv_proj_tx TYPE c LENGTH 12,
        lv_step    TYPE i.

  CLEAR: gs_contract-light, gs_contract-status_tx, gs_contract-stage_tx,
         gs_contract-dept_tx, gs_contract-due_date, gs_contract-sort_due,
         gs_contract-paid_amt, gs_contract-open_amt, gs_contract-overdue.

  ""1. 금액: 입금액 / 잔액
  IF gs_contract-dp_payst = '02'.
    gs_contract-paid_amt = gs_contract-paid_amt + gs_contract-dp_amt.
  ENDIF.

  IF gs_contract-bal_payst = '02'.
    gs_contract-paid_amt = gs_contract-paid_amt + gs_contract-bal_amt.
  ENDIF.

  gs_contract-open_amt = gs_contract-netwr - gs_contract-paid_amt.

    "2. 단계 판단 (앞 단계부터: 끝나지 않은 첫 단계에서 멈춤)
  IF gs_contract-dp_vbeln IS INITIAL.
    lv_step = 2.
    gs_contract-light    = '1'.
    gs_contract-stage_tx = '선수금 청구 대기'.
    gs_contract-dept_tx  = '영업관리팀'.
    gs_contract-due_date = gs_contract-audat + 30.

  ELSEIF gs_contract-dp_payst = '03'
      OR ( gs_contract-dp_payst = '01' AND gs_contract-dp_duedat < sy-datum ).
    lv_step = 3.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = '선수금 입금 기한 경과'.
    gs_contract-dept_tx  = '재무팀'.
    gs_contract-due_date = gs_contract-dp_duedat.
    gs_contract-overdue  = 'X'.

  ELSEIF gs_contract-dp_payst <> '02'.
    lv_step = 3.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = '선수금 입금 대기'.
    gs_contract-dept_tx  = '재무팀'.
    gs_contract-due_date = gs_contract-dp_duedat.

  ELSEIF gs_contract-vbeln_s IS INITIAL.
    lv_step = 4.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = 'SO 생성 대기'.
    gs_contract-dept_tx  = '영업팀'.

  ELSEIF gs_contract-status_p < '50'.
    lv_step = 4.
    PERFORM get_contract_text CHANGING lv_proj_tx.
    gs_contract-light    = '2'.
    CONCATENATE '시공 중 (' lv_proj_tx ')' INTO gs_contract-stage_tx.
    gs_contract-dept_tx  = '시공팀'.

  ELSEIF gs_contract-status_p = '50'.
    lv_step = 5.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = '고객 검수 대기'.
    gs_contract-dept_tx  = '시공팀'.

  ELSEIF gs_contract-bal_vbeln IS INITIAL.
    lv_step = 6.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = '잔금 청구 대기'.
    gs_contract-dept_tx  = '영업관리팀'.

  ELSEIF gs_contract-bal_payst = '03'
      OR ( gs_contract-bal_payst = '01' AND gs_contract-bal_duedat < sy-datum ).
    lv_step = 7.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = '잔금 입금 기한 경과'.
    gs_contract-dept_tx  = '재무팀'.
    gs_contract-due_date = gs_contract-bal_duedat.
    gs_contract-overdue  = 'X'.

  ELSEIF gs_contract-bal_payst <> '02'.
    lv_step = 7.
    gs_contract-light    = '2'.
    gs_contract-stage_tx = '잔금 입금 대기'.
    gs_contract-dept_tx  = '재무팀'.
    gs_contract-due_date = gs_contract-bal_duedat.

  ELSE.
    lv_step = 8.
    gs_contract-light    = '3'.
    gs_contract-stage_tx = '완료'.
  ENDIF.

  "3. 진행 상태 텍스트
  IF gs_contract-light = '1'.
    gs_contract-status_tx = '미진행'.
  ELSEIF gs_contract-light = '2'.
    gs_contract-status_tx = '진행중'.
  ELSEIF gs_contract-light = '3'.
    gs_contract-status_tx = '진행완료'.
  ENDIF.
  "상태 아이콘: 진행완료만 표시
  CLEAR gs_contract-icon.
  IF gs_contract-light = '3'.
    gs_contract-icon = icon_led_green.
  ENDIF.

  "4. 단계 아이콘
  PERFORM set_step_icons USING lv_step.

  "기한을 청구 / 입금으로 나누기
  CLEAR: gs_contract-bill_due, gs_contract-pay_due.

  IF gs_contract-stage_tx = '선수금 청구 대기'.
*    gs_contract-bill_due = gs_contract-due_date. " 청구기한.
  ELSEIF gs_contract-stage_tx = '선수금 입금 대기'
      OR gs_contract-stage_tx = '잔금 입금 대기'.
    gs_contract-pay_due = gs_contract-due_date.
  ENDIF.
  "4. 정렬용 마감일
  PERFORM set_sort_due.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_project_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_PROJ_TX
*&---------------------------------------------------------------------*
FORM get_contract_text  CHANGING pv_text.
  CASE gs_contract-status_p.
    WHEN '10'. pv_text = '프로젝트 생성'.
    WHEN '20'. pv_text = '일정 확정'.
    WHEN '30'. pv_text = '인력 배정'.
    WHEN '40'. pv_text = '설치 진행'.
    WHEN '50'. pv_text = '설치 완료'.
    WHEN OTHERS. pv_text = '준비 중'. "SO는 있는데 프로젝트가 아직 없으면 준비 중으로 나옴.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_due_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_sort_due.

  "잔금 청구 대기: 진행중 안에서 맨 위
  IF gs_contract-stage_tx = '잔금 청구 대기'.
    gs_contract-sort_due = '00000001'.
    "마감일 없는 단계: 맨 아래
  ELSEIF gs_contract-due_date IS INITIAL.
    gs_contract-sort_due = '99991231'.
  ELSE.
    gs_contract-sort_due = gs_contract-due_date.
  ENDIF.

  gs_contract-sort_due = gs_contract-due_date.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_contract .
  CREATE OBJECT go_cont_contract
    EXPORTING
      container_name = 'C_ALV'.

  CREATE OBJECT go_alv_contract
    EXPORTING
      i_parent = go_cont_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout_contract .
  CLEAR gs_layout_contract.
  gs_layout_contract-zebra      = 'X'.
*  gs_layout_contract-cwidth_opt = 'X'.
  gs_layout_contract-sel_mode   = 'B'.
*  gs_layout_contract-excp_fname = 'LIGHT'.
*  gs_layout_contract-excp_led = 'X'.
*  gs_layout_contract-excp_rolln = 'Z8E_BILL_LIGHT'.
*  gs_layout_contract-ctab_fname = 'CELL_COLOR'.

  PERFORM set_grid_title_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_grid_title_contract .

  DATA: lv_lines TYPE i,
        lv_cnt   TYPE c LENGTH 10,
        lv_view  TYPE c LENGTH 10,
        lv_all   TYPE c LENGTH 10,
        lv_req   TYPE c LENGTH 10,
        lv_prg   TYPE c LENGTH 10,
        lV_done  TYPE c LENGTH 10.

*  DESCRIBE TABLE gt_contract LINES lv_lines.
*  lv_cnt = lv_lines.
*  CONDENSE lv_cnt.

  IF p_r2 = 'X'.
    lv_view = '미진행'.
  ELSEIF p_r3 = 'X'.
    lv_view = '진행중'.
  ELSEIF p_r4 = 'X'.
    lv_view = '진행완료'.
  ELSE.
    lv_view = '전체'.
  ENDIF.

  DESCRIBE TABLE gt_contract LINES lv_lines.
  lv_cnt  = lv_lines.     CONDENSE lv_cnt.
  lv_all  = gv_cnt_all.   CONDENSE lv_all.
  lv_req  = gv_cnt_req.   CONDENSE lv_req.
  lv_prg  = gv_cnt_prg.   CONDENSE lv_prg.
  lv_done = gv_cnt_done.  CONDENSE lv_done.

  CONCATENATE lv_view lv_cnt '건   (전체' lv_all '· 미진행' lv_req
              '· 진행중' lv_prg '· 진행완료' lv_done ')'
    INTO gs_layout_contract-grid_title SEPARATED BY space.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_contract .
  CLEAR gt_fcat_contract.

  gw_fcat_contract-fieldname = 'ICON'.
  gw_fcat_contract-coltext   = '상태'.
  gw_fcat_contract-icon = 'X'.
  gw_fcat_contract-outputlen = 2.
  gw_fcat_contract-key = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STATUS_TX'.
  gw_fcat_contract-coltext   = '진행상태 '.
  gw_fcat_contract-outputlen = 6.
  gw_fcat_contract-key = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.


  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'VBELN_Q'.
  gw_fcat_contract-coltext   = '견적번호'.
  gw_fcat_contract-key = 'X'.
  gw_fcat_contract-hotspot = 'X'.
  gw_fcat_contract-outputlen = 11.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'NAME1'.
  gw_fcat_contract-coltext   = '고객명'.
  gw_fcat_contract-outputlen = 12.
  gw_fcat_contract-col_opt = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'BRANCH_NM'.
  gw_fcat_contract-coltext   = '지사'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  "단계 7칸
  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP1'.
  gw_fcat_contract-coltext   = '견적'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP2'.
  gw_fcat_contract-coltext   = '선수금청구'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP3'.
  gw_fcat_contract-coltext   = '선수금입금'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP4'.
  gw_fcat_contract-coltext   = '시공'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP5'.
  gw_fcat_contract-coltext   = '검수'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP6'.
  gw_fcat_contract-coltext   = '잔금청구'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STEP7'.
  gw_fcat_contract-coltext   = '잔금입금'.
  gw_fcat_contract-icon      = 'X'.
  gw_fcat_contract-just      = 'C'.
  gw_fcat_contract-outputlen = 7.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'STAGE_TX'.
  gw_fcat_contract-coltext   = '현재단계'.
  gw_fcat_contract-outputlen = 15.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'DEPT_TX'.
  gw_fcat_contract-coltext   = '담당 부서'.
  gw_fcat_contract-no_out = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

*  CLEAR gw_fcat_contract.
*  gw_fcat_contract-fieldname = 'BILL_DUE'.
*  gw_fcat_contract-coltext   = '청구 기한'.
*  gw_fcat_contract-datatype  = 'DATS'.
*  APPEND gw_fcat_contract TO gt_fcat_contract.

*  CLEAR gw_fcat_contract.
*  gw_fcat_contract-fieldname = 'REMAIN_TX'.
*  gw_fcat_contract-coltext   = '남은 기간'.
*  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname  = 'NETWR'.
  gw_fcat_contract-coltext    = '계약금액'.
  gw_fcat_contract-cfieldname = 'WAERK'.
  gw_fcat_contract-datatype   = 'CURR'.
*  gw_fcat_contract-do_sum     = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname  = 'PAID_AMT'.
  gw_fcat_contract-coltext    = '입금액'.
  gw_fcat_contract-cfieldname = 'WAERK'.
  gw_fcat_contract-datatype   = 'CURR'.
*  gw_fcat_contract-do_sum     = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname  = 'OPEN_AMT'.
  gw_fcat_contract-coltext    = '잔액'.
  gw_fcat_contract-cfieldname = 'WAERK'.
  gw_fcat_contract-datatype   = 'CURR'.
*  gw_fcat_contract-do_sum     = 'X'.
*  gw_fcat_contract-emphasize  = 'C311'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'WAERK'.
  gw_fcat_contract-coltext   = '통화'.
*  gw_fcat_contract-emphasize  = 'C311'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

    CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'PAY_DUE'.
  gw_fcat_contract-coltext   = '입금 기한'.
  gw_fcat_contract-datatype  = 'DATS'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  "숨김 컬럼 (레이아웃 변경으로 꺼내 볼 수 있음)
  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'AUDAT'.
  gw_fcat_contract-coltext   = '견적일'.
  gw_fcat_contract-datatype  = 'DATS'.
  gw_fcat_contract-no_out    = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'KUNNR'.
  gw_fcat_contract-coltext   = '고객번호'.
  gw_fcat_contract-no_out    = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'BUPLA'.
  gw_fcat_contract-coltext   = '지사코드'.
  gw_fcat_contract-no_out    = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'VBELN_S'.
  gw_fcat_contract-coltext   = 'SO번호'.
  gw_fcat_contract-no_out    = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'DP_VBELN'.
  gw_fcat_contract-coltext   = '선수금 청구번호'.
  gw_fcat_contract-no_out    = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.

  CLEAR gw_fcat_contract.
  gw_fcat_contract-fieldname = 'BAL_VBELN'.
  gw_fcat_contract-coltext   = '잔금 청구번호'.
  gw_fcat_contract-no_out    = 'X'.
  APPEND gw_fcat_contract TO gt_fcat_contract.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_contract .
  CALL METHOD go_alv_contract->set_table_for_first_display
    EXPORTING
      is_layout            = gs_layout_contract
      it_toolbar_excluding = gt_exclude_contract
    CHANGING
      it_outtab            = gt_contract
      it_fieldcatalog      = gt_fcat_contract.
*      it_filter             = gt_filter_contract.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM refresh_alv_contract .
  DATA: ls_stable TYPE lvc_s_stbl.

  PERFORM get_data_contract.
  PERFORM set_grid_title_contract.

  CALL METHOD go_alv_contract->set_gridtitle
    EXPORTING
      i_gridtitle = gs_layout_contract-grid_title.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.

  CALL METHOD go_alv_contract->refresh_table_display
    EXPORTING
      is_stable = ls_stable.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_contract .
  IF go_alv_contract IS NOT INITIAL.
    CALL METHOD go_alv_contract->free.
  ENDIF.

  IF go_cont_contract IS NOT INITIAL.
    CALL METHOD go_cont_contract->free.
  ENDIF.

  CLEAR: go_alv_contract, go_cont_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_step_icons
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
FORM set_step_icons USING pv_step TYPE i. "단계 7칸 아이콘.

  PERFORM get_step_icon USING pv_step 1 CHANGING gs_contract-step1.
  PERFORM get_step_icon USING pv_step 2 CHANGING gs_contract-step2.
  PERFORM get_step_icon USING pv_step 3 CHANGING gs_contract-step3.
  PERFORM get_step_icon USING pv_step 4 CHANGING gs_contract-step4.
  PERFORM get_step_icon USING pv_step 5 CHANGING gs_contract-step5.
  PERFORM get_step_icon USING pv_step 6 CHANGING gs_contract-step6.
  PERFORM get_step_icon USING pv_step 7 CHANGING gs_contract-step7.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_step_icon
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_STEP
*&      --> P_1
*&      <-- GS_CONTRACT_STEP1
*&---------------------------------------------------------------------*
FORM get_step_icon USING    pv_step TYPE i
                                                    pv_no   TYPE i
                                    CHANGING pv_icon TYPE icon-id.

  CLEAR pv_icon.

  IF pv_step = 0.
    RETURN.
  ENDIF.

  IF pv_no < pv_step.
    pv_icon = icon_led_green.
  ELSEIF pv_no = pv_step.
    IF gs_contract-overdue = 'X'.
      pv_icon = icon_led_red.   "기한 경과로 멈춤.
    ELSE.
    pv_icon = icon_led_yellow.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_button_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM set_button_text. "상태 버튼에 건수 표시.
*
*  DATA: lv_all  TYPE i,
*        lv_req  TYPE i,
*        lv_prg  TYPE i,
*        lv_done TYPE i,
*        lv_tx   TYPE c LENGTH 10.
*
*  CLEAR: lv_all, lv_req, lv_prg, lv_done.
*
**  LOOP AT gt_contract_all INTO gs_contract.
*    LOOP AT gt_contract INTO gs_contract.
*    lv_all = lv_all + 1.
*    IF gs_contract-light = '1'.
*      lv_req = lv_req + 1.
*    ELSEIF gs_contract-light = '2'.
*      lv_prg = lv_prg + 1.
*    ELSEIF gs_contract-light = '3'.
*      lv_done = lv_done + 1.
*    ENDIF.
*  ENDLOOP.
*
*  lv_tx = lv_all. CONDENSE lv_tx.
*  CONCATENATE '전체' lv_tx INTO gv_btn_all-text SEPARATED BY space.
*
*  lv_tx = lv_req. CONDENSE lv_tx.
*  CONCATENATE '미진행' lv_tx INTO gv_btn_req-text SEPARATED BY space.
*
*  lv_tx = lv_prg. CONDENSE lv_tx.
*  CONCATENATE '진행중' lv_tx INTO gv_btn_prg-text SEPARATED BY space.
*
*  lv_tx = lv_done. CONDENSE lv_tx.
*  CONCATENATE '진행완료' lv_tx INTO gv_btn_done-text SEPARATED BY space.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form filter_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM filter_contract ."현재보기로 거르기.
*  CLEAR gt_contract.
*
*  IF gv_view = '0'.
*    gt_contract = gt_contract_all.
*  ELSE.
*    LOOP AT gt_contract_all INTO gs_contract WHERE light = gv_view.
*      APPEND gs_contract TO gt_contract.
*    ENDLOOP.
*  ENDIF.
*
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form change_view_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*FORM change_view_contract . "상태 버튼 눌렀을 때.
*  DATA: ls_stable TYPE lvc_s_stbl.
*
*  PERFORM filter_contract.
*  PERFORM set_grid_title_contract.
*
*  CALL METHOD go_alv_contract->set_gridtitle
*    EXPORTING
*      i_gridtitle = gs_layout_contract-grid_title.
*
*  ls_stable-row = 'X'.
*  ls_stable-col = 'X'.
*
*  CALL METHOD go_alv_contract->refresh_table_display
*    EXPORTING
*      is_stable = ls_stable.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_billing_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_billing_contract.

  DATA: lt_rows  TYPE lvc_t_row,
        ls_row   TYPE lvc_s_row,
        lv_lines TYPE i.

  "1. 선택 확인
  CALL METHOD go_alv_contract->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  DESCRIBE TABLE lt_rows LINES lv_lines.
  IF lv_lines <> 1.
    MESSAGE s080(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.
  READ TABLE gt_contract INTO gs_contract INDEX ls_row-index.


  PERFORM submit_billing.
  "5. 돌아오면 새로고침 (보던 보기 그대로)
  PERFORM refresh_alv_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_filter_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_filter_contract .
  CLEAR gt_filter_contract.

  CLEAR gs_filter_contract.
  gs_filter_contract-fieldname = 'STATUS_TX'.
  gs_filter_contract-sign = 'E'.
  gs_filter_contract-option = 'EQ'.
  gs_filter_contract-low = '진행완료'.
  APPEND gs_filter_contract TO gt_filter_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form count_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM  count_contract.

  CLEAR: gv_cnt_all, gv_cnt_req, gv_cnt_prg, gv_cnt_done.

  LOOP AT gt_contract INTO gs_contract.
    gv_cnt_all = gv_cnt_all + 1.
    IF gs_contract-light = '1'.
      gv_cnt_req = gv_cnt_req + 1.
    ELSEIF gs_contract-light = '2'.
      gv_cnt_prg = gv_cnt_prg + 1.
    ELSEIF gs_contract-light = '3'.
      gv_cnt_done = gv_cnt_done + 1.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_exclude_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_exclude_contract.

  CLEAR gt_exclude_contract.

  APPEND cl_gui_alv_grid=>mc_fc_detail    TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_find      TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_find_more TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_sum       TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_subtot    TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_print     TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_mb_view      TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_graph     TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_info      TO gt_exclude_contract.
  APPEND cl_gui_alv_grid=>mc_fc_refresh   TO gt_exclude_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_contract
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler_contract .
  SET HANDLER lcl_handler=>on_hotspot_click FOR go_alv_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_contract_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_contract_detail .
  CLEAR gv_due_label.
  IF gs_detail-stage_tx = '선수금 청구 대기'.
    gv_due_label = '청구 기한'.
  ELSEIF gs_detail-stage_tx = '선수금 입금 대기'
      OR gs_detail-stage_tx = '잔금 입금 대기'.
    gv_due_label = '입금 기한'.
  ENDIF.
  CONCATENATE gs_detail-stage_tx ' (' gs_detail-dept_tx ')'
    INTO gv_stage_disp.

  PERFORM get_customer_detail.
  PERFORM make_payment_detail.
  PERFORM set_cell_style_payment.   "셀당 핫스팟 관리.
  PERFORM get_item_detail.

  CALL SCREEN 0200.

  "상세에서 청구하기로 청구했을 수도 있으니 돌아오면 새로고침하기.
  PERFORM refresh_alv_contract.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_customer_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_customer_detail .
  CLEAR: gs_customer, gv_address.

  SELECT SINGLE *
    FROM z8customer_m
    WHERE kunnr = @gs_detail-kunnr
    INTO @gs_customer.

  CONCATENATE gs_customer-pstlz gs_customer-ort01 gs_customer-stras
    INTO gv_address SEPARATED BY space.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_payment_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_payment_detail. "입금내역 - 선수금/ 잔금.

  DATA: lv_dp_bill TYPE z8sd_billing_h-netwr.

  CLEAR gt_payment.

  "1. 선수금 줄
  CLEAR gs_payment.
  gs_payment-kind_tx = '선수금'.
  gs_payment-waerk   = gs_detail-waerk.

  IF gs_detail-dp_vbeln IS NOT INITIAL.
    gs_payment-vbeln    = gs_detail-dp_vbeln.
    gs_payment-fkdat    = gs_detail-dp_fkdat.
    gs_payment-zduedat  = gs_detail-dp_duedat.
    gs_payment-zpaydat  = gs_detail-dp_paydat.
    gs_payment-belnr    = gs_detail-dp_belnr.
    gs_payment-bill_amt = gs_detail-dp_amt.
    gs_payment-gjahr    = gs_detail-dp_gjahr.

    IF gs_detail-dp_payst = '02'.
      gs_payment-pay_tx   = '입금완료'.
      gs_payment-paid_amt = gs_detail-dp_amt.
    ELSE.
      gs_payment-pay_tx   = '미입금'.
    ENDIF.
  ELSE.
    gs_payment-pay_tx   = '청구예정'.
    gs_payment-bill_amt = gs_detail-netwr * '0.3'.     " 청구 예정액
  ENDIF.

  gs_payment-rest_amt = gs_payment-bill_amt - gs_payment-paid_amt.
  lv_dp_bill = gs_payment-bill_amt.
  APPEND gs_payment TO gt_payment.

  "2. 잔금 줄
  CLEAR gs_payment.
  gs_payment-kind_tx = '잔금'.
  gs_payment-waerk   = gs_detail-waerk.

  IF gs_detail-bal_vbeln IS NOT INITIAL.
    gs_payment-vbeln    = gs_detail-bal_vbeln.
    gs_payment-fkdat    = gs_detail-bal_fkdat.
    gs_payment-zduedat  = gs_detail-bal_duedat.
    gs_payment-zpaydat  = gs_detail-bal_paydat.
    gs_payment-belnr    = gs_detail-bal_belnr.
    gs_payment-bill_amt = gs_detail-bal_amt.
    gs_payment-gjahr    = gs_detail-bal_gjahr.

    IF gs_detail-bal_payst = '02'.
      gs_payment-pay_tx   = '입금완료'.
      gs_payment-paid_amt = gs_detail-bal_amt.
    ELSE.
      gs_payment-pay_tx   = '미입금'.
    ENDIF.
  ELSE.
    gs_payment-pay_tx   = '미청구'.
    gs_payment-bill_amt = gs_detail-netwr - lv_dp_bill.  " 청구 예정액
  ENDIF.

  gs_payment-rest_amt = gs_payment-bill_amt - gs_payment-paid_amt.
  APPEND gs_payment TO gt_payment.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_item_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_item_detail. "견적품목+운송비,설치비.

  DATA: lt_quot_i TYPE TABLE OF z8sd_quotation_i,
        ls_quot_i TYPE z8sd_quotation_i,
        lv_posnr  TYPE z8sd_quotation_i-posnr.

  CLEAR: gt_item, lv_posnr.

  SELECT *
    FROM z8sd_quotation_i
    WHERE vbeln_q = @gs_detail-vbeln_q
    ORDER BY posnr
    INTO TABLE @lt_quot_i.

  LOOP AT lt_quot_i INTO ls_quot_i.
    CLEAR gs_item.
    MOVE-CORRESPONDING ls_quot_i TO gs_item.
    gs_item-waerk = gs_detail-waerk.
    APPEND gs_item TO gt_item.
    lv_posnr = ls_quot_i-posnr.
  ENDLOOP.

  "운송비
  IF gs_detail-transit > 0.
    CLEAR gs_item.
    lv_posnr = lv_posnr + 10.
    gs_item-posnr  = lv_posnr.
    gs_item-matnr  = 'SVC-TRANS'.
    gs_item-arktx  = '운송비'.
    gs_item-kwmeng = 1.
    gs_item-vrkme  = 'EA'.
    gs_item-netwr  = gs_detail-transit.
    gs_item-netpr  = gs_detail-transit.
    gs_item-waerk  = gs_detail-waerk.
    APPEND gs_item TO gt_item.
  ENDIF.

  "설치비
  IF gs_detail-install > 0.
    CLEAR gs_item.
    lv_posnr = lv_posnr + 10.
    gs_item-posnr  = lv_posnr.
    gs_item-matnr  = 'SVC-INST'.
    gs_item-arktx  = '설치비'.
    gs_item-kwmeng = 1.
    gs_item-vrkme  = 'EA'.
    gs_item-netwr  = gs_detail-install.
    gs_item-netpr  = gs_detail-install.
    gs_item-waerk  = gs_detail-waerk.
    APPEND gs_item TO gt_item.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_detail .
  CREATE OBJECT go_cont_payment
    EXPORTING
      container_name = 'P_ALV'.
  CREATE OBJECT go_alv_payment
    EXPORTING
      i_parent = go_cont_payment.

  CREATE OBJECT go_cont_item
    EXPORTING
      container_name = 'I_ALV'.
  CREATE OBJECT go_alv_item
    EXPORTING
      i_parent = go_cont_item.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout_detail .
  CLEAR gs_layout_payment.
  gs_layout_payment-zebra      = 'X'.
*  gs_layout_payment-cwidth_opt = 'X'.
  gs_layout_payment-no_toolbar = 'X'.
  gs_layout_payment-stylefname = 'CT'.
  gs_layout_payment-grid_title = '입금 내역'.

  CLEAR gs_layout_item.
  gs_layout_item-zebra      = 'X'.
*  gs_layout_item-cwidth_opt = 'X'.
  gs_layout_item-no_toolbar = 'X'.
  gs_layout_item-grid_title = '계약 품목'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_payment
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_payment .
  CLEAR gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'KIND_TX'.
  gw_fcat_payment-coltext   = '구분'.
  gw_fcat_payment-outputlen = 8.
  gw_fcat_payment-key = 'X'.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'VBELN'.
  gw_fcat_payment-coltext   = '청구번호'.
  gw_fcat_payment-outputlen = 12.
*  gw_fcat_payment-hotspot    = 'X'.
  gw_fcat_payment-key = 'X'.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'FKDAT'.
  gw_fcat_payment-coltext   = '청구일'.
  gw_fcat_payment-datatype  = 'DATS'.
  gw_fcat_payment-outputlen = 11.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'ZDUEDAT'.
  gw_fcat_payment-coltext   = '입금기한'.
  gw_fcat_payment-datatype  = 'DATS'.
  gw_fcat_payment-outputlen = 11.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'PAY_TX'.
  gw_fcat_payment-coltext   = '입금상태'.
  gw_fcat_payment-outputlen = 10.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'ZPAYDAT'.
  gw_fcat_payment-coltext   = '입금일'.
  gw_fcat_payment-datatype  = 'DATS'.
  gw_fcat_payment-outputlen = 12.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'BELNR'.
  gw_fcat_payment-coltext   = '전표번호'.
  gw_fcat_payment-outputlen = 12.
*  gw_fcat_payment-hotspot    = 'X'.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname  = 'BILL_AMT'.
  gw_fcat_payment-coltext    = '청구금액'.
  gw_fcat_payment-cfieldname = 'WAERK'.
  gw_fcat_payment-datatype   = 'CURR'.
  gw_fcat_payment-do_sum     = 'X'.
  gw_fcat_payment-outputlen = 15.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname  = 'PAID_AMT'.
  gw_fcat_payment-coltext    = '입금액'.
  gw_fcat_payment-cfieldname = 'WAERK'.
  gw_fcat_payment-datatype   = 'CURR'.
  gw_fcat_payment-do_sum     = 'X'.
  gw_fcat_payment-outputlen = 15.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname  = 'REST_AMT'.
  gw_fcat_payment-coltext    = '잔액'.
  gw_fcat_payment-cfieldname = 'WAERK'.
  gw_fcat_payment-datatype   = 'CURR'.
  gw_fcat_payment-do_sum     = 'X'.
*  gw_fcat_payment-emphasize  = 'C311'.
  gw_fcat_payment-outputlen = 15.
  APPEND gw_fcat_payment TO gt_fcat_payment.

  CLEAR gw_fcat_payment.
  gw_fcat_payment-fieldname = 'WAERK'.
  gw_fcat_payment-coltext   = '통화'.
*  gw_fcat_payment-no_out    = 'X'.
  APPEND gw_fcat_payment TO gt_fcat_payment.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_item.

  CLEAR gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname = 'POSNR'.
  gw_fcat_item-coltext   = '품목'.
  gw_fcat_item-outputlen = 6.
  gw_fcat_item-just      = 'C'.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname = 'MATNR'.
  gw_fcat_item-coltext   = '자재코드'.
  gw_fcat_item-outputlen = 14.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname = 'ARKTX'.
  gw_fcat_item-coltext   = '품목명'.
  gw_fcat_item-outputlen = 30.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname = 'PLACE_TYPE'.
  gw_fcat_item-coltext   = '설치장소'.
  gw_fcat_item-outputlen = 22.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname  = 'KWMENG'.
  gw_fcat_item-coltext    = '수량'.
  gw_fcat_item-qfieldname = 'VRKME'.
  gw_fcat_item-datatype   = 'QUAN'.
  gw_fcat_item-decimals_o = '0'.
  gw_fcat_item-outputlen  = 10.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname = 'VRKME'.
  gw_fcat_item-coltext   = '단위'.
  gw_fcat_item-outputlen = 6.
  gw_fcat_item-just      = 'C'.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname  = 'NETPR'.
  gw_fcat_item-coltext    = '단가'.
  gw_fcat_item-cfieldname = 'WAERK'.
  gw_fcat_item-datatype   = 'CURR'.
  gw_fcat_item-outputlen  = 18.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname  = 'NETWR'.
  gw_fcat_item-coltext    = '금액'.
  gw_fcat_item-cfieldname = 'WAERK'.
  gw_fcat_item-datatype   = 'CURR'.
  gw_fcat_item-do_sum     = 'X'.
  gw_fcat_item-outputlen  = 20.
  APPEND gw_fcat_item TO gt_fcat_item.

  CLEAR gw_fcat_item.
  gw_fcat_item-fieldname = 'WAERK'.
  gw_fcat_item-coltext   = '통화'.
*  gw_fcat_item-no_out    = 'X'.
  gw_fcat_item-outputlen  = 6.
  APPEND gw_fcat_item TO gt_fcat_item.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_detail .
  CALL METHOD go_alv_payment->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_payment
    CHANGING
      it_outtab       = gt_payment
      it_fieldcatalog = gt_fcat_payment.

  CALL METHOD go_alv_item->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layout_item
    CHANGING
      it_outtab       = gt_item
      it_fieldcatalog = gt_fcat_item.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_control_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_control_detail .
  IF go_alv_payment IS NOT INITIAL.
    CALL METHOD go_alv_payment->free.
  ENDIF.
  IF go_cont_payment IS NOT INITIAL.
    CALL METHOD go_cont_payment->free.
  ENDIF.

  IF go_alv_item IS NOT INITIAL.
    CALL METHOD go_alv_item->free.
  ENDIF.
  IF go_cont_item IS NOT INITIAL.
    CALL METHOD go_cont_item->free.
  ENDIF.

  CLEAR: go_alv_payment, go_cont_payment, go_alv_item, go_cont_item.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form submit_billing
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM submit_billing .
  DATA: lv_cnt   TYPE i,
        lv_payst TYPE z8sd_billing_h-zzpayst,
        lv_msg   TYPE c LENGTH 100.
  "2. 단계 확인
  IF gs_contract-light = '3'.
    MESSAGE s082(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_contract-stage_tx <> '선수금 청구 대기'
 AND gs_contract-stage_tx <> '잔금 청구 대기'.
    CONCATENATE '청구 단계가 아닌 계약입니다. (현재:' gs_contract-stage_tx ')'
      INTO lv_msg SEPARATED BY space.
    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "3. 선수금 청구
  IF gs_contract-stage_tx = '선수금 청구 대기'.

    "DB 재확인: 그 사이 청구됐나
    SELECT COUNT(*)
      FROM z8sd_billing_h
      WHERE vgbel = @gs_contract-vbeln_q
        AND fkart = 'F1'
      INTO @lv_cnt.

    IF lv_cnt > 0.
      MESSAGE S141(Z8_MSG)  DISPLAY LIKE 'E'.
      PERFORM refresh_alv_contract.
      RETURN.
    ENDIF.

    "선수금 청구
    SUBMIT z8sdbi0100 WITH p_r1     = 'X'
                      WITH p_r2     = ' '
                      WITH s_vbelnq = gs_contract-vbeln_q
                      WITH s_qdat BETWEEN '19000101' AND '99991231'
                      AND RETURN.


    "4. 잔금 청구
  ELSE.

    "DB 재확인: 선수금 입금됐나
    SELECT SINGLE zzpayst
      FROM z8sd_billing_h
      WHERE vgbel = @gs_contract-vbeln_q
        AND fkart = 'F1'
      INTO @lv_payst.

    IF lv_payst <> '02'.
      MESSAGE S142(Z8_MSG)  DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    "DB 재확인: 그 사이 잔금 청구됐나
    SELECT COUNT(*)
      FROM z8sd_billing_h
      WHERE vgbel = @gs_contract-vbeln_s
        AND fkart = 'F2'
      INTO @lv_cnt.

    IF lv_cnt > 0.
      MESSAGE S141(Z8_MSG)  DISPLAY LIKE 'E'.
      PERFORM refresh_alv_contract.
      RETURN.
    ENDIF.

    "잔금 청구
    SUBMIT z8sdbi0100 WITH p_r1     = ' '
                      WITH p_r2     = 'X'
                      WITH s_vbelns = gs_contract-vbeln_s
                      WITH s_sdat BETWEEN '19000101' AND '99991231'
                      AND RETURN.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_billing_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM call_billing_detail .
  gs_contract = gs_detail.
  PERFORM submit_billing.

  "청구하고 돌아오면 상세 내용이 바뀌었으니 목록으로 복귀
  PERFORM free_control_detail.
  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_required
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_required .

  IF sy-ucomm <> 'ONLI' AND sy-ucomm <> 'SJOB'.
    RETURN.
  ENDIF.
"시작일, 종료일 모두 없음 -막기.
  IF s_audat[] IS INITIAL.
    SET CURSOR FIELD 'S_AUDAT-LOW'.
    MESSAGE E121(z8_msg)  WITH '견적일은'.
  ENDIF.

  "시작 없이 종료만 있음 - 막기
    IF s_audat-low IS INITIAL.
      SET CURSOR FIELD 'S_AUDAT-LOW'.
      MESSAGE E121(z8_msg) WITH '견적일은'.
    ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_billing_doc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_billing_doc .
  IF gs_payment-vbeln IS INITIAL.
    MESSAGE S122(z8_msg) DISPLAY LIKE 'E'  WITH '청구'.
    RETURN.
  ENDIF.

  SUBMIT z8sdbi0100 WITH p_detail = gs_payment-vbeln
                                      AND RETURN.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_fi_doc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_fi_doc .
  DATA: lv_bukrs TYPE z8sd_billing_h-bukrs VALUE '1000',
              lv_belnr TYPE z8sd_billing_h-belnr,
   	          lv_gjahr TYPE z8sd_billing_h-gjahr.

  IF  gs_payment-belnr IS INITIAL.
    MESSAGE S122(z8_msg) DISPLAY LIKE 'E' WITH '입금 처리'.
    RETURN.
  ENDIF.

  lv_belnr = gs_payment-belnr.
  lv_gjahr = gs_payment-gjahr.

  "FI 상세조회 프로그램에 전표 키 전달
    EXPORT bukrs = lv_bukrs
                    belnr = lv_belnr
                    gjahr = lv_gjahr
      TO MEMORY ID 'Z8FI_DETAIL_1200'.

    "FI 회계전표 상세조회
    CALL TRANSACTION 'Z8FIDR1200'.
    "이전에 전달한 전표번호가 남지 않게 하는 정리 작업
    FREE MEMORY ID 'Z8FI_DETAIL_1200'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler_detail .
  SET HANDLER lcl_handler=>on_hotspot_payment FOR go_alv_payment.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_cell_style_payment
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_cell_style_payment .
  DATA: ls_ct TYPE lvc_s_styl.

  LOOP AT gt_payment INTO gs_payment.

    CLEAR gs_payment-ct.

    "청구번호가 있는 줄만 청구번호 핫스팟.
    IF gs_payment-vbeln IS NOT INITIAL.
      CLEAR ls_ct.
      ls_ct-fieldname = 'VBELN'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.
      INSERT ls_ct INTO TABLE gs_payment-ct.
    ENDIF.

    "청구번호가 있는 줄만 청구번호 핫스팟.
    IF gs_payment-belnr IS NOT INITIAL.
      CLEAR ls_ct.
      ls_ct-fieldname = 'BELNR'.
      ls_ct-style = cl_gui_alv_grid=>mc_style_hotspot.
      INSERT ls_ct INTO TABLE gs_payment-ct.
    ENDIF.

    MODIFY gt_payment FROM gs_payment.

 ENDLOOP.

ENDFORM.
