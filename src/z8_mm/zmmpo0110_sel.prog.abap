*&---------------------------------------------------------------------*
*& Include ZMMPO0110_SEL
*&---------------------------------------------------------------------*
*& 조회조건 서브스크린 1100 / 후보조건 서브스크린 1200
*&   코드 칸 옆에 이름 표시, 구매그룹은 001 고정(숨김), 발주일 기간(시작일 필수)
*& 담당: MM(이규빈) / 프로그램: ZMMPO0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-07  이규빈  최초 개발   최초 작성: PR 묶음 발주(PR N건 → PO 1건), PO 목록·취소 (개발 10/07~10/13)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등, 후보 ALV에서 골라 바로 PO 생성
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 생성 확인 메시지 축약, '납기 충족 / N일 지연', 취소 메시지 202·134 구분
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 0100은 서브스크린 1100(PO 조회조건), 0200은 1200(PR 후보조건)을 넣는다.
" 두 서브스크린은 SE51에서 만들지 않는다. 이 SEL을 활성화하면 자동 생성된다.

" 처리상태는 화면에 보이지 않는다. 오른쪽 상태카드를 누르면 값이 바뀐다.
" A=전체 W=입고대기 F=입고완료 X=취소 (부분입고는 쓰지 않는다)

PARAMETERS p_state TYPE char1 NO-DISPLAY DEFAULT 'A'.

" PUR 업무현황(ZMMPUR0100)에서 바로 들어올 때 쓰는 호출값이다.
" p_purnew = 'X' → PO 생성 화면(0200), p_purlst = 'X' → PO 조회 화면(0100)
PARAMETERS: p_purnew TYPE abap_bool NO-DISPLAY,
            p_purlst TYPE abap_bool NO-DISPLAY.
" PUR이 넘기는 지사·PO번호. 화면 칸(p_bupla/p_doc)은 서브스크린에 있어 SUBMIT로 직접 못 받는다.
PARAMETERS: p_purwk TYPE z8mm_pr-werks NO-DISPLAY,
            p_purdoc TYPE z8mm_po_h-ebeln NO-DISPLAY.

" 조회조건 틀 안의 [조회] 버튼(PUSHBUTTON)의 기능코드를 받는 표준 구조이다.
TABLES sscrfields.

" 구매그룹은 항상 001이라 화면에 보이지 않게 숨긴다. PO 생성 때 이 값이 들어간다.
PARAMETERS n_ekgrp TYPE ekgrp NO-DISPLAY DEFAULT '001'.

" 코드 칸 옆의 회색 글씨(gv_n*)는 지사명·업체명·자재명이다. E01의 fill_names가 채운다.
" 열 배치(한 줄 83열 이내, 요소끼리 겹치면 활성화 오류):
" 라벨 2~12 / 입력칸 14~ / 이름 20~·26~·30~ / 오른쪽 라벨 36~46 / 오른쪽 칸 48~57 / [조회] 발주 종료일 오른쪽 60~69
SELECTION-SCREEN BEGIN OF SCREEN 1100 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b_query WITH FRAME TITLE text-q01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lplt FOR FIELD p_bupla.
SELECTION-SCREEN POSITION 14.
" 구매지사 = 지사코드(B001). 입고플랜트(P100)는 목록 열에 나온다.
PARAMETERS p_bupla TYPE z8plant_m-bupla VISIBLE LENGTH 4.
SELECTION-SCREEN COMMENT 20(14) gv_nplt.
SELECTION-SCREEN COMMENT 36(11) gv_ldoc FOR FIELD p_doc.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_doc TYPE z8mm_po_h-ebeln VISIBLE LENGTH 10.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lvend FOR FIELD p_lifnr.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_lifnr TYPE z8mm_pr-lifnr VISIBLE LENGTH 10.
SELECTION-SCREEN COMMENT 26(20) gv_nven.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lmat FOR FIELD p_matnr.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_matnr TYPE z8mm_pr-matnr VISIBLE LENGTH 14.
SELECTION-SCREEN COMMENT 30(20) gv_nmat.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lbfr FOR FIELD p_dfrom.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_dfrom TYPE z8mm_po_h-bedat.
SELECTION-SCREEN COMMENT 36(11) gv_lbto FOR FIELD p_dto.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_dto TYPE z8mm_po_h-bedat.
" [조회] 버튼: 발주 종료일 바로 오른쪽(60열). 누르면 기능코드 QUERY.
SELECTION-SCREEN PUSHBUTTON 60(10) gv_bqry1 USER-COMMAND query.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b_query.
SELECTION-SCREEN END OF SCREEN 1100.

" 0200 위쪽 서브스크린: 발주 후보를 거르는 조건만 둔다. 열 배치는 1100과 같다.
SELECTION-SCREEN BEGIN OF SCREEN 1200 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b_cand WITH FRAME TITLE text-c01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_cplt FOR FIELD c_bupla.
SELECTION-SCREEN POSITION 14.
PARAMETERS c_bupla TYPE z8plant_m-bupla VISIBLE LENGTH 4.
SELECTION-SCREEN COMMENT 20(14) gv_ncplt.
SELECTION-SCREEN COMMENT 36(11) gv_cdat FOR FIELD c_lfdat.
SELECTION-SCREEN POSITION 48.
PARAMETERS c_lfdat TYPE z8mm_pr-lfdat.
" [조회] 버튼: 희망납기까지 칸 바로 오른쪽(60열). 0100(1100)과 같은 위치.
SELECTION-SCREEN PUSHBUTTON 60(10) gv_bqry2 USER-COMMAND query.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_cvend FOR FIELD c_lifnr.
SELECTION-SCREEN POSITION 14.
PARAMETERS c_lifnr TYPE z8mm_pr-lifnr VISIBLE LENGTH 10.
SELECTION-SCREEN COMMENT 26(20) gv_ncven.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_cmat FOR FIELD c_matnr.
SELECTION-SCREEN POSITION 14.
PARAMETERS c_matnr TYPE z8mm_pr-matnr VISIBLE LENGTH 14.
SELECTION-SCREEN COMMENT 30(20) gv_ncmat.
SELECTION-SCREEN END OF LINE.
" 상태·요청구분 드롭다운. 목록 값은 E01(AT SELECTION-SCREEN OUTPUT)의 cand_listbox가 채운다.
"   USER-COMMAND가 없어 고르기만 해서는 조회하지 않고, [조회]·Enter 때 적용된다.
"   c_stat : A 전체 / G 정상(초록) / L 주의(노랑: 납기지연·최소발주량 미만) / X 발주불가(빨강)
"   c_src  : ALL 전체 + 도메인 Z8D_SOURCE_TYPE 고정값(= Z8MM_PR-SOURCE_TYPE). 목록 글자는 SE11 도메인 내역 그대로
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_cstat FOR FIELD c_stat.
SELECTION-SCREEN POSITION 14.
PARAMETERS c_stat TYPE char1 AS LISTBOX VISIBLE LENGTH 14 DEFAULT 'A'.
SELECTION-SCREEN COMMENT 36(11) gv_csrc FOR FIELD c_src.
SELECTION-SCREEN POSITION 48.
PARAMETERS c_src TYPE char10 AS LISTBOX VISIBLE LENGTH 12 DEFAULT 'ALL'.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b_cand.
SELECTION-SCREEN END OF SCREEN 1200.
