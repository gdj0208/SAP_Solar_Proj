*&---------------------------------------------------------------------*
*& Include Z8MM_STO_C01
*&---------------------------------------------------------------------*
*& STO 검사·예약·출고(351)·입고(101)·취소 공통 클래스 (STO 화면·배치 공통)
*& 사용: ZMMSTO0100, Z8MMB0100
*& 담당: MM(이규빈)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: STO 생성·출고(351)·입고(101)·취소 저장 공통 클래스
*& 2026-10-30  이규빈  변경사항    STO 1건 품목 N줄, 351·101 자재문서도 STO 단위 1건 N줄
*& 2026-11-05  이규빈  변경사항    STO 예약 추가: 미래 출고일은 RSV(예약재고)로 저장
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" STO 처리 방식
"   - 출고일 = 오늘 : 저장 즉시 351 출고 → 이동중(procstat 15)
"   - 출고일 = 미래 : 예약(procstat 10). 출발지 재고를 예약재고(ZZRSVQTY)로 잡고 품목 STO_RSV_QTY = 수량
"                     → 출고일에 배치(ship_sto)가 351 출고 → 이동중 → 예상도착일에 배치(receive_sto)가 101 입고
"   - 예약 취소(cancel_sto) : 출고 전(예약중)만 가능. 예약재고를 풀고 품목 LOEKZ = X, 이력 'CAN'
"   - 재고가 움직이지 않는 예약·취소도 STO 이력(Z8MM_STO_HIST)에 남긴다(BWART 'RSV'/'CAN', 자재문서번호 없음).
" 문서이력: ZZREFTYPE = '03', ZZREFDOC = STO 번호, REF_ITEM = EBELP
" STO 1건에 자재 여러 개. 351·101 자재문서도 문서 1건에 품목줄(ZEILE 0001~)로 여러 자재를 담는다.

CLASS lcl_mm_sto DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_preview,
      source TYPE z8material_stk_m,
      dest TYPE z8material_stk_m,
      movable TYPE z8mm_po_i-menge,
      arrival TYPE sy-datum,
      days TYPE i,
      END OF ty_preview.
    CLASS-METHODS preview_sto IMPORTING item TYPE z8mm_po_i
      RETURNING VALUE(result) TYPE ty_preview RAISING lcx_mm.
    " STO 1건 = 자재 N개(품목 10·20·30…). 출고 351과 입고 101도 각각 자재문서 1건 N줄이다.
    CLASS-METHODS create_sto IMPORTING items TYPE lcl_mm_common=>ty_items
      expected_arrival TYPE sy-datum
      RETURNING VALUE(result) TYPE z8mm_po_h-ebeln RAISING lcx_mm.
    " receive_sto : STO 한 건의 도래한 미입고 품목 전체를 101 자재문서 1건(N줄)로 입고한다.
    "   result = 101 자재문서번호(모의실행이면 빈 값). 한 품목이라도 실패하면 STO 전체가 실패한다.
    CLASS-METHODS receive_sto IMPORTING document TYPE z8mm_po_i-ebeln
      asof TYPE sy-datum simulation TYPE abap_bool
      RETURNING VALUE(result) TYPE z8mm_matdoc_h-mblnr RAISING lcx_mm.
    " ship_sto : 예약 STO 중 출고일이 도래한 품목을 351 자재문서 1건(N줄)로 출고한다(배치용).
    "   result = 351 자재문서번호(모의실행이면 빈 값).
    CLASS-METHODS ship_sto IMPORTING document TYPE z8mm_po_i-ebeln
      asof TYPE sy-datum simulation TYPE abap_bool
      RETURNING VALUE(result) TYPE z8mm_matdoc_h-mblnr RAISING lcx_mm.
    " cancel_sto : 출고 전(예약중) STO 전체를 취소하고 예약재고를 푼다.
    CLASS-METHODS cancel_sto IMPORTING document TYPE z8mm_po_i-ebeln RAISING lcx_mm.
    " route_days : 출발→도착 플랜트의 운송일수(화면에서 도착희망일 → 출고일 역산용). DB 변경 없음.
    CLASS-METHODS route_days IMPORTING source TYPE z8mm_po_i-reswk dest TYPE z8mm_po_i-werks
      RETURNING VALUE(days) TYPE i RAISING lcx_mm.
  PRIVATE SECTION.
    CLASS-METHODS append_history IMPORTING po_item TYPE z8mm_po_i
      doc_head TYPE z8mm_matdoc_h doc_item TYPE z8mm_matdoc_i RAISING lcx_mm.
    " 재고가 움직이지 않는 예약(RSV)·예약취소(CAN) 이력. 자재문서번호는 비우고 BUZEI로 구분한다.
    CLASS-METHODS append_event IMPORTING po_item TYPE z8mm_po_i kind TYPE z8mm_sto_hist-bwart
      seq TYPE i RAISING lcx_mm.   " 숫자(1 예약 / 2 취소)로 받고 안에서 BUZEI로 바꾼다
ENDCLASS.

