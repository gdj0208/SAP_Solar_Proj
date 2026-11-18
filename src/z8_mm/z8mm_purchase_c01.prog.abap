*&---------------------------------------------------------------------*
*& Include Z8MM_PURCHASE_C01
*&---------------------------------------------------------------------*
*& PR 생성·변경·취소, PO 생성(PR 묶음)·취소·납기 변경 저장(lcl_mm_purchase)
*& COMMIT/ROLLBACK과 잠금 해제는 호출한 F01에서 한다.
*& 사용: ZMMPR0100, ZMMPR0110, ZMMPO0110
*& 담당: MM(이규빈)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: PR·PO 저장 공통 처리
*& 2026-11-02  이규빈  수정사항    저장 전 재검사 보완: 조회 후 바뀐 PR·PO는 저장 차단
*& 2026-11-05  이규빈  변경사항    PR 저장·변경·PO 취소는 문서 잠금
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" Z8MM_PURCHASE_C01: COMMIT/ROLLBACK과 공통 잠금 해제는 호출한 F01에서 담당한다.
CLASS lcl_mm_purchase DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS: c_ekorg TYPE ekorg VALUE 'DL02',
      c_bukrs TYPE bukrs VALUE '1000',
      c_lgort TYPE z8mm_pr-lgort VALUE '0001'.
    CLASS-METHODS create_pr IMPORTING request TYPE z8mm_pr
      RETURNING VALUE(result) TYPE z8mm_pr RAISING lcx_mm.
    CLASS-METHODS change_pr IMPORTING original TYPE z8mm_pr quantity TYPE z8mm_pr-menge
      vendor TYPE z8mm_pr-lifnr cancel TYPE abap_bool DEFAULT abap_false
      requested_date TYPE sy-datum OPTIONAL RAISING lcx_mm.
    CLASS-METHODS create_po IMPORTING requests TYPE lcl_mm_common=>ty_prs purchasing_org TYPE ekorg
      purchasing_group TYPE ekgrp expected_price TYPE z8purch_info_m expected_arrival TYPE sy-datum
      RETURNING VALUE(result) TYPE z8mm_po_h-ebeln RAISING lcx_mm.
    CLASS-METHODS cancel_po IMPORTING document TYPE z8mm_po_h-ebeln RAISING lcx_mm.
