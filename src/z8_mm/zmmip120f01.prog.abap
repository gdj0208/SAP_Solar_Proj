*&---------------------------------------------------------------------*
*& Include          ZMMGR030F01
*&---------------------------------------------------------------------*

FORM change_field_catalog USING    pv_structure   TYPE csequence
                                   pv_keep_fields TYPE csequence
                                   pv_coltexts    TYPE csequence  " 컬럼 텍스트용 인자 추가
                          CHANGING pt_fcat        TYPE lvc_t_fcat.

  DATA: lt_fields TYPE TABLE OF string,
        lt_texts  TYPE TABLE OF string,
        lv_field  TYPE string,
        lv_text   TYPE string,
        lv_tabix  TYPE sy-tabix,
        ls_fcat   TYPE lvc_s_fcat.

  " 1. 입력받은 필드명과 컬럼 텍스트를 콤마(,)를 기준으로 분리하여 배열(Internal Table)에 저장
  SPLIT pv_keep_fields AT ',' INTO TABLE lt_fields.
  SPLIT pv_coltexts    AT ',' INTO TABLE lt_texts.

  " 2. 분리된 필드명 테이블을 기준으로 LOOP를 돌며 필드 카탈로그 구성
  LOOP AT lt_fields INTO lv_field.
    lv_tabix = sy-tabix.

    CLEAR ls_fcat.

    " 2-1. Field Name (공백 제거)
    CONDENSE lv_field NO-GAPS.
    TRANSLATE lv_field TO UPPER CASE.
    ls_fcat-fieldname = lv_field.

    " 2-2. Reference Table
    ls_fcat-ref_table = pv_structure.
    TRANSLATE ls_fcat-ref_table TO UPPER CASE.

    " 2-3. Reference Field (구조체-필드명 형태로 연결)
    "ls_fcat-ref_field = |{ pv_structure }-{ lv_field }|.
    ls_fcat-ref_field = lv_field.

    " 2-4. Column Text (순번에 맞춰 텍스트를 가져오되, 부족할 경우 필드명을 그대로 사용)
    READ TABLE lt_texts INTO lv_text INDEX lv_tabix.
    IF sy-subrc = 0.
      " CONDENSE lv_text NO-GAPS. " 양옆 공백이 있을 수 있으므로 제거
      ls_fcat-coltext = lv_text.
      ls_fcat-reptext   = lv_text.
    ELSE.
      ls_fcat-coltext = lv_field.
    ENDIF.
    " ls_fcat-col_opt = 'X'.

    " 2-5. Column Position (순번)
    ls_fcat-col_pos = lv_tabix.

    " 날짜 레이아웃
    IF lv_field = 'ESDAT' OR lv_field = 'BEDAT'.
      ls_fcat-datatype = 'DATS'.
    ENDIF.

    IF lv_field = 'I_WRBTR' OR  lv_field = 'HIST_WRBTR' OR  lv_field = 'INV_WRBTR'.
      ls_fcat-cfieldname = 'WAERS'.
      ls_fcat-datatype   = 'CURR'.
      "ls_fcat-qfieldname = 'WAERS'.
    ENDIF.
    IF lv_field = 'I_MENGE' OR lv_field = 'HIST_MENGE' OR lv_field = 'INV_MENGE' .
      ls_fcat-qfieldname = 'MEINS'.
      ls_fcat-decimals_o = '0'.
    ENDIF.

    " 2-8. 컬럼 최소 출력 길이 강제 고정 [추가]
    ls_fcat-outputlen = 15.

    " 3. Field Catalog 테이블에 데이터 추가
    APPEND ls_fcat TO pt_fcat.
  ENDLOOP.

ENDFORM.

