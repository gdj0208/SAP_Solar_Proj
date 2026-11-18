*&---------------------------------------------------------------------*
*& Include ZMMSTO0100_E01
*&---------------------------------------------------------------------*
*& 초기값·라벨·F4·시작 처리
*&   PUR·PR에서 넘어온 값(p_pur*)으로 목록 또는 입력 화면을 연다.
*& 담당: MM(이규빈) / 프로그램: ZMMSTO0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: 지사 간 자재이동(STO) 목록·입력·취소 (개발 10/17~10/23)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: STO 1건 품목 N줄 구조, 목록 카드·이력 ALV
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: STO 예약 추가, 취소 메시지 202·134 구분, 수량 소수점·카드 크기 수정
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
  p_due = 'A'.
  " 출고일 기간 기본값: 오늘 앞뒤 15일(PR 목록과 동일). 예약 STO는 출고일이 미래라 뒤쪽도 본다.
  p_dfrom = sy-datum - 15.
  p_dto = sy-datum + 15.

AT SELECTION-SCREEN OUTPUT.
  gv_lsrc = '출발 플랜트'.
  gv_ldst = '도착 플랜트'.
  gv_ldoc = 'STO 번호'.
  gv_lmat = '자재번호'.
  " 회계전표 조회처럼: 기간 시작 라벨에 * (필수), 오른쪽은 "종료"
  gv_ldfr = '출고일자 *'.
  gv_ldto = '종료'.
  gv_bqry = '조회'.
  gv_esrc = '출발 플랜트'.
  gv_edst = '도착 플랜트'.
  gv_lwant = '도착희망일 *'.      " 출고일은 오른쪽에 자동 표시
  " 코드 칸 옆 이름(지사명·자재명). 코드를 바꾸고 Enter/F4 하면 다시 채운다.
  PERFORM fill_names.
  IF sy-dynnr = '1200'.
    " 한 화면 = 한 조합(출발→도착). STO를 생성(저장)하면 플랜트를 잠근다.
    "   자재를 입력하는 중에는 플랜트를 바꿀 수 있다. [초기화]를 누르면 다시 열린다.
    DATA lv_hdr_lock TYPE abap_bool.
    PERFORM entry_header_locked CHANGING lv_hdr_lock.
    LOOP AT SCREEN.
      IF screen-group1 = 'FIX' OR ( screen-group1 = 'HDR' AND lv_hdr_lock = abap_true )
        OR ( screen-group1 = 'DAT' AND gv_posted = abap_true ).   " 저장 후에는 도착희망일도 잠금
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

" 글자 일부만 넣고 Enter 해도 찾아 준다(1건이면 자동 완성, 여러 건이면 목록).
AT SELECTION-SCREEN ON p_sfrom.
  lcl_mm_f4=>resolve( EXPORTING kind = 'PLANT' CHANGING value = p_sfrom ).
AT SELECTION-SCREEN ON p_sto.
  lcl_mm_f4=>resolve( EXPORTING kind = 'PLANT' CHANGING value = p_sto ).
AT SELECTION-SCREEN ON p_mat.
  lcl_mm_f4=>resolve( EXPORTING kind = 'MAT' CHANGING value = p_mat ).
AT SELECTION-SCREEN ON p_doc.
  lcl_mm_f4=>resolve( EXPORTING kind = 'STO' CHANGING value = p_doc ).
AT SELECTION-SCREEN ON p_from.
  lcl_mm_f4=>resolve( EXPORTING kind = 'PLANT' CHANGING value = p_from ).
AT SELECTION-SCREEN ON p_to.
  lcl_mm_f4=>resolve( EXPORTING kind = 'PLANT' CHANGING value = p_to ).

" 입력 서브스크린(1200) PAI: 플랜트·도착희망일이 정해지면 출고일·예상도착일을 다시 계산한다.
AT SELECTION-SCREEN.
  IF sy-dynnr = '1200'.
    PERFORM calc_schedule.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sfrom.
  PERFORM screen_help USING 'PLANT' 'P_SFROM'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sto.
  PERFORM screen_help USING 'PLANT' 'P_STO'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_mat.
  PERFORM screen_help USING 'MAT' 'P_MAT'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_doc.
  PERFORM screen_help USING 'STO' 'P_DOC'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_from.
  PERFORM screen_help USING 'PLANT' 'P_FROM'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_to.
  PERFORM screen_help USING 'PLANT' 'P_TO'.

START-OF-SELECTION.
  CREATE OBJECT go_events.
  " PUR에서 넘긴 STO 번호로 목록을 연다.
  " 시작일 필수 규칙: 기간을 비우지 않고 그 STO의 출고일 하루로 맞춘다.
  IF p_purdoc IS NOT INITIAL.
    p_doc = p_purdoc.
    SELECT MIN( sto_dep_date ) FROM z8mm_po_i WHERE ebeln = @p_purdoc INTO @p_dfrom.
    IF p_dfrom IS INITIAL.
      p_dfrom = sy-datum.
    ENDIF.
    CLEAR p_dto.
  ENDIF.
  " PUR에서 고른·방금 만든 STO(메모리 Z8MM_STO_MARK)는 조회조건과 관계없이 맨 위 파란 줄·선택으로 보여준다.
  DATA lt_sto_marks TYPE STANDARD TABLE OF z8mm_po_h-ebeln WITH EMPTY KEY.
  IMPORT marks = lt_sto_marks FROM MEMORY ID 'Z8MM_STO_MARK'.
  FREE MEMORY ID 'Z8MM_STO_MARK'.
  LOOP AT lt_sto_marks INTO DATA(lv_sto_mark).
    INSERT lv_sto_mark INTO TABLE gt_new_sto.
  ENDLOOP.
  gv_mark_new = xsdbool( gt_new_sto IS NOT INITIAL ).
  PERFORM query_list.
  " PUR의 [STO 생성]: 입력화면만 열고, 뒤로 가면 PUR로 돌아간다.
  " 저장에 성공하면 같은 실행 안에서 STO 목록(0100)으로 바뀌어 방금 만든 STO가 선택돼 보인다.
  IF p_new = abap_true AND p_list <> abap_true.
    gv_direct = abap_true.
    PERFORM reset_entry.
    CALL SCREEN 0200.
    LEAVE PROGRAM.
  ENDIF.
  CALL SCREEN 0100.
