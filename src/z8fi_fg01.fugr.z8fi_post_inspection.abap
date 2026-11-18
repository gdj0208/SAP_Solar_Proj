FUNCTION z8fi_post_inspection.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_PRO_ID) TYPE  Z8PS_PROJECT-PRO_ID
*"  EXPORTING
*"     REFERENCE(EV_BELNR) TYPE  Z8FI_ACCDOC_H-BELNR
*"     REFERENCE(EV_GJAHR) TYPE  Z8FI_ACCDOC_H-GJAHR
*"     REFERENCE(EV_RETURN) TYPE  SY-SUBRC
*"     REFERENCE(EV_MESSAGE) TYPE  STRING
*"  EXCEPTIONS
*"      PROJECT_NOT_FOUND
*"      INSPECTION_NOT_COMPLETED
*"      DATA_ERROR
*"      ALREADY_POSTED
*"      INVALID_AMOUNT
*"      POSTING_FAILED
*"----------------------------------------------------------------------

  DATA:
    ls_project TYPE z8ps_project,
    ls_so      TYPE z8sd_so_h,
    ls_bill    TYPE z8sd_billing_h,

    lv_belnr   TYPE z8fi_accdoc_h-belnr,
    lv_gjahr   TYPE z8fi_accdoc_h-gjahr,
    lv_bupla   TYPE z8fi_accdoc_i-bupla,
    lv_ar_amt  TYPE z8fi_accdoc_i-wrbtr,
    lv_monat   TYPE z8fi_accdoc_h-monat,
    lv_bldat   TYPE z8fi_accdoc_h-bldat, "증빙일
    lv_budat   TYPE z8fi_accdoc_h-budat, "전기일
    lv_prctr   TYPE z8fi_accdoc_i-prctr,

    ls_acc_h   TYPE z8fi_accdoc_h,
    lt_acc_i   TYPE TABLE OF z8fi_accdoc_i,
    ls_acc_i   TYPE z8fi_accdoc_i,
    ls_cust    TYPE z8fi_customer.

  "검증용
  DATA:
    lv_debit  TYPE z8fi_accdoc_i-wrbtr,
    lv_credit TYPE z8fi_accdoc_i-wrbtr,
    lv_lines  TYPE i.

  CLEAR:
        ev_belnr,
        ev_gjahr,
        ev_message.

  "프로젝트 조회
  IF iv_pro_id IS INITIAL.
    ev_message = '프로젝트 ID가 입력되지 않았습니다.'.
    RAISE data_error.
  ENDIF.

  SELECT SINGLE *
    FROM z8ps_project
    INTO ls_project
    WHERE pro_id = iv_pro_id.

  IF sy-subrc <> 0.
    RAISE project_not_found.
  ENDIF.

  "고객 검수 상태 확인 60
  IF ls_project-status_p <> '60'.
    RAISE inspection_not_completed.
  ENDIF.

  lv_bupla = ls_project-branch.

  IF lv_bupla IS INITIAL.
    RAISE data_error.
  ENDIF.

  "so 번호 조회
  SELECT SINGLE *
    FROM z8sd_so_h
    INTO ls_so
    WHERE vbeln_s = ls_project-vbeln.

  IF sy-subrc <> 0.
    RAISE data_error.
  ENDIF.

  "선수금 청구서 조회
  SELECT SINGLE *
    FROM z8sd_billing_h
    INTO ls_bill
    WHERE vgbel = ls_so-vbeln_q
        AND fkart = 'F1'
        AND zzpayst = '02'.
