*&---------------------------------------------------------------------*
*& Include ZMMPR0100_SEL
*&---------------------------------------------------------------------*
*& 조회조건 서브스크린 1100
*&   코드 옆 이름 표시, 발주 여부는 오른쪽 카드로 고르고 [조회] 버튼은 조회조건 틀 안에 둔다.
*& 담당: MM(이규빈) / 프로그램: ZMMPR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-14  이규빈  최초 개발   최초 작성: PR 목록 조회·취소, PR 생성/변경·PO 생성 화면 연결 (개발 10/14~10/16)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등 화면 통일, 조회조건·버튼 동작 보완
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 조회 결과 없음 오류 표시, 취소 메시지 정리
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 조회조건 틀 안의 [조회] 버튼(PUSHBUTTON)의 기능코드를 받는 표준 구조이다.
TABLES sscrfields.

" 발주 여부는 화면에 보이지 않는다. 오른쪽 카드를 누르면 값이 바뀐다.
" A=전체 W=발주대기 C=발주완료 X=취소
PARAMETERS p_state TYPE char1 NO-DISPLAY DEFAULT 'W'.

" PUR 업무현황이 SUBMIT로 넘기는 값이다. 화면 칸(p_doc/p_bupla)은 서브스크린 1100에 있어
" SUBMIT ... WITH로 직접 받을 수 없으므로, 기본화면(1000) 숨김 칸으로 받고 START-OF-SELECTION에서 옮긴다.
PARAMETERS: p_purdoc TYPE z8mm_pr-banfn NO-DISPLAY,
            p_purwk TYPE z8mm_pr-werks NO-DISPLAY,
            p_pursta TYPE char1 NO-DISPLAY.

" 코드 칸 옆 회색 글씨(gv_n*)는 지사명·업체명·자재명이다. F01의 fill_names가 채운다.
" 열 배치(PO와 동일): 라벨 2~12 / 입력칸 14~ / 이름 20~·26~·30~ / 오른쪽 라벨 36~46 / 오른쪽 칸 48~57 / [조회] 납기 종료일 오른쪽 60~69
SELECTION-SCREEN BEGIN OF SCREEN 1100 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b_query WITH FRAME TITLE text-q01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lsite FOR FIELD p_bupla.
SELECTION-SCREEN POSITION 14.
" 구매지사 = 지사코드(B001). 입고플랜트(P100)는 목록 열에 그대로 나온다.
PARAMETERS p_bupla TYPE z8plant_m-bupla VISIBLE LENGTH 4.
SELECTION-SCREEN COMMENT 20(14) gv_nplt.
SELECTION-SCREEN COMMENT 36(11) gv_ldoc FOR FIELD p_doc.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_doc TYPE z8mm_pr-banfn VISIBLE LENGTH 10.
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
" 희망납기일 기간(PO의 발주일, STO의 출고일과 같은 줄 배치).
" PR 테이블에는 생성일이 없어 희망납기일(LFDAT)로 거른다.
" SELECT-OPTIONS와 같은 규칙: 시작일 필수, 종료일 비우면 시작일 하루만. 기본: 오늘-15일 ~ 오늘+15일.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_ldfr FOR FIELD p_dfrom.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_dfrom TYPE z8mm_pr-lfdat.
SELECTION-SCREEN COMMENT 36(11) gv_ldto FOR FIELD p_dto.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_dto TYPE z8mm_pr-lfdat.
" [조회] 버튼: 납기 종료일 바로 오른쪽(60열). 누르면 기능코드 QUERY.
SELECTION-SCREEN PUSHBUTTON 60(10) gv_bqry USER-COMMAND query.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b_query.
SELECTION-SCREEN END OF SCREEN 1100.
