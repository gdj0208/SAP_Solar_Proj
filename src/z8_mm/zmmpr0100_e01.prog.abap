*&---------------------------------------------------------------------*
*& Include ZMMPR0100_E01
*&---------------------------------------------------------------------*
*& 초기값·라벨·F4·조회 시작
*&   PUR에서 넘어온 값(p_pur*)을 조회조건에 반영한다.
*& 담당: MM(이규빈) / 프로그램: ZMMPR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-14  이규빈  최초 개발   최초 작성: PR 목록 조회·취소, PR 생성/변경·PO 생성 화면 연결 (개발 10/14~10/16)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등 화면 통일, 조회조건·버튼 동작 보완
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 조회 결과 없음 오류 표시, 취소 메시지 정리
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

INITIALIZATION.
  " 실행 권한: MM 프로그램 권한(Z8MM_ADMIN)의 실행(16)이 없으면 시작하지 않는다(팀 MM 프로그램 공통).
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
    ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.   " MM 관리자 전용 프로그램입니다. 권한을 요청하세요.
  ENDIF.

  p_state = 'W'.
  " 오늘 기준 앞뒤 15일(희망납기일은 앞날짜가 많아서 '오늘까지'로 끊지 않음)
  p_dfrom = sy-datum - 15.
  p_dto = sy-datum + 15.
AT SELECTION-SCREEN OUTPUT.
  gv_lsite = '구매지사'.
  gv_ldoc = 'PR 번호'.
  gv_lvend = '공급업체'.
  gv_lmat = '자재번호'.
  gv_bqry = '조회'.
  " 회계전표 조회처럼: 기간 시작 라벨에 * (필수), 오른쪽은 "종료"
  gv_ldfr = '납기일자 *'.
  gv_ldto = '종료'.
  " 코드 칸 옆 이름(지사명·업체명·자재명). 코드를 바꾸고 Enter/F4 하면 다시 채운다.
  PERFORM fill_names.
" 글자 일부만 넣고 Enter 해도 찾아 준다(1건이면 자동 완성, 여러 건이면 목록).
AT SELECTION-SCREEN ON p_bupla.
  lcl_mm_f4=>resolve( EXPORTING kind = 'BRANCH' CHANGING value = p_bupla ).
AT SELECTION-SCREEN ON p_lifnr.
  lcl_mm_f4=>resolve( EXPORTING kind = 'VEND' CHANGING value = p_lifnr ).
AT SELECTION-SCREEN ON p_matnr.
  lcl_mm_f4=>resolve( EXPORTING kind = 'MAT' CHANGING value = p_matnr ).
AT SELECTION-SCREEN ON p_doc.
  lcl_mm_f4=>resolve( EXPORTING kind = 'PR' CHANGING value = p_doc ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_doc.
  PERFORM screen_help USING 'PR' 'P_DOC'.
" 구매지사 F4: 팀 서치헬프(Z8SH_BRANCH)를 빈 값으로 열어 칸에 B001이 있어도 전체 지사가 나온다.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_bupla.
  PERFORM screen_help USING 'BRANCH' 'P_BUPLA'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_matnr.
  PERFORM screen_help USING 'MAT' 'P_MATNR'.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_lifnr.
  PERFORM screen_help USING 'VEND' 'P_LIFNR'.
START-OF-SELECTION.
  " PUR에서 넘긴 PR번호·지사·상태를 화면 조회조건으로 옮긴다.
  IF p_purdoc IS NOT INITIAL.
    p_doc = p_purdoc.
    " 시작일 필수 규칙: 기간을 비우지 않고 그 PR의 희망납기일 하루로 맞춘다.
    SELECT SINGLE lfdat FROM z8mm_pr WHERE banfn = @p_purdoc INTO @p_dfrom.
    IF p_dfrom IS INITIAL.
      p_dfrom = sy-datum.
    ENDIF.
    CLEAR p_dto.
  ENDIF.
  " PUR은 입고플랜트(P100)를 넘긴다 → 그 플랜트의 구매지사(B001)로 바꿔 조회조건에 넣는다.
  IF p_purwk IS NOT INITIAL.
    SELECT SINGLE bupla FROM z8plant_m WHERE werks = @p_purwk INTO @p_bupla.
  ENDIF.
  IF p_pursta IS NOT INITIAL.
    p_state = p_pursta.
  ENDIF.
  " PUR에서 고른·방금 만든 PR(메모리 Z8MM_PR_MARK)은 조회조건과 관계없이 맨 위 파란 줄·선택으로 보여준다.
  DATA lt_pr_marks TYPE STANDARD TABLE OF z8mm_pr WITH EMPTY KEY.
  IMPORT marks = lt_pr_marks FROM MEMORY ID 'Z8MM_PR_MARK'.
  FREE MEMORY ID 'Z8MM_PR_MARK'.
  LOOP AT lt_pr_marks INTO DATA(ls_pr_mark).
    INSERT VALUE #( banfn = ls_pr_mark-banfn bnfpo = ls_pr_mark-bnfpo ) INTO TABLE gt_mark.
  ENDLOOP.
  gv_sel_mark = xsdbool( gt_mark IS NOT INITIAL ).
  PERFORM query_list.
  CALL SCREEN 0100.
