*&---------------------------------------------------------------------*
*& Include          Z8MMGR100F03
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& 오류 등록 (S 메시지만 사용 : 화면 전환 → 암묵적 커밋 방지)
*&---------------------------------------------------------------------*
FORM set_error USING pv_step TYPE csequence.
  gv_err = 'X'.
  MESSAGE s231(z8_msg) WITH pv_step DISPLAY LIKE 'E'.
ENDFORM.

*&---------------------------------------------------------------------*
*& INVO 시작 전 초기화 (이전 실행 잔여 데이터 제거)
*&---------------------------------------------------------------------*
FORM init_invo .
  CLEAR : gv_err,
          gt_matdoc_h, gs_matdoc_h, gv_new_doc_mblnr,
          gt_po_hist,  gs_po_hist,
          gt_accdoc_h, gs_accdoc_h,
          gt_accdoc_i, gs_accdoc_i, gv_belnr.
ENDFORM.

*&---------------------------------------------------------------------*
*& INVO 실패 시 전체 취소
*& - 대기 내역(gt_matdoc_i)과 PO Lock은 유지 → 300번에서 재시도 가능
*&---------------------------------------------------------------------*
FORM rollback_invo .
  ROLLBACK WORK.
  PERFORM unlock_stk_val.
  CLEAR : gt_matdoc_h, gs_matdoc_h, gv_new_doc_mblnr,
          gt_po_hist,  gs_po_hist,
          gt_accdoc_h, gs_accdoc_h,
          gt_accdoc_i, gs_accdoc_i, gv_belnr.
ENDFORM.

FORM lock_po USING    pv_ebeln TYPE z8mm_po_h-ebeln
             CHANGING pv_subrc TYPE sy-subrc.

  IF line_exists( gt_locked_po[ table_line = pv_ebeln ] ).
    pv_subrc = 0.
    RETURN.
  ENDIF.

  CALL FUNCTION 'ENQUEUE_EZ8MM_PO'
    EXPORTING
      mode_z8mm_po_h = 'E'
      ebeln          = pv_ebeln
      _scope         = '1'          " 화면 간 유지 (명시적 해제 전까지)
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  pv_subrc = sy-subrc.

  CASE pv_subrc.
    WHEN 0.
      INSERT pv_ebeln INTO TABLE gt_locked_po.
    WHEN 1.
      " sy-msgv1 : 현재 Lock을 잡고 있는 사용자
      MESSAGE s228(z8_msg) WITH pv_ebeln sy-msgv1 DISPLAY LIKE 'E'.
    WHEN OTHERS.
      MESSAGE s229(z8_msg) DISPLAY LIKE 'E'.
  ENDCASE.
ENDFORM.

FORM unlock_po USING pv_ebeln TYPE z8mm_po_h-ebeln.
  CHECK line_exists( gt_locked_po[ table_line = pv_ebeln ] ).

  CALL FUNCTION 'DEQUEUE_EZ8MM_PO'
    EXPORTING
      mode_z8mm_po_h = 'E'
      ebeln          = pv_ebeln
      _scope         = '1'.

  DELETE TABLE gt_locked_po WITH TABLE KEY table_line = pv_ebeln.
ENDFORM.

FORM unlock_po_if_no_pending USING pv_ebeln TYPE z8mm_po_h-ebeln.
  IF NOT line_exists( gt_matdoc_i[ zzrefdoc = pv_ebeln ] ).
    PERFORM unlock_po USING pv_ebeln.
  ENDIF.
ENDFORM.

