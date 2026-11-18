*&---------------------------------------------------------------------*
*& Include          Z8MMGR100F02
*&---------------------------------------------------------------------*

FORM get_po_h .
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF gs_po_h
    FROM z8mm_po_h
    WHERE ebeln = gv_ebeln.
ENDFORM.

FORM get_po_i .
  SELECT SINGLE *
    INTO CORRESPONDING FIELDS OF gs_po_i
    FROM z8mm_po_i
    WHERE ebeln = gv_ebeln
      AND ebelp = gv_ebelp.
ENDFORM.

FORM get_datas .

  " 1. PO_H, PO_I에서 가져온 정보를 바탕으로 데이터에 넣기
  SELECT SINGLE h~lifnr, v~name1, bedat, werks, lgort, maktx, i~matnr, netpr, i~waers,  i~meins, i~menge
    INTO ( @p_sup2,  @gv_name, @p_ordat, @p_plant, @p_strloc, @p_matnam, @p_matcod, @p_netpr, @gv_peinh, @p_meins, @p_menge )
  FROM z8mm_po_h AS h
    INNER JOIN z8vendor_m AS v ON h~lifnr = v~lifnr
    INNER JOIN z8mm_po_i AS i ON h~ebeln = i~ebeln
    INNER JOIN z8material_txt_m AS t ON t~matnr = i~matnr
  WHERE i~ebeln = @gs_po_i-ebeln
    AND i~ebelp = @gs_po_i-ebelp.

DATA(lv_zetc) = |{ gs_po_i-ebelp ALPHA = OUT }|.

  " 2. 입고된 자재 수량 구하기
  SELECT SUM( menge )
    FROM z8mm_matdoc_i
   WHERE matnr = @p_matcod
     AND zzrefdoc = @gs_po_i-ebeln
     and zetc = @lv_zetc
     AND bwart = '105'
    INTO @p_inv.

  " 3. 금액 보정
  IF gs_po_i-waers = 'KRW'. p_netpr = gs_po_i-netpr * 100.  " 15.00 * 100 = 1,500 출력
  ELSE. p_netpr = gs_po_i-netpr.
  ENDIF.

ENDFORM.

FORM make_matdoc .
  DATA: lv_answer TYPE c.

  " 1. 자재이동문서 생성 확인 팝업
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = '검증 내역을 저장하시겠습니까?'(q01) " 화면에 표시될 질문
      text_button_1         = '예'(a01)                 " 버튼 1 텍스트
      text_button_2         = '아니오'(a02)             " 버튼 2 텍스트
      display_cancel_button = ''                       " 취소 버튼 표시 여부 ('X' = 표시, ' ' = 숨김)
    IMPORTING
      answer                = lv_answer                 " 사용자의 선택 결과
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0. MESSAGE S202(Z8_MSG) WITH |자재이동문서 생성| DISPLAY LIKE 'E'. RETURN. ENDIF.

  " 2. 자재이동문서 생성 및 저장하기
  IF lv_answer = '1'.

    " 2-0. 구매오더 자재이동문서 다시 불러오기
    gv_ebeln = gs_po_h-ebeln.
    DATA(lv_zetc) = |{ gs_po_i-ebelp ALPHA = OUT }|.

    " 2-1. 정상입고(105) / 2-2. 반품(124)
    IF p_in  <> 0. PERFORM create_matdoc_i USING 'IN'.  ENDIF.
    IF p_ret <> 0. PERFORM create_matdoc_i USING 'RET'. ENDIF.

    MESSAGE s053(z8_msg).

    " 2-4. 종료
    "CALL FUNCTION 'DEQUEUE_ALL'.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Include          ZMMGR020F02
*&---------------------------------------------------------------------*

FORM create_matdoc_i  USING p_type TYPE char3.

  DATA :
        lv_mblnr TYPE mblnr.

  " 아이템 품목 번호 구하기
  " (채번 코드를 사용하는게 정석이지만 야메로...)
  CLEAR gv_new_doc_no.
  LOOP AT gt_matdoc_i INTO DATA(ls_exist).
    IF ls_exist-zeile > gv_new_doc_no.
      gv_new_doc_no = ls_exist-zeile.
    ENDIF.
  ENDLOOP.
  gv_new_doc_no = gv_new_doc_no + 1.
  CLEAR gs_matdoc_i.

  IF p_type = 'IN'.
    gs_matdoc_i-bwart = 105.
    gs_matdoc_i-menge = p_in.
    "gs_matdoc_i-wrbtr = gs_po_i-netpr * p_in.
  ELSEIF p_type = 'RET'.
    gs_matdoc_i-bwart = 124.
    gs_matdoc_i-menge = p_ret.
    "gs_matdoc_i-wrbtr = gs_po_i-netpr * p_ret.
  ENDIF.

  PERFORM calc_amount USING    gs_po_i-matnr
                               gs_po_i-netpr
                               gs_matdoc_i-menge
                      CHANGING gs_matdoc_i-wrbtr.

