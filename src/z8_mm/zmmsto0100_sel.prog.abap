*&---------------------------------------------------------------------*
*& Include ZMMSTO0100_SEL
*&---------------------------------------------------------------------*
*& 조회조건(1100)과 이동 입력(1200) 서브스크린
*&   배치: 라벨 2(11) / 칸 14 / 이름 20·30 / 오른쪽 라벨 36(11) / 칸 48, [조회] 버튼은 틀 안
*& 담당: MM(이규빈) / 프로그램: ZMMSTO0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: 지사 간 자재이동(STO) 목록·입력·취소 (개발 10/17~10/23)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: STO 1건 품목 N줄 구조, 목록 카드·이력 ALV
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: STO 예약 추가, 취소 메시지 202·134 구분, 수량 소수점·카드 크기 수정
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 호출 구분: p_new = PUR에서 [STO 생성]으로 바로 입력화면, p_list = 목록으로 시작

PARAMETERS: p_new TYPE abap_bool NO-DISPLAY,
            p_list TYPE abap_bool NO-DISPLAY.
" PUR → STO 값 전달용(SUBMIT ... WITH 는 1000 화면 파라미터만 채우므로 숨은 칸으로 받는다)
PARAMETERS: p_purwk TYPE z8mm_po_i-reswk NO-DISPLAY,
            p_purdoc TYPE z8mm_po_i-ebeln NO-DISPLAY.
" PR 생성(빠른 납기 행의 STO 링크) → 도착 플랜트·자재·수량을 미리 채움
PARAMETERS: p_purto TYPE z8mm_po_i-werks NO-DISPLAY,
            p_purmat TYPE z8mm_po_i-matnr NO-DISPLAY,
            p_purqty TYPE z8mm_po_i-menge NO-DISPLAY,
            p_purdt   TYPE sy-datum NO-DISPLAY.   " PR 희망납기일 → 도착희망일
" 카드로 고르는 상태(A 전체 / M 이동중 / C 입고완료)와 도착일정(A 전체 / L 예정일 경과)
PARAMETERS: p_state TYPE char1 NO-DISPLAY DEFAULT 'A',
            p_due TYPE char1 NO-DISPLAY DEFAULT 'A'.
" 저장위치는 항상 0001이라 화면에서 숨긴다(PO의 구매그룹 001과 같은 방식).
" 출고일·예상도착일은 화면에 칸으로 두지 않고 계산값만 보관한다(도착희망일에서 역산).
PARAMETERS: p_date TYPE sy-datum NO-DISPLAY DEFAULT sy-datum,
            p_eta TYPE sy-datum NO-DISPLAY.
PARAMETERS: p_floc TYPE z8mm_po_i-reslo NO-DISPLAY DEFAULT '0001',
            p_tloc TYPE z8mm_po_i-lgort NO-DISPLAY DEFAULT '0001'.

TABLES sscrfields.

SELECTION-SCREEN BEGIN OF SCREEN 1100 AS SUBSCREEN.
" 조회조건 틀(제목 '조회 조건')은 PR·PO 목록 화면과 같은 모양이다.
SELECTION-SCREEN BEGIN OF BLOCK b_query WITH FRAME TITLE text-q01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lsrc FOR FIELD p_sfrom.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_sfrom TYPE z8mm_po_i-reswk VISIBLE LENGTH 4.
SELECTION-SCREEN COMMENT 20(14) gv_nsrc.
SELECTION-SCREEN COMMENT 36(11) gv_ldoc FOR FIELD p_doc.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_doc TYPE z8mm_po_i-ebeln VISIBLE LENGTH 10.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_ldst FOR FIELD p_sto.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_sto TYPE z8mm_po_i-werks VISIBLE LENGTH 4.
SELECTION-SCREEN COMMENT 20(14) gv_ndst.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lmat FOR FIELD p_mat.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_mat TYPE z8mm_po_i-matnr VISIBLE LENGTH 14.
SELECTION-SCREEN COMMENT 30(20) gv_nmat.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_ldfr FOR FIELD p_dfrom.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_dfrom TYPE z8mm_po_i-sto_dep_date.
SELECTION-SCREEN COMMENT 36(11) gv_ldto FOR FIELD p_dto.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_dto TYPE z8mm_po_i-sto_dep_date.
" [조회] 버튼: 출고 종료일 바로 오른쪽(60열)
SELECTION-SCREEN PUSHBUTTON 60(10) gv_bqry USER-COMMAND query.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b_query.
SELECTION-SCREEN END OF SCREEN 1100.

SELECTION-SCREEN BEGIN OF SCREEN 1200 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b_entry WITH FRAME TITLE text-e01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_esrc FOR FIELD p_from.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_from TYPE z8mm_po_i-reswk VISIBLE LENGTH 4 MODIF ID hdr.
SELECTION-SCREEN COMMENT 20(14) gv_nefr.
SELECTION-SCREEN COMMENT 36(11) gv_edst FOR FIELD p_to.
SELECTION-SCREEN POSITION 48.
PARAMETERS p_to TYPE z8mm_po_i-werks VISIBLE LENGTH 4 MODIF ID hdr.
SELECTION-SCREEN COMMENT 54(14) gv_neto.
SELECTION-SCREEN END OF LINE.
" 입력은 '도착희망일' 하나. 출고일(p_date)·예상도착일(p_eta)은 운송일수로 자동 계산(calc_schedule)하고
"   오른쪽 글자(gv_nship)로 '출고 예정 2026.10.31 (운송 2일)' 처럼 보여준다.
"   출고일 = 오늘이면 저장 즉시 출고, 미래면 예약(출고일에 배치가 출고).
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 2(11) gv_lwant FOR FIELD p_want.
SELECTION-SCREEN POSITION 14.
PARAMETERS p_want TYPE sy-datum MODIF ID dat.
SELECTION-SCREEN COMMENT 30(46) gv_nship.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b_entry.
SELECTION-SCREEN END OF SCREEN 1200.