FORM lock_stk_val CHANGING pv_fail TYPE c.
  DATA ls_lock TYPE ty_stk_lock.

  CLEAR : pv_fail, gt_stk_lock.

  " 1. 대상 자재/플랜트/저장위치 중복 없이 추출
  LOOP AT gt_matdoc_i INTO gs_matdoc_i.
    ls_lock-matnr = gs_matdoc_i-matnr.
    ls_lock-werks = gs_matdoc_i-werks.
    ls_lock-lgort = gs_matdoc_i-lgort.
    INSERT ls_lock INTO TABLE gt_stk_lock.
  ENDLOOP.

  " 2. 재고 → 평가 순서로 Lock
  LOOP AT gt_stk_lock INTO ls_lock.
    CALL FUNCTION 'ENQUEUE_EZ8MATSTK'
      EXPORTING
        mode_z8material_stk_m = 'E'
        matnr                 = ls_lock-matnr
        werks                 = ls_lock-werks
        lgort                 = ls_lock-lgort
      EXCEPTIONS
        foreign_lock          = 1
        system_failure        = 2
        OTHERS                = 3.
    IF sy-subrc = 0.
      CALL FUNCTION 'ENQUEUE_EZ8MATVAL'
        EXPORTING
          mode_z8material_val_m = 'E'
          matnr                 = ls_lock-matnr
          bwkey                 = ls_lock-werks
        EXCEPTIONS
          foreign_lock          = 1
          system_failure        = 2
          OTHERS                = 3.
    ENDIF.

    IF sy-subrc <> 0.
      IF sy-subrc = 1.
        MESSAGE s230(z8_msg) WITH ls_lock-matnr ls_lock-werks sy-msgv1
                DISPLAY LIKE 'E'.
      ELSE.
        MESSAGE s229(z8_msg) DISPLAY LIKE 'E'.
      ENDIF.
      pv_fail = 'X'.
      PERFORM unlock_stk_val.
      RETURN.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM unlock_stk_val .
  DATA ls_lock TYPE ty_stk_lock.

  LOOP AT gt_stk_lock INTO ls_lock.
    CALL FUNCTION 'DEQUEUE_EZ8MATSTK'
      EXPORTING
        mode_z8material_stk_m = 'E'
        matnr                 = ls_lock-matnr
        werks                 = ls_lock-werks
        lgort                 = ls_lock-lgort.

    CALL FUNCTION 'DEQUEUE_EZ8MATVAL'
      EXPORTING
        mode_z8material_val_m = 'E'
        matnr                 = ls_lock-matnr
        bwkey                 = ls_lock-werks.
  ENDLOOP.
  CLEAR gt_stk_lock.
ENDFORM.

FORM unlock_all .
  CALL FUNCTION 'DEQUEUE_ALL'.
  CLEAR : gt_locked_po, gt_stk_lock.
ENDFORM.

FORM get_accdoc_h_no CHANGING p_accdoc_h_no.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'Z8FI_BELNR'
    IMPORTING
      number      = p_accdoc_h_no
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    PERFORM set_error USING '회계전표 채번'.     " LEAVE TO SCREEN 0 제거
  ENDIF.
ENDFORM.

FORM get_matdoc_h_index CHANGING p_lv_new_doc_no.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'Z8MATDOCH'
    IMPORTING
      number      = p_lv_new_doc_no
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    PERFORM set_error USING '자재문서 채번'.
  ENDIF.
ENDFORM.


FORM create_matdoc_h .
  PERFORM get_matdoc_h_index CHANGING gv_new_doc_mblnr.
  CHECK gv_err IS INITIAL.

  CLEAR : gt_matdoc_h, gs_matdoc_h.
  gs_matdoc_h-mblnr = gv_new_doc_mblnr.
  gs_matdoc_h-mjahr = sy-datum(4).
  gs_matdoc_h-bldat = sy-datum.
  gs_matdoc_h-budat = sy-datum.
  APPEND gs_matdoc_h TO gt_matdoc_h.

  INSERT z8mm_matdoc_h FROM TABLE gt_matdoc_h ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    PERFORM set_error USING '자재문서 헤더 생성'.
  ENDIF.
ENDFORM.

FORM alloc_matdoc_i .
  DATA : lt_insert_data TYPE TABLE OF z8mm_matdoc_i.
  lt_insert_data = CORRESPONDING #( gt_matdoc_i ).

  LOOP AT lt_insert_data ASSIGNING FIELD-SYMBOL(<ls_data>).
    <ls_data>-mblnr = gv_new_doc_mblnr.
    <ls_data>-mjahr = gs_matdoc_h-mjahr.     " 헤더와 연도 일치
  ENDLOOP.

  INSERT z8mm_matdoc_i FROM TABLE lt_insert_data ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    PERFORM set_error USING '자재문서 품목 생성'.
  ENDIF.
ENDFORM.