CLASS lcl_mm_sto IMPLEMENTATION.

  " ------------------------------------------------------------
  " METHOD preview_sto : 서로 다른 지사의 이동 조건·재고·안전재고·경로를 검사해 확인값을 반환한다.
  " 확인: 내부테이블/화면 변경과 DB 저장은 다르다. 아래 호출의 역할을 따라 읽는다.
  " ------------------------------------------------------------
  METHOD preview_sto.
    IF item-matnr IS INITIAL OR item-menge <= 0 OR item-reswk IS INITIAL
      OR item-reslo <> '0001' OR item-werks IS INITIAL OR item-lgort <> '0001'
      OR item-reswk = item-werks OR item-sto_dep_date < sy-datum.
      lcl_mm_common=>fail( `서로 다른 플랜트, 저장위치0001, 자재·양수수량·출고일(오늘 이후)을 확인하세요.` ).
    ENDIF.
    DATA(source_company) = lcl_mm_stock=>company( item-reswk ).
    DATA(dest_company) = lcl_mm_stock=>company( item-werks ).
    IF source_company <> dest_company.
      lcl_mm_common=>fail( `동일 회사 내 이동만 가능합니다.` ).
    ENDIF.
    SELECT SINGLE region_code FROM z8plant_m WHERE werks = @item-reswk INTO @DATA(from_region).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `출발 플랜트 지역 없음` ).
    ENDIF.
    SELECT SINGLE region_code FROM z8plant_m WHERE werks = @item-werks INTO @DATA(to_region).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `도착 플랜트 지역 없음` ).
    ENDIF.
    result-days = lcl_mm_stock=>route( source = from_region dest = to_region ).
    result-arrival = item-sto_dep_date + result-days.   " 출고일(오늘 또는 예약일) + 운송일수
    result-source = lcl_mm_stock=>location( VALUE #( matnr = item-matnr werks = item-reswk lgort = item-reslo ) ).
    result-dest = lcl_mm_stock=>location( VALUE #( matnr = item-matnr werks = item-werks lgort = item-lgort ) ).
    IF result-source-meins <> result-dest-meins OR result-source-meins IS INITIAL.
      lcl_mm_common=>fail( `출발·도착 자재 단위 불일치` ).
    ENDIF.
    IF result-dest-umlme < 0.
      lcl_mm_common=>fail( `도착지 이동중재고 오류` ).
    ENDIF.
    SELECT SINGLE eisbe FROM z8matplant_m
      WHERE matnr = @item-matnr AND werks = @item-reswk AND lgort = @item-reslo
      INTO @DATA(safety).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `출발 창고 안전재고 기준정보 없음` ).
    ENDIF.
    result-movable = result-source-labst - result-source-zzrsvqty - safety.
    IF result-source-labst < result-movable.
      result-movable = result-source-labst.
    ENDIF.
    IF result-movable < 0.
      result-movable = 0.
    ENDIF.
    " 요청량이 초과해도 이동가능량을 반환해 화면에서 수정할 수 있도록 한다.
    " 실제 저장은 create_sto에서 재고 잠금 후 이동가능량을 다시 검사한다.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD append_history : 자재문서와 연결된 STO 이동이력을 기록한다. 실패하면 예외를 전달한다.
  " DB 변경: z8mm_sto_hist. 저장 확정은 호출부 COMMIT을 확인한다.
  " ------------------------------------------------------------
  METHOD append_history.
    lcl_mm_common=>require_lock( ).
    DATA hist TYPE z8mm_sto_hist.
    hist = VALUE #( mandt = sy-mandt ebeln = po_item-ebeln ebelp = po_item-ebelp
      gjahr = doc_head-mjahr belnr = doc_head-mblnr buzei = doc_item-zeile
      bwart = doc_item-bwart budat = doc_head-budat matnr = po_item-matnr
      werks = po_item-werks lgort = po_item-lgort reswk = po_item-reswk reslo = po_item-reslo
      menge = doc_item-menge meins = doc_item-meins erdat = sy-datum erzet = sy-uzeit ernam = sy-uname ).
    INSERT z8mm_sto_hist FROM @hist.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `STO 처리이력 저장 실패: 이번 재고·문서 처리를 롤백합니다.` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD create_sto : STO 1건(품목 N개)을 예약하거나 즉시 351 출고한다.
  "   - 모든 품목은 출발·도착 플랜트/저장위치와 출고일이 같아야 한다.
  "   - 같은 자재가 두 줄이면 합계로 이동가능량을 검사하고 재고도 합계로 한 번에 바꾼다.
  "   - 하나라도 실패하면 예외 → 호출부 ROLLBACK으로 STO 전체가 취소된다(반쪽 문서 없음).
  " DB 변경: z8material_stk_m, z8mm_matdoc_h, z8mm_matdoc_i, z8mm_po_h, z8mm_po_i, z8mm_sto_hist.
  "   저장 확정은 호출부 COMMIT을 확인한다.
  " ------------------------------------------------------------
  METHOD create_sto.
    lcl_mm_common=>require_lock( ).
    IF items IS INITIAL.
      lcl_mm_common=>fail( `STO로 보낼 자재가 없습니다.` ).
    ENDIF.
    " EBELP는 10씩, 자재문서 ZEILE는 1씩 증가한다. 넘친 뒤 저장하지 않도록 먼저 검사한다.
    IF lines( items ) > 9999.
      lcl_mm_common=>fail( `한 STO에는 최대 9999개 품목을 입력할 수 있습니다.` ).
    ENDIF.
    DATA first TYPE z8mm_po_i.
    READ TABLE items INDEX 1 INTO first.
    " 1) 품목 공통 조건: 한 STO = 한 조합(출발→도착), 같은 출고일
    LOOP AT items INTO DATA(chk).
      IF chk-matnr IS INITIAL OR chk-menge <= 0.
        lcl_mm_common=>fail( |{ chk-matnr }: 자재와 양수 수량이 필요합니다.| ).
      ENDIF.
      IF chk-reswk <> first-reswk OR chk-reslo <> first-reslo
        OR chk-werks <> first-werks OR chk-lgort <> first-lgort
        OR chk-sto_dep_date <> first-sto_dep_date.
        lcl_mm_common=>fail( `한 STO의 자재는 출발·도착 플랜트가 모두 같아야 합니다.` ).
      ENDIF.
    ENDLOOP.
    IF first-reswk IS INITIAL OR first-werks IS INITIAL
      OR first-reslo <> '0001' OR first-lgort <> '0001'
      OR first-reswk = first-werks OR first-sto_dep_date < sy-datum.
      lcl_mm_common=>fail( `서로 다른 플랜트, 저장위치 0001, 출고일은 오늘 이후만 가능합니다.` ).
    ENDIF.
    " 출고일이 미래면 예약(재고는 예약재고로만 잡고 출고는 출고일에 배치가 한다).
    DATA(reserve) = xsdbool( first-sto_dep_date > sy-datum ).
    DATA(src_company) = lcl_mm_stock=>company( first-reswk ).
    DATA(dst_company) = lcl_mm_stock=>company( first-werks ).
    IF src_company <> dst_company.
      lcl_mm_common=>fail( `동일 회사 내 이동만 가능합니다.` ).
    ENDIF.
    SELECT SINGLE region_code FROM z8plant_m WHERE werks = @first-reswk INTO @DATA(src_region).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `출발 플랜트 지역 없음` ).
    ENDIF.
    SELECT SINGLE region_code, bupla FROM z8plant_m WHERE werks = @first-werks INTO @DATA(dst_plant).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `도착 플랜트 지역 없음` ).
    ENDIF.
    DATA(days) = lcl_mm_stock=>route( source = src_region dest = dst_plant-region_code ).
    DATA arrival TYPE sy-datum.
    arrival = first-sto_dep_date + days.
    IF arrival <> expected_arrival.
      lcl_mm_common=>fail( `운송일수 변경: 다시 생성하세요.` ).
    ENDIF.

    " 2) 자재별 합계로 재고 검사(같은 자재가 여러 줄이어도 한 번에)
    TYPES: BEGIN OF ty_mat,
             matnr TYPE z8mm_po_i-matnr,
             meins TYPE z8mm_po_i-meins,
             menge TYPE z8mm_po_i-menge,
             src TYPE z8material_stk_m,
             dst TYPE z8material_stk_m,
             dst_new TYPE abap_bool,
           END OF ty_mat.
    DATA mats TYPE SORTED TABLE OF ty_mat WITH UNIQUE KEY matnr.
    LOOP AT items INTO DATA(sum_item).
      READ TABLE mats ASSIGNING FIELD-SYMBOL(<mat>) WITH TABLE KEY matnr = sum_item-matnr.
      IF sy-subrc <> 0.
        INSERT VALUE #( matnr = sum_item-matnr meins = sum_item-meins ) INTO TABLE mats ASSIGNING <mat>.
      ELSEIF <mat>-meins <> sum_item-meins.
        lcl_mm_common=>fail( |{ sum_item-matnr }: 같은 자재의 단위가 줄마다 다릅니다.| ).
      ENDIF.
      <mat>-menge = <mat>-menge + sum_item-menge.
    ENDLOOP.
    LOOP AT mats ASSIGNING <mat>.
      <mat>-src = lcl_mm_stock=>location( VALUE #( matnr = <mat>-matnr werks = first-reswk lgort = first-reslo ) ).
      <mat>-dst = lcl_mm_stock=>location( VALUE #( matnr = <mat>-matnr werks = first-werks lgort = first-lgort ) ).
      IF <mat>-src-meins <> <mat>-dst-meins OR <mat>-src-meins <> <mat>-meins.
        lcl_mm_common=>fail( |{ <mat>-matnr }: 출발·도착 자재 단위 불일치| ).
      ENDIF.
      SELECT SINGLE eisbe FROM z8matplant_m
        WHERE matnr = @<mat>-matnr AND werks = @first-reswk AND lgort = @first-reslo
        INTO @DATA(safety).
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( |{ <mat>-matnr }: 출발 창고 안전재고 기준정보 없음| ).
      ENDIF.
      DATA movable TYPE z8mm_po_i-menge.
      movable = <mat>-src-labst - <mat>-src-zzrsvqty - safety.
      IF movable < <mat>-menge OR <mat>-src-labst < <mat>-menge.
        lcl_mm_common=>fail( |{ <mat>-matnr }: 출발지 이동가능재고 부족(예약·안전재고 제외)| ).
      ENDIF.
      IF <mat>-dst-umlme < 0.
        lcl_mm_common=>fail( |{ <mat>-matnr }: 도착지 이동중재고 오류| ).
      ENDIF.
      SELECT SINGLE matnr FROM z8material_stk_m
        WHERE matnr = @<mat>-matnr AND werks = @first-werks AND lgort = @first-lgort
        INTO @DATA(dst_exists).
      <mat>-dst_new = xsdbool( sy-subrc <> 0 ).
    ENDLOOP.

    " 3) STO 헤더 1건
    result = lcl_mm_common=>number( 'Z8MMSTON' ).
    " procstat : 10 예약중(출고 전) / 15 이동중(351 출고 후) / 20 입고완료
    DATA(head) = VALUE z8mm_po_h( mandt = sy-mandt ebeln = result bsart = 'UB'
      bukrs = dst_company bupla = dst_plant-bupla bedat = sy-datum
      ernam = sy-uname procstat = COND #( WHEN reserve = abap_true THEN '10' ELSE '15' ) ).
    INSERT z8mm_po_h FROM @head.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `STO 헤더 저장 실패` ).
    ENDIF.

    " 예약: 출발지 예약재고만 늘리고 품목(STO_RSV_QTY = 수량)·예약 이력만 남긴다. 351 문서 없음.
    IF reserve = abap_true.
      LOOP AT mats ASSIGNING <mat>.
        UPDATE z8material_stk_m SET zzrsvqty = zzrsvqty + @<mat>-menge
          WHERE matnr = @<mat>-matnr AND werks = @first-reswk AND lgort = @first-reslo
          AND labst = @<mat>-src-labst AND zzrsvqty = @<mat>-src-zzrsvqty.
        IF sy-subrc <> 0 OR sy-dbcnt <> 1.
          lcl_mm_common=>fail( |{ <mat>-matnr }: 출발지 예약재고 반영 충돌| ).
        ENDIF.
      ENDLOOP.
      DATA rsv_ebelp TYPE z8mm_po_i-ebelp.
      LOOP AT items INTO DATA(ri).
        rsv_ebelp = rsv_ebelp + 10.
        ri-mandt = sy-mandt.
        ri-ebeln = result.
        ri-ebelp = rsv_ebelp.
        ri-sto_dep_date = first-sto_dep_date.
        ri-sto_arr_date = arrival.
        ri-sto_rsv_qty = ri-menge.        " 예약중 표시 = 예약수량. 출고(ship_sto) 때 0
        CLEAR: ri-kdauf, ri-kdpos, ri-proc_seq, ri-banfn, ri-bnfpo, ri-loekz, ri-elikz.
        INSERT z8mm_po_i FROM @ri.
        IF sy-subrc <> 0.
          lcl_mm_common=>fail( |{ ri-matnr }: STO 품목 저장 실패| ).
        ENDIF.
        lcl_mm_sto=>append_event( po_item = ri kind = 'RSV' seq = 1 ).
      ENDLOOP.
      RETURN.
    ENDIF.

    " 4) 351 자재문서 헤더 1건
    DATA nr TYPE nriv-nrlevel.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING object = 'Z8MATDOCH' nr_range_nr = '01'
      IMPORTING number = nr EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0 OR nr < 1 OR nr > 9999999999.
      lcl_mm_common=>fail( `자재문서 번호범위 Z8MATDOCH/01 오류` ).
    ENDIF.
    DATA docno TYPE n LENGTH 10.
    docno = nr.
    DATA(mh) = VALUE z8mm_matdoc_h( mandt = sy-mandt mblnr = docno
      mjahr = sy-datum(4) bldat = sy-datum budat = sy-datum ).
    INSERT z8mm_matdoc_h FROM @mh.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `351 문서 헤더 실패` ).
    ENDIF.

    " 5) 재고: 자재별 합계로 한 번씩(출발 현재고 감소, 도착 이동중재고 증가)
    LOOP AT mats ASSIGNING <mat>.
      UPDATE z8material_stk_m SET labst = labst - @<mat>-menge
        WHERE matnr = @<mat>-matnr AND werks = @first-reswk AND lgort = @first-reslo
        AND labst = @<mat>-src-labst AND zzrsvqty = @<mat>-src-zzrsvqty.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |{ <mat>-matnr }: 출발지 351 차감 충돌| ).
      ENDIF.
      IF <mat>-dst_new = abap_true.
        INSERT z8material_stk_m FROM @<mat>-dst.
        IF sy-subrc <> 0.
          lcl_mm_common=>fail( |{ <mat>-matnr }: 도착지 재고행 생성 실패| ).
        ENDIF.
      ENDIF.
      UPDATE z8material_stk_m SET umlme = umlme + @<mat>-menge
        WHERE matnr = @<mat>-matnr AND werks = @first-werks AND lgort = @first-lgort
        AND umlme = @<mat>-dst-umlme.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |{ <mat>-matnr }: 도착지 이동중재고 증가 실패| ).
      ENDIF.
    ENDLOOP.

    " 6) 품목 10·20·30… + 351 품목줄 0001·0002… + STO 이력
    DATA ebelp TYPE z8mm_po_i-ebelp.
    DATA zeile TYPE z8mm_matdoc_i-zeile.
    LOOP AT items INTO DATA(pi).
      ebelp = ebelp + 10.
      zeile = zeile + 1.
      pi-mandt = sy-mandt.
      pi-ebeln = result.
      pi-ebelp = ebelp.
      pi-sto_dep_date = first-sto_dep_date.   " = 오늘(즉시 출고)
      pi-sto_arr_date = arrival.
      pi-sto_rsv_qty = 0.
      CLEAR: pi-kdauf, pi-kdpos, pi-proc_seq, pi-banfn, pi-bnfpo, pi-loekz, pi-elikz.
      INSERT z8mm_po_i FROM @pi.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( |{ pi-matnr }: STO 품목 저장 실패| ).
      ENDIF.
      DATA(gi) = VALUE z8mm_matdoc_i( mandt = sy-mandt mblnr = docno
        mjahr = mh-mjahr zeile = zeile bwart = '351'
        matnr = pi-matnr werks = pi-reswk lgort = pi-reslo
        menge = pi-menge meins = pi-meins zzreftype = '03'
        zzrefdoc = result ref_item = pi-ebelp ).
      INSERT z8mm_matdoc_i FROM @gi.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( |{ pi-matnr }: 351 문서 품목 실패| ).
      ENDIF.
      lcl_mm_sto=>append_history( po_item = pi doc_head = mh doc_item = gi ).
    ENDLOOP.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD receive_sto : STO 한 건의 도래한 미입고 품목 전체를 101 자재문서 1건(N줄)로 입고한다.
  "   품목마다 351 출고 1건·101 중복 없음·351 내용 일치를 검사하고, 도착지 재고는 자재별 합계로 바꾼다.
  "   한 품목이라도 실패하면 예외 → 호출부 ROLLBACK으로 이 STO 전체를 다음 실행으로 넘긴다.
  " DB 변경: z8material_stk_m, z8mm_matdoc_h, z8mm_matdoc_i, z8mm_po_h, z8mm_po_i, z8mm_sto_hist.
  "   저장 확정은 호출부 COMMIT을 확인한다.
  " ------------------------------------------------------------
  METHOD receive_sto.
    lcl_mm_common=>require_lock( ).
    CLEAR result.
    " asof는 대상 고르는 기준일이다(예상도착일 <= asof). 자재문서 전기일은 항상 오늘이다.
    "   미래 asof로 실제 처리하면 그날까지 도착할 STO를 오늘 날짜로 앞당겨 입고한다(직접 실행에서 확인창 후).
    IF asof IS INITIAL.
      lcl_mm_common=>fail( `입고 기준일이 없습니다.` ).
    ENDIF.
    SELECT SINGLE * FROM z8mm_po_h WHERE ebeln = @document INTO @DATA(head).
    IF sy-subrc <> 0 OR head-bsart <> 'UB'.
      lcl_mm_common=>fail( `유효한 STO가 아닙니다.` ).
    ENDIF.
    " 도래한 미입고 품목만 대상으로 한다(같은 STO는 예상도착일이 같아 보통 전부이다).
    SELECT * FROM z8mm_po_i WHERE ebeln = @document AND elikz = @space AND loekz = @space
      AND sto_arr_date <> '00000000' AND sto_arr_date <= @asof
      ORDER BY ebelp INTO TABLE @DATA(open_items).
    IF open_items IS INITIAL.
      lcl_mm_common=>fail( `입고할 품목이 없습니다(미도래·완료·취소).` ).
    ENDIF.

    IF lines( open_items ) > 9999.
      lcl_mm_common=>fail( `입고 자재문서 품목 수 한도(9999)를 초과했습니다.` ).
    ENDIF.
    TYPES: BEGIN OF ty_rcv,
             matnr TYPE z8mm_po_i-matnr,
             werks TYPE z8mm_po_i-werks,
             lgort TYPE z8mm_po_i-lgort,
             meins TYPE z8mm_po_i-meins,
             menge TYPE z8mm_po_i-menge,
             dst TYPE z8material_stk_m,
           END OF ty_rcv.
    DATA rcv TYPE SORTED TABLE OF ty_rcv WITH UNIQUE KEY matnr werks lgort.

    " 1) 품목별 검사
    LOOP AT open_items INTO DATA(pi).
      IF pi-sto_dep_date IS INITIAL OR pi-sto_dep_date > asof
        OR pi-sto_arr_date < pi-sto_dep_date
        OR pi-kdauf IS NOT INITIAL OR pi-kdpos IS NOT INITIAL OR pi-proc_seq IS NOT INITIAL
        OR pi-sto_rsv_qty <> 0 OR pi-reswk IS INITIAL OR pi-reslo IS INITIAL
        OR pi-werks IS INITIAL OR pi-lgort IS INITIAL
        OR pi-menge <= 0 OR pi-reswk = pi-werks.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 입고할 수 없는 상태입니다.| ).
      ENDIF.
      DATA(ref) = CONV z8mm_matdoc_i-ref_item( pi-ebelp ).
      SELECT * FROM z8mm_matdoc_i WHERE zzreftype = '03' AND zzrefdoc = @document
        AND ref_item = @ref INTO TABLE @DATA(history).
      DATA gi_count TYPE i.
      CLEAR gi_count.                 " 같은 메서드의 다음 품목에서는 다시 0부터 센다.
      LOOP AT history TRANSPORTING NO FIELDS WHERE bwart = '351'.
        gi_count = gi_count + 1.
      ENDLOOP.
      IF gi_count <> 1.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 351 출고이력은 정확히 1건이어야 합니다.| ).
      ENDIF.
      LOOP AT history INTO DATA(move).
        IF move-bwart = '101'.
          lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 101 입고이력이 이미 있습니다.| ).
        ELSEIF move-bwart <> '351'.
          lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 351 이외 이동이력이 있어 수동 확인이 필요합니다.| ).
        ENDIF.
        IF move-matnr <> pi-matnr OR move-werks <> pi-reswk OR move-lgort <> pi-reslo
          OR move-menge <> pi-menge OR move-meins <> pi-meins.
          lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 351 실적과 STO 품목 내용이 다릅니다.| ).
        ENDIF.
        SELECT SINGLE mblnr FROM z8mm_matdoc_h WHERE mblnr = @move-mblnr
          AND mjahr = @move-mjahr INTO @DATA(gi_header).
        IF sy-subrc <> 0.
          lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 351 헤더 누락| ).
        ENDIF.
      ENDLOOP.
      SELECT COUNT( * ) FROM z8mm_sto_hist
        WHERE ebeln = @document AND ebelp = @pi-ebelp AND bwart = '101' INTO @DATA(hist_gr_count).
      IF hist_gr_count <> 0.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: STO 이력에 101 입고가 이미 있습니다.| ).
      ENDIF.
      DATA(current_company) = lcl_mm_stock=>company( pi-werks ).
      DATA(source_company) = lcl_mm_stock=>company( pi-reswk ).
      IF current_company <> source_company OR current_company <> head-bukrs.
        lcl_mm_common=>fail( `생성 후 STO 회사 연결이 변경되었습니다.` ).
      ENDIF.
      READ TABLE rcv ASSIGNING FIELD-SYMBOL(<rcv>)
        WITH TABLE KEY matnr = pi-matnr werks = pi-werks lgort = pi-lgort.
      IF sy-subrc <> 0.
        INSERT VALUE #( matnr = pi-matnr werks = pi-werks lgort = pi-lgort meins = pi-meins )
          INTO TABLE rcv ASSIGNING <rcv>.
      ELSEIF <rcv>-meins <> pi-meins.
        lcl_mm_common=>fail( |{ pi-matnr }: 같은 자재의 품목별 단위가 다릅니다.| ).
      ENDIF.
      <rcv>-menge = <rcv>-menge + pi-menge.
    ENDLOOP.

    " 2) 도착지 이동중재고가 자재별 합계 이상인지
    LOOP AT rcv ASSIGNING <rcv>.
      <rcv>-dst = lcl_mm_stock=>location( VALUE #( matnr = <rcv>-matnr werks = <rcv>-werks lgort = <rcv>-lgort ) ).
      IF <rcv>-dst-umlme < <rcv>-menge OR <rcv>-dst-meins <> <rcv>-meins.
        lcl_mm_common=>fail( |{ <rcv>-matnr }: 도착지 이동중 수량 부족 또는 단위 오류| ).
      ENDIF.
    ENDLOOP.

    " 모의실행이면 검사만 마치고 돌아간다. 아래 실제 재고·문서 저장은 실행하지 않는다.
    IF simulation = abap_true.
      RETURN.
    ENDIF.

    " 3) 재고: 자재별 합계로 이동중재고 → 현재고
    LOOP AT rcv ASSIGNING <rcv>.
      UPDATE z8material_stk_m SET umlme = umlme - @<rcv>-menge,
        labst = labst + @<rcv>-menge
        WHERE matnr = @<rcv>-matnr AND werks = @<rcv>-werks AND lgort = @<rcv>-lgort
        AND umlme = @<rcv>-dst-umlme AND labst = @<rcv>-dst-labst.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |{ <rcv>-matnr }: 101 입고 재고 변경 충돌| ).
      ENDIF.
    ENDLOOP.

    " 4) 101 자재문서 헤더 1건 + 품목줄 N개 + 이력 + 품목 입고완료
    DATA nr TYPE nriv-nrlevel.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING object = 'Z8MATDOCH' nr_range_nr = '01'
      IMPORTING number = nr EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0 OR nr < 1 OR nr > 9999999999.
      lcl_mm_common=>fail( `자재문서 번호범위 Z8MATDOCH/01 오류` ).
    ENDIF.
    DATA docno TYPE n LENGTH 10.
    docno = nr.
    DATA(mh) = VALUE z8mm_matdoc_h( mandt = sy-mandt mblnr = docno
      mjahr = sy-datum(4) bldat = sy-datum budat = sy-datum ).
    INSERT z8mm_matdoc_h FROM @mh.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `101 문서 헤더 실패` ).
    ENDIF.
    DATA zeile TYPE z8mm_matdoc_i-zeile.
    LOOP AT open_items INTO pi.
      zeile = zeile + 1.
      DATA(gr) = VALUE z8mm_matdoc_i( mandt = sy-mandt mblnr = docno
        mjahr = mh-mjahr zeile = zeile bwart = '101'
        matnr = pi-matnr werks = pi-werks lgort = pi-lgort
        menge = pi-menge meins = pi-meins zzreftype = '03'
        zzrefdoc = document ref_item = CONV z8mm_matdoc_i-ref_item( pi-ebelp ) ).
      INSERT z8mm_matdoc_i FROM @gr.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 101 문서 품목 실패| ).
      ENDIF.
      lcl_mm_sto=>append_history( po_item = pi doc_head = mh doc_item = gr ).
      UPDATE z8mm_po_i SET elikz = 'X' WHERE ebeln = @document
        AND ebelp = @pi-ebelp AND elikz = @space AND loekz = @space.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: STO 입고완료 표시 실패| ).
      ENDIF.
    ENDLOOP.
    SELECT COUNT( * ) FROM z8mm_po_i WHERE ebeln = @document
      AND loekz = @space AND elikz = @space INTO @DATA(still_open).
    IF still_open = 0.
      UPDATE z8mm_po_h SET procstat = '20' WHERE ebeln = @document.
    ELSE.
      UPDATE z8mm_po_h SET procstat = '15' WHERE ebeln = @document.
    ENDIF.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `STO 헤더 완료 처리 실패` ).
    ENDIF.
    result = docno.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD route_days : 출발·도착 플랜트의 지역으로 운송일수를 구한다. DB 변경 없음.
  " ------------------------------------------------------------
  METHOD route_days.
    SELECT SINGLE region_code FROM z8plant_m WHERE werks = @source INTO @DATA(from_region).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `출발 플랜트 지역 없음` ).
    ENDIF.
    SELECT SINGLE region_code FROM z8plant_m WHERE werks = @dest INTO @DATA(to_region).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `도착 플랜트 지역 없음` ).
    ENDIF.
    days = lcl_mm_stock=>route( source = from_region dest = to_region ).
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD append_event : 예약(RSV)·예약취소(CAN)처럼 재고 이동이 없는 STO 이력을 남긴다.
  "   키(EBELN·EBELP·GJAHR·BELNR·BUZEI)에서 BELNR은 비우고 BUZEI로 구분한다(예약 1, 취소 2).
  " DB 변경: z8mm_sto_hist. 저장 확정은 호출부 COMMIT.
  " ------------------------------------------------------------
  METHOD append_event.
    lcl_mm_common=>require_lock( ).
    DATA(hist) = VALUE z8mm_sto_hist( mandt = sy-mandt ebeln = po_item-ebeln ebelp = po_item-ebelp
      gjahr = sy-datum(4) buzei = CONV #( seq ) bwart = kind budat = sy-datum matnr = po_item-matnr
      werks = po_item-werks lgort = po_item-lgort reswk = po_item-reswk reslo = po_item-reslo
      menge = po_item-menge meins = po_item-meins erdat = sy-datum erzet = sy-uzeit ernam = sy-uname ).
    INSERT z8mm_sto_hist FROM @hist.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( |STO 이력({ kind }) 저장 실패: 이번 처리를 롤백합니다.| ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD ship_sto : 예약중 STO의 출고일이 도래한 품목을 출고한다(배치에서 입고 전에 호출).
  "   품목별 검사 → 자재별 합계로 출발지 현재고·예약재고 차감, 도착지 이동중재고 증가
  "   → 351 자재문서 1건(N줄) + STO 이력 → 품목 STO_RSV_QTY = 0, 헤더 procstat 15(이동중).
  "   한 품목이라도 실패하면 예외 → 호출부 ROLLBACK(이 STO는 다음 실행으로).
  " DB 변경: z8material_stk_m, z8mm_matdoc_h, z8mm_matdoc_i, z8mm_po_h, z8mm_po_i, z8mm_sto_hist.
  " ------------------------------------------------------------
  METHOD ship_sto.
    lcl_mm_common=>require_lock( ).
    CLEAR result.
    " asof는 대상 고르는 기준일이다(출고일 <= asof). 자재문서 전기일은 항상 오늘이다.
    "   미래 asof로 실제 처리하면 그날까지 출고할 예약 STO를 오늘 날짜로 앞당겨 출고한다(직접 실행에서 확인창 후).
    IF asof IS INITIAL.
      lcl_mm_common=>fail( `출고 기준일이 없습니다.` ).
    ENDIF.
    SELECT SINGLE * FROM z8mm_po_h WHERE ebeln = @document INTO @DATA(head).
    IF sy-subrc <> 0 OR head-bsart <> 'UB'.
      lcl_mm_common=>fail( `유효한 STO가 아닙니다.` ).
    ENDIF.
    SELECT * FROM z8mm_po_i WHERE ebeln = @document AND elikz = @space AND loekz = @space
      AND sto_rsv_qty > 0 AND sto_dep_date <> '00000000' AND sto_dep_date <= @asof
      ORDER BY ebelp INTO TABLE @DATA(due_items).
    IF due_items IS INITIAL.
      lcl_mm_common=>fail( `출고할 예약 품목이 없습니다(미도래·출고완료·취소).` ).
    ENDIF.
    TYPES: BEGIN OF ty_shp,
             matnr TYPE z8mm_po_i-matnr,
             meins TYPE z8mm_po_i-meins,
             menge TYPE z8mm_po_i-menge,
             src TYPE z8material_stk_m,
             dst TYPE z8material_stk_m,
             dst_new TYPE abap_bool,
           END OF ty_shp.
    DATA shp TYPE SORTED TABLE OF ty_shp WITH UNIQUE KEY matnr.
    IF lines( due_items ) > 9999.
      lcl_mm_common=>fail( `출고 자재문서 품목 수 한도(9999)를 초과했습니다.` ).
    ENDIF.
    DATA first TYPE z8mm_po_i.
    READ TABLE due_items INDEX 1 INTO first.
    DATA(src_company) = lcl_mm_stock=>company( first-reswk ).
    DATA(dst_company) = lcl_mm_stock=>company( first-werks ).
    IF src_company <> dst_company OR dst_company <> head-bukrs.
      lcl_mm_common=>fail( `생성 후 STO 회사 연결이 변경되었습니다.` ).
    ENDIF.
    LOOP AT due_items INTO DATA(pi).
      IF pi-matnr IS INITIAL OR pi-menge <= 0 OR pi-meins IS INITIAL
        OR pi-sto_rsv_qty <> pi-menge OR pi-kdauf IS NOT INITIAL
        OR pi-kdpos IS NOT INITIAL OR pi-proc_seq IS NOT INITIAL
        OR pi-reswk <> first-reswk OR pi-werks <> first-werks OR pi-reswk = pi-werks
        OR pi-reslo <> '0001' OR pi-lgort <> '0001'
        OR pi-sto_dep_date <> first-sto_dep_date OR pi-sto_arr_date <> first-sto_arr_date
        OR pi-sto_arr_date IS INITIAL OR pi-sto_arr_date < pi-sto_dep_date.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 출고할 수 없는 예약 상태입니다.| ).
      ENDIF.
      " 예약표시가 잘못 남았어도 같은 품목을 두 번 출고하지 않는다.
      DATA ref_item TYPE z8mm_matdoc_i-ref_item.
      ref_item = pi-ebelp.
      SELECT SINGLE mblnr FROM z8mm_matdoc_i
        WHERE zzreftype = '03' AND zzrefdoc = @document AND ref_item = @ref_item
        INTO @DATA(old_move).
      IF sy-subrc = 0.
        lcl_mm_common=>fail( |품목 { pi-ebelp }: 이미 자재문서 이력이 있어 예약 출고를 중단합니다.| ).
      ENDIF.
      SELECT SINGLE ebeln FROM z8mm_sto_hist
        WHERE ebeln = @document AND ebelp = @pi-ebelp AND bwart <> 'RSV'
        INTO @DATA(old_event).
      IF sy-subrc = 0.
        lcl_mm_common=>fail( |품목 { pi-ebelp }: 예약 이외 처리이력이 있어 출고를 중단합니다.| ).
      ENDIF.
      READ TABLE shp ASSIGNING FIELD-SYMBOL(<s>) WITH TABLE KEY matnr = pi-matnr.
      IF sy-subrc <> 0.
        INSERT VALUE #( matnr = pi-matnr meins = pi-meins ) INTO TABLE shp ASSIGNING <s>.
      ELSEIF <s>-meins <> pi-meins.
        lcl_mm_common=>fail( |{ pi-matnr }: 같은 자재의 품목별 단위가 다릅니다.| ).
      ENDIF.
      <s>-menge = <s>-menge + pi-menge.
    ENDLOOP.
    LOOP AT shp ASSIGNING <s>.
      <s>-src = lcl_mm_stock=>location( VALUE #( matnr = <s>-matnr werks = first-reswk lgort = first-reslo ) ).
      IF <s>-src-zzrsvqty < <s>-menge OR <s>-src-labst < <s>-menge OR <s>-src-meins <> <s>-meins.
        lcl_mm_common=>fail( |{ <s>-matnr }: 출발지 현재고·예약재고가 예약수량보다 적습니다.| ).
      ENDIF.
      <s>-dst = lcl_mm_stock=>location(
        VALUE #( matnr = <s>-matnr werks = first-werks lgort = first-lgort ) ).
      IF <s>-dst-meins <> <s>-meins.
        lcl_mm_common=>fail( |{ <s>-matnr }: 도착지 자재 단위가 다릅니다.| ).
      ENDIF.
      SELECT SINGLE matnr FROM z8material_stk_m
        WHERE matnr = @<s>-matnr AND werks = @first-werks AND lgort = @first-lgort
        INTO @DATA(dst_exists).
      <s>-dst_new = xsdbool( sy-subrc <> 0 ).
    ENDLOOP.
    IF simulation = abap_true.
      RETURN.                                " 모의실행: 검사만
    ENDIF.
    " 재고: 출발 현재고·예약재고 감소, 도착 이동중재고 증가(읽은 값 그대로일 때만 = 동시 변경 방지)
    LOOP AT shp ASSIGNING <s>.
      UPDATE z8material_stk_m SET labst = labst - @<s>-menge, zzrsvqty = zzrsvqty - @<s>-menge
        WHERE matnr = @<s>-matnr AND werks = @first-reswk AND lgort = @first-reslo
        AND labst = @<s>-src-labst AND zzrsvqty = @<s>-src-zzrsvqty.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |{ <s>-matnr }: 출발지 351 차감 충돌| ).
      ENDIF.
      IF <s>-dst_new = abap_true.
        INSERT z8material_stk_m FROM @<s>-dst.
        IF sy-subrc <> 0.
          lcl_mm_common=>fail( |{ <s>-matnr }: 도착지 재고행 생성 실패| ).
        ENDIF.
      ENDIF.
      UPDATE z8material_stk_m SET umlme = umlme + @<s>-menge
        WHERE matnr = @<s>-matnr AND werks = @first-werks AND lgort = @first-lgort
        AND umlme = @<s>-dst-umlme.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |{ <s>-matnr }: 도착지 이동중재고 증가 실패| ).
      ENDIF.
    ENDLOOP.
    " 351 자재문서(팀 공용 번호범위 Z8MATDOCH)
    DATA nr TYPE nriv-nrlevel.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING object = 'Z8MATDOCH' nr_range_nr = '01'
      IMPORTING number = nr EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0 OR nr < 1 OR nr > 9999999999.
      lcl_mm_common=>fail( `자재문서 번호범위 Z8MATDOCH/01 오류` ).
    ENDIF.
    DATA docno TYPE n LENGTH 10.
    docno = nr.
    DATA(mh) = VALUE z8mm_matdoc_h( mandt = sy-mandt mblnr = docno
      mjahr = sy-datum(4) bldat = sy-datum budat = sy-datum ).
    INSERT z8mm_matdoc_h FROM @mh.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `351 문서 헤더 실패` ).
    ENDIF.
    DATA zeile TYPE z8mm_matdoc_i-zeile.
    LOOP AT due_items INTO pi.
      zeile = zeile + 1.
      DATA(gi) = VALUE z8mm_matdoc_i( mandt = sy-mandt mblnr = docno
        mjahr = mh-mjahr zeile = zeile bwart = '351'
        matnr = pi-matnr werks = pi-reswk lgort = pi-reslo
        menge = pi-menge meins = pi-meins zzreftype = '03'
        zzrefdoc = document ref_item = CONV z8mm_matdoc_i-ref_item( pi-ebelp ) ).
      INSERT z8mm_matdoc_i FROM @gi.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 351 문서 품목 실패| ).
      ENDIF.
      lcl_mm_sto=>append_history( po_item = pi doc_head = mh doc_item = gi ).
      UPDATE z8mm_po_i SET sto_rsv_qty = 0 WHERE ebeln = @document AND ebelp = @pi-ebelp
        AND sto_rsv_qty = @pi-sto_rsv_qty AND elikz = @space AND loekz = @space.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 예약 해제(출고) 표시 실패| ).
      ENDIF.
    ENDLOOP.
    SELECT COUNT( * ) FROM z8mm_po_i WHERE ebeln = @document
      AND loekz = @space AND elikz = @space AND sto_rsv_qty > 0 INTO @DATA(still_reserved).
    IF still_reserved = 0.
      UPDATE z8mm_po_h SET procstat = '15' WHERE ebeln = @document.
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( `STO 헤더 이동중 처리 실패` ).
      ENDIF.
    ENDIF.
    result = docno.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD cancel_sto : 예약중 STO 전체 취소. 출고(351)된 품목이 하나라도 있으면 취소 불가.
  "   출발지 예약재고 감소 → 품목 LOEKZ = X, STO_RSV_QTY = 0 → 품목별 '예약 취소' 이력(CAN).
  " DB 변경: z8material_stk_m, z8mm_po_i, z8mm_sto_hist. 저장 확정은 호출부 COMMIT.
  " ------------------------------------------------------------
  METHOD cancel_sto.
    lcl_mm_common=>require_lock( ).
    SELECT SINGLE * FROM z8mm_po_h WHERE ebeln = @document INTO @DATA(head).
    IF sy-subrc <> 0 OR head-bsart <> 'UB'.
      lcl_mm_common=>fail( `유효한 STO가 아닙니다.` ).
    ENDIF.
    SELECT * FROM z8mm_po_i WHERE ebeln = @document AND loekz = @space
      ORDER BY ebelp INTO TABLE @DATA(open_items).
    IF open_items IS INITIAL.
      lcl_mm_common=>fail( `이미 취소된 STO입니다.` ).
    ENDIF.
    TYPES: BEGIN OF ty_cnl,
             matnr TYPE z8mm_po_i-matnr,
             meins TYPE z8mm_po_i-meins,
             menge TYPE z8mm_po_i-menge,
             src TYPE z8material_stk_m,
           END OF ty_cnl.
    DATA cnl TYPE SORTED TABLE OF ty_cnl WITH UNIQUE KEY matnr.
    DATA(first) = open_items[ 1 ].
    LOOP AT open_items INTO DATA(pi).
      IF pi-matnr IS INITIAL OR pi-meins IS INITIAL
        OR pi-reswk IS INITIAL OR pi-werks IS INITIAL OR pi-reswk = pi-werks
        OR pi-reslo <> '0001' OR pi-lgort <> '0001'
        OR pi-elikz IS NOT INITIAL OR pi-sto_rsv_qty <> pi-menge OR pi-sto_rsv_qty <= 0
        OR pi-kdauf IS NOT INITIAL OR pi-kdpos IS NOT INITIAL OR pi-proc_seq IS NOT INITIAL
        OR pi-reswk <> first-reswk OR pi-reslo <> first-reslo
        OR pi-werks <> first-werks OR pi-lgort <> first-lgort.
        lcl_mm_common=>fail( `예약수량·창고·참조키를 확인하세요. 정상 예약중 STO만 취소할 수 있습니다.` ).
      ENDIF.
      DATA ref_item TYPE z8mm_matdoc_i-ref_item.
      ref_item = pi-ebelp.
      SELECT SINGLE mblnr FROM z8mm_matdoc_i
        WHERE zzreftype = '03' AND zzrefdoc = @document AND ref_item = @ref_item
        INTO @DATA(old_move).
      IF sy-subrc = 0.
        lcl_mm_common=>fail( `자재문서 이력이 있는 STO는 예약 취소할 수 없습니다.` ).
      ENDIF.
      SELECT SINGLE ebeln FROM z8mm_sto_hist
        WHERE ebeln = @document AND ebelp = @pi-ebelp AND bwart <> 'RSV'
        INTO @DATA(old_event).
      IF sy-subrc = 0.
        lcl_mm_common=>fail( `예약 이외 처리이력이 있는 STO는 예약 취소할 수 없습니다.` ).
      ENDIF.
      READ TABLE cnl ASSIGNING FIELD-SYMBOL(<c>) WITH TABLE KEY matnr = pi-matnr.
      IF sy-subrc <> 0.
        INSERT VALUE #( matnr = pi-matnr meins = pi-meins ) INTO TABLE cnl ASSIGNING <c>.
      ELSEIF <c>-meins <> pi-meins.
        lcl_mm_common=>fail( |{ pi-matnr }: 같은 자재의 품목별 단위가 다릅니다.| ).
      ENDIF.
      <c>-menge = <c>-menge + pi-sto_rsv_qty.
    ENDLOOP.
    LOOP AT cnl ASSIGNING <c>.
      <c>-src = lcl_mm_stock=>location( VALUE #( matnr = <c>-matnr werks = first-reswk lgort = first-reslo ) ).
      IF <c>-src-zzrsvqty < <c>-menge OR <c>-src-meins <> <c>-meins.
        lcl_mm_common=>fail( |{ <c>-matnr }: 출발지 예약재고 부족 또는 단위 오류입니다.| ).
      ENDIF.
      UPDATE z8material_stk_m SET zzrsvqty = zzrsvqty - @<c>-menge
        WHERE matnr = @<c>-matnr AND werks = @first-reswk AND lgort = @first-reslo
        AND zzrsvqty = @<c>-src-zzrsvqty.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |{ <c>-matnr }: 예약재고 해제 충돌| ).
      ENDIF.
    ENDLOOP.
    LOOP AT open_items INTO pi.
      UPDATE z8mm_po_i SET loekz = 'X', sto_rsv_qty = 0 WHERE ebeln = @document AND ebelp = @pi-ebelp
        AND loekz = @space AND elikz = @space AND sto_rsv_qty = @pi-sto_rsv_qty.
      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        lcl_mm_common=>fail( |품목 { pi-ebelp } { pi-matnr }: 취소 표시 실패| ).
      ENDIF.
      lcl_mm_sto=>append_event( po_item = pi kind = 'CAN' seq = 2 ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
