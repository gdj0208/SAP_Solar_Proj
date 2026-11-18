*&---------------------------------------------------------------------*
*& Include          Z8MMSH0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form check_input
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_input .
  " 플랜트가 입력된 경우 존재 여부 확인
  IF s_werks[] IS NOT INITIAL.
    SELECT SINGLE werks FROM z8plant_m
      WHERE werks IN @s_werks
      INTO @DATA(lv_werks).
    IF sy-subrc <> 0.
      MESSAGE '입력한 플랜트가 존재하지 않습니다.' TYPE 'E'.
    ENDIF.
  ENDIF.

  IF p_rate < 1 OR p_rate > 100.
    MESSAGE '재주문 비율은 1~100 사이여야 합니다.' TYPE 'E'.
  ENDIF.

  IF p_days < 0.
    MESSAGE '납기 기본 일수는 0 이상이어야 합니다.' TYPE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form select_target
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_target .

"뷰 사용
CLEAR: gt_alv, gv_checked.

  " 목표수량이 등록된 자재·플랜트 (사용중단 자재 제외) - DB 뷰 Z8V_MATPLANT 사용
  SELECT matnr, werks, mabst, eisbe
    FROM z8v_matplant
    WHERE matnr IN @s_matnr
      AND werks IN @s_werks
      AND mabst > 0
      AND mmsta = '01'         " 플랜트 사용 상태
      AND mstae <> '99'        " 사용중단 자재 제외
    INTO CORRESPONDING FIELDS OF TABLE @gt_alv.

  gv_checked = lines( gt_alv ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form select_stock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_stock .
  TYPES: BEGIN OF lty_stk,
           matnr    TYPE z8material_stk_m-matnr,
           werks    TYPE z8material_stk_m-werks,
           labst    TYPE z8material_stk_m-labst,        "가용재고
           zzrsvqty TYPE z8material_stk_m-zzrsvqty, "예약재고
         END OF lty_stk.

  DATA: lt_stk TYPE STANDARD TABLE OF lty_stk,
        ls_stk TYPE lty_stk.

  " 저장위치 0001 재고만 읽는다- (저장위치 비어있는 줄 걸러냄)
  SELECT matnr werks labst zzrsvqty
    FROM z8material_stk_m
    INTO TABLE lt_stk
    FOR ALL ENTRIES IN gt_alv
    WHERE matnr = gt_alv-matnr
      AND werks = gt_alv-werks
      AND lgort = '0001'.

*  SORT lt_stk BY werks ASCENDING
*                             matnr ASCENDING.
  SORT lt_stk BY matnr werks.

  LOOP AT gt_alv INTO gs_alv.
    CLEAR ls_stk.                          " 재고 줄이 없으면 0으로 남는다
    READ TABLE lt_stk INTO ls_stk
         WITH KEY matnr = gs_alv-matnr
                  werks = gs_alv-werks
         BINARY SEARCH.

    gs_alv-labst    = ls_stk-labst.
    gs_alv-zzrsvqty = ls_stk-zzrsvqty.

    " 가용재고 = 현재고 - 예약재고 - 안전재고
    gs_alv-avail    = gs_alv-labst - gs_alv-zzrsvqty - gs_alv-eisbe.
    " 재주문 기준 = 목표수량 x 비율
    gs_alv-base_qty = gs_alv-mabst * p_rate / 100.

    MODIFY gt_alv FROM gs_alv.             " 계산한 값을 테이블에 되돌려 넣는다
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_inbound
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM calc_inbound_pr . "입고예정 수량 계산.
  TYPES: BEGIN OF lty_pr,
           matnr TYPE z8mm_pr-matnr,
           werks TYPE z8mm_pr-werks,
           menge TYPE z8mm_pr-menge,   "이동중인 수량
         END OF lty_pr.

  DATA: lt_pr TYPE STANDARD TABLE OF lty_pr,
        ls_pr TYPE lty_pr.
  "PR에서 EBELN이 빈줄(PO로 안넘어간 PR)을 한번에 읽어두고,

  " 1. 아직 PO가 안 된 PR (EBELN이 비어 있는 것)
  SELECT matnr werks menge
    FROM z8mm_pr
    INTO TABLE lt_pr
    WHERE ebeln = ''  " PO로 전환 전 = 구매요청 대기
    AND loekz = ''     " 삭제 표시 안 된 것
    AND source_type IN ( 'SAFETY' , 'INSPECT' , 'STO_REPL' )
      AND matnr IN s_matnr
      AND werks IN s_werks.

  " 자재/플랜트별로 menge를 더한다.
  LOOP AT gt_alv INTO gs_alv.
    CLEAR gs_alv-inb_pr.
    LOOP AT lt_pr INTO ls_pr
         WHERE matnr = gs_alv-matnr
           AND werks = gs_alv-werks.
      gs_alv-inb_pr = gs_alv-inb_pr + ls_pr-menge.
    ENDLOOP.

    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_inbound_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM calc_inbound_po.
  TYPES: BEGIN OF lty_po,
           ebeln TYPE z8mm_po_i-ebeln,
           matnr TYPE z8mm_po_i-matnr,
           werks TYPE z8mm_po_i-werks,
           menge TYPE z8mm_po_i-menge,
         END OF lty_po.

  DATA: lt_raw    TYPE STANDARD TABLE OF lty_po,
        lt_po     TYPE STANDARD TABLE OF lty_po,     " PO번호+자재+플랜트별 합계
        lt_done   TYPE STANDARD TABLE OF lty_po,     " 처리된 입고/반품 합계
        ls_po     TYPE lty_po,
        ls_done   TYPE lty_po,
        lv_remain TYPE z8mm_po_i-menge.

  " 0. 모든 줄의 2번 값을 먼저 비운다
  LOOP AT gt_alv INTO gs_alv.
    CLEAR gs_alv-inb_po.
    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.

  " 1. 열린 PO 품목 (삭제 안 됨, 납품완료 아님, 헤더 상태 10 또는 15)
  SELECT i~ebeln i~matnr i~werks i~menge
    FROM z8mm_po_i AS i
    INNER JOIN z8mm_po_h AS h ON h~ebeln = i~ebeln
    INTO TABLE lt_raw
    WHERE i~matnr IN s_matnr
      AND i~werks IN s_werks
      AND i~loekz = ''
      AND i~elikz = ''
      AND ( h~procstat = '10' OR h~procstat = '15' ). "입고안됨/ 부분입고.

  IF lt_raw IS INITIAL.
    RETURN.
  ENDIF.

  " PO번호 + 자재 + 플랜트가 같은 줄은 수량을 합친다  (합계)
  LOOP AT lt_raw INTO ls_po.
    COLLECT ls_po INTO lt_po.
  ENDLOOP.

  " 2. 그 PO에 대해 처리된 입고(105)와 반품(124) 수량
  TYPES: BEGIN OF lty_doc,
           zzrefdoc TYPE z8mm_matdoc_i-zzrefdoc,
           matnr    TYPE z8mm_matdoc_i-matnr,
           werks    TYPE z8mm_matdoc_i-werks,
           menge    TYPE z8mm_matdoc_i-menge,
         END OF lty_doc.
  DATA: lt_doc TYPE STANDARD TABLE OF lty_doc,
        ls_doc TYPE lty_doc.

  SELECT zzrefdoc matnr werks menge
    FROM z8mm_matdoc_i
    INTO TABLE lt_doc
    FOR ALL ENTRIES IN lt_po
    WHERE zzrefdoc = lt_po-ebeln
      AND matnr    = lt_po-matnr
      AND werks    = lt_po-werks
      AND ( bwart = '105' OR bwart = '124' )
      AND mblnr <> ''.

  LOOP AT lt_doc INTO ls_doc.
    CLEAR ls_done.
    ls_done-ebeln = ls_doc-zzrefdoc.
    ls_done-matnr = ls_doc-matnr.
    ls_done-werks = ls_doc-werks.
    ls_done-menge = ls_doc-menge.
    COLLECT ls_done INTO lt_done.
  ENDLOOP.

  " 3. 남은 수량 = PO 수량 - 처리 수량 (0보다 작으면 0)
  LOOP AT lt_po INTO ls_po.
    CLEAR ls_done.
    READ TABLE lt_done INTO ls_done
         WITH KEY ebeln = ls_po-ebeln
                  matnr = ls_po-matnr
                  werks = ls_po-werks.
    lv_remain = ls_po-menge - ls_done-menge.
    IF lv_remain < 0.
      lv_remain = 0.
    ENDIF.

    READ TABLE gt_alv INTO gs_alv
         WITH KEY matnr = ls_po-matnr
                  werks = ls_po-werks.
    IF sy-subrc = 0.
      gs_alv-inb_po = gs_alv-inb_po + lv_remain.
      MODIFY gt_alv FROM gs_alv INDEX sy-tabix.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_reorder
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_reorder .
  DATA: lv_net TYPE z8material_stk_m-labst.

  LOOP AT gt_alv INTO gs_alv.
    " 확보된 수량 = 가용재고 + 입고예정
    lv_net = gs_alv-avail + gs_alv-inbound.

    IF lv_net < gs_alv-base_qty.
      " 재주문 대상: 목표수량까지 채울 수량
      gs_alv-order_qty = gs_alv-mabst - lv_net.
*      IF lv_net < 0.
*        gs_alv-fill_rate = 0.
*      ELSE.
*        gs_alv-fill_rate = lv_net * 100 / gs_alv-mabst.
*      ENDIF.

      MODIFY gt_alv FROM gs_alv.
    ELSE.
      " 충분하면 목록에서 제외 (점검 건수에는 이미 포함됨)
      DELETE gt_alv.
    ENDIF.
  ENDLOOP.

  gv_target = lines( gt_alv ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form select_vendor
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM select_vendor.
  TYPES: BEGIN OF lty_info,
           matnr TYPE z8purch_info_m-matnr,
           lifnr TYPE z8purch_info_m-lifnr,
           meins TYPE z8purch_info_m-meins,
           netpr TYPE z8purch_info_m-netpr,
           peinh TYPE z8purch_info_m-peinh,
           waers TYPE z8purch_info_m-waers,
           minbm TYPE z8purch_info_m-minbm,
         END OF lty_info.

  DATA: lt_info      TYPE STANDARD TABLE OF lty_info,
        ls_info      TYPE lty_info,
        ls_best      TYPE lty_info,
        lv_unit      TYPE p LENGTH 15 DECIMALS 4,   " 업체 줄의 단가 (NETPR / PEINH)
        lv_best      TYPE p LENGTH 15 DECIMALS 4,   " 지금까지 가장 낮은 단가
        lv_found     TYPE c LENGTH 1,
        lv_days      TYPE i,                         " 이 업체에서 이 플랜트까지 이동일수
        lv_best_days TYPE i.                         " 최저가 후보의 이동일수

  IF gt_alv IS INITIAL.
    RETURN.
  ENDIF.

  " 대상 자재의 구매정보를 한 번에 읽는다
  SELECT matnr lifnr meins netpr peinh waers minbm
    FROM z8purch_info_m
    INTO TABLE lt_info
    FOR ALL ENTRIES IN gt_alv
    WHERE matnr = gt_alv-matnr.

  SORT lt_info BY matnr lifnr.          " 단가와 이동일수가 모두 같으면 업체번호가 작은 쪽이 먼저

  LOOP AT gt_alv INTO gs_alv.
    CLEAR: ls_best, lv_best, lv_found, lv_best_days.

    " 같은 자재를 파는 업체 줄 중 단가(NETPR / PEINH)가 가장 낮은 줄 고르기
    " 단가가 같으면 이동일수가 짧은 쪽 → ls_best에 저장
    LOOP AT lt_info INTO ls_info WHERE matnr = gs_alv-matnr.
      IF ls_info-peinh = 0.
        CONTINUE.                        " 0으로 나누기 방지
      ENDIF.
      lv_unit = ls_info-netpr / ls_info-peinh.

      " 이 업체에서 이 플랜트까지 이동일수 (업체 권역 → 플랜트 권역)
      PERFORM get_days USING ls_info-lifnr gs_alv-werks CHANGING lv_days.

      IF lv_found = ''
          OR lv_unit < lv_best
          OR ( lv_unit = lv_best AND lv_days < lv_best_days ).
        ls_best      = ls_info.
        lv_best      = lv_unit.
        lv_best_days = lv_days.
        lv_found     = 'X'.
      ENDIF.
    ENDLOOP.

    IF lv_found = 'X'.
      gs_alv-lifnr = ls_best-lifnr.
      gs_alv-preis = lv_best.
      gs_alv-meins = ls_best-meins.
      gs_alv-waers = ls_best-waers.
      gs_alv-minbm = ls_best-minbm.
      " 최소 구매수량보다 적으면 최소 구매수량으로 올린다
      IF gs_alv-order_qty < ls_best-minbm.
        gs_alv-order_qty = ls_best-minbm.
      ENDIF.
    ELSE.
      gs_alv-remark = '구매정보 없음'.
    ENDIF.

    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_due_date
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM calc_due_date .
  "업체의 권역 → 플랜트의 권역 → Z8ROUTE_M에서 운송일수를 찾고,
  " 없으면 선택 화면의 납기 기본 일수(7)를 쓴다.
  DATA: lv_from TYPE z8vendor_m-region_code,
        lv_to   TYPE z8plant_m-region_code,
        lv_est  TYPE z8route_m-est_transit_days,
        lv_days TYPE i.

  LOOP AT gt_alv INTO gs_alv.
    " 업체를 못 찾은 줄(구매정보 없음)은 납기를 계산하지 않는다
    IF gs_alv-lifnr IS INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR: lv_from, lv_to, lv_est.

    " 출발 권역 = 업체의 권역, 도착 권역 = 플랜트의 권역
    SELECT SINGLE region_code FROM z8vendor_m
      INTO lv_from
      WHERE lifnr = gs_alv-lifnr.

    SELECT SINGLE region_code FROM z8plant_m
      INTO lv_to
      WHERE werks = gs_alv-werks.

    " 기본값은 선택 화면의 납기 기본 일수, 경로가 있으면 예상 운송일수 사용
    lv_days = p_days.

    SELECT SINGLE est_transit_days FROM z8route_m
      INTO lv_est
      WHERE from_region = lv_from
        AND to_region   = lv_to
        AND use_yn      = 'Y'.
    IF sy-subrc = 0.
      lv_days = lv_est.
    ENDIF.

    gs_alv-lfdat = sy-datum + lv_days.
    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_pr.
  DATA: ls_pr    TYPE z8mm_pr,
        lv_nr    TYPE n LENGTH 8,
*            lv_max    TYPE z8mm_pr-banfn,
*            lv_seq    TYPE n LENGTH 4,
        lv_error TYPE c LENGTH 1.

  CLEAR: gv_created, gv_skipped, gv_planned.

  LOOP AT gt_alv INTO gs_alv.

    " 구매정보가 없어 업체를 못 찾은 줄은 건너뜀
    IF gs_alv-lifnr IS INITIAL.
      gs_alv-light = '1'. "icon_red_light.
      gv_skipped = gv_skipped + 1.
      MODIFY gt_alv FROM gs_alv.
      CONTINUE.
    ENDIF.

    " 시험 실행: DB에 저장하지 않고 표시만(번호도 받지 않음)
    IF p_test = 'X'.
      gs_alv-light = '2'.
      gv_planned  = gv_planned + 1.
      MODIFY gt_alv FROM gs_alv.
      CONTINUE.
    ENDIF.

    " 실제 실행: PR 한 줄 만들기
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'Z8MMPRN'
      IMPORTING
        number      = lv_nr
      EXCEPTIONS
        OTHERS      = 1.
    IF sy-subrc <> 0.
      lv_error = 'X'.
      EXIT.
    ENDIF.
    CLEAR ls_pr.
    ls_pr-mandt       = sy-mandt.
    CONCATENATE 'PR' lv_nr INTO ls_pr-banfn.
    ls_pr-bnfpo       = '00010'.
    ls_pr-bsart       = 'NB'.
    ls_pr-matnr       = gs_alv-matnr.
    ls_pr-menge       = gs_alv-order_qty.
    ls_pr-meins       = gs_alv-meins.
    ls_pr-werks       = gs_alv-werks.
    ls_pr-lgort       = '0001'.
    ls_pr-lfdat       = gs_alv-lfdat.
    ls_pr-lifnr       = gs_alv-lifnr.
    ls_pr-preis       = gs_alv-preis.
    ls_pr-waers       = gs_alv-waers.
    ls_pr-source_type = 'SAFETY'.

    INSERT z8mm_pr FROM ls_pr.
    IF sy-subrc <> 0.
      lv_error = 'X'.
      EXIT.
    ENDIF.

    gs_alv-banfn = ls_pr-banfn.
    gs_alv-light  = '3'.
    gv_created   = gv_created + 1.
    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.

  " 한 건이라도 실패하면 전부 취소
  IF lv_error = 'X'.
    ROLLBACK WORK.
    MESSAGE E137(z8_msg).
  ELSEIF p_exec = 'X'.
    COMMIT WORK.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form write_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM write_list .
  "확인용 임시 출력
  WRITE: / '점검', gv_checked, '건 / 재주문 대상', gv_target,
        '건 / PR 생성', gv_created, '건 / 건너뜀', gv_skipped, '건'.
  SKIP.
  WRITE: / '자재코드', 14 '플랜트', 22 '      목표', 34 '      기준',
           46 '    현재고', 58 '      예약', 70 '      안전', 82 '      가용',
           94 '  입고예정', 106 '  주문수량', 118 '  공급업체',  132 '       단가',
           146 '비고', 170 '  납기일'.
  ULINE.
  LOOP AT gt_alv INTO gs_alv.
    WRITE: / gs_alv-matnr,
           14 gs_alv-werks,
           22(10) gs_alv-mabst     DECIMALS 0,
           34(10) gs_alv-base_qty  DECIMALS 0,
           46(10) gs_alv-labst     DECIMALS 0,
           58(10) gs_alv-zzrsvqty  DECIMALS 0,
           70(10) gs_alv-eisbe     DECIMALS 0,
           82(10) gs_alv-avail     DECIMALS 0,
           94(10) gs_alv-inbound   DECIMALS 0,
           106(10) gs_alv-order_qty DECIMALS 0,
           118(10) gs_alv-lifnr,
           130(14) gs_alv-preis CURRENCY gs_alv-waers DECIMALS 0,
           146(20) gs_alv-remark,
           170(10) gs_alv-lfdat,
           182 gs_alv-light AS ICON,
           188(10) gs_alv-banfn.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects .
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'B_ALV'.
  CREATE OBJECT go_alv
    EXPORTING
      i_parent = go_cont.

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
  gs_layout-zebra      = 'X'.
  gs_layout-info_fname = 'COLOR'.      " 건너뜀 줄 색 (3번에서 채움)
  gs_layout-excp_fname = 'LIGHT'.
  gs_layout-excp_led = 'X'.
  DATA lv_extra TYPE string.
  IF gv_skipped > 0.
    lv_extra = |, 구매정보 없음 { gv_skipped }건|.
  ENDIF.

  IF p_test = 'X'.
    gs_layout-grid_title = |[시험 실행] 점검 { gv_checked }건 중 재고 부족 { gv_target }건 → PR { gv_planned }건 생성 예정{ lv_extra } (저장 안 됨)|.
  ELSE.
    gs_layout-grid_title = |[실제 실행] 점검 { gv_checked }건 중 재고 부족 { gv_target }건 → PR { gv_created }건 생성 완료{ lv_extra }|.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  DATA ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LIGHT'.     ls_fcat-coltext = '상태'.        ls_fcat-outputlen = 5.  " ls_fcat-icon = 'X'.
  ls_fcat-tooltip = '노랑: PR 생성 예정 / 초록: 생성 완료 / 빨강: 건너뜀'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'REMARK'.   ls_fcat-coltext = '처리 내용'.   ls_fcat-outputlen = 11.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MATNR'.    ls_fcat-coltext = '자재코드'.    ls_fcat-outputlen = 10.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MAKTX'.    ls_fcat-coltext = '자재명'.      ls_fcat-outputlen = 17.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'WERKS'.    ls_fcat-coltext = '플랜트'.      ls_fcat-outputlen = 7.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'PNAME'.    ls_fcat-coltext = '플랜트명'.    ls_fcat-outputlen = 11.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MABST'.    ls_fcat-coltext = '목표수량'.    ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'BASE_QTY'. ls_fcat-coltext = '재주문 기준'. ls_fcat-outputlen = 10.  ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LABST'.    ls_fcat-coltext = '현재고'.      ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'ZZRSVQTY'. ls_fcat-coltext = '예약재고'.    ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'EISBE'.    ls_fcat-coltext = '안전재고'.    ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'AVAIL'.    ls_fcat-coltext = '가용재고'.    ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'INBOUND'.  ls_fcat-coltext = '입고예정'.    ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'ORDER_QTY'. ls_fcat-coltext = '주문수량'.   ls_fcat-outputlen = 8.   ls_fcat-decimals_o = '0'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LIFNR'.    ls_fcat-coltext = '업체코드'.    ls_fcat-outputlen = 11.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LIFNAME'.  ls_fcat-coltext = '공급업체'.    ls_fcat-outputlen = 12.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'PREIS'.    ls_fcat-coltext = '단가'.        ls_fcat-outputlen = 12.  ls_fcat-cfieldname = 'WAERS'.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'LFDAT'.    ls_fcat-coltext = '납기일'.      ls_fcat-outputlen = 10.
  APPEND ls_fcat TO gt_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = 'BANFN'.    ls_fcat-coltext = 'PR번호'.      ls_fcat-outputlen = 12.
  APPEND ls_fcat TO gt_fcat.

*  CLEAR ls_fcat.
*  ls_fcat-fieldname = 'FILL_RATE'.    ls_fcat-coltext = '확보율(%)'.      ls_fcat-outputlen = 10.
*  ls_fcat-tooltip = '(가용재고+입고예정) % 목표수량'.
*  APPEND ls_fcat TO gt_fcat.
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
      is_layout       = gs_layout
    CHANGING
      it_outtab       = gt_alv
      it_fieldcatalog = gt_fcat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fill_display
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM fill_display .
  TYPES: BEGIN OF lty_mat,
           matnr TYPE z8material_m-matnr,
           maktx TYPE z8material_txt_m-maktx,
         END OF lty_mat,
         BEGIN OF lty_plant,
           werks TYPE z8plant_m-werks,
           name1 TYPE z8plant_m-name1,
         END OF lty_plant,
         BEGIN OF lty_vend,
           lifnr TYPE z8vendor_m-lifnr,
           name1 TYPE z8vendor_m-name1,
         END OF lty_vend.
  DATA: lt_mat   TYPE STANDARD TABLE OF lty_mat,
        ls_mat   TYPE lty_mat,
        lt_plant TYPE STANDARD TABLE OF lty_plant,
        ls_plant TYPE lty_plant,
        lt_vend  TYPE STANDARD TABLE OF lty_vend,
        ls_vend  TYPE lty_vend,
        lv_base  TYPE c LENGTH 30,
        lv_old   TYPE c LENGTH 60.
  "자재명, 플랜트명, 공급업체명  가져오기.
  SELECT matnr maktx
    FROM z8material_txt_m INTO TABLE lt_mat
      WHERE spras = '3'.
  SELECT werks name1
    FROM z8plant_m    INTO TABLE lt_plant.
  SELECT lifnr name1
    FROM z8vendor_m   INTO TABLE lt_vend.
  "이름 채움.
  LOOP AT gt_alv INTO gs_alv.
    READ TABLE lt_mat INTO ls_mat WITH KEY matnr = gs_alv-matnr.
    IF sy-subrc = 0.
      gs_alv-maktx = ls_mat-maktx.
    ENDIF.

    READ TABLE lt_plant INTO ls_plant WITH KEY werks = gs_alv-werks.
    IF sy-subrc = 0.
      gs_alv-pname = ls_plant-name1.
    ENDIF.

    IF gs_alv-lifnr IS NOT INITIAL.
      READ TABLE lt_vend INTO ls_vend WITH KEY lifnr = gs_alv-lifnr.
      IF sy-subrc = 0.
        gs_alv-lifname = ls_vend-name1.
      ENDIF.
    ENDIF.

    " 처리 내용 (기존 비고가 있으면 뒤에 붙인다)
    lv_old = gs_alv-remark.
    IF gs_alv-banfn IS NOT INITIAL.
      lv_base = 'PR 생성 완료'.
    ELSEIF gs_alv-lifnr IS INITIAL.
      lv_base = '건너뜀'.
      gs_alv-color = 'C610'.            " 건너뜀 줄은 빨간색
    ELSEIF p_test = 'X'.
      lv_base = 'PR 생성 예정'.
    ELSE.
      lv_base = '건너뜀 (PR 저장 안 됨)'.
      gs_alv-color = 'C610'.
    ENDIF.

    IF lv_old IS INITIAL.
      gs_alv-remark = lv_base.
    ELSE.
      gs_alv-remark = |{ lv_base } - { lv_old }|.
    ENDIF.

    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.
*  SORT gt_alv BY fill_rate ASCENDING.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_days
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_INFO_LIFNR
*&      --> GS_ALV_WERKS
*&      <-- LV_DAYS
*&---------------------------------------------------------------------*
FORM get_days USING    pv_lifnr TYPE z8e_lifnr
                       pv_werks TYPE z8e_werks
              CHANGING pv_days  TYPE i.
  DATA: lv_from TYPE z8e_region_code,
        lv_to   TYPE z8e_region_code,
        lv_numc TYPE n LENGTH 3.

  pv_days = 999.                                  " 루트가 없으면 큰 값 → 동점일 때 뒤로 밀림

  SELECT SINGLE region_code FROM z8vendor_m
    INTO lv_from WHERE lifnr = pv_lifnr.          " 업체의 권역
  SELECT SINGLE region_code FROM z8plant_m
    INTO lv_to   WHERE werks = pv_werks.          " 플랜트의 권역 (필드명 확인!)

  SELECT SINGLE est_transit_days FROM z8route_m
    INTO lv_numc
    WHERE from_region = lv_from
      AND to_region   = lv_to
      AND use_yn      = 'Y'.
  IF sy-subrc = 0.
    pv_days = lv_numc.                            " NUMC → 정수로 옮김 (001 → 1)
  ENDIF.
ENDFORM.