FORM update_procstat .
  DATA : lt_po_list     TYPE TABLE OF z8e_ebeln,
         lv_ebeln       TYPE z8e_ebeln,
         ls_po_h        TYPE z8mm_po_h,
         ls_po_i        TYPE z8mm_po_i,
         lv_ebelp       TYPE z8mm_po_i-ebelp,
         lv_zetc        TYPE z8mm_matdoc_i-zetc,
         lv_cur_sum     TYPE z8mm_matdoc_i-menge,
         lv_inv_sum     TYPE z8mm_matdoc_i-menge,
         lv_uncompleted TYPE c.

  " 1. PO_I : 납품완료지시자(ELIKZ)
  LOOP AT gt_matdoc_i INTO gs_matdoc_i.
    lv_ebelp = gs_matdoc_i-zetc.

    SELECT SINGLE * INTO ls_po_i
      FROM z8mm_po_i
     WHERE ebeln = gs_matdoc_i-zzrefdoc
       AND ebelp = lv_ebelp
       AND matnr = gs_matdoc_i-matnr.
    IF sy-subrc <> 0.
      PERFORM set_error USING '구매오더 품목 조회'. RETURN.
    ENDIF.

    lv_zetc = |{ ls_po_i-ebelp ALPHA = OUT }|.
    SELECT SUM( CASE WHEN mblnr =  @gs_matdoc_h-mblnr THEN menge ELSE 0 END ),
           SUM( CASE WHEN mblnr <> @gs_matdoc_h-mblnr THEN menge ELSE 0 END )
      INTO ( @lv_cur_sum, @lv_inv_sum )
      FROM z8mm_matdoc_i
     WHERE matnr    = @gs_matdoc_i-matnr
       AND zzrefdoc = @ls_po_i-ebeln
       AND zetc     = @lv_zetc
       AND werks    = @ls_po_i-werks
       AND ( bwart = '105' OR bwart = '301' ).

    IF lv_inv_sum + lv_cur_sum >= ls_po_i-menge.
      ls_po_i-elikz = 'X'.
    ELSE.
      ls_po_i-elikz = space.
    ENDIF.

    UPDATE z8mm_po_i FROM ls_po_i.
    IF sy-subrc <> 0.
      PERFORM set_error USING '구매오더 품목 상태 변경'. RETURN.
    ENDIF.

    APPEND ls_po_i-ebeln TO lt_po_list.
  ENDLOOP.

  " 2. PO_H : 진행 상태(PROCSTAT)
  SORT lt_po_list.
  DELETE ADJACENT DUPLICATES FROM lt_po_list.

  LOOP AT lt_po_list INTO lv_ebeln.
    SELECT SINGLE * INTO ls_po_h FROM z8mm_po_h WHERE ebeln = lv_ebeln.
    IF sy-subrc <> 0.
      PERFORM set_error USING '구매오더 헤더 조회'. RETURN.
    ENDIF.

    CLEAR lv_uncompleted.
    SELECT SINGLE 'X' INTO @lv_uncompleted
      FROM z8mm_po_i
     WHERE ebeln = @lv_ebeln
       AND elikz <> 'X'.

    ls_po_h-procstat = COND #( WHEN sy-subrc = 0 THEN '15' ELSE '20' ).

    UPDATE z8mm_po_h FROM ls_po_h.
    IF sy-subrc <> 0.
      PERFORM set_error USING '구매오더 헤더 상태 변경'. RETURN.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM update_po_hist .
  DATA : lv_po_i       TYPE z8mm_po_i,
         lv_ebelp      TYPE z8mm_po_i-ebelp.

  CLEAR gt_po_hist.

  LOOP AT gt_matdoc_i INTO gs_matdoc_i.
    lv_ebelp = gs_matdoc_i-zetc.

    SELECT SINGLE * INTO lv_po_i
      FROM z8mm_po_i
     WHERE ebeln = gs_matdoc_i-zzrefdoc
       AND ebelp = lv_ebelp
       AND matnr = gs_matdoc_i-matnr.
    IF sy-subrc <> 0.
      PERFORM set_error USING '구매오더 이력 대상 조회'. RETURN.
    ENDIF.

    CLEAR gs_po_hist.
    gs_po_hist-ebeln = lv_po_i-ebeln.
    gs_po_hist-ebelp = lv_po_i-ebelp.
    gs_po_hist-zekkn = '00'.
    gs_po_hist-vgabe = 1.
    gs_po_hist-gjahr = gs_matdoc_h-mjahr.
    gs_po_hist-belnr = gv_new_doc_mblnr.
    gs_po_hist-buzei = gs_matdoc_i-zeile.
    gs_po_hist-bewtp = 'E'.
    gs_po_hist-budat = sy-datum.
    gs_po_hist-waers = lv_po_i-waers.
    gs_po_hist-meins = lv_po_i-meins.
    gs_po_hist-bwart = gs_matdoc_i-bwart.
    gs_po_hist-menge = gs_matdoc_i-menge.
    gs_po_hist-wrbtr = gs_matdoc_i-wrbtr.    " 자재문서 금액 그대로

    CASE gs_matdoc_i-bwart.
      WHEN '105'. gs_po_hist-shkzg = 'S'.
      WHEN '124'. gs_po_hist-shkzg = 'H'.
    ENDCASE.

    APPEND gs_po_hist TO gt_po_hist.
  ENDLOOP.

  CHECK gt_po_hist IS NOT INITIAL.
  INSERT z8mm_po_hist FROM TABLE gt_po_hist ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    PERFORM set_error USING '구매오더 이력 생성'.
  ENDIF.
