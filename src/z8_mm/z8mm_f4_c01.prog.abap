*&---------------------------------------------------------------------*
*& Include Z8MM_F4_C01
*&---------------------------------------------------------------------*
*& 공통 검색(F4·Enter)과 도메인 고정값·문서번호 문구 도우미 (PR·PO·STO·PUR 공통)
*& 사용: ZMMPR0100, ZMMPR0110, ZMMPO0110, ZMMSTO0100, ZMMPUR0100, Z8MMB0100
*& 담당: MM(이규빈)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 공통 검색(F4)
*& 2026-10-30  이규빈  변경사항    글자 일부 검색 추가
*& 2026-11-02  이규빈  수정사항    PR·PO·STO·PUR 검색 방식 통일
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" 사용법
"   1) 조회칸에 일부만 입력(예: CAB, 케이블, 태양, P2) 후 F4
"        → 코드가 그 글자로 시작하거나 이름에 그 글자가 들어간 것만 목록에 나온다.
"        → 1건뿐이면 목록 없이 바로 들어간다.
"   2) 일부만 입력 후 Enter
"        → 정확한 코드가 아니면 같은 방식으로 찾아 1건이면 자동 완성, 여러 건이면 목록을 띄운다.
"   3) * 를 쓰면 패턴 검색이다(예: *패널*).
" kind 값: PLANT(플랜트) BRANCH(구매지사 코드, 예 B001) MAT(자재) VEND(공급업체) PR(PR 번호) PO(PO 번호) STO(STO 번호)
" 이 클래스는 DB를 읽기만 한다. 저장·잠금은 하지 않는다.

CLASS lcl_mm_f4 DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_hit,
             code TYPE c LENGTH 18,
             name TYPE c LENGTH 40,
             info TYPE c LENGTH 30,
           END OF ty_hit,
           ty_hits TYPE STANDARD TABLE OF ty_hit WITH EMPTY KEY.

    " F4 : typed(화면에 입력돼 있던 글자)로 걸러 목록을 띄우고 고른 코드를 돌려준다. 취소하면 빈 값.
    CLASS-METHODS pick IMPORTING kind TYPE clike typed TYPE clike OPTIONAL
                       RETURNING VALUE(value) TYPE string.
    " Enter : value가 정확한 코드가 아니면 찾아서 바꿔 준다. 못 찾으면 그대로 둔다.
    CLASS-METHODS resolve IMPORTING kind TYPE clike CHANGING value TYPE clike.
    " 선택화면/서브스크린에서 F4 누를 때 칸에 적혀 있던 글자를 읽는다.
    CLASS-METHODS screen_value IMPORTING field TYPE clike RETURNING VALUE(value) TYPE string.
    " 고른 값을 F4를 누른 화면 칸에 바로 써 준다.
    CLASS-METHODS put_screen IMPORTING field TYPE clike value TYPE clike.

    " 도메인 고정값(SE11 값 범위)과 내역을 그대로 읽는다(DD07T, 로그온 언어 → 없으면 아무 언어).
    "   화면 글자를 바꾸려면 코드가 아니라 SE11 도메인 고정값 내역을 바꾸면 된다.
    TYPES: BEGIN OF ty_domval,
             value TYPE dd07t-domvalue_l,
             text  TYPE dd07t-ddtext,
           END OF ty_domval,
           ty_domvals TYPE STANDARD TABLE OF ty_domval WITH EMPTY KEY.
    CLASS-METHODS domain_values IMPORTING domain TYPE clike RETURNING VALUE(values) TYPE ty_domvals.
    " 값 하나의 내역. 고정값에 없으면 값 그대로 돌려준다.
    CLASS-METHODS domain_text IMPORTING domain TYPE clike value TYPE clike RETURNING VALUE(text) TYPE string.

    " 완료 메시지용 문서번호 문구: 1건이면 'PR00000289', 여러 건이면 'PR00000289 외 2건'.
    "   사용: DATA(lv_txt) = lcl_mm_f4=>doc_text( lt_docs ). MESSAGE s133(z8_msg) WITH lv_txt '생성'.  → 'PR00000289 생성 완료'
    CLASS-METHODS doc_text IMPORTING docs TYPE string_table RETURNING VALUE(text) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS load IMPORTING kind TYPE clike RETURNING VALUE(hits) TYPE ty_hits.
    CLASS-METHODS narrow IMPORTING typed TYPE clike CHANGING hits TYPE ty_hits.
    CLASS-METHODS popup IMPORTING kind TYPE clike hits TYPE ty_hits RETURNING VALUE(value) TYPE string.
    CLASS-METHODS mat_name IMPORTING matnr TYPE clike RETURNING VALUE(name) TYPE z8material_txt_m-maktx.
    CLASS-METHODS branch_help RETURNING VALUE(value) TYPE string.
    " 도메인 고정값을 한 번만 읽도록 프로그램 실행 동안 보관한다.
    TYPES: BEGIN OF ty_domcache,
             domain TYPE dd07t-domname,
             values TYPE ty_domvals,
           END OF ty_domcache.
    CLASS-DATA domcache TYPE STANDARD TABLE OF ty_domcache WITH EMPTY KEY.
