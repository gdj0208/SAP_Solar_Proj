*&---------------------------------------------------------------------*
*& Include ZMMPO0110_E01
*&---------------------------------------------------------------------*
*& 초기값·라벨·F4·시작 처리
*&   발주일 기본값 오늘-30~오늘, PUR·PR 목록에서 넘어온 값(p_purnew / p_purlst / 메모리) 처리
*& 담당: MM(이규빈) / 프로그램: ZMMPO0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-07  이규빈  최초 개발   최초 작성: PR 묶음 발주(PR N건 → PO 1건), PO 목록·취소 (개발 10/07~10/13)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등, 후보 ALV에서 골라 바로 PO 생성
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 생성 확인 메시지 축약, '납기 충족 / N일 지연', 취소 메시지 202·134 구분
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

INITIALIZATION.
  " 실행 권한: MM 프로그램 권한(Z8MM_ADMIN)의 실행(16)이 없으면 시작하지 않는다(팀 MM 프로그램 공통).
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
    ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.   " MM 관리자 전용 프로그램입니다. 권한을 요청하세요.
  ENDIF.

  p_state = 'A'.
  " 발주 시작일·종료일 기본값: 최근 30일
  p_dfrom = sy-datum - 30.
  p_dto = sy-datum.

AT SELECTION-SCREEN OUTPUT.
  gv_lplt = '구매지사'.
  gv_lmat = '자재번호'.
  gv_lvend = '공급업체'.
  gv_ldoc = 'PO 번호'.
  " 회계전표 조회처럼: 기간 시작 라벨에 * (필수), 오른쪽은 "종료"
  gv_lbfr = '발주일자 *'.
  gv_lbto = '종료'.
  gv_cplt = '구매지사'.
  gv_cmat = '자재번호'.
  gv_cvend = '공급업체'.
  " '납기일까지' → '희망납기까지': 희망납기일이 이 날짜 이하인 PR만 후보로 보여준다(비우면 전체).
  gv_cdat = '희망납기까지'.
  gv_cstat = '상태'.
  gv_csrc = '요청구분'.
  PERFORM cand_listbox.                 " 상태·요청구분 드롭다운 목록
  gv_bqry1 = '조회'.
  gv_bqry2 = '조회'.
  " 코드 칸 옆 이름(지사명·업체명·자재명). 코드를 바꾸고 Enter/F4 하면 다시 채운다.
  PERFORM fill_names.

" PR·STO·PUR과 같은 방식(Z8MM_F4_C01)
"   글자 일부만 넣고 Enter → 1건이면 자동 완성, 여러 건이면 목록. F4도 입력한 글자로 걸러서 보여준다.
AT SELECTION-SCREEN ON p_bupla.
  lcl_mm_f4=>resolve( EXPORTING kind = 'BRANCH' CHANGING value = p_bupla ).
AT SELECTION-SCREEN ON p_lifnr.
  lcl_mm_f4=>resolve( EXPORTING kind = 'VEND' CHANGING value = p_lifnr ).
AT SELECTION-SCREEN ON p_matnr.
  lcl_mm_f4=>resolve( EXPORTING kind = 'MAT' CHANGING value = p_matnr ).
AT SELECTION-SCREEN ON p_doc.
  lcl_mm_f4=>resolve( EXPORTING kind = 'PO' CHANGING value = p_doc ).
AT SELECTION-SCREEN ON c_bupla.
  lcl_mm_f4=>resolve( EXPORTING kind = 'BRANCH' CHANGING value = c_bupla ).
AT SELECTION-SCREEN ON c_lifnr.
  lcl_mm_f4=>resolve( EXPORTING kind = 'VEND' CHANGING value = c_lifnr ).
AT SELECTION-SCREEN ON c_matnr.
  lcl_mm_f4=>resolve( EXPORTING kind = 'MAT' CHANGING value = c_matnr ).

" 구매지사 F4: 팀 서치헬프(Z8SH_BRANCH)를 빈 값으로 열어 칸에 B001이 있어도 전체 지사가 나온다.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_bupla.
  PERFORM screen_help USING 'BRANCH' 'P_BUPLA'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR c_bupla.
  PERFORM screen_help USING 'BRANCH' 'C_BUPLA'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_matnr.
  PERFORM screen_help USING 'MAT' 'P_MATNR'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_lifnr.
  PERFORM screen_help USING 'VEND' 'P_LIFNR'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_doc.
  PERFORM screen_help USING 'PO' 'P_DOC'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR c_matnr.
  PERFORM screen_help USING 'MAT' 'C_MATNR'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR c_lifnr.
  PERFORM screen_help USING 'VEND' 'C_LIFNR'.

START-OF-SELECTION.
  " PUR에서 넘긴 지사·PO번호를 화면 조회조건에 옮긴다.
  " PUR은 입고플랜트(P100)를 넘긴다 → 그 플랜트의 구매지사(B001)로 바꾼다.
  IF p_purwk IS NOT INITIAL.
    SELECT SINGLE bupla FROM z8plant_m WHERE werks = @p_purwk INTO @p_bupla.
  ENDIF.
  IF p_purdoc IS NOT INITIAL.
    p_doc = p_purdoc.
    " 시작일 필수 규칙: 기간을 비우지 않고 그 PO의 발주일 하루로 맞춘다.
    SELECT SINGLE bedat FROM z8mm_po_h WHERE ebeln = @p_purdoc INTO @p_dfrom.
    IF p_dfrom IS INITIAL.
      p_dfrom = sy-datum.
    ENDIF.
    CLEAR p_dto.
  ENDIF.
  " PUR 업무현황에서 [PO 생성]으로 들어오면 생성 화면만 쓰고, 돌아가기 때 PUR로 복귀한다.
  IF p_purnew = abap_true.
    gv_from_pr = abap_true.
    PERFORM open_create.
    CALL SCREEN 0200.
    LEAVE PROGRAM.
  ENDIF.
  " PR 목록(ZMMPR0100)에서 선택해 넘어왔으면 바로 PO 생성 화면(0200)으로 간다.
  IMPORT keys = gt_presel FROM MEMORY ID 'Z8MM_PO_SELECTED'.
  FREE MEMORY ID 'Z8MM_PO_SELECTED'.
  IF gt_presel IS NOT INITIAL.
    gv_from_pr = abap_true.
    PERFORM open_create.
    CALL SCREEN 0200.
    LEAVE PROGRAM.
  ENDIF.
  " 일반 실행과 PUR의 [PO 목록](p_purlst)은 PO 조회 화면으로 시작한다.
  " PUR에서 고른·방금 만든 PO(메모리 Z8MM_PO_MARK)는 조회조건과 관계없이 맨 위 파란 줄·선택으로 보여준다.
  DATA lt_po_marks TYPE STANDARD TABLE OF z8mm_po_h-ebeln WITH EMPTY KEY.
  IMPORT marks = lt_po_marks FROM MEMORY ID 'Z8MM_PO_MARK'.
  FREE MEMORY ID 'Z8MM_PO_MARK'.
  LOOP AT lt_po_marks INTO DATA(lv_po_mark).
    INSERT lv_po_mark INTO TABLE gt_new_po.
  ENDLOOP.
  gv_sel_new = xsdbool( gt_new_po IS NOT INITIAL ).
  PERFORM query_po.
  CALL SCREEN 0100.