FORM get_data.
  " 1. 데이터 초기화
  CLEAR: gt_qunt_3comp, gt_amnt_3comp, gv_3cof, gv_wrbtr_un, gv_menge_un, gv_inv_err.

  " 2. 구매 오더(PO) 기본 데이터 조회
  SELECT po~ebeln, po~ebelp, mat~maktx AS maktx, p~name1 AS name1,
         po~menge AS i_menge, po~meins AS meins,
         po~netwr AS i_wrbtr, po~waers AS waers
    INTO TABLE @DATA(lt_po)
    FROM z8mm_po_i AS po
    LEFT JOIN z8material_txt_m AS mat ON po~matnr = mat~matnr AND mat~spras = @sy-langu
    LEFT JOIN z8plant_m AS p ON po~werks = p~werks
   WHERE po~ebeln = @gv_ebeln.

  " 3. PO History(입고) 내역 집계
  SELECT ebeln, ebelp, SUM( menge ) AS hist_menge, SUM( wrbtr ) AS hist_wrbtr
    INTO TABLE @DATA(lt_hist)
    FROM z8mm_po_hist
   WHERE ebeln = @gv_ebeln
     AND bwart IN ( '105', '301', '321' )
   GROUP BY ebeln, ebelp.

  " 4. 청구서 내역 집계 (메모리의 gt_inv_i 기준)
  TYPES: BEGIN OF ty_inv_agg,
           ebeln     TYPE ebeln,
           ebelp     TYPE ebelp,
           maktx     TYPE maktx,
           meins     TYPE meins,
           waers     TYPE waers,
           inv_menge TYPE menge_d,
           inv_wrbtr TYPE wrbtr,
           inv_no    TYPE z8mm_inv_i-inv_no,
         END OF ty_inv_agg.
  DATA: lt_inv     TYPE TABLE OF ty_inv_agg,
        ls_inv_agg TYPE ty_inv_agg.

  CLEAR lt_inv.
  LOOP AT gt_inv_i INTO gs_inv_i.
    ls_inv_agg-ebeln     = gs_inv_i-ebeln.
    ls_inv_agg-ebelp     = gs_inv_i-ebelp.
    ls_inv_agg-maktx     = gs_inv_i-maktx.
    ls_inv_agg-waers     = gs_inv_i-waers. " [추가] 메모리에 세팅된 KRW 가져오기
    ls_inv_agg-meins     = gs_inv_i-meins.
    ls_inv_agg-inv_menge = gs_inv_i-menge.
    ls_inv_agg-inv_wrbtr = gs_inv_i-wrbtr.
    ls_inv_agg-inv_no    = gs_inv_i-inv_no.
    COLLECT ls_inv_agg INTO lt_inv.
  ENDLOOP.

  " =====================================================================
  " 5. [핵심] PO와 청구서의 모든 아이템 키(EBELN, EBELP) 합집합 구하기
  " =====================================================================
  TYPES: BEGIN OF ty_all_items,
           ebeln TYPE ebeln,
           ebelp TYPE ebelp,
         END OF ty_all_items.
  DATA: lt_all_items TYPE TABLE OF ty_all_items,
        ls_all_item  TYPE ty_all_items.

  " PO에 있는 아이템 수집
  LOOP AT lt_po INTO DATA(ls_po_temp).
    ls_all_item-ebeln = ls_po_temp-ebeln.
    ls_all_item-ebelp = ls_po_temp-ebelp.
    COLLECT ls_all_item INTO lt_all_items.
  ENDLOOP.

  " 청구서에 있는 아이템 수집 (PO에 없는 아이템도 여기서 추가됨)
  LOOP AT lt_inv INTO DATA(ls_inv_temp).
    ls_all_item-ebeln = ls_inv_temp-ebeln.
    ls_all_item-ebelp = ls_inv_temp-ebelp.
    COLLECT ls_all_item INTO lt_all_items.
  ENDLOOP.


  " =====================================================================
  " 6. 통합 수집된 아이템을 기준으로 3-Way 매칭 데이터 조립
  " =====================================================================
  DATA: lt_3comp_agg TYPE TABLE OF ty_3comp.
  CLEAR lt_3comp_agg.

  LOOP AT lt_all_items INTO ls_all_item.
    DATA(ls_result) = VALUE ty_3comp( ebeln = ls_all_item-ebeln ).

    " 6-1. PO 데이터 매핑
    DATA(ls_po_read) = VALUE #( lt_po[ ebeln = ls_all_item-ebeln ebelp = ls_all_item-ebelp ] OPTIONAL ).
    IF ls_po_read IS NOT INITIAL.
      ls_result-maktx   = ls_po_read-maktx.
      ls_result-name1   = ls_po_read-name1.
      ls_result-i_menge = ls_po_read-i_menge.
      ls_result-i_wrbtr = ls_po_read-i_wrbtr.
      ls_result-meins   = ls_po_read-meins.
      ls_result-waers   = ls_po_read-waers.
    ENDIF.

    " 6-2. PO History (입고) 데이터 매핑
    DATA(ls_hist_read) = VALUE #( lt_hist[ ebeln = ls_all_item-ebeln ebelp = ls_all_item-ebelp ] OPTIONAL ).
    IF ls_hist_read IS NOT INITIAL.
      ls_result-hist_menge = ls_hist_read-hist_menge.
      ls_result-hist_wrbtr = ls_hist_read-hist_wrbtr.
    ENDIF.

    " 6-3. 청구서 데이터 매핑
    DATA(ls_inv_read) = VALUE #( lt_inv[ ebeln = ls_all_item-ebeln ebelp = ls_all_item-ebelp ] OPTIONAL ).
    IF ls_inv_read IS NOT INITIAL.
      ls_result-inv_menge = ls_inv_read-inv_menge.
      ls_result-inv_wrbtr = ls_inv_read-inv_wrbtr.
      ls_result-inv_no    = ls_inv_read-inv_no.

      " [수정] PO에 없는 아이템일 경우 자재명과 통화 빈칸 보정
      IF ls_result-maktx IS INITIAL.
        ls_result-maktx = ls_inv_read-maktx.
      ENDIF.
      IF ls_result-meins IS INITIAL.
        ls_result-meins = ls_inv_read-meins. " [추가] 구한 단위를 ALV로 전달
      ENDIF.
      IF ls_result-waers IS INITIAL.
        ls_result-waers = ls_inv_read-waers.
      ENDIF.
    ENDIF.

    " 서로 다른 2개의 pr, 하나의 po일 때 자재가 2번 나오는 것 방지
    ASSIGN COMPONENT 'EBELP' OF STRUCTURE ls_result TO FIELD-SYMBOL(<fs_ebelp>).
    IF sy-subrc = 0.
      CLEAR <fs_ebelp>.
    ENDIF.
    COLLECT ls_result INTO lt_3comp_agg.

