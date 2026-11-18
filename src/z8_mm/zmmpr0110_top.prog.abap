*&---------------------------------------------------------------------*
*& Include ZMMPR0110_TOP
*&---------------------------------------------------------------------*
*& 입력행, 변경 대상 PR 원본, 화면 객체
*& 담당: MM(이규빈) / 프로그램: ZMMPR0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 구매지사 기준 PR 신규 입력·변경·삭제 (개발 10/01~10/06)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 입력 화면 개편(신호등·입력 열 색), 공급업체·희망납기일 자동 채움
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 저장·삭제 메시지 정리, ALV 행 버튼 제거, PR 변경은 수량·희망납기일만
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_entry,
  icon TYPE c LENGTH 4,
  rowclr TYPE c LENGTH 4,
  matnr TYPE z8mm_pr-matnr,
  maktx TYPE z8material_txt_m-maktx,
  menge TYPE z8mm_pr-menge,
  meins TYPE z8mm_pr-meins,
  lifnr TYPE z8mm_pr-lifnr,
  vendor_name TYPE z8vendor_m-name1,
  lfdat TYPE z8mm_pr-lfdat,
  preis TYPE z8mm_pr-preis,
  waers TYPE z8mm_pr-waers,
  banfn TYPE z8mm_pr-banfn,
  result TYPE c LENGTH 16,
  detail TYPE c LENGTH 100,
  sto_from TYPE z8mm_pr-werks,     " 빠른 납기 행: STO로 보낼 수 있는 출발 플랜트(화면에 안 보임)
  cellstyle TYPE lvc_t_styl,
  END OF ty_entry.
DATA: gt_entry TYPE STANDARD TABLE OF ty_entry WITH EMPTY KEY,
  gs_original TYPE z8mm_pr,
  go_entryc TYPE REF TO cl_gui_custom_container,
  go_entry TYPE REF TO cl_gui_alv_grid,
  ok_code TYPE sy-ucomm,
  gv_cmd TYPE sy-ucomm,
  gv_mode TYPE c LENGTH 1 VALUE 'N',
  gv_posted TYPE abap_bool.

" 지사 코드는 저장하고, 옆 설명에는 마스터의 지사명을 표시한다.
DATA gv_display_werks TYPE z8mm_pr-werks.
" 기본 희망납기일 직전 값(헤더 날짜를 바꾸면 이 값과 같은 미저장 행만 새 날짜로 바꾼다)
DATA gv_prev_lfdat TYPE z8mm_pr-lfdat.
" 처음 열 때·새로 작성할 때 미리 깔아 두는 빈 입력행 수
" 처음 깔아 두는 빈 입력행 수. 행 추가는 [자재추가] 버튼(ensure_blank_row는 행이 0개일 때만 1줄).
CONSTANTS gc_blank_rows TYPE i VALUE 1.
" 처리 안내 STO 링크를 클릭한 입력행 번호(STO 생성 화면으로 넘길 행)
DATA gv_sto_row TYPE i.
" 구매지사 필수 안내 뒤 다음 화면 출력(PBO)에서 커서를 구매지사 칸으로 옮기기 위한 표시
DATA gv_focus_site TYPE abap_bool.
" 표준 납기일(오늘+3영업일). '빠른 납기' 판단 기준이며 기본 납기일 칸을 바꿔도 변하지 않는다.
DATA gv_std_due TYPE z8mm_pr-lfdat.
