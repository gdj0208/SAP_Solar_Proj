*&---------------------------------------------------------------------*
*& Include Z8MMB0100_TOP
*&---------------------------------------------------------------------*
*& 전역 타입·결과 테이블
*& 담당: MM(이규빈) / 프로그램: Z8MMB0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-22  이규빈  최초 개발   최초 작성: 예상도착일이 된 이동중 STO 자동 101 입고 배치 (개발 10/22~10/26)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 예약 STO 351 출고 단계 추가, 모의 실행·결과 표시 보완
*& 2026-11-04  이규빈  수정사항    STO 번호 F4(STO 화면과 같은 공통 검색) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" gt_result : 배치에서 각 STO를 처리한 결과와 오류 설명이다.

TYPES: BEGIN OF ty_candidate,
  ebeln TYPE z8mm_po_i-ebeln,
  ebelp TYPE z8mm_po_i-ebelp,
  eta TYPE z8mm_po_i-sto_arr_date,
  matnr TYPE z8mm_po_i-matnr,
  werks TYPE z8mm_po_i-werks,
  menge TYPE z8mm_po_i-menge,
  meins TYPE z8mm_po_i-meins,
  END OF ty_candidate,
  BEGIN OF ty_result,
  signal TYPE icon_d,
  step TYPE c LENGTH 8,               " 처리구분: 출고(351) / 입고(101)
  ebeln TYPE z8mm_po_i-ebeln,
  ebelp TYPE z8mm_po_i-ebelp,
  eta TYPE z8mm_po_i-sto_arr_date,
  matnr TYPE z8mm_po_i-matnr,
  werks TYPE z8mm_po_i-werks,
  menge TYPE z8mm_po_i-menge,
  meins TYPE z8mm_po_i-meins,
  belnr TYPE z8mm_sto_hist-belnr,
  result TYPE c LENGTH 12,
  detail TYPE c LENGTH 120,
  END OF ty_result.
DATA gt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.
DATA gv_asof TYPE sy-datum.