ENDFORM.

FORM create_accdoc_h .
  DATA :
    lv_bukrs    TYPE bukrs.
  lv_bukrs = '1000'.

  CLEAR gs_accdoc_h.
  gs_accdoc_h-bukrs = lv_bukrs.              " 회사 코드
  gs_accdoc_h-belnr = gv_belnr.      " 회계 전표 번호

  gs_accdoc_h-gjahr = sy-datum(4).        " 연도
  gs_accdoc_h-monat = sy-datum+4(2).  " 월

  gs_accdoc_h-blart = 'WE'.                      " 전표 유형 (WE : 입고)
  gs_accdoc_h-bldat = sy-datum.              " 증빙일

  " 전기일
  gs_accdoc_h-budat = gs_po_hist-budat.

  gs_accdoc_h-waers = gs_po_hist-waers. " 통화
*  gs_accdoc_h-stblg = .
  gs_accdoc_h-xblnr = gs_matdoc_h-mblnr. " 참조번호(자재문서 번호)
  APPEND gs_accdoc_h TO gt_accdoc_h.
ENDFORM.

FORM create_accdoc_i .
  DATA :
    lv_buzei   TYPE buzei,
    ls_po_info TYPE z8mm_po_i,
    lv_lifnr   TYPE lifnr,
    lv_bupla   TYPE bupla.

  SELECT MAX( buzei )
    INTO lv_buzei
  FROM z8fi_accdoc_i
  WHERE belnr = gv_belnr.


  IF lv_buzei IS INITIAL.
    lv_buzei = 0.
  ENDIF.

  LOOP AT gt_matdoc_i INTO gs_matdoc_i.
*  LOOP AT gt_matdoc_d INTO gs_matdoc_d.

    " 1. 회계전표 생성 대상 이동유형인지 체크
    IF gs_matdoc_i-bwart <> '105'. "AND gs_matdoc_i-bwart = '301'.
      CONTINUE.
    ENDIF.

    " 구매 오더 품목 가져오기
    DATA lv_ebelp TYPE z8mm_po_i-ebelp.
    lv_ebelp = gs_matdoc_i-zetc.

    CLEAR ls_po_info.
    SELECT SINGLE *
      INTO @ls_po_info
      FROM z8mm_po_i
     WHERE ebeln = @gs_matdoc_i-zzrefdoc
       AND ebelp = @lv_ebelp
       AND matnr = @gs_matdoc_i-matnr.
    IF sy-subrc <> 0.
      PERFORM set_error USING '회계전표 대상 조회'. RETURN.
    ENDIF.

    " 구매 오더에 대한 공급처 정보 가져오기
    SELECT SINGLE lifnr
      INTO lv_lifnr
      FROM z8mm_po_h
      WHERE ebeln = ls_po_info-ebeln.

    " 차후 오류가 될 수 있는 코드
    " 원래는 여러 플랜트(werks)에 하나의 지사(buplan)가 있을 수 있지만 다행히 우리 시나리오에서는 무조건 하나이다.
    SELECT SINGLE bupla
      INTO lv_bupla
    FROM z8plant_m
    WHERE werks = ls_po_info-werks.

    " ========================================================================
    " [라인 1] 차변 (S : Debit) - 자재(재고자산) 계정
    " ========================================================================
    ADD 1 TO lv_buzei.
    CLEAR gs_accdoc_i.
    gs_accdoc_i-bukrs = gs_accdoc_h-bukrs.
    gs_accdoc_i-belnr = gs_accdoc_h-belnr.
    gs_accdoc_i-gjahr = gs_accdoc_h-gjahr.
    gs_accdoc_i-buzei = lv_buzei.
    gs_accdoc_i-koart = 'S'. "계정 유형
    gs_accdoc_i-hkont = '14100000'.
    gs_accdoc_i-bupla = lv_bupla. "Branch Code (z8plant_m의 werks를 보는 중 -> bupla로 바꾸자)
    gs_accdoc_i-shkzg = 'S'.
    gs_accdoc_i-wrbtr = gs_matdoc_i-wrbtr.