*    DATA(ls_inv_read) = VALUE #( lt_inv[ ebeln = ls_all_item-ebeln ebelp = ls_all_item-ebelp ] OPTIONAL ).
*    IF ls_inv_read IS NOT INITIAL.
*      ls_result-inv_menge = ls_inv_read-inv_menge.
*      ls_result-inv_wrbtr = ls_inv_read-inv_wrbtr.
*      ls_result-inv_no    = ls_inv_read-inv_no.


    " PO에 없는 아이템이 청구서로 들어왔을 경우 자재명만이라도 표시되도록 보완
    IF ls_result-maktx IS INITIAL.
      ls_result-maktx = ls_inv_read-maktx.
    ENDIF.

    " 개별 검증 및 ALV 테이블 적재 호출
*    PERFORM append_amount_data   USING ls_result.
*    PERFORM append_quantity_data USING ls_result.
  ENDLOOP.

    " =====================================================================
  " 7. 합산이 완료된 데이터를 ALV 적재(Append) 로직으로 최종 전달
  " =====================================================================
  LOOP AT lt_3comp_agg INTO DATA(ls_agg).
    PERFORM append_amount_data   USING ls_agg.
    PERFORM append_quantity_data USING ls_agg.
  ENDLOOP.
ENDFORM.

" [Subroutine] 금액 데이터 일치 검증 및 테이블 적재
FORM append_amount_data USING is_data TYPE ty_3comp.
  DATA(ls_amnt) = is_data.

  " 1. 청구서를 안 불러왔을 경우 ('청구서 없음' 상태)
  IF gt_inv_i[] IS INITIAL.
    ls_amnt-amnt_light = '1'.       " 빨간불
    ls_amnt-uneq       = '청구서 없음'.
    gv_3cof            = 'X'.       " 확정 불가 플래그
    gv_wrbtr_un        = 'X'.

  " 2. 청구서를 불러왔을 때 상세 비교 진행
  ELSE.
    " 2-1. [불러오기 차단] 청구 금액(inv)이 입고 내역(hist)과 다를 때
    IF is_data-inv_wrbtr <> is_data-i_wrbtr.
      ls_amnt-amnt_light = '1'.       " 빨간불
      ls_amnt-uneq       = '청구 금액 불일치'.
      gv_3cof            = 'X'.       " 확정 불가
      gv_wrbtr_un        = 'X'.
      gv_inv_err         = 'X'.       " 청구서 불러오기를 막기 위한 전용 플래그 세팅

    " 2-2. [불러오기 허용, 확정 불가] 청구=입고 일치하나, 발주(i)와 입고(hist)가 다를 때
    ELSEIF is_data-i_wrbtr <> is_data-hist_wrbtr.
      ls_amnt-amnt_light = '2'.       " 노란불 (경고)
      ls_amnt-uneq       = '발주-입고 불일치'.
      gv_3cof            = 'X'.       " 최종 3-Way 일치가 아니므로 확정 불가
      gv_wrbtr_un        = 'X'.
      " (gv_inv_err는 'X'가 아니므로 청구서는 화면에 정상적으로 불려옴)

    " 2-3. [3-Way 완벽 일치] 발주 = 입고 = 청구
    ELSE.
      ls_amnt-amnt_light = '3'.       " 초록불
      ls_amnt-uneq       = '일치'.
    ENDIF.
  ENDIF.

  APPEND ls_amnt TO gt_amnt_3comp.