ENDCLASS.
CLASS lcl_mm_purchase IMPLEMENTATION.

  " ------------------------------------------------------------
  " METHOD create_pr : 기준정보를 검사하고 평가가격으로 신규 PR 한 건을 작성한다.
  " DB 변경: z8mm_pr. 저장 확정(COMMIT)은 호출한 F01에서 한다.
  " ------------------------------------------------------------
  METHOD create_pr.
    " PR 저장은 재고를 바꾸지 않으므로 문서 잠금으로 충분하다.
    lcl_mm_common=>require_doc_lock( ).
    DATA(key) = VALUE lcl_mm_common=>ty_key( matnr = request-matnr werks = request-werks lgort = c_lgort ).
    DATA(stock) = lcl_mm_stock=>location( key ).
    result = request.
    result-lgort = c_lgort.
    CLEAR: result-banfn, result-ebeln, result-ebelp, result-loekz,
      result-kdauf, result-kdpos, result-proc_seq, result-ref_ebeln, result-ref_ebelp.
    result-mandt = sy-mandt.
    result-bnfpo = '00010'.
    result-bsart = 'NB'.
    result-meins = stock-meins.
    result-source_type = 'MANUAL'.         " 화면(ZMMPR0110)에서 사용자가 만든 PR
    IF result-menge <= 0.
      lcl_mm_common=>fail( `요청수량은 0보다 커야 합니다.` ).
    ENDIF.
    IF result-lfdat < sy-datum.
      lcl_mm_common=>fail( `희망납기일은 오늘 이후로 입력하세요.` ).
    ENDIF.
    IF result-lifnr IS NOT INITIAL.
      DATA(info) = lcl_mm_stock=>price( material = result-matnr vendor = result-lifnr ).
      result-waers = info-waers.
      " 희망납기일은 사용자 요청값을 유지한다. PO 예상도착일 계산값으로 바꾸지 않는다.
    ELSE.
      CLEAR result-waers.
    ENDIF.
    " PR은 자재 평가가격을 사용한다. 업체 구매단가와 구분한다.
    DATA(val) = lcl_mm_stock=>valuation( key ).
    IF val-meins <> result-meins.
      lcl_mm_common=>fail( `평가 수량단위 불일치` ).
    ENDIF.
    IF val-vprsv = 'S'.
      result-preis = val-stprs / val-peinh.
    ELSE.
      result-preis = val-verpr / val-peinh.
    ENDIF.
    result-waers = val-waers.
    result-banfn = lcl_mm_common=>number( 'Z8MMPRN' ).
    INSERT z8mm_pr FROM @result.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `PR 저장 실패` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD change_pr : 조회 당시 PR과 현재 DB를 비교한 후 수량·업체·희망납기일 또는 취소표시를 저장한다.
  " DB 변경: z8mm_pr. 저장 확정(COMMIT)은 호출한 F01에서 한다.
  " ------------------------------------------------------------
  METHOD change_pr.
    lcl_mm_common=>require_doc_lock( ).    " PR 변경·취소는 재고를 바꾸지 않는다
    SELECT SINGLE * FROM z8mm_pr WHERE banfn = @original-banfn AND bnfpo = @original-bnfpo INTO @DATA(live).
    IF sy-subrc <> 0 OR live <> original
      OR live-ebeln IS NOT INITIAL OR live-loekz IS NOT INITIAL.
      lcl_mm_common=>fail( `변경된 PR이거나 이미 발주/취소된 PR입니다. 재조회하세요.` ).
    ENDIF.
    IF live-kdauf IS NOT INITIAL OR live-kdpos IS NOT INITIAL OR live-proc_seq IS NOT INITIAL.
      lcl_mm_common=>fail( `SO 연계 구 PR은 조달계획까지 함께 변경해야 합니다. 이 독립 PR 화면에서는 수정·취소하지 않습니다.` ).
    ENDIF.
    IF cancel = abap_true.
      live-loekz = 'X'.
    ELSE.
      IF quantity <= 0.
        lcl_mm_common=>fail( `수량은 0보다 커야 합니다.` ).
      ENDIF.
      live-menge = quantity.
      live-lifnr = vendor.
      IF requested_date IS SUPPLIED.
        IF requested_date < sy-datum.
          lcl_mm_common=>fail( `희망납기일은 오늘 이후로 입력하세요.` ).
        ENDIF.
        live-lfdat = requested_date.
      ENDIF.
      IF vendor IS NOT INITIAL.
        DATA(info) = lcl_mm_stock=>price( material = live-matnr vendor = vendor ).
        " 추천 공급업체만 바꿀 때 희망납기일은 유지한다.
      ENDIF.
    ENDIF.
    UPDATE z8mm_pr FROM @live.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `PR 변경 실패` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD create_po : 동일 묶음 PR들을 재검사하고 PO 헤더·품목·원본 PR 연결을 작성한다.
  " DB 변경: z8mm_po_h, z8mm_po_i, z8mm_pr. 저장 확정(COMMIT)은 호출한 F01에서 한다.
  " ------------------------------------------------------------
  METHOD create_po.
    lcl_mm_common=>require_lock( ).
    IF requests IS INITIAL.
      lcl_mm_common=>fail( `선택한 PR이 없습니다.` ).
    ENDIF.
    DATA first TYPE z8mm_pr.
    READ TABLE requests INDEX 1 INTO first.
    DATA(info) = lcl_mm_stock=>price( material = first-matnr vendor = first-lifnr ).
    DATA(arrival) = lcl_mm_stock=>eta( vendor = first-lifnr plant = first-werks ).
    IF info <> expected_price OR arrival <> expected_arrival.
      lcl_mm_common=>fail( `미리보기 이후 가격·루트·기준일이 변경되었습니다. 재조회 후 확인하세요.` ).
    ENDIF.
    DATA bukrs TYPE bukrs.
    bukrs = c_bukrs.
    IF purchasing_org <> c_ekorg OR first-lgort <> c_lgort.
      lcl_mm_common=>fail( `프로젝트 고정값: 구매조직 DL02 / 저장위치 0001을 사용하세요.` ).
    ENDIF.
    SELECT SINGLE bukrs FROM z8company_m WHERE bukrs = @c_bukrs INTO @DATA(company_exists).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `회사코드 1000의 회사 마스터를 등록하세요.` ).
    ENDIF.
    SELECT SINGLE * FROM t024e WHERE ekorg = @purchasing_org INTO @DATA(org).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `구매조직 DL02가 T024E에 없습니다.` ).
    ENDIF.
    SELECT SINGLE ekgrp FROM t024 WHERE ekgrp = @purchasing_group INTO @DATA(grp).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `구매그룹을 확인하세요.` ).
    ENDIF.
    " 묶음 PR의 현재 DB 값과 기존 PO 연결을 한 번에 읽어 두고, 아래 루프에서는 읽은 표만 찾는다.
    "   (requests는 위에서 빈 값이면 중단하므로 FOR ALL ENTRIES 조건이 비지 않는다)
    DATA live_prs TYPE SORTED TABLE OF z8mm_pr WITH NON-UNIQUE KEY banfn bnfpo.
    SELECT * FROM z8mm_pr FOR ALL ENTRIES IN @requests
      WHERE banfn = @requests-banfn AND bnfpo = @requests-bnfpo
      INTO TABLE @live_prs.
    TYPES: BEGIN OF ty_link,
             banfn TYPE z8mm_po_i-banfn,
             bnfpo TYPE z8mm_po_i-bnfpo,
           END OF ty_link.
    DATA linked_prs TYPE SORTED TABLE OF ty_link WITH NON-UNIQUE KEY banfn bnfpo.
    SELECT banfn, bnfpo FROM z8mm_po_i FOR ALL ENTRIES IN @requests
      WHERE banfn = @requests-banfn AND bnfpo = @requests-bnfpo AND loekz = @space
      INTO CORRESPONDING FIELDS OF TABLE @linked_prs.
    " 묶음 PR은 자재·플랜트·창고가 같으므로(아래 루프에서 검사) 재고 기준정보는 한 번만 확인한다.
    lcl_mm_stock=>location( VALUE #( matnr = first-matnr werks = first-werks lgort = first-lgort ) ).
    DATA seen TYPE SORTED TABLE OF z8mm_pr WITH UNIQUE KEY banfn bnfpo.
    DATA total TYPE z8mm_pr-menge.
    LOOP AT requests INTO DATA(request).
      INSERT request INTO TABLE seen.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( `중복 선택 PR입니다.` ).
      ENDIF.
      READ TABLE live_prs INTO DATA(live) WITH TABLE KEY banfn = request-banfn bnfpo = request-bnfpo.
      IF sy-subrc <> 0 OR live <> request
        OR live-loekz IS NOT INITIAL OR live-ebeln IS NOT INITIAL OR live-menge <= 0.
        lcl_mm_common=>fail( `선택 후 PR이 변경/발주/취소되었습니다. 재조회하세요.` ).
      ENDIF.
      IF live-matnr <> first-matnr OR live-lifnr <> first-lifnr OR live-werks <> first-werks
        OR live-lgort <> first-lgort OR live-meins <> first-meins OR live-meins <> info-meins.
        lcl_mm_common=>fail( `공급업체·자재·입고창고·단위가 다른 PR은 별도 PO로 생성하세요.` ).
      ENDIF.
      READ TABLE linked_prs TRANSPORTING NO FIELDS WITH TABLE KEY banfn = live-banfn bnfpo = live-bnfpo.
      IF sy-subrc = 0.
        lcl_mm_common=>fail( `PR에 유효한 PO 연결 이력이 있습니다.` ).
      ENDIF.
      " SO 연계 PR(이전 시나리오 데이터)은 발주하지 않는다. 지금 PR은 SO 번호 없이 만든다.
      IF live-kdauf IS NOT INITIAL OR live-kdpos IS NOT INITIAL OR live-proc_seq IS NOT INITIAL.
        lcl_mm_common=>fail( `SO 연계 PR(이전 시나리오)은 발주할 수 없습니다.` ).
      ENDIF.
      total = total + live-menge.
    ENDLOOP.
    IF total < info-minbm.
      lcl_mm_common=>fail( `묶음 합계가 공급업체 최소발주량보다 작습니다.` ).
    ENDIF.
    IF lines( requests ) > 9999.
      lcl_mm_common=>fail( `PO 품목 수 한도 초과` ).
    ENDIF.
    result = lcl_mm_common=>number( 'Z8MMPON' ).
    SELECT SINGLE bupla FROM z8plant_m WHERE werks = @first-werks INTO @DATA(branch).
    DATA head TYPE z8mm_po_h.
    head-mandt = sy-mandt.
    head-ebeln = result.
    head-bukrs = bukrs.
    head-bsart = 'NB'.
    head-lifnr = first-lifnr.
    head-bedat = sy-datum.
    head-ekorg = purchasing_org.
    head-ekgrp = purchasing_group.
    head-waers = info-waers.
    head-procstat = '10'.
    head-ernam = sy-uname.
    head-bupla = branch.
    " 문서 공통정보(헤더)를 작성한다. 아래 품목·연결 처리까지 성공해야 전체를 확정한다.
    INSERT z8mm_po_h FROM @head.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `PO 헤더 저장 실패` ).
    ENDIF.
    DATA pos TYPE i.
    LOOP AT requests INTO request.
      pos = pos + 10.
      DATA item TYPE z8mm_po_i.
      CLEAR item.                       " 이전 PR 품목의 값이 다음 품목에 남지 않게 비운다.
      item-mandt = sy-mandt.
      item-ebeln = result.
      item-ebelp = pos.
      item-matnr = request-matnr.
      item-werks = request-werks.
      item-lgort = request-lgort.
      item-menge = request-menge.
      item-meins = request-meins.
      item-netpr = info-netpr.
      item-peinh = info-peinh.
      item-netwr = request-menge * info-netpr / info-peinh.
      item-waers = info-waers.
      item-banfn = request-banfn.
      item-bnfpo = request-bnfpo.
      item-lfdat = arrival.
      INSERT z8mm_po_i FROM @item.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( `PO 품목 저장 실패` ).
      ENDIF.
      " 원본 PR에 생성 PO번호/품목을 남겨 어느 PO로 발주됐는지 추적한다.
      UPDATE z8mm_pr SET ebeln = @result, ebelp = @item-ebelp
        WHERE banfn = @request-banfn AND bnfpo = @request-bnfpo AND ebeln = @space AND loekz = @space.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( `PR·PO 연결 실패` ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD cancel_po : 자재문서·구매 처리이력이 없는 대기 PO를 취소하고 원본 PR 연결을 해제한다.
  " DB 변경: z8mm_po_i, z8mm_pr. 저장 확정(COMMIT)은 호출한 F01에서 한다.
  " ------------------------------------------------------------
  METHOD cancel_po.
    lcl_mm_common=>require_doc_lock( ).    " PO 취소는 재고를 바꾸지 않는다
    SELECT SINGLE * FROM z8mm_po_h WHERE ebeln = @document INTO @DATA(head).
    IF sy-subrc <> 0 OR head-bsart <> 'NB' OR head-procstat <> '10'.
      lcl_mm_common=>fail( `입고대기 외부구매 PO만 취소할 수 있습니다.` ).
    ENDIF.
    SELECT SINGLE mblnr FROM z8mm_matdoc_i WHERE zzrefdoc = @document AND zzreftype = '01' INTO @DATA(history).
    IF sy-subrc = 0.
      lcl_mm_common=>fail( `자재문서 이력이 있는 PO는 직접 취소할 수 없습니다.` ).
    ENDIF.
    SELECT SINGLE ebeln FROM z8mm_po_hist WHERE ebeln = @document INTO @DATA(po_history).
    IF sy-subrc = 0.
      lcl_mm_common=>fail( `구매 처리이력이 있는 PO는 직접 취소할 수 없습니다.` ).
    ENDIF.
    SELECT * FROM z8mm_po_i WHERE ebeln = @document INTO TABLE @DATA(items).
    IF items IS INITIAL.
      lcl_mm_common=>fail( `PO 품목 없음` ).
    ENDIF.
    LOOP AT items INTO DATA(item).
      IF item-elikz IS NOT INITIAL OR item-loekz IS NOT INITIAL.
        lcl_mm_common=>fail( `입고/취소 품목이 포함되어 있습니다.` ).
      ENDIF.
      " SO 연계 PO(이전 시나리오 데이터)는 조달계획까지 되돌려야 해서 여기서 취소하지 않는다.
      IF item-kdauf IS NOT INITIAL OR item-kdpos IS NOT INITIAL OR item-proc_seq IS NOT INITIAL.
        lcl_mm_common=>fail( `SO 연계 PO(이전 시나리오)는 취소할 수 없습니다.` ).
      ENDIF.
      " PO 취소 시 원본 PR의 발주 연결을 해제해 다시 발주할 수 있게 한다.
      UPDATE z8mm_pr SET ebeln = @space, ebelp = '00000'
        WHERE banfn = @item-banfn AND bnfpo = @item-bnfpo AND ebeln = @document
        AND ebelp = @item-ebelp AND loekz = @space.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( `원본 PR 연결 불일치: 취소 전체 롤백` ).
      ENDIF.
    ENDLOOP.
    UPDATE z8mm_po_i SET loekz = 'X' WHERE ebeln = @document.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `PO 취소 저장 실패` ).
    ENDIF.
    " 헤더 PROCSTAT은 입고상태이다. 취소 여부는 품목 LOEKZ로 판정한다.
  ENDMETHOD.
ENDCLASS.