ENDCLASS.

CLASS lcl_mm_f4 IMPLEMENTATION.

" pick : F4 버튼. 칸에 적힌 글자로 목록을 걸러 팝업으로 보여주고 고른 코드를 돌려준다(1건이면 바로 반환).
  METHOD pick.
    " 구매지사 F4 = 팀 서치헬프 Z8SH_BRANCH. 칸에 B001이 있어도 전체 지사가 나오게 빈 값으로 연다.
    IF kind = 'BRANCH'.
      value = branch_help( ).
      RETURN.
    ENDIF.
    DATA(hits) = load( kind ).
    DATA(text) = condense( val = CONV string( typed ) ).
    " 칸에 이미 정확한 코드(예: P100)가 있으면 '다른 값으로 바꾸려는 F4'이다.
    " 칸에 정확한 코드가 이미 있으면 다른 값으로 바꾸려는 F4이므로 거르지 않고 전체 목록을 보여준다.
    " 글자 일부만 있을 때는 그 글자로 걸러서 보여준다.
    IF text IS NOT INITIAL.
      READ TABLE hits TRANSPORTING NO FIELDS WITH KEY code = text.
      IF sy-subrc = 0.
        CLEAR text.
      ENDIF.
    ENDIF.
    IF text IS NOT INITIAL.
      DATA(all) = hits.
      narrow( EXPORTING typed = text CHANGING hits = hits ).
      IF lines( hits ) = 1.
        value = hits[ 1 ]-code.
        RETURN.
      ELSEIF hits IS INITIAL.
        MESSAGE s050(z8_msg).   " 검색조건에 맞는 데이터가 없습니다(전체 목록 표시)
        hits = all.
      ENDIF.
    ENDIF.
    value = popup( kind = kind hits = hits ).
  ENDMETHOD.

" resolve : Enter. 정확한 코드가 아니면 글자로 찾아 1건이면 자동 완성, 여러 건이면 목록을 띄운다.
  METHOD resolve.
    IF value IS INITIAL.
      RETURN.
    ENDIF.
    " 뒤로/종료 버튼에서는 목록을 띄우지 않는다.
    IF sy-ucomm = 'BACK' OR sy-ucomm = 'EXIT' OR sy-ucomm = 'CANC'.
      RETURN.
    ENDIF.
    DATA(hits) = load( kind ).
    DATA(text) = condense( val = CONV string( value ) ).
    READ TABLE hits TRANSPORTING NO FIELDS WITH KEY code = text.
    IF sy-subrc = 0.
      RETURN.                                   " 정확한 코드 → 그대로
    ENDIF.
    narrow( EXPORTING typed = text CHANGING hits = hits ).
    CASE lines( hits ).
      WHEN 0.
        RETURN.                                 " 옆 이름칸에 '등록되지 않은 코드'로 보인다.
      WHEN 1.
        value = hits[ 1 ]-code.                 " 1건뿐이면 목록 없이 그 코드로 바로 바꾼다
      WHEN OTHERS.
        DATA(chosen) = popup( kind = kind hits = hits ).
        IF chosen IS NOT INITIAL.
          value = chosen.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

" screen_value : F4를 누른 순간 화면 칸에 적혀 있던 값을 읽는다(PAI 전이라 변수에는 아직 없음).
  METHOD screen_value.
    DATA fields TYPE STANDARD TABLE OF dynpread WITH EMPTY KEY.
    fields = VALUE #( ( fieldname = field ) ).
    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING dyname = sy-repid dynumb = sy-dynnr
      TABLES dynpfields = fields EXCEPTIONS OTHERS = 1.
    IF sy-subrc = 0 AND fields IS NOT INITIAL.
      value = condense( val = CONV string( fields[ 1 ]-fieldvalue ) ).
    ENDIF.
  ENDMETHOD.