ENDFORM.


" [Subroutine] 수량 데이터 일치 검증 및 테이블 적재
FORM append_quantity_data USING is_data TYPE ty_3comp.
  DATA(ls_qunt) = is_data.

" 1. 청구서를 안 불러왔을 경우 ('청구서 없음' 상태)
  IF gt_inv_i[] IS INITIAL.
    ls_qunt-qunt_light = '1'.       " 빨간불
    ls_qunt-uneq       = '청구서 없음'.
    gv_3cof            = 'X'.       " 확정 불가 플래그
    gv_menge_un        = 'X'.

  " 2. 청구서를 불러왔을 때 상세 비교 진행
  ELSE.
    " 2-1. [불러오기 차단] 청구 수량(inv)이 입고 내역(hist)과 다를 때
    IF is_data-inv_menge <> is_data-i_menge.
      ls_qunt-qunt_light = '1'.       " 빨간불
      ls_qunt-uneq       = '청구 수량 불일치'.
      gv_3cof            = 'X'.       " 확정 불가
      gv_menge_un        = 'X'.
      gv_inv_err         = 'X'.       " ★ 신규: 청구서 불러오기를 막기 위한 전용 플래그 세팅

    " 2-2. [불러오기 허용, 확정 불가] 청구=입고 일치하나, 발주(i)와 입고(hist)가 다를 때
    ELSEIF is_data-i_menge <> is_data-hist_menge.
      ls_qunt-qunt_light = '2'.       " 노란불 (경고)
      ls_qunt-uneq       = '발주-입고 불일치'.
      gv_3cof            = 'X'.       " 최종 3-Way 일치가 아니므로 확정 불가
      gv_menge_un        = 'X'.
      " (gv_inv_err는 'X'가 아니므로 청구서는 화면에 정상적으로 불려옴)

    " 2-3. [3-Way 완벽 일치] 발주 = 입고 = 청구
    ELSE.
      ls_qunt-qunt_light = '3'.       " 초록불
      ls_qunt-uneq       = '일치'.
    ENDIF.
  ENDIF.

  APPEND ls_qunt TO gt_qunt_3comp.