*        AND bupla = lv_bupla.

  IF sy-subrc <> 0.
    RAISE data_error.
  ENDIF.

  "검수완료 건에 대해 전표 중복 생성 확인
  CLEAR: lv_belnr, lv_gjahr.

  SELECT SINGLE belnr gjahr
    FROM z8fi_accdoc_h
    INTO ( lv_belnr, lv_gjahr )
    WHERE bukrs = ls_bill-bukrs
        AND blart = 'DR'
        AND xblnr = iv_pro_id.

  IF sy-subrc = 0.
    RAISE already_posted.
  ENDIF.

  "금액 검증
  "1) 총 계약금액 확인
  IF ls_so-netwr IS INITIAL OR ls_so-netwr <= 0.
    RAISE invalid_amount.
  ENDIF.

  "2) 선수금 금액 확인
  IF ls_bill-netwr IS INITIAL OR ls_bill-netwr <= 0.
    RAISE invalid_amount.
  ENDIF.

  "3) 선수금이 총 계약금액 보다 큰 경우
  IF ls_bill-netwr >= ls_so-netwr.
    RAISE invalid_amount.
  ENDIF.

  "+) 통화 일치
  IF ls_bill-waerk <> ls_so-waerk.
    RAISE data_error.
  ENDIF.

  lv_ar_amt = ls_so-netwr - ls_bill-netwr.

  "문서 증빙일은 최종 고객 검수 완료일로
  SELECT SINGLE inspect_date
     FROM z8ps_custom_inv
       INTO lv_bldat
   WHERE pro_id = iv_pro_id
       AND insp_res = 'Y'.

  IF sy-subrc <> 0 OR lv_bldat IS INITIAL.
    RAISE data_error.
  ENDIF.

  lv_budat = lv_bldat.
  lv_gjahr = lv_budat+0(4).
  lv_monat = lv_budat+4(2).

  "손익센터
  SELECT SINGLE prctr
    FROM z8procenter_m
    INTO lv_prctr
    WHERE bukrs = ls_bill-bukrs
    AND prctr = 'SLS01'
    AND use_yn = 'Y'.

  IF sy-subrc <> 0.
    ev_message = '사용 가능한 영업부 손익센터가 없습니다'.
    RAISE data_error.
  ENDIF.

  "전표번호(belnr) 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8FI_BELNR'
      toyear                  = lv_gjahr
    IMPORTING
      number                  = lv_belnr
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
*    ev_message = '전표번호 채번 중 오류가 발생했습니다.'.
    RAISE posting_failed.
  ENDIF.

  "회계전표 h구성
  CLEAR ls_acc_h.
  ls_acc_h-bukrs = ls_bill-bukrs.
  ls_acc_h-belnr = lv_belnr.
  ls_acc_h-gjahr = lv_gjahr.
  ls_acc_h-monat = lv_monat.
  ls_acc_h-blart = 'DR'.
  ls_acc_h-bldat = lv_bldat.
  ls_acc_h-budat = lv_budat.
  ls_acc_h-waers = ls_so-waerk.
  ls_acc_h-xblnr = iv_pro_id.

  "회계전표 i 구성 - 선수금 상계
  CLEAR ls_acc_i.
  ls_acc_i-bukrs = ls_bill-bukrs.
  ls_acc_i-belnr = lv_belnr.
  ls_acc_i-gjahr = lv_gjahr.
  ls_acc_i-buzei = '001'.
  ls_acc_i-koart = 'D'.
  ls_acc_i-hkont = '21000100'.
  ls_acc_i-bupla = lv_bupla. "ls_bill-bupla.
  ls_acc_i-shkzg = 'S'.
  ls_acc_i-wrbtr = ls_bill-netwr.
  ls_acc_i-waers = ls_bill-waerk.
  ls_acc_i-kunnr = ls_so-kunnr.
  ls_acc_i-umskz = 'A'.

  APPEND ls_acc_i TO lt_acc_i.

  "회계전표 i 구성 - 외상매출금 발생
  CLEAR ls_acc_i.
  ls_acc_i-bukrs = ls_bill-bukrs.
  ls_acc_i-belnr = lv_belnr.
  ls_acc_i-gjahr = lv_gjahr.
  ls_acc_i-buzei = '002'.
  ls_acc_i-koart = 'D'.
  ls_acc_i-hkont = '11010000'.
  ls_acc_i-bupla = lv_bupla.
  ls_acc_i-shkzg = 'S'.
  ls_acc_i-wrbtr = lv_ar_amt.
  ls_acc_i-waers = ls_bill-waerk.
  ls_acc_i-prctr = lv_prctr.
  ls_acc_i-kunnr = ls_so-kunnr.

  APPEND ls_acc_i TO lt_acc_i.

  "회계전표 i 구성 - 매출 인식
  CLEAR ls_acc_i.
  ls_acc_i-bukrs = ls_bill-bukrs.
  ls_acc_i-belnr = lv_belnr.
  ls_acc_i-gjahr = lv_gjahr.
  ls_acc_i-buzei = '003'.
  ls_acc_i-koart = 'S'.
  ls_acc_i-hkont = '41000000'.
  ls_acc_i-bupla = lv_bupla.
  ls_acc_i-shkzg = 'H'.
  ls_acc_i-wrbtr = ls_so-netwr.
  ls_acc_i-waers = ls_so-waerk.
  ls_acc_i-prctr = lv_prctr.

  APPEND ls_acc_i TO lt_acc_i.

  "fi_customer - 고객 미결 발생
  CLEAR ls_cust.
  ls_cust-bukrs = ls_bill-bukrs.
  ls_cust-gjahr = lv_gjahr.
  ls_cust-belnr = lv_belnr.
  ls_cust-bupla = lv_bupla.
  ls_cust-kunnr = ls_so-kunnr.
  ls_cust-wrbtr = lv_ar_amt.
  ls_cust-waers = ls_so-waerk.
  ls_cust-bldat = lv_bldat.
  ls_cust-budat = lv_budat.
  ls_cust-xblnr = iv_pro_id. "ls_so-vbeln_s.

  "최종 검증
  DESCRIBE TABLE lt_acc_i LINES lv_lines.

  IF lv_lines <> 3.
    MESSAGE e064(z8_msg)."'전표 아이템 구성이 올바르지 않습니다.' TYPE 'E'.
    RAISE posting_failed.
  ENDIF.

  "차대 일치
  CLEAR: lv_debit, lv_credit.

  LOOP AT lt_acc_i INTO ls_acc_i.

    IF ls_acc_i-shkzg = 'S'.
      lv_debit = lv_debit + ls_acc_i-wrbtr.
    ELSEIF ls_acc_i-shkzg = 'H'.
      lv_credit = lv_credit + ls_acc_i-wrbtr.
    ENDIF.

  ENDLOOP.

  IF lv_debit IS INITIAL OR lv_credit IS INITIAL OR lv_debit <> lv_credit.
    RAISE posting_failed.
  ENDIF.

  "DB에 데이터 생성
  INSERT z8fi_accdoc_h FROM ls_acc_h.

  IF sy-subrc <> 0 .
    RAISE posting_failed.
  ENDIF.

  INSERT z8fi_accdoc_i FROM TABLE lt_acc_i.

  IF sy-subrc <> 0 OR sy-dbcnt <> 3.
    RAISE posting_failed.
  ENDIF.

  INSERT z8fi_customer FROM ls_cust.

  IF sy-subrc <> 0 .
    RAISE posting_failed.
  ENDIF.

  ev_belnr = lv_belnr.
  ev_gjahr = lv_gjahr.
  ev_message = |회계전표 { lv_belnr }가 생성되었습니다.|.

ENDFUNCTION.
