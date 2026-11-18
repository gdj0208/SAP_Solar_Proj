*&---------------------------------------------------------------------*
*& Include          ZMMIP120F02
*&---------------------------------------------------------------------*

FORM upload_and_parse_xml  .

  DATA: lt_filetable TYPE filetable,
        lv_rc        TYPE i,
        lv_filename  TYPE string,
        lt_raw_data  TYPE STANDARD TABLE OF x255,
        lv_file_len  TYPE i,
        lv_xml_xstr  TYPE xstring.

  " 1) 파일 선택 다이얼로그 띄우기
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      default_extension       = 'XML'
      file_filter             = 'XML Files (*.xml)|*.xml|'
    CHANGING
      file_table              = lt_filetable
      rc                      = lv_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.

  "  시스템 에러, GUI 오류 또는 팝업창 강제 종료 등 비정상 상황 처리
  IF sy-subrc <> 0.
    MESSAGE S221(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 사용자가 취소를 누르거나 실제 선택된 파일이 없는 경우 (이중 검증)
  IF lv_rc <= 0 OR lines( lt_filetable ) = 0.
    MESSAGE '파일 선택이 취소되었습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_filetable INTO DATA(ls_file) INDEX 1.
  lv_filename = ls_file-filename.

  " 2) 선택한 XML 파일을 Binary(RAW) 형태로 읽어오기
  CALL METHOD cl_gui_frontend_services=>gui_upload
    EXPORTING
      filename   = lv_filename
      filetype   = 'BIN'
    IMPORTING
      filelength = lv_file_len
    CHANGING
      data_tab   = lt_raw_data
    EXCEPTIONS
      OTHERS     = 1.

  " 3) Binary 테이블을 XSTRING(바이트 문자열)으로 변환
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_file_len
    IMPORTING
      buffer       = lv_xml_xstr
    TABLES
      binary_tab   = lt_raw_data.


  IF lv_xml_xstr(3) = 'EFBBBF'.
    lv_xml_xstr = lv_xml_xstr+3.
  ENDIF.

  TRY.
      CALL TRANSFORMATION ztr_tax_inv
        SOURCE XML lv_xml_xstr
        RESULT doc = gs_xml_doc.

    CATCH cx_transformation_error INTO DATA(lx_err).
      CALL FUNCTION 'POPUP_TO_INFORM'
        EXPORTING
          titel = '세금계산서 파일 형식 오류'
          txt1  = '선택하신 파일은 올바른 세금계산서 XML 형식이 아닙니다.'
          txt2  = '파일 내부에 필수 태그가 누락되었거나 데이터 구조가 손상되었습니다.'
          txt3  = '홈택스에서 다운로드하신 원본 파일이 맞는지 다시 한번 확인해 주세요.'
          txt4  = '※ 계속해서 오류가 발생할 경우 IT 담당자에게 문의 바랍니다.'.

      " 팝업 확인 후 프로세스 중단
      LEAVE LIST-PROCESSING.
  ENDTRY.
ENDFORM.

FORM save_to_invoice_tables USING p_invno.
  DATA:
    lv_bupla    TYPE bupla,
    lv_invno    TYPE inv_no,
    lv_inv_item TYPE z8mm_inv_i-inv_item VALUE 0.

  CHECK gs_xml_doc-issue_id IS NOT INITIAL.

  " [참고] 실무에서는 이 위치에 3-Way Matching 검증 로직이 들어갑니다.


*----------------------------------------------------------------------
* 1. 청구서 헤더 생성
*----------------------------------------------------------------------
  lv_invno = p_invno.
*  PERFORM get_invno CHANGING lv_invno.

  " 1) 매입 송장 헤더(INV_H) 데이터 구성
  gs_inv_h-mandt  = sy-mandt.
  gs_inv_h-inv_no  = |IV{ lv_invno }|.          " 송장 문서번호 (실제는 Number Range 채번)

  gs_inv_h-lifnr  = gs_po_h-lifnr.  " 선택한 입고건의 공급업체 코드
  gs_inv_h-bupla = gs_po_h-bupla. " 종사업장 코드
  gs_inv_h-ekorg = gs_po_h-ekorg. " 구매조직
  gs_inv_h-ekgrp = gs_po_h-ekgrp. " 구매 그룹

  gs_inv_h-bldat  = gs_xml_doc-bldat. " 송장 일자
  gs_inv_h-budat  = sy-datum.          " 전기일

  gs_inv_h-waers  = gs_po_h-waers.  " 통화키
  IF gs_inv_h-waers = 'KRW'.
    gs_inv_h-rmwwr  = gs_xml_doc-rmwwr / 100.  " 총 청구 금액
  ELSE.
    gs_inv_h-rmwwr  = gs_xml_doc-rmwwr.  " 총 청구 금액
  ENDIF.
  gs_inv_h-zzrefdoc = gs_po_h-ebeln. "참조 문서 번호 <- 구매 오더가 들어가야 한다.

  gs_inv_h-rbstat = '4'. "송장 상태 (4 : 정상 전기 - 아무 문제 없이 3way matching을 통과함)
  gs_inv_h-belnr = ''. " 회계 전표 번호
  gs_inv_h-ref_inv_id = gs_xml_doc-issue_id.

*----------------------------------------------------------------------
* 2. 청구서 아이템 생성
*----------------------------------------------------------------------

  " 2) 매입 송장 아이템(ZMMT_INV_I) 데이터 구성
  " XML의 품목 내역과 화면에서 선택한 입고 내역(PO/입고번호)을 결합!
  LOOP AT gs_xml_doc-items INTO DATA(ls_xml_item).
    ADD 1 TO lv_inv_item.

    CLEAR gs_inv_i.
    gs_inv_i-mandt  = sy-mandt.
    gs_inv_i-inv_no = gs_inv_h-inv_no.
    gs_inv_i-inv_item = ls_xml_item-seq. " 송장 품목 번호

    gs_inv_i-menge  = ls_xml_item-menge.      "  청구 수량
    IF gs_inv_h-waers = 'KRW'.
      gs_inv_i-wrbtr = ls_xml_item-wrbtr / 100.
    ELSE.
      gs_inv_i-wrbtr  = ls_xml_item-wrbtr.      " 청구 금액
    ENDIF.

    SELECT SINGLE ebeln, ebelp, i~matnr, meins, waers, maktx
      INTO ( @gs_inv_i-ebeln, @gs_inv_i-ebelp, @gs_inv_i-matnr, @gs_inv_i-meins, @gs_inv_i-waers, @gs_inv_i-maktx )
      FROM z8mm_po_i AS i
        INNER JOIN z8material_txt_m AS t ON i~matnr = t~matnr
      WHERE ebeln = @gs_po_h-ebeln
          AND t~spras = @sy-langu
          AND t~maktx = @ls_xml_item-item_text.

    APPEND gs_inv_i TO gt_inv_i.
  ENDLOOP.

  " 3) DB 테이블에 저장
  "MODIFY z8mm_inv_h FROM gs_inv_h.
  "MODIFY z8mm_inv_i FROM TABLE gt_inv_i.

  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    gv_inv_saved = 'X'.
    MESSAGE |청구서를 성공적으로 불러왔습니다.| TYPE 'I'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE '청구서를 불러오지 못했습니다.' TYPE 'E'.
  ENDIF.

ENDFORM.


FORM map_xml_to_itab.
  DATA: lv_inv_item TYPE z8mm_inv_i-inv_item VALUE 0,
        ls_po_h     TYPE z8mm_po_h..

  CHECK gs_xml_doc-issue_id IS NOT INITIAL.
  CLEAR: gs_inv_h, gt_inv_i.

  " 0) 메모리에 올리기 전, 기준 PO 헤더 데이터를 DB에서 명시적으로 조회
  SELECT SINGLE *
    INTO @ls_po_h
    FROM z8mm_po_h
   WHERE ebeln = @gv_ebeln.
  IF sy-subrc <> 0.
    MESSAGE S220(z8_msg) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 1) 헤더 데이터 메모리 구성
  gs_inv_h-mandt    = sy-mandt.
  gs_inv_h-inv_no   = ''.   " 임시 번호 할당
  gs_inv_h-lifnr    = ls_po_h-lifnr.
  gs_inv_h-bupla    = ls_po_h-bupla.
  gs_inv_h-ekorg    = ls_po_h-ekorg.
  gs_inv_h-ekgrp    = ls_po_h-ekgrp.
  gs_inv_h-ekgrp    = ls_po_h-ekgrp.
  gs_inv_h-waers    = ls_po_h-waers.

  gs_inv_h-bldat    = gs_xml_doc-bldat.
  gs_inv_h-budat    = sy-datum.

  IF gs_inv_h-waers = 'KRW'.
    gs_inv_h-rmwwr  = gs_xml_doc-rmwwr / 100.
  ELSE.
    gs_inv_h-rmwwr  = gs_xml_doc-rmwwr.
  ENDIF.
  gs_inv_h-zzrefdoc = gv_ebeln.
  gs_inv_h-rbstat   = '4'.
  gs_inv_h-ref_inv_id = gs_xml_doc-issue_id.

  " 2) 아이템 데이터 메모리 구성
  LOOP AT gs_xml_doc-items INTO DATA(ls_xml_item).
    ADD 1 TO lv_inv_item.
    CLEAR gs_inv_i.
    gs_inv_i-mandt    = sy-mandt.
    gs_inv_i-inv_no   = gs_inv_h-inv_no.
    gs_inv_i-inv_item = ls_xml_item-seq.
    gs_inv_i-menge    = ls_xml_item-menge.

    " 자재 정보 취득 (XML 자재명 기준으로 PO 아이템 매핑)
    SELECT SINGLE ebeln, ebelp, i~matnr, meins, waers, maktx
      INTO ( @gs_inv_i-ebeln, @gs_inv_i-ebelp, @gs_inv_i-matnr, @gs_inv_i-meins, @gs_inv_i-waers, @gs_inv_i-maktx )
      FROM z8mm_po_i AS i
      INNER JOIN z8material_txt_m AS t ON i~matnr = t~matnr
     WHERE ebeln = @gv_ebeln
       AND t~spras = @sy-langu
       AND t~maktx = @ls_xml_item-item_text.

    " =================================================================
    " [수정] PO에 없는 자재일 경우: 자재 마스터에서 단위(MEINS) 추적
    " =================================================================
    IF sy-subrc <> 0.
      gs_inv_i-maktx = ls_xml_item-item_text.
      gs_inv_i-waers = 'KRW'.

      " 자재 텍스트 테이블과 자재 마스터 테이블 조인하여 단위 가져오기
      SELECT SINGLE m~meins, m~matnr
        INTO ( @gs_inv_i-meins, @gs_inv_i-matnr )
        FROM z8material_txt_m AS t
        INNER JOIN z8material_m AS m ON t~matnr = m~matnr
       WHERE t~spras = @sy-langu
         AND t~maktx = @ls_xml_item-item_text.

      " 마스터에도 없는 미등록 자재일 경우 방어 로직
      IF sy-subrc <> 0.
        gs_inv_i-meins = 'EA'.
      ENDIF.
    ENDIF.

    " 금액 한화 보정 로직 (유지)
    IF gs_inv_i-waers = 'KRW'.
      gs_inv_i-wrbtr = ls_xml_item-wrbtr / 100.
    ELSE.
      gs_inv_i-wrbtr = ls_xml_item-wrbtr.
    ENDIF.

    APPEND gs_inv_i TO gt_inv_i.
  ENDLOOP.

  "MESSAGE S219(z8_msg).
ENDFORM.

FORM get_invno  CHANGING p_lv_invno.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z8_INVNO'
    IMPORTING
      number                  = p_lv_invno
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.
ENDFORM.


FORM update_po_hist .
  "UPDATE z8mm_po_hist SET procstat = '25' WHERE ebeln = gv_ebeln.
ENDFORM.