ENDFORM.

FORM create_accdoc_i  USING p_invno.
  DATA :
    lv_buzei     TYPE buzei,
    ls_po_info   TYPE z8mm_po_i,
    lv_lifnr     TYPE lifnr,
    lv_bupla     TYPE bupla,
    lv_total_amt TYPE wrbtr.  " [추가] 총 금액을 담을 변수 선언

  " 전표 라인 번호 취득하기
  SELECT MAX( buzei )
    INTO lv_buzei
  FROM z8fi_accdoc_i
  WHERE belnr = gv_belnr.
  IF lv_buzei IS INITIAL.
    lv_buzei = 0.
  ENDIF.

  " 1. 청구서 아이템들 가져오기
  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE gt_inv_i
    FROM z8mm_inv_i
    WHERE ebeln = gv_ebeln
      AND inv_no = p_invno.

  " 2. 아이템 데이터가 존재하는 경우에만 헤더 조회 수행
  IF gt_inv_i IS NOT INITIAL.
    READ TABLE gt_inv_i INTO gs_inv_i INDEX 1.

    IF sy-subrc = 0.
      SELECT SINGLE *
        INTO gs_inv_h
        FROM z8mm_inv_h
        WHERE inv_no = gs_inv_i-inv_no.
    ENDIF.
  ENDIF.

  " ========================================================================
  " [금액 합산 로직] 여러 자재의 청구 금액을 하나의 변수에 모두 더함
  " ========================================================================
  CLEAR lv_total_amt.
  LOOP AT gt_inv_i INTO gs_inv_i.
    lv_total_amt = lv_total_amt + gs_inv_i-wrbtr.
  ENDLOOP.


  " 데이터가 있을 경우에만 차/대변 1건씩 전표 라인 생성
  IF lv_total_amt > 0.
    " ========================================================================
    " [라인 1] 차변 (S : Debit) - GR/IR 계정
    " ========================================================================
    ADD 1 TO lv_buzei.
    CLEAR gs_accdoc_i.
    gs_accdoc_i-bukrs = gs_accdoc_h-bukrs.
    gs_accdoc_i-belnr = gs_accdoc_h-belnr.
    gs_accdoc_i-gjahr = gs_accdoc_h-gjahr.
    gs_accdoc_i-buzei = lv_buzei.
    gs_accdoc_i-koart = 'S'.          " 계정 유형 (G/L)
    gs_accdoc_i-hkont = '21900100'.   " GR/IR 계정 (기존 재고 계정에서 GR/IR로 수정)
    gs_accdoc_i-bupla = gs_inv_h-bupla.
    gs_accdoc_i-shkzg = 'S'.          " 차변
    gs_accdoc_i-wrbtr = lv_total_amt. " 합산된 총 금액
    gs_accdoc_i-waers = gs_inv_i-waers.
    " GR/IR 계정이므로 공급처(LIFNR)는 넣지 않음
    APPEND gs_accdoc_i TO gt_accdoc_i.

    " ========================================================================
    " [라인 2] 대변 (H : Credit) - 외상매입금 (AP)
    " ========================================================================
    ADD 1 TO lv_buzei.
    CLEAR gs_accdoc_i.
    gs_accdoc_i-bukrs = gs_accdoc_h-bukrs.
    gs_accdoc_i-belnr = gs_accdoc_h-belnr.
    gs_accdoc_i-gjahr = gs_accdoc_h-gjahr.
    gs_accdoc_i-buzei = lv_buzei.
    gs_accdoc_i-koart = 'K'.          " 계정 유형 (Vendor)
    gs_accdoc_i-hkont = '21100000'.   " 외상매입금 계정
    gs_accdoc_i-bupla = gs_inv_h-bupla.
    gs_accdoc_i-shkzg = 'H'.          " 대변
    gs_accdoc_i-wrbtr = lv_total_amt. " 합산된 총 금액
    gs_accdoc_i-waers = gs_inv_i-waers.
    gs_accdoc_i-lifnr = gs_inv_h-lifnr. " 매입채무이므로 공급처 필수
    APPEND gs_accdoc_i TO gt_accdoc_i.
  ENDIF.

  " ========================================================================
  " [DB 저장]
  " ========================================================================
  INSERT z8fi_accdoc_h FROM TABLE gt_accdoc_h ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    " 헤더 저장 실패 시 예외 처리 로직
  ENDIF.

  INSERT z8fi_accdoc_i  FROM TABLE gt_accdoc_i ACCEPTING DUPLICATE KEYS.
  IF sy-subrc <> 0.
    " 아이템 저장 실패 시 예외 처리 로직
  ENDIF.