" put_screen : 고른 값을 F4를 누른 화면 칸에 바로 써 준다.
  METHOD put_screen.
    DATA fields TYPE STANDARD TABLE OF dynpread WITH EMPTY KEY.
    fields = VALUE #( ( fieldname = field fieldvalue = value ) ).
    CALL FUNCTION 'DYNP_VALUES_UPDATE'
      EXPORTING dyname = sy-repid dynumb = sy-dynnr
      TABLES dynpfields = fields EXCEPTIONS OTHERS = 1.
  ENDMETHOD.

" narrow : 코드 앞글자 일치 또는 이름에 글자가 들어간 행만 남긴다(* 패턴 지원).
  METHOD narrow.
    DATA(text) = condense( val = CONV string( typed ) ).
    IF text IS INITIAL.
      RETURN.
    ENDIF.
    IF text CA '*+'.
      DELETE hits WHERE NOT ( code CP text OR name CP text ).
    ELSE.
      DATA(prefix) = |{ text }*|.
      " CP·CS는 대소문자를 가리지 않는다. 코드는 앞글자, 이름·참고는 포함 검색이다.
      DELETE hits WHERE NOT ( code CP prefix OR name CS text OR info CS text ).
    ENDIF.
  ENDMETHOD.

" mat_name : 자재명(로그인 언어 → 한국어 순서로 찾음).
  METHOD mat_name.
    SELECT SINGLE maktx FROM z8material_txt_m
      WHERE matnr = @matnr AND spras = @sy-langu INTO @name.
    IF sy-subrc <> 0.
      SELECT SINGLE maktx FROM z8material_txt_m
        WHERE matnr = @matnr AND spras = '3' INTO @name.
    ENDIF.
  ENDMETHOD.

" load : 종류(kind)별 F4 목록 전체를 DB에서 읽는다. 읽기 전용.
  METHOD load.
    CASE kind.
      WHEN 'PLANT'.
        SELECT werks, name1, bupla FROM z8plant_m ORDER BY werks INTO TABLE @DATA(plants).
        SELECT branch, name FROM z8branch_m INTO TABLE @DATA(branches).
        LOOP AT plants INTO DATA(plant).
          DATA(cnt) = REDUCE i( INIT n = 0 FOR b IN branches WHERE ( branch = plant-bupla ) NEXT n = n + 1 ).
          DATA(hit) = VALUE ty_hit( code = plant-werks info = plant-name1 ).
          IF cnt = 1.
            hit-name = branches[ branch = plant-bupla ]-name.
          ELSE.
            hit-name = plant-name1.
            CLEAR hit-info.
          ENDIF.
          APPEND hit TO hits.
        ENDLOOP.

      WHEN 'BRANCH'.
        " 구매지사 = 지사코드(B001). 오른쪽 칸에는 그 지사의 입고플랜트를 보여준다.
        SELECT branch, name FROM z8branch_m ORDER BY branch INTO TABLE @DATA(brs).
        DELETE ADJACENT DUPLICATES FROM brs COMPARING branch.
        SELECT werks, bupla FROM z8plant_m ORDER BY werks INTO TABLE @DATA(bplants).
        LOOP AT brs INTO DATA(br).
          DATA(bhit) = VALUE ty_hit( code = br-branch name = br-name ).
          LOOP AT bplants INTO DATA(bp) WHERE bupla = br-branch.
            bhit-info = COND #( WHEN bhit-info IS INITIAL THEN bp-werks ELSE |{ bhit-info }, { bp-werks }| ).
          ENDLOOP.
          APPEND bhit TO hits.
        ENDLOOP.

      WHEN 'MAT'.
        SELECT matnr, meins FROM z8material_m ORDER BY matnr INTO TABLE @DATA(mats).
        SELECT matnr, spras, maktx FROM z8material_txt_m INTO TABLE @DATA(texts).
        SORT texts BY matnr spras.
        LOOP AT mats INTO DATA(mat).
          DATA(mhit) = VALUE ty_hit( code = mat-matnr info = mat-meins ).
          READ TABLE texts INTO DATA(txt) WITH KEY matnr = mat-matnr spras = sy-langu BINARY SEARCH.
          IF sy-subrc <> 0.
            READ TABLE texts INTO txt WITH KEY matnr = mat-matnr spras = '3' BINARY SEARCH.
          ENDIF.
          IF sy-subrc = 0.
            mhit-name = txt-maktx.
          ENDIF.
          APPEND mhit TO hits.
        ENDLOOP.

      WHEN 'VEND'.
        SELECT lifnr, name1 FROM z8vendor_m ORDER BY lifnr INTO TABLE @DATA(vendors).
        hits = VALUE #( FOR v IN vendors ( code = v-lifnr name = v-name1 ) ).

      WHEN 'PR'.
        SELECT banfn, matnr, werks, lfdat FROM z8mm_pr
          ORDER BY banfn DESCENDING INTO TABLE @DATA(prs).
        DELETE ADJACENT DUPLICATES FROM prs COMPARING banfn.
        LOOP AT prs INTO DATA(pr).
          APPEND VALUE #( code = pr-banfn name = mat_name( pr-matnr )
            info = |{ pr-werks } · { pr-lfdat DATE = USER }| ) TO hits.
        ENDLOOP.

      WHEN 'PO' OR 'STO'.
        IF kind = 'PO'.
          SELECT ebeln, bedat, lifnr FROM z8mm_po_h WHERE bsart <> 'UB'
            ORDER BY ebeln DESCENDING INTO TABLE @DATA(pos).
          SELECT lifnr, name1 FROM z8vendor_m INTO TABLE @DATA(vnames).
          LOOP AT pos INTO DATA(po).
            DATA(phit) = VALUE ty_hit( code = po-ebeln info = |{ po-bedat DATE = USER }| ).
            READ TABLE vnames INTO DATA(vn) WITH KEY lifnr = po-lifnr.
            phit-name = COND #( WHEN sy-subrc = 0 THEN vn-name1 ELSE po-lifnr ).
            APPEND phit TO hits.
          ENDLOOP.
        ELSE.
          SELECT h~ebeln, i~matnr, i~reswk, i~werks FROM z8mm_po_h AS h
            INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
            WHERE h~bsart = 'UB' ORDER BY h~ebeln DESCENDING INTO TABLE @DATA(stos).
          DELETE ADJACENT DUPLICATES FROM stos COMPARING ebeln.
          LOOP AT stos INTO DATA(sto).
            APPEND VALUE #( code = sto-ebeln name = mat_name( sto-matnr )
              info = |{ sto-reswk } → { sto-werks }| ) TO hits.
          ENDLOOP.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