*    gs_accdoc_i-wrbtr = gs_matdoc_d-wrbtr.
    gs_accdoc_i-waers = ls_po_info-waers.
    " gs_accdoc_i-kostl = ''. "비용 센터
    "gs_accdoc_i-prctr = ''. "손익센터
    gs_accdoc_i-kunnr = ''. "Customer ID
    "gs_accdoc_i-lifnr = lv_lifnr.
    APPEND gs_accdoc_i TO gt_accdoc_i.

    " ========================================================================
    " [라인 2] 대변 (H : Credit) - GR/IR (입고/송장 가계정)
    " ========================================================================
    ADD 1 TO lv_buzei.
    CLEAR gs_accdoc_i.
    gs_accdoc_i-bukrs = gs_accdoc_h-bukrs.
    gs_accdoc_i-belnr = gs_accdoc_h-belnr.
    gs_accdoc_i-gjahr = gs_accdoc_h-gjahr.
    gs_accdoc_i-buzei = lv_buzei.
    gs_accdoc_i-koart = 'S'. "계정 유형
    gs_accdoc_i-hkont = '21900100'. " gr/ir
    gs_accdoc_i-bupla = lv_bupla. "Branch Code
    gs_accdoc_i-shkzg = 'H'.
    gs_accdoc_i-wrbtr = gs_matdoc_i-wrbtr.
*    gs_accdoc_i-wrbtr = gs_matdoc_d-wrbtr.
    gs_accdoc_i-waers = ls_po_info-waers.
    " gs_accdoc_i-kostl = ''. "비용 센터
    "gs_accdoc_i-prctr = ''. "손익센터
    gs_accdoc_i-kunnr = ''. "Customer ID
    "gs_accdoc_i-lifnr = lv_lifnr.
    APPEND gs_accdoc_i TO gt_accdoc_i.
  ENDLOOP.


  INSERT z8fi_accdoc_h FROM TABLE gt_accdoc_h ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    PERFORM set_error USING '회계전표 헤더 생성'. RETURN.
  ENDIF.

  " 105가 없으면(반품만) 품목이 없을 수 있음
  CHECK gt_accdoc_i IS NOT INITIAL.

  INSERT z8fi_accdoc_i FROM TABLE gt_accdoc_i ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    PERFORM set_error USING '회계전표 품목 생성'.
  ENDIF.
ENDFORM.

FORM get_mat_data .
  IF gt_matdoc_i IS INITIAL.
    "MESSAGE S135(z8_MSG) DISPLAY LIKE 'E'.
    "CLEAR : gt_po_i, gs_po_i.
    LEAVE TO SCREEN 0.
  ENDIF.

  LOOP AT gt_matdoc_i ASSIGNING FIELD-SYMBOL(<fs_po>).

    " 자재 이름 넣기
    SELECT SINGLE maktx, v~name1 AS sup_name, p~name1 AS plant_name
      FROM z8mm_po_i AS poi
        INNER JOIN z8mm_po_h AS poh ON poi~ebeln = poh~ebeln
        INNER JOIN z8material_txt_m AS m ON m~matnr = poi~matnr
        INNER JOIN z8plant_m AS p ON poi~werks = p~werks
        INNER JOIN z8vendor_m AS v ON v~lifnr = poh~lifnr
     WHERE poi~matnr = @<fs_po>-matnr
          AND spras = @sy-langu
          AND poi~ebeln = @<fs_po>-zzrefdoc
        AND poi~ebelp    = @<fs_po>-zetc
      INTO (@<fs_po>-maktx, @<fs_po>-sup_name, @<fs_po>-plant_name).


    CASE <fs_po>-bwart.
      WHEN '105'." OR '301'.
        <fs_po>-inv_ret = '입고 예정'.
      WHEN '124'." OR '302'.
        <fs_po>-inv_ret = '반품 예정'.
    ENDCASE.

    MODIFY gt_matdoc_i FROM <fs_po>.
  ENDLOOP.
