*&---------------------------------------------------------------------*
*& Include Z8MMSH0100TOP                            - Report Z8MMSH0100
*&---------------------------------------------------------------------*
REPORT Z8MMSH0100 LINE-SIZE 200 NO STANDARD PAGE HEADING.. "재고 보충 배치 (목표수량 기준 PR 생성)"

TABLES: z8matplant_m.
"배치결과를 담을 구조체 정의.
TYPES: BEGIN OF ty_alv,
         light(1) TYPE c," 결과 신호등
         matnr     TYPE z8matplant_m-matnr,          " 자재코드
        maktx   TYPE z8material_txt_m-maktx,     " 자재명
         werks     TYPE z8matplant_m-werks,          " 플랜트
        pname   TYPE z8plant_m-name1,        " 플랜트명
         mabst     TYPE z8matplant_m-mabst,          " 목표수량
         eisbe     TYPE z8matplant_m-eisbe,          " 안전재고
         base_qty  TYPE z8matplant_m-mabst,          " 재주문 기준 (목표수량 x 비율)
         labst     TYPE z8material_stk_m-labst,      " 현재고
         zzrsvqty  TYPE z8material_stk_m-zzrsvqty,   " 예약재고
         avail     TYPE z8material_stk_m-labst,      " 가용재고
          inb_pr    TYPE z8material_stk_m-labst,      " 입고예정 ① PR
         inb_po    TYPE z8material_stk_m-labst,      " 입고예정 ② PO 남은 수량
         inbound   TYPE z8material_stk_m-labst,      " 입고예정
         order_qty TYPE z8mm_pr-menge,               " 주문수량
         lifnr     TYPE z8mm_pr-lifnr,               " 공급업체
        lifname TYPE z8vendor_m-name1,       " 공급업체명
         meins     TYPE z8purch_info_m-meins,        " 단위
         waers     TYPE z8purch_info_m-waers,        " 통화
         minbm     TYPE z8purch_info_m-minbm,        " 최소 구매수량
         preis     TYPE z8mm_pr-preis,               " 단가
         lfdat     TYPE z8mm_pr-lfdat,               " 납기일
         banfn     TYPE z8mm_pr-banfn,               " PR 번호
         color   TYPE c LENGTH 4,             " 줄 색상
         remark    TYPE char60,                    " 비고
*         fill_rate TYPE p LENGTH 5 DECIMALS 0,  "목표대비 확보율(%)
       END OF ty_alv.

DATA: gt_alv     TYPE STANDARD TABLE OF ty_alv,
      gs_alv     TYPE ty_alv,
      gv_checked TYPE i,                            " 점검 건수
      gv_target  TYPE i,                             " 재주문 대상 건수
      gv_created TYPE i,                             " PR 생성 건수
      gv_skipped TYPE i,                            " 건너뜀 건수
      gv_planned TYPE i.                            "'시험 실행 PR 대상 건수

DATA: go_cont TYPE REF TO cl_gui_custom_container,
      go_alv      TYPE REF TO cl_gui_alv_grid,
      gt_fcat      TYPE lvc_t_fcat,
      gs_layout    TYPE lvc_s_layo,
      ok_code TYPE sy-ucomm,
      gv_mode TYPE c LENGTH 10.