ENDFORM.

MODULE load_gv_ebeln INPUT.
  GET PARAMETER ID 'EBELN' FIELD gv_ebeln.
ENDMODULE.

FORM create_accdoc_h USING p_accdoc_h_no.
  DATA :
    lv_bukrs    TYPE bukrs.

  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF gs_inv_h
  FROM z8mm_inv_h AS h
    INNER JOIN z8mm_inv_i AS i ON h~inv_no = i~inv_no
  WHERE ebeln = gv_ebeln
    AND h~loekz = ''.

  "GET PARAMETER ID 'BUK' FIELD lv_bukrs.
  "IF lv_bukrs IS INITIAL.
  lv_bukrs = '1000'.
  "ENDIF.

  CLEAR gs_accdoc_h.
  gs_accdoc_h-bukrs = lv_bukrs.              " 회사 코드
  gs_accdoc_h-belnr = p_accdoc_h_no.      " 회계 전표 번호

  gs_accdoc_h-gjahr = sy-datum(4).        " 연도
  gs_accdoc_h-monat = sy-datum+4(2).  " 월

  gs_accdoc_h-blart = 'RE'.                      " 전표 유형 (WE : 입고)
  gs_accdoc_h-budat = sy-datum.       " 전기일
  gs_accdoc_h-bldat = gs_inv_h-bldat.              " 증빙일
  gs_accdoc_h-waers = gs_inv_h-waers. " 통화
  gs_accdoc_h-stblg = ''.
  gs_accdoc_h-xblnr = gs_inv_h-inv_no. " 참조번호(청구서 번호)
  APPEND gs_accdoc_h TO gt_accdoc_h.


  " ** inv_h에도 BELNR(회계전표 번호)를 연결해줘야한다.
  gs_inv_h-belnr = p_accdoc_h_no.
  UPDATE z8mm_inv_h
  SET belnr = p_accdoc_h_no
  WHERE inv_no = gs_inv_h-inv_no
    AND bupla = gs_inv_h-bupla.
ENDFORM.

FORM get_accdoc_h_no  CHANGING p_accdoc_h_no.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8FI_BELNR'
    IMPORTING
      number                  = p_accdoc_h_no
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
    MESSAGE |회계전표 순번 획득 실패| TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM change_poh_invh .
  UPDATE z8mm_po_h SET procstat = '25' WHERE ebeln = gv_ebeln.
ENDFORM.

FORM create_vendor .
  CLEAR gt_vendor.

  " 공급업체(LIFNR) 값이 존재하는 대변(매입채무) 아이템만 걸러서 루프를 돕니다.
  LOOP AT gt_accdoc_i INTO gs_accdoc_i WHERE lifnr IS NOT INITIAL.
    CLEAR gs_vendor.
    gs_vendor-bukrs = gs_accdoc_h-bukrs.
    gs_vendor-gjahr = gs_accdoc_h-gjahr.
    gs_vendor-belnr = gs_accdoc_h-belnr.
    gs_vendor-bupla = gs_accdoc_i-bupla.
    gs_vendor-lifnr = gs_accdoc_i-lifnr.
    gs_vendor-wrbtr = gs_accdoc_i-wrbtr.
    gs_vendor-waers = gs_accdoc_h-waers.
    gs_vendor-bldat = gs_accdoc_h-bldat.
    gs_vendor-budat = sy-datum.
    gs_vendor-xblnr = gs_accdoc_h-xblnr.


    " 대변 금액들(150k + 100k + 20k)만 깔끔하게 270,000으로 한 줄로 합산됩니다.
    COLLECT gs_vendor INTO gt_vendor.
  ENDLOOP.

  INSERT z8fi_vendor FROM TABLE gt_vendor ACCEPTING DUPLICATE KEYS.