" popup : 목록을 표준 F4 팝업(F4IF_INT_TABLE_VALUE_REQUEST)으로 보여주고 고른 코드를 돌려준다.
  METHOD popup.
    IF hits IS INITIAL.
      MESSAGE s050(z8_msg) DISPLAY LIKE 'W'.   " 검색조건에 맞는 데이터가 없습니다
      RETURN.
    ENDIF.
    DATA: h1 TYPE scrtext_m, h2 TYPE scrtext_m, h3 TYPE scrtext_m.
    CASE kind.
      WHEN 'PLANT'. h1 = '플랜트'.     h2 = '지사·플랜트명'. h3 = '플랜트명'.
      WHEN 'BRANCH'. h1 = '구매지사'.  h2 = '지사명'.        h3 = '입고플랜트'.
      WHEN 'MAT'.   h1 = '자재번호'.   h2 = '자재명'.        h3 = '단위'.
      WHEN 'VEND'.  h1 = '공급업체'.   h2 = '업체명'.        h3 = ''.
      WHEN 'PR'.    h1 = 'PR 번호'.    h2 = '자재명'.        h3 = '지사·희망납기일'.
      WHEN 'PO'.    h1 = 'PO 번호'.    h2 = '공급업체명'.    h3 = '발주일'.
      WHEN 'STO'.   h1 = 'STO 번호'.   h2 = '자재명'.        h3 = '출발 → 도착'.
    ENDCASE.
    " 열 제목을 한글로 보이게 직접 정의한다(오프셋은 바이트 단위).
    DATA(cs) = cl_abap_char_utilities=>charsize.
    DATA fields TYPE STANDARD TABLE OF dfies WITH EMPTY KEY.
    fields = VALUE #(
      ( tabname = 'LCL_MM_F4' fieldname = 'CODE' position = 1 offset = 0
        leng = 18 intlen = 18 * cs outputlen = 18 datatype = 'CHAR' inttype = 'C'
        scrtext_s = h1 scrtext_m = h1 scrtext_l = h1 reptext = h1 keyflag = abap_true )
      ( tabname = 'LCL_MM_F4' fieldname = 'NAME' position = 2 offset = 18 * cs
        leng = 40 intlen = 40 * cs outputlen = 30 datatype = 'CHAR' inttype = 'C'
        scrtext_s = h2 scrtext_m = h2 scrtext_l = h2 reptext = h2 ) ).
    IF h3 IS NOT INITIAL.
      APPEND VALUE #( tabname = 'LCL_MM_F4' fieldname = 'INFO' position = 3 offset = 58 * cs
        leng = 30 intlen = 30 * cs outputlen = 18 datatype = 'CHAR' inttype = 'C'
        scrtext_s = h3 scrtext_m = h3 scrtext_l = h3 reptext = h3 ) TO fields.
    ENDIF.
    DATA list TYPE ty_hits.
    list = hits.
    DATA returns TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING retfield = 'CODE' value_org = 'S' window_title = CONV char40( |{ h1 } 선택| )
      TABLES value_tab = list field_tab = fields return_tab = returns
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc = 0 AND returns IS NOT INITIAL.
      value = condense( val = CONV string( returns[ 1 ]-fieldval ) ).
    ENDIF.
  ENDMETHOD.
  " branch_help : 팀 서치헬프 Z8SH_BRANCH(Z8BRANCH_M-BRANCH)를 화면 값 없이 호출 → 전체 지사 목록.
  "   (칸에 붙은 서치헬프를 그대로 쓰면 칸의 B001로 걸러져 B001만 보이기 때문)
  METHOD branch_help.
    DATA lt_ret TYPE STANDARD TABLE OF ddshretval.
    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
      EXPORTING tabname = 'Z8BRANCH_M' fieldname = 'BRANCH'
      TABLES return_tab = lt_ret
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0 OR lt_ret IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE lt_ret INTO DATA(ls_ret) WITH KEY fieldname = 'BRANCH'.
    IF sy-subrc <> 0.
      READ TABLE lt_ret INTO ls_ret INDEX 1.
    ENDIF.
    value = ls_ret-fieldval.
  ENDMETHOD.