*  gs_matdoc_i-mblnr =  lv_mblnr.

  gs_matdoc_i-mjahr = p_date(+4).
  gs_matdoc_i-zeile = gv_new_doc_no.
  gs_matdoc_i-matnr = p_matcod.
  gs_matdoc_i-werks = p_plant.
  gs_matdoc_i-lgort = p_strloc.
  gs_matdoc_i-meins = p_meins.
  gs_matdoc_i-zzrefdoc = gv_ebeln.
  gs_matdoc_i-waers = gv_peinh.

  gs_matdoc_i-zetc = |{ gs_po_i-ebelp ALPHA = OUT }|.

  CASE gs_po_h-bsart.
    WHEN 'NB'. " 표준 구매 오더
      gs_matdoc_i-zzreftype = '01'.
    WHEN 'UB'. " 재고 이송 오더 (플랜트간 이동)
      gs_matdoc_i-zzreftype = '03'.
    WHEN OTHERS.
  ENDCASE.

  APPEND gs_matdoc_i TO gt_matdoc_i.
*  MODIFY z8mm_matdoc_i FROM gs_matdoc_i.
*  IF sy-subrc <> 0.
*    MESSAGE |자재 이동문서 생성 실패| type 'S' DISPLAY LIKE 'E'.
*  ENDIF.

ENDFORM.

FORM clear_data .
  CLEAR :
    p_inv,
    p_in,
    p_ret.

  "CLEAR : gt_matdoc_i, gs_matdoc_i, gt_matdoc_h, gs_matdoc_h.
ENDFORM.

*&---------------------------------------------------------------------*
*& 가격단위(PEINH) 조회 : 자재 기본단위가 M이면 100, 그 외 1
*&---------------------------------------------------------------------*
FORM get_peinh USING    pv_matnr TYPE z8mm_po_i-matnr
               CHANGING pv_peinh TYPE z8material_val_m-peinh.
  DATA lv_meins TYPE z8material_m-meins.

  SELECT SINGLE meins
    INTO @lv_meins
    FROM z8material_m
   WHERE matnr = @pv_matnr.

  IF lv_meins = 'M'.
    pv_peinh = 100.
  ELSE.
    pv_peinh = 1.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& 금액 계산 : 수량 × 단가 ÷ 가격단위
*&---------------------------------------------------------------------*
FORM calc_amount USING    pv_matnr TYPE z8mm_po_i-matnr
                          pv_netpr TYPE numeric
                          pv_menge TYPE numeric
                 CHANGING pv_wrbtr TYPE numeric.
  DATA lv_peinh TYPE z8material_val_m-peinh.

  PERFORM get_peinh USING pv_matnr CHANGING lv_peinh.

  " 곱셈을 먼저 하고 나눠야 소수점 손실이 없음
  pv_wrbtr = pv_netpr * pv_menge / lv_peinh.
ENDFORM.

FORM init_screen_200 .
  DATA(lv_zetc) = |{ gv_ebelp ALPHA = OUT }|.

  " 1. 표시 필드 + 입력 필드 전부 초기화
  CLEAR : p_sup2, gv_name, p_ordat, p_plant, p_strloc,
          p_matnam, p_matcod, p_netpr, gv_peinh, p_meins,
          p_menge, p_inv, p_in, p_ret.
  p_date = sy-datum.

  " 2. 같은 품목에 확정 대기 중인 내역이 있으면 다시 채워 넣기
  LOOP AT gt_matdoc_i INTO DATA(ls_pend)
       WHERE zzrefdoc = gv_ebeln
         AND zetc     = lv_zetc.
    CASE ls_pend-bwart.
      WHEN '105'. p_in  = p_in  + ls_pend-menge.
      WHEN '124'. p_ret = p_ret + ls_pend-menge.
    ENDCASE.
  ENDLOOP.
ENDFORM.