ENDFORM.

FORM update_mat_stk_val .
  DATA : ls_po_i  TYPE z8mm_po_i,
         ls_stk_m TYPE z8material_stk_m,
         ls_val_m TYPE z8material_val_m.

  LOOP AT gt_po_hist INTO gs_po_hist.

    " 1. PO 품목
    CLEAR ls_po_i.
    SELECT SINGLE * INTO CORRESPONDING FIELDS OF ls_po_i
      FROM z8mm_po_i
     WHERE ebeln = gs_po_hist-ebeln
       AND ebelp = gs_po_hist-ebelp.
    IF sy-subrc <> 0.
      PERFORM set_error USING '재고 대상 조회'. RETURN.
    ENDIF.

    " 2. 재고 수량
    CLEAR ls_stk_m.
    SELECT SINGLE * INTO ls_stk_m
      FROM z8material_stk_m
     WHERE matnr = ls_po_i-matnr
       AND werks = ls_po_i-werks
       AND lgort = ls_po_i-lgort.
    IF sy-subrc <> 0.
      ls_stk_m-matnr = ls_po_i-matnr.
      ls_stk_m-werks = ls_po_i-werks.
      ls_stk_m-lgort = ls_po_i-lgort.
      ls_stk_m-meins = 'EA'.
      INSERT z8material_stk_m FROM ls_stk_m.
      IF sy-subrc <> 0.
        PERFORM set_error USING '재고 레코드 생성'. RETURN.
      ENDIF.
    ENDIF.

    IF gs_po_hist-shkzg = 'S'.
      ls_stk_m-labst = ls_stk_m-labst + gs_po_hist-menge.
    ENDIF.

    UPDATE z8material_stk_m FROM ls_stk_m.
    IF sy-subrc <> 0.
      PERFORM set_error USING '재고 수량 변경'. RETURN.
    ENDIF.

    " 3. 평가
    CLEAR ls_val_m.
    SELECT SINGLE * INTO ls_val_m
      FROM z8material_val_m
     WHERE matnr = ls_po_i-matnr
       AND bwkey = ls_po_i-werks.
    IF sy-subrc <> 0.
      ls_val_m-matnr   = ls_po_i-matnr.
      ls_val_m-bwkey   = ls_po_i-werks.
      ls_val_m-vprsv   = 'V'.
      ls_val_m-zzdrcls = 14100000.
      ls_val_m-waers   = ls_po_i-waers.
      ls_val_m-meins   = ls_po_i-meins.
      PERFORM get_peinh USING ls_po_i-matnr CHANGING ls_val_m-peinh.
      INSERT z8material_val_m FROM ls_val_m.
      IF sy-subrc <> 0.
        PERFORM set_error USING '평가 레코드 생성'. RETURN.
      ENDIF.
    ENDIF.

    PERFORM get_peinh USING ls_po_i-matnr CHANGING ls_val_m-peinh.

    IF gs_po_hist-shkzg = 'S'.
      ls_val_m-salk3 = ls_val_m-salk3 + gs_po_hist-wrbtr.
      ls_val_m-lbkum = ls_val_m-lbkum + gs_po_hist-menge.
    ENDIF.

    IF ls_val_m-lbkum > 0.
      ls_val_m-verpr = ls_val_m-salk3 / ls_val_m-lbkum * ls_val_m-peinh.
    ELSE.
      ls_val_m-verpr = 0.
    ENDIF.

    UPDATE z8material_val_m FROM ls_val_m.
    IF sy-subrc <> 0.
      PERFORM set_error USING '재고 평가 변경'. RETURN.
    ENDIF.
  ENDLOOP.
ENDFORM.