" domain_values : 도메인 고정값 목록(값 순서 VALPOS). 프로그램 실행 중 한 번만 DB에서 읽는다.
  METHOD domain_values.
    DATA(lv_domain) = CONV dd07t-domname( to_upper( domain ) ).
    READ TABLE domcache INTO DATA(ls_cache) WITH KEY domain = lv_domain.
    IF sy-subrc = 0.
      values = ls_cache-values.
      RETURN.
    ENDIF.
    " 고정값은 DD07L에서 전부 읽고, 내역은 값마다 로그온 언어 → 다른 언어 → 값 그대로 순으로 붙인다.
    "   (로그온 언어 내역이 일부 값에만 있으면 드롭다운에 그 값만 보이던 문제)
    SELECT domvalue_l AS value FROM dd07l
      WHERE domname = @lv_domain AND as4local = 'A'
      ORDER BY valpos INTO CORRESPONDING FIELDS OF TABLE @values.
    SELECT domvalue_l, ddlanguage, ddtext FROM dd07t
      WHERE domname = @lv_domain AND as4local = 'A' INTO TABLE @DATA(lt_texts).
    LOOP AT values ASSIGNING FIELD-SYMBOL(<dom_value>).
      READ TABLE lt_texts INTO DATA(ls_dom_text)
        WITH KEY domvalue_l = <dom_value>-value ddlanguage = sy-langu.
      IF sy-subrc <> 0 OR ls_dom_text-ddtext IS INITIAL.
        LOOP AT lt_texts INTO ls_dom_text WHERE domvalue_l = <dom_value>-value AND ddtext IS NOT INITIAL.
          EXIT.
        ENDLOOP.
      ENDIF.
      <dom_value>-text = COND #( WHEN sy-subrc = 0 THEN ls_dom_text-ddtext ELSE <dom_value>-value ).
    ENDLOOP.
    APPEND VALUE #( domain = lv_domain values = values ) TO domcache.
  ENDMETHOD.

" domain_text : 값 하나의 내역. 고정값에 없거나 내역이 비어 있으면 값 그대로이다.
  METHOD domain_text.
    DATA(lt_values) = domain_values( domain ).
    READ TABLE lt_values INTO DATA(ls_value) WITH KEY value = value.
    text = COND #( WHEN sy-subrc = 0 AND ls_value-text IS NOT INITIAL THEN ls_value-text ELSE value ).
  ENDMETHOD.
  METHOD doc_text.
    " 같은 문서번호(PR 품목 여러 줄 등)는 한 번만 센다.
    DATA(lt_docs) = docs.
    SORT lt_docs.
    DELETE ADJACENT DUPLICATES FROM lt_docs.
    IF lt_docs IS INITIAL.
      RETURN.
    ENDIF.
    text = lt_docs[ 1 ].
    IF lines( lt_docs ) > 1.
      text = |{ text } 외 { lines( lt_docs ) - 1 }건|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