ENDFORM.

FORM delete_invh  USING p_ref_doc.
*  DATA lv_ref_inv_id TYPE z8mm_inv_h-ref_inv_id.

*  SELECT SINGLE inv_no
*    INTO lv_invno
*  FROM z8mm_inv_i
*  WHERE ebeln = gv_ebeln.

  UPDATE z8mm_inv_h SET loekz = 'X' rbstat = 2 WHERE zzrefdoc = p_ref_doc.
ENDFORM.

FORM lock_po USING    pv_ebeln TYPE z8mm_po_i-ebeln
             CHANGING pv_rc    TYPE sy-subrc
                      pv_uname TYPE sy-uname.
  CLEAR: pv_rc, pv_uname.

  CALL FUNCTION 'ENQUEUE_EZ8MM_PO_H'
    EXPORTING
      mode_z8mm_po_h = 'E'
      mandt          = sy-mandt
      ebeln          = pv_ebeln
      _scope         = '1'          " 직접 DB 갱신(update task 미사용)이므로 dialog 전용
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  pv_rc = sy-subrc.

  CASE pv_rc.
    WHEN 0.
      gv_po_locked = 'X'.
      gv_lock_ebeln = pv_ebeln.
    WHEN 1.
      pv_uname = sy-msgv1.          " 락을 잡고 있는 사용자 ID
  ENDCASE.
ENDFORM.

FORM unlock_po.
  CHECK gv_po_locked = 'X'.

  CALL FUNCTION 'DEQUEUE_EZ8MM_PO_H'
    EXPORTING
      mode_z8mm_po_h = 'E'
      mandt          = sy-mandt
      ebeln          = gv_lock_ebeln.

  CLEAR: gv_po_locked, gv_lock_ebeln.
ENDFORM.

FORM check_po_state USING    pv_ebeln TYPE z8mm_po_i-ebeln
                    CHANGING pv_ok    TYPE c.
  DATA: lv_invno  TYPE z8mm_inv_h-inv_no,
        lv_procst TYPE z8mm_po_h-procstat.

  CLEAR pv_ok.

  " 1) 유효 청구서가 이미 있는지
  SELECT SINGLE inv_no
    INTO lv_invno
    FROM z8mm_inv_h
   WHERE zzrefdoc = pv_ebeln
     AND loekz    = ' '.
  IF sy-subrc = 0.
    MESSAGE i202(z8_msg).                  " 호출부가 화면을 닫으므로 팝업(I) 사용
    RETURN.
  ENDIF.

  " 2) 이미 검증 완료(25)된 PO인지
  SELECT SINGLE procstat
    INTO lv_procst
    FROM z8mm_po_h
   WHERE ebeln = pv_ebeln.
  IF sy-subrc <> 0 OR lv_procst = '25'.
    MESSAGE i202(z8_msg).                  " 호출부가 화면을 닫으므로 팝업(I) 사용
    RETURN.
  ENDIF.

  pv_ok = 'X'.
ENDFORM.

