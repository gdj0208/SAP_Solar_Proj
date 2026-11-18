*&---------------------------------------------------------------------*
*& Include ZMMPR0110_E01
*&---------------------------------------------------------------------*
*& 라벨·F4·신규/변경 진입 처리
*& 담당: MM(이규빈) / 프로그램: ZMMPR0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 구매지사 기준 PR 신규 입력·변경·삭제 (개발 10/01~10/06)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 입력 화면 개편(신호등·입력 열 색), 공급업체·희망납기일 자동 채움
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 저장·삭제 메시지 정리, ALV 행 버튼 제거, PR 변경은 수량·희망납기일만
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

INITIALIZATION.
  " 실행 권한: MM 프로그램 권한(Z8MM_ADMIN)의 실행(16)이 없으면 시작하지 않는다(팀 MM 프로그램 공통).
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
    ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.   " MM 관리자 전용 프로그램입니다. 권한을 요청하세요.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  gv_esite = '구매지사'.          " 조회 화면과 같이 지사코드(B001)로 입력, 옆에 입고플랜트 자동 표시
  gv_ldate = '희망납기일'.
  CLEAR gv_lhint.                  " 기본값 안내는 ALV 제목줄로 옮김
  PERFORM site_text.
  PERFORM update_summary.
  IF sy-dynnr = '1200'.
    LOOP AT SCREEN.
      IF ( screen-group1 = 'HDR' AND ( gv_mode = 'C' OR gv_posted = abap_true ) )
        OR ( screen-group1 = 'DFT' AND gv_mode = 'C' ).
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF screen-name = 'N_BUPLA'.
        " 필수 입력 표시만 한다(값 검사는 입력 확인·저장 때). 뒤로가기는 막지 않는다.
        screen-required = '2'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
    " '구매지사를 입력해주세요' 안내가 나간 뒤에는 커서를 구매지사 칸에 둔다.
    "   메시지는 S 타입(DISPLAY LIKE E/W)이라 SAP가 커서를 옮겨 주지 않으므로 직접 옮긴다.
    IF gv_focus_site = abap_true.
      SET CURSOR FIELD 'N_BUPLA'.
      CLEAR gv_focus_site.
    ENDIF.
  ENDIF.
" 글자 일부만 넣고 Enter 해도 찾아 준다(1건이면 자동 완성, 여러 건이면 목록).
" F4: 팀 서치헬프(Z8SH_BRANCH)를 빈 값으로 열어 칸에 B001이 있어도 전체 지사가 나온다.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR n_bupla.
  " 잠긴 칸(PR 변경·이미 저장)은 회색이어도 F4로 값이 들어갈 수 있으므로 F4를 열지 않는다.
  IF gv_mode = 'N' AND gv_posted = abap_false.
    PERFORM screen_help USING 'BRANCH' 'N_BUPLA'.
  ENDIF.
AT SELECTION-SCREEN ON n_bupla.
  IF gv_mode = 'N' AND gv_posted = abap_false.
    lcl_mm_f4=>resolve( EXPORTING kind = 'BRANCH' CHANGING value = n_bupla ).
    PERFORM branch_plant.            " 구매지사 → 입고플랜트
  ELSE.
    " PR 변경, 또는 이 화면에서 PR을 이미 저장했으면 구매지사를 바꿀 수 없다.
    "   칸이 열려 있어 값을 바꿨더라도 저장에 쓰는 플랜트(n_werks)의 지사로 되돌린다.
    PERFORM plant_branch.            " 입고플랜트 → 구매지사
  ENDIF.
START-OF-SELECTION.
  IF p_so IS NOT INITIAL OR p_pos IS NOT INITIAL.
    MESSAGE s022(z8_msg) DISPLAY LIKE 'E'.   " 데이터를 불러올 수 없습니다(SO 연계 PR은 이 화면에서 처리하지 않음)
    RETURN.
  ENDIF.
  IF p_cancel = abap_true OR p_view = abap_true.
    MESSAGE s022(z8_msg) DISPLAY LIKE 'E'.   " 데이터를 불러올 수 없습니다(PR 조회·취소는 ZMMPR0100에서 처리)
    RETURN.
  ENDIF.
  CREATE OBJECT go_events.
  IF p_chg = abap_true.
    DATA loaded TYPE abap_bool.
    PERFORM load_change CHANGING loaded.
    IF loaded <> abap_true.
      RETURN.
    ENDIF.
  ELSE.
    n_werks = p_werks.
    PERFORM plant_branch.              " 넘어온 플랜트(P100) → 구매지사(B001)
    PERFORM reset_entry.
  ENDIF.
  CALL SCREEN 0100.
