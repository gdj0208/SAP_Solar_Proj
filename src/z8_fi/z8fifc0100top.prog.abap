*&---------------------------------------------------------------------*
*& Include Z8FIFC0100TOP                            - Report Z8FIFC0100
*&---------------------------------------------------------------------*
REPORT z8fifc0100.

TABLES: z8sd_billing_h.

TABLES: sscrfields.

DATA ok_code TYPE sy-ucomm.

CONSTANTS gc_bukrs TYPE z8company_m-bukrs VALUE '1000'.

"100번 화면
TYPES: BEGIN OF ty_alv_100,
         check(1) TYPE c,                          "선택 체크박스
         light(1) TYPE c,                            "신호등
         paystt   TYPE c LENGTH 9, "입금상태 출력용
         bukrs    TYPE z8sd_billing_h-bukrs, "회사코드
         bupla    TYPE z8sd_billing_h-bupla, "종사업장
         brancht  TYPE z8branch_m-name, "종사업장명
         vbeln    TYPE z8sd_billing_h-vbeln, "청구번호
         vgbel    TYPE z8sd_billing_h-vgbel, "SO 번호
         kunnr    TYPE z8sd_billing_h-kunnr, "고객번호
         name1    TYPE z8customer_m-name1, "고객이름
         fkdat    TYPE z8sd_billing_h-fkdat, "청구일
         netwr    TYPE z8sd_billing_h-netwr, "청구금액
         waerk    TYPE z8sd_billing_h-waerk, "통화
         zzpayst  TYPE z8sd_billing_h-zzpayst, "입금상태
         zduedat  TYPE z8sd_billing_h-zduedat, "입금기한
         zpaydat  TYPE z8sd_billing_h-zpaydat, "입금날짜
         ar_belnr TYPE z8fi_customer-belnr, "외상매출금 전표번호
         ar_gjahr TYPE z8fi_customer-gjahr,
         augbl    TYPE z8fi_customer-augbl, "전표번호
         augdt    TYPE z8fi_customer-augdt, "입금일
         auggj    TYPE z8fi_customer-auggj,
         ct       TYPE lvc_t_styl, "셀 단위 스타일
       END OF ty_alv_100.

DATA : gt_bill TYPE STANDARD TABLE OF ty_alv_100,
       gs_bill TYPE ty_alv_100.

"ALV
DATA go_cont_100 TYPE REF TO cl_gui_custom_container.
DATA go_alv_100  TYPE REF TO cl_gui_alv_grid.

DATA:
  go_cont_org TYPE REF TO cl_gui_custom_container,
  go_alv_org  TYPE REF TO cl_gui_alv_grid.

DATA:
  go_cont_pre TYPE REF TO cl_gui_custom_container,
  go_alv_pre  TYPE REF TO cl_gui_alv_grid.

"필드 카탈로그
DATA gt_fcat_100 TYPE lvc_t_fcat.
DATA gs_fcat_100 TYPE lvc_s_fcat.

DATA:
  gt_fcat_org TYPE lvc_t_fcat,
  gs_fcat_org TYPE lvc_s_fcat.

DATA:
  gt_fcat_pre TYPE lvc_t_fcat,
  gs_fcat_pre TYPE lvc_s_fcat.


"레이아웃
DATA gs_layout_100 TYPE lvc_s_layo.
DATA gs_layout_org TYPE lvc_s_layo.
DATA gs_layout_pre TYPE lvc_s_layo.

"정렬
DATA gt_sort TYPE lvc_t_sort.
DATA gs_sort TYPE lvc_s_sort.

"스크린 페인터

DATA: gv_netwr_txt TYPE char20,   "청구금액 표시용
      gv_pay_txt   TYPE char20.   "입금금액 표시용

"청구일자
DATA: gv_fkdat TYPE z8sd_billing_h-fkdat.

"청구번호
DATA gv_last_vbeln TYPE z8sd_billing_h-vbeln.

"화면 갱신
DATA gv_refresh_100(1) TYPE c.
DATA gs_stable TYPE lvc_s_stbl.

DATA:  gs_ar_item TYPE z8fi_accdoc_i.

"200번
DATA:
  gv_paydat    TYPE sy-datum, "실제 지급일
  gv_pay       TYPE z8fi_customer-wrbtr, "지급금액
  gv_pay_waers TYPE z8fi_customer-waers. "통화

"락
DATA gv_return TYPE sy-subrc.

"번호
DATA:
  gv_last_bukrs TYPE z8fi_vendor-bukrs,
  gv_last_gjahr TYPE z8fi_vendor-gjahr,
  gv_last_belnr TYPE z8fi_vendor-belnr.

"200번 alv
TYPES: BEGIN OF ty_alv_200,
         buzei      TYPE z8fi_accdoc_i-buzei,    "전표 라인
         koart      TYPE z8fi_accdoc_i-koart,     "계정 유형
         hkont      TYPE z8fi_accdoc_i-hkont,   "G/L계정
         txt20      TYPE z8glacc_m-txt20,        "계정과목 명
*         bupla  TYPE z8sd_billing_h-bupla,   "종사업장
         shkzg      TYPE z8fi_accdoc_i-shkzg,   "차/대 구분코드
         shkzgt     TYPE char4,                        "차변 / 대변 표시용
         debit      TYPE z8fi_accdoc_i-wrbtr,   "차변금액
         credit     TYPE z8fi_accdoc_i-wrbtr,   "대변금액
         waers      TYPE z8fi_accdoc_h-waers,   "통화
         kunnr      TYPE z8fi_accdoc_i-kunnr,   "고객번호
         umskz      TYPE z8fi_accdoc_i-umskz,  "특별지시자
         target(10) TYPE c,
*         umskz TYPE z8fi_accdoc_i-umskz,   "특별지시자
*         kunnr   TYPE z8sd_billing_h-kunnr, "고객번호
       END OF ty_alv_200.

DATA:
  gt_org TYPE STANDARD TABLE OF ty_alv_200,
  gs_org TYPE ty_alv_200,

  gt_pre TYPE STANDARD TABLE OF ty_alv_200,
  gs_pre TYPE ty_alv_200.

DATA:
  gt_acc_i TYPE STANDARD TABLE OF z8fi_accdoc_i,
  gs_acc_i TYPE z8fi_accdoc_i.

DATA:
      gs_acc_h TYPE z8fi_accdoc_h.