FORM save_invoice_and_posting.
  DATA: lv_inv_no TYPE z8mm_inv_h-inv_no.

  CLEAR gv_save_err.

  " 락과 재검증을 통과한 뒤에 채번하여 결번을 줄인다.
  PERFORM get_invno CHANGING lv_inv_no.
  IF sy-subrc <> 0 OR lv_inv_no IS INITIAL.
    gv_save_err = 'X'.
    MESSAGE s081(z8_msg) WITH |청구서 번호| DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  DATA(lv_real_invno) = |IV{ lv_inv_no }|.
  gs_inv_h-inv_no = lv_real_invno.
  LOOP AT gt_inv_i ASSIGNING FIELD-SYMBOL(<fs_inv_i>).
    <fs_inv_i>-inv_no = lv_real_invno.
  ENDLOOP.

  PERFORM get_accdoc_h_no CHANGING gv_belnr.
  IF gv_belnr IS INITIAL.
    gv_save_err = 'X'.
    RETURN.
  ENDIF.

  INSERT z8mm_inv_h FROM gs_inv_h.
  IF sy-subrc <> 0.
    gv_save_err = 'X'.
    MESSAGE '청구서 헤더 저장에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  INSERT z8mm_inv_i FROM TABLE gt_inv_i.
  IF sy-subrc <> 0.
    gv_save_err = 'X'.
    MESSAGE '청구서 품목 저장에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM create_accdoc_h USING gv_belnr.
  IF gv_save_err = 'X'. RETURN. ENDIF.

  PERFORM create_accdoc_i USING lv_real_invno.
  IF gv_save_err = 'X'. RETURN. ENDIF.

  PERFORM change_poh_invh.
  IF gv_save_err = 'X'. RETURN. ENDIF.

  PERFORM create_vendor.
ENDFORM.

*FORM lock_accdoc_h USING p_belnr.
*  CALL FUNCTION 'ENQUEUE_EZ8FI_ACCDOC_H'
*    EXPORTING
*      mode_z8fi_accdoc_h = 'E'
*      mandt              = sy-mandt
*      belnr              = p_belnr
*      gjahr              = sy-datum(+4)
*    .
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.
*
*ENDFORM.

*FORM lock_accdoc_i  USING p_belnr.
*  CALL FUNCTION 'ENQUEUE_EZ8FI_ACCDOC_I'
*    EXPORTING
*      mode_z8fi_accdoc_i = 'E'
*      mandt              = sy-mandt
*      belnr              = p_belnr
*      gjahr              = sy-datum(+4)
*    EXCEPTIONS
*      foreign_lock       = 1
*      system_failure     = 2
*      OTHERS             = 3.
*
*ENDFORM.

*FORM lock_po_h  USING p_ebeln.
*  CALL FUNCTION 'ENQUEUE_EZ8MM_PO_H'
*    EXPORTING
*      mode_z8mm_po_h = 'E'
*      mandt          = sy-mandt
*      ebeln          = p_ebeln
*    EXCEPTIONS
*      foreign_lock   = 1
*      system_failure = 2
*      OTHERS         = 3.
*
*ENDFORM.

*FORM lock_inv_h  USING    p_inv_no.
*  CALL FUNCTION 'ENQUEUE_EZ8MM_INV_I'
*    EXPORTING
*      mode_z8mm_inv_i = 'E'
*      mandt           = sy-mandt
*      inv_no          = p_inv_no
*    EXCEPTIONS
*      foreign_lock    = 1
*      system_failure  = 2
*      OTHERS          = 3.
*ENDFORM.

*FORM lock_fi_vendor  USING    p_accdoc_h_no.
*  CALL FUNCTION 'ENQUEUE_EZ8FI_VENDOR'
*    EXPORTING
*      mode_z8fi_vendor = 'E'
*      mandt            = sy-mandt
*      gjahr            = sy-datum(+4)
*      belnr            = p_accdoc_h_no
*    EXCEPTIONS
*      foreign_lock     = 1
*      system_failure   = 2
*      OTHERS           = 3.
*ENDFORM.

FORM has_inv  CHANGING p_invno.
  SELECT SINGLE inv_no
    INTO p_invno
  FROM z8mm_inv_h
  WHERE zzrefdoc = gv_ebeln
      AND LOekz = ' '.

  IF sy-subrc <> 0.
    CLEAR p_invno.
  ENDIF.
ENDFORM.
