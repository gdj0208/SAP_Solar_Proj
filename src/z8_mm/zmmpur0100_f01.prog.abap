*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_F01
*&---------------------------------------------------------------------*
*& 조회·카드·ALV FORM (DB는 읽기만 함)
*&   [새로고침]·Enter·하위 화면 복귀 때 세 업무를 한 번 읽고, 카드 전환은 읽은 데이터로 목록만 바꾼다.
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회, 조회 기간(시작·종료일) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

FORM read_data.
  DATA plants TYPE RANGE OF z8mm_pr-werks.
  PERFORM site_plants CHANGING plants.   " 담당 지사(B001) → 그 지사의 입고플랜트(P100…)
  gv_date = sy-datum.
  " 조회 기간: 종료일이 비면 시작일 하루. 목록마다 기준 날짜가 다르다
  "   (미발주 PR = 희망납기일, 진행 중 PO = 예상도착일, STO = 예상도착일).
  DATA(lv_dto) = COND sy-datum( WHEN gv_dto IS INITIAL THEN gv_dfrom ELSE gv_dto ).
  CLEAR: gt_pr, gt_po, gt_sto.

  " PR에는 생성일 필드가 없다. LFDAT(필요일)를 표시한다.
  SELECT banfn AS docno, bnfpo AS item, matnr, werks, menge, meins, lfdat, lifnr
    FROM z8mm_pr
    WHERE ebeln = @space AND loekz = @space AND werks IN @plants
      AND lfdat BETWEEN @gv_dfrom AND @lv_dto
    INTO CORRESPONDING FIELDS OF TABLE @gt_pr.
  LOOP AT gt_pr ASSIGNING FIELD-SYMBOL(<pr>).
    <pr>-status = '미발주'.
  ENDLOOP.

  " 외부구매 NB 중 미취소·미완료 품목. PO 목록(ZMMPO0110)의 저장위치 정책과 같다.
  SELECT i~ebeln AS docno, i~ebelp AS item, i~matnr, i~werks,
    i~menge, i~meins, i~lfdat, h~bedat, h~lifnr, h~procstat
    FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
    WHERE h~bsart = 'NB' AND i~loekz = @space AND i~elikz = @space
      AND i~lgort = '0001' AND i~werks IN @plants
      AND i~lfdat BETWEEN @gv_dfrom AND @lv_dto
    INTO TABLE @DATA(orders).
  LOOP AT orders INTO DATA(order).
    DATA(po_row) = CORRESPONDING ty_row( order ).
    " 헤더 PROCSTAT 15(일부 품목 입고)는 부분입고, 나머지 미완료 품목은 입고대기이다(ZMMPO0110과 같은 기준).
    IF order-procstat = '15'.
      po_row-status = '부분입고'.
    ELSE.
      po_row-status = '입고대기'.
    ENDIF.
    APPEND po_row TO gt_po.
  ENDLOOP.

  " 담당 지사의 플랜트가 출발 또는 도착인 이동을 포함한다. 전체에서는 중복하지 않는다.
  SELECT i~ebeln AS docno, i~ebelp AS item, i~matnr, i~reswk, i~werks,
    i~menge, i~meins, i~sto_dep_date AS dep_date, i~sto_arr_date AS eta, i~sto_rsv_qty AS rsv_qty
    FROM z8mm_po_h AS h INNER JOIN z8mm_po_i AS i ON i~ebeln = h~ebeln
    WHERE h~bsart = 'UB' AND i~loekz = @space AND i~elikz = @space
      AND ( i~reswk IN @plants OR i~werks IN @plants )
      AND i~sto_arr_date BETWEEN @gv_dfrom AND @lv_dto
    INTO CORRESPONDING FIELDS OF TABLE @gt_sto.
  " 예약 STO(출고 전)도 함께 보여주고 처리상태로 구분한다.
  LOOP AT gt_sto ASSIGNING FIELD-SYMBOL(<sto>).
    IF <sto>-rsv_qty > 0.
      <sto>-status = '예약중'.
    ELSE.
      <sto>-status = '이동 중'.
    ENDIF.
  ENDLOOP.
  PERFORM decorate_rows CHANGING gt_pr.
  PERFORM decorate_rows CHANGING gt_po.
  PERFORM decorate_rows CHANGING gt_sto.
  " 신호등: 노랑=진행 중(날짜가 지나도 노랑, 처리상태 글자로 경과 표시), 초록=오늘 도착
  LOOP AT gt_pr ASSIGNING FIELD-SYMBOL(<pr_sig>).
    <pr_sig>-signal = icon_led_yellow.
    IF <pr_sig>-lfdat IS NOT INITIAL AND <pr_sig>-lfdat < gv_date.
      <pr_sig>-status = '희망납기 경과'.
    ENDIF.
  ENDLOOP.
  " 진행 중 PO: 신호등은 노랑(입고대기), 예상도착일이 지났으면 처리상태 '도착일 경과'
  LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<po_sig>).
    <po_sig>-signal = icon_led_yellow.
    IF <po_sig>-lfdat IS NOT INITIAL AND <po_sig>-lfdat < gv_date.
      <po_sig>-status = '도착일 경과'.
    ENDIF.
  ENDLOOP.
  " STO는 도착지연이 없다(예정일에 Z8MMB0100 배치가 자동 입고).
  "   예정일이 지났는데 아직 이동 중이면 배치 실행 전이라 '입고 처리 대기'(노랑)로만 표시한다.
  LOOP AT gt_sto ASSIGNING FIELD-SYMBOL(<sto_sig>).
    IF <sto_sig>-rsv_qty > 0.
      <sto_sig>-signal = icon_led_yellow.   " 예약중: 출고일에 배치가 출고
      CONTINUE.
    ENDIF.
    IF <sto_sig>-eta IS NOT INITIAL AND <sto_sig>-eta < gv_date.
      <sto_sig>-signal = icon_led_yellow.
      <sto_sig>-status = '입고 처리 대기'.
    ELSEIF <sto_sig>-eta = gv_date.
      <sto_sig>-signal = icon_led_green.
      <sto_sig>-status = '오늘 도착'.
    ELSE.
      <sto_sig>-signal = icon_led_yellow.
    ENDIF.
  ENDLOOP.
  " 기본정렬: 날짜가 빠른(먼저 처리할) 것부터. PR=희망납기일, PO=예상도착일, STO=도착예정일
  " 방금 만든 문서(gt_pur_new)는 파란 줄로 맨 위에
  LOOP AT gt_pr ASSIGNING FIELD-SYMBOL(<pr_new>).
    READ TABLE gt_pur_new TRANSPORTING NO FIELDS WITH TABLE KEY table_line = <pr_new>-docno.
    IF sy-subrc = 0.
      <pr_new>-rowclr = 'C410'.
    ENDIF.
  ENDLOOP.
  LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<po_new>).
    READ TABLE gt_pur_new TRANSPORTING NO FIELDS WITH TABLE KEY table_line = <po_new>-docno.
    IF sy-subrc = 0.
      <po_new>-rowclr = 'C410'.
    ENDIF.
  ENDLOOP.
  LOOP AT gt_sto ASSIGNING FIELD-SYMBOL(<sto_new>).
    READ TABLE gt_pur_new TRANSPORTING NO FIELDS WITH TABLE KEY table_line = <sto_new>-docno.
    IF sy-subrc = 0.
      <sto_new>-rowclr = 'C410'.
    ENDIF.
  ENDLOOP.
  SORT gt_pr BY rowclr DESCENDING lfdat docno item.
  SORT gt_po BY rowclr DESCENDING lfdat docno item.
  SORT gt_sto BY rowclr DESCENDING eta docno item.
  PERFORM count_documents USING gt_pr CHANGING gv_pr_docs.
  PERFORM count_documents USING gt_po CHANGING gv_po_docs.
  PERFORM count_documents USING gt_sto CHANGING gv_sto_docs.
  " 카드 아래 작은 글씨: 날짜가 지난 문서 수(문서번호 중복 제외)
  DATA late_rows TYPE ty_rows.
  late_rows = gt_pr.
  DELETE late_rows WHERE status <> '희망납기 경과'.   " 신호등은 노랑이라 상태 글자로 셈
  PERFORM count_documents USING late_rows CHANGING gv_pr_late.
  late_rows = gt_po.
  DELETE late_rows WHERE status <> '도착일 경과'.   " 신호등은 노랑이라 상태 글자로 셈
  PERFORM count_documents USING late_rows CHANGING gv_po_late.
ENDFORM.

" decorate_rows : 업무 목록 한 줄에 자재명·업체명·지사명을 채운다. DB 변경 없음.
FORM decorate_rows CHANGING rows TYPE ty_rows.
  IF rows IS INITIAL.
    RETURN.
  ENDIF.
  " 자재명·업체명은 목록 전체를 한 번에 읽어 두고 줄마다 찾아 넣는다(루프 안 SELECT 없음).
  TYPES: BEGIN OF ty_mat_txt,
           matnr TYPE z8material_txt_m-matnr,
           maktx TYPE z8material_txt_m-maktx,
         END OF ty_mat_txt,
         BEGIN OF ty_vendor_txt,
           lifnr TYPE z8vendor_m-lifnr,
           name1 TYPE z8vendor_m-name1,
         END OF ty_vendor_txt.
  DATA: lt_mat_txt TYPE SORTED TABLE OF ty_mat_txt WITH NON-UNIQUE KEY matnr,
        lt_vendor_txt TYPE SORTED TABLE OF ty_vendor_txt WITH NON-UNIQUE KEY lifnr.
  SELECT matnr, maktx FROM z8material_txt_m FOR ALL ENTRIES IN @rows
    WHERE matnr = @rows-matnr AND spras = @sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @lt_mat_txt.
  DATA(lt_vendor_rows) = rows.
  DELETE lt_vendor_rows WHERE lifnr IS INITIAL.
  IF lt_vendor_rows IS NOT INITIAL.
    SELECT lifnr, name1 FROM z8vendor_m FOR ALL ENTRIES IN @lt_vendor_rows
      WHERE lifnr = @lt_vendor_rows-lifnr
      INTO CORRESPONDING FIELDS OF TABLE @lt_vendor_txt.
  ENDIF.
  LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
    READ TABLE lt_mat_txt INTO DATA(ls_mat_txt) WITH TABLE KEY matnr = <row>-matnr.
    IF sy-subrc = 0.
      <row>-maktx = ls_mat_txt-maktx.
    ENDIF.
    IF <row>-lifnr IS NOT INITIAL.
      READ TABLE lt_vendor_txt INTO DATA(ls_vendor_txt) WITH TABLE KEY lifnr = <row>-lifnr.
      IF sy-subrc = 0.
        <row>-vendor_name = ls_vendor_txt-name1.
      ELSE.
        <row>-vendor_name = <row>-lifnr.
      ENDIF.
    ENDIF.
    " 구매지사·출발/도착지사 열은 지사명(예: 충청지사)으로 보여준다.
    PERFORM site_label USING <row>-werks CHANGING <row>-site_name.
    IF <row>-reswk IS NOT INITIAL.
      PERFORM site_label USING <row>-reswk CHANGING <row>-source_name.
    ENDIF.
  ENDLOOP.
ENDFORM.

" site_label : 플랜트 코드 → 지사명. 그 플랜트의 지사(z8branch_m)가 1건이면 지사명, 아니면 플랜트명, 없으면 코드.
FORM site_label USING iv_werks TYPE clike CHANGING cv_name TYPE clike.
  READ TABLE gt_plants INTO DATA(ls_plant) WITH KEY werks = iv_werks.
  IF sy-subrc <> 0.
    cv_name = iv_werks.
    RETURN.
  ENDIF.
  DATA lv_hits TYPE i.
  DATA lv_branch TYPE z8branch_m-name.
  LOOP AT gt_branches INTO DATA(ls_branch) WHERE branch = ls_plant-bupla.
    lv_hits = lv_hits + 1.
    lv_branch = ls_branch-name.
  ENDLOOP.
  IF lv_hits = 1 AND lv_branch IS NOT INITIAL.
    cv_name = lv_branch.
  ELSEIF ls_plant-name1 IS NOT INITIAL.
    cv_name = ls_plant-name1.
  ELSE.
    cv_name = iv_werks.
  ENDIF.
ENDFORM.

" 건수는 문서번호 중복을 제거한다. 한 PO에 품목이 둘이면 1건이다.
FORM count_documents USING rows TYPE ty_rows CHANGING total TYPE i.
  DATA documents TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line.
  LOOP AT rows INTO DATA(row).
    INSERT row-docno INTO TABLE documents.
  ENDLOOP.
  total = lines( documents ).
ENDFORM.

" select_view : 고른 카드(PR/PO/STO)의 목록을 ALV용 gt_out에 옮기고 ALV 제목을 만든다.
FORM select_view.
  DATA title TYPE c LENGTH 40.
  DATA documents TYPE i.
  CASE gv_view.
    WHEN 'R'.
      gt_out = gt_pr.
      title = '미발주 PR'.
      documents = gv_pr_docs.
    WHEN 'O'.
      gt_out = gt_po.
      title = '진행 중 PO'.
      documents = gv_po_docs.
    WHEN 'S'.
      gt_out = gt_sto.
      title = '예약·이동 STO'.
      documents = gv_sto_docs.
  ENDCASE.
  gv_list_title = |{ title } · { documents }건 / { lines( gt_out ) }품목|.
  " 건수는 ALV 제목에 보이므로 상태줄 메시지는 데이터가 없을 때만 띄운다.
  IF gt_out IS INITIAL.
    MESSAGE s061(z8_msg).   " 조회 조건에 해당하는 데이터가 없습니다
  ENDIF.
  CLEAR gv_row.
ENDFORM.

" 지사명은 화면 옆 출력칸 GV_WNAME에 표시한다(예: 경기남부지사).
FORM show_site_name.
  CLEAR gv_wname.
  IF gv_werks IS INITIAL OR gv_werks = '*'.
    gv_wname = '전체 지사'.
  ELSE.
    READ TABLE gt_branches INTO DATA(ls_site_branch) WITH KEY branch = gv_werks.
    IF sy-subrc = 0.
      gv_wname = ls_site_branch-name.
    ELSE.
      gv_wname = '등록되지 않은 지사'.
    ENDIF.
  ENDIF.
ENDFORM.

" site_plants : 담당 지사(B001)에 속한 입고플랜트(P100…) 조건. 전체 지사면 비워 둔다(전체).
FORM site_plants CHANGING ct_plants TYPE STANDARD TABLE.
  DATA lr_plants TYPE RANGE OF z8mm_pr-werks.
  CLEAR ct_plants.
  IF gv_werks IS INITIAL OR gv_werks = '*'.
    RETURN.
  ENDIF.
  LOOP AT gt_plants INTO DATA(ls_site_plant) WHERE bupla = gv_werks.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_site_plant-werks ) TO lr_plants.
  ENDLOOP.
  IF lr_plants IS INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = '####' ) TO lr_plants.   " 플랜트 없는 지사 → 결과 없음
  ENDIF.
  ct_plants = lr_plants.
ENDFORM.

" site_plant : 하위 프로그램(PR·PO·STO 생성·목록)에 넘길 플랜트 하나. 지사의 첫 플랜트, 전체면 공백.
FORM site_plant CHANGING cv_plant TYPE z8mm_pr-werks.
  CLEAR cv_plant.
  IF gv_werks IS INITIAL OR gv_werks = '*'.
    RETURN.
  ENDIF.
  LOOP AT gt_plants INTO DATA(ls_first_plant) WHERE bupla = gv_werks.
    cv_plant = ls_first_plant-werks.
    EXIT.
  ENDLOOP.
ENDFORM.

" 유효하지 않은 코드는 마지막 조회 지사로 되돌리고 생성/문서호출을 중단한다.
FORM validate_site CHANGING valid TYPE abap_bool.
  valid = abap_true.
  TRANSLATE gv_werks TO UPPER CASE.
  IF gv_werks = '*'.
    CLEAR gv_werks.
  ENDIF.
  IF gv_werks IS INITIAL.
    PERFORM show_site_name.
    RETURN.
  ENDIF.
  " 글자 일부(예: B0, 충청)만 넣고 Enter → 1건이면 자동 완성, 여러 건이면 목록에서 고른다.
  lcl_mm_f4=>resolve( EXPORTING kind = 'BRANCH' CHANGING value = gv_werks ).
  READ TABLE gt_branches TRANSPORTING NO FIELDS WITH KEY branch = gv_werks.
  IF sy-subrc <> 0.
    gv_werks = gv_previous.
    PERFORM show_site_name.
    valid = abap_false.
    MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '등록된 지사'.   " 등록된 지사를 입력해주세요(이전 지사로 되돌림)
  ELSE.
    PERFORM show_site_name.
  ENDIF.
ENDFORM.

" choose_plant : 담당 지사(GV_WERKS, 일반 입력칸) F4. 지사코드(B001)와 지사명을 보여주고 코드만 돌려받는다.
"   맨 위 '전체 지사'는 빈 값이다.
FORM choose_plant.
  TYPES: BEGIN OF ty_help,
           branch TYPE z8branch_m-branch,
           name   TYPE z8branch_m-name,
         END OF ty_help.
  DATA values TYPE STANDARD TABLE OF ty_help WITH EMPTY KEY.
  DATA returns TYPE STANDARD TABLE OF ddshretval WITH EMPTY KEY.
  " 칸에 값이 있어도 항상 '전체 지사' + 전체 목록을 보여준다(지사를 고른 뒤 전체로 되돌릴 수 있게).
  "   글자 일부(예: B0)로 찾기는 Enter로 한다(validate_site).
  APPEND VALUE #( name = '전체 지사' ) TO values.
  LOOP AT gt_branches INTO DATA(ls_help_branch).
    APPEND VALUE #( branch = ls_help_branch-branch name = ls_help_branch-name ) TO values.
  ENDLOOP.
  SORT values BY branch.
  DELETE ADJACENT DUPLICATES FROM values COMPARING branch.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'BRANCH' value_org = 'S' window_title = '지사 선택'
    TABLES value_tab = values return_tab = returns
    EXCEPTIONS parameter_error = 1 no_values_found = 2 OTHERS = 3.
  IF sy-subrc <> 0.
    MESSAGE s022(z8_msg) DISPLAY LIKE 'E'.   " 데이터를 불러올 수 없습니다(지사 검색도움말)
    RETURN.
  ENDIF.
  READ TABLE returns INDEX 1 INTO DATA(selected).
  IF sy-subrc <> 0.
    RETURN. " F4 취소: 기존 코드와 지사명을 유지한다.
  ENDIF.
  gv_werks = selected-fieldval.
  PERFORM show_site_name.
  DATA fields TYPE STANDARD TABLE OF dynpread WITH EMPTY KEY.
  fields = VALUE #( ( fieldname = 'GV_WERKS' fieldvalue = gv_werks )
                    ( fieldname = 'GV_WNAME' fieldvalue = gv_wname ) ).
  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING dyname = sy-repid dynumb = sy-dynnr
    TABLES dynpfields = fields EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
    MESSAGE s105(z8_msg) DISPLAY LIKE 'E'.   " 상태 변경에 실패했습니다(화면 값 갱신)
    RETURN.
  ENDIF.
  " F4로 고르면 코드·지사명만 화면에 넣는다. 조회는 PR·PO·STO 목록과 같이 Enter·[조회] 때 한다.
ENDFORM.

" column : ALV 열 하나(필드·제목·폭)를 gt_catalog에 추가한다.
FORM column USING field TYPE clike title TYPE clike width TYPE i.
  DATA fc TYPE lvc_s_fcat.
  fc-fieldname = field.
  fc-coltext = title.
  fc-scrtext_l = title.
  fc-scrtext_m = title.
  fc-scrtext_s = title.
  fc-outputlen = width.
  CASE field.
    WHEN 'SIGNAL'.
      fc-icon = abap_true.
      fc-just = 'C'.
    WHEN 'DOCNO'.
      fc-ref_table = 'Z8MM_PO_H'.
      fc-ref_field = 'EBELN'.
    WHEN 'ITEM'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'EBELP'.
    WHEN 'MENGE'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'MENGE'.
      fc-qfieldname = 'MEINS'.
      fc-decimals_o = 0.
      " 실제 소수수량이 있으면 열 전체를 3자리로 표시해 수량 손실을 막는다.
      LOOP AT gt_out INTO DATA(row).
        DATA(amount) = CONV decfloat34( row-menge ).
        IF amount <> trunc( amount ).
          fc-decimals_o = 3.
          EXIT.
        ENDIF.
      ENDLOOP.
    WHEN 'MEINS'.
      fc-ref_table = 'Z8MM_PO_I'.
      fc-ref_field = 'MEINS'.
    WHEN 'LFDAT' OR 'BEDAT' OR 'DEP_DATE' OR 'ETA'.
      fc-datatype = 'DATS'.
      fc-inttype = 'D'.
  ENDCASE.
  APPEND fc TO gt_catalog.
ENDFORM.

" build_catalog : 고른 업무(gv_view)에 맞는 열 목록을 만든다(열 순서 = PERFORM column 순서).
FORM build_catalog.
  CLEAR gt_catalog.
  PERFORM column USING 'SIGNAL' '상태' 4.
  " 상태 글자를 신호등 바로 옆에(멀리서도 색 이유가 보이게)
  PERFORM column USING 'STATUS' '처리상태' 12.
  IF gv_view = 'R'.
    PERFORM column USING 'DOCNO' 'PR 번호' 11.
  ELSEIF gv_view = 'O'.
    PERFORM column USING 'DOCNO' 'PO 번호' 12.
  ELSE.
    PERFORM column USING 'DOCNO' 'STO 번호' 12.
  ENDIF.
  IF gv_view = 'S'.
    PERFORM column USING 'SOURCE_NAME' '출발지사' 20.
    PERFORM column USING 'SITE_NAME' '도착지사' 20.
  ELSE.
    PERFORM column USING 'SITE_NAME' '구매지사' 20.
  ENDIF.
  PERFORM column USING 'MATNR' '자재번호' 14.
  PERFORM column USING 'MAKTX' '자재명' 18.
  PERFORM column USING 'MENGE' '수량' 10.
  PERFORM column USING 'MEINS' '단위' 5.
  IF gv_view = 'R' OR gv_view = 'O'.
    PERFORM column USING 'VENDOR_NAME' '공급업체' 14.
  ENDIF.
  CASE gv_view.
    WHEN 'R'.
      PERFORM column USING 'LFDAT' '희망납기일' 10.
    WHEN 'O'.
      PERFORM column USING 'BEDAT' '발주일' 10.
      PERFORM column USING 'LFDAT' '예상도착일' 10.
    WHEN OTHERS.
      PERFORM column USING 'DEP_DATE' '출고일' 10.
      PERFORM column USING 'ETA' '예상도착일' 10.
  ENDCASE.
ENDFORM.

" display_grid : 업무 목록 ALV를 그린다. 업무가 바뀌면 ALV를 새로 만들어 정렬·필터가 섞이지 않게 한다.
FORM display_grid.
  " 업무 전환 시 정렬·필터·선택이 이전 업무에서 남지 않도록 ALV를 다시 만든다.
  IF go_grid IS BOUND AND gv_rendered_view <> gv_view.
    go_grid->free( ).
    FREE go_grid.
  ENDIF.
  PERFORM build_catalog.
  IF go_grid IS NOT BOUND.
    IF go_container IS NOT BOUND.
      CREATE OBJECT go_container EXPORTING container_name = 'CC_MAIN'.
    ENDIF.
    CREATE OBJECT go_grid EXPORTING i_parent = go_container.
    IF go_events IS NOT BOUND.
      CREATE OBJECT go_events.
    ENDIF.
    SET HANDLER go_events->double_click FOR go_grid.
    DATA layout TYPE lvc_s_layo.
    layout-zebra = abap_true.               " 얼룩무늬
    layout-sel_mode = 'A'.
    " 열 너비 자동맞춤 끔: 처음 화면과 카드로 다시 연 화면의 열 모양이 같도록
    " 항상 build_catalog의 고정 너비를 쓴다.
    layout-cwidth_opt = abap_false.
    " 줄 색은 방금 만든 문서(파란 줄)에만 쓴다. 상태는 신호등 열로 표시한다.
    layout-info_fname = 'ROWCLR'.
    layout-smalltitle = abap_true.
    layout-grid_title = gv_list_title.
    " ALV 위쪽 버튼은 정렬(오름차순·내림차순)만 남긴다.
    " 위쪽 버튼줄 없음. 정렬은 열 머리글 오른쪽 클릭 → 오름차순/내림차순.
    " ALV 위쪽 버튼줄을 다시 보이게 한다: 열 머리글을 눌러 고른 뒤 [오름차순]/[내림차순] 버튼으로 정렬(PO 화면과 동일).
    layout-no_toolbar = abap_false.
    DATA lt_excl TYPE ui_functions.
    PERFORM sort_only_toolbar CHANGING lt_excl.
    go_grid->set_table_for_first_display(
      EXPORTING is_layout = layout it_toolbar_excluding = lt_excl
      CHANGING it_outtab = gt_out it_fieldcatalog = gt_catalog ).
    gv_rendered_view = gv_view.
    PERFORM select_pur_new.
  ELSE.
    go_grid->set_frontend_fieldcatalog( it_fieldcatalog = gt_catalog ).
    DATA grid_title TYPE lvc_title.
    grid_title = gv_list_title.
    go_grid->set_gridtitle( i_gridtitle = grid_title ).
    DATA selected TYPE lvc_t_row.
    go_grid->set_selected_rows( it_index_rows = selected ).
    go_grid->refresh_table_display(
      EXPORTING is_stable = VALUE lvc_s_stbl( row = abap_true col = abap_true ) ).
    PERFORM select_pur_new.
  ENDIF.
ENDFORM.

" select_pur_new : 방금 만든 문서 행을 한 번 선택 상태로 걸어 둔다.
FORM select_pur_new.
  IF go_grid IS NOT BOUND OR gv_pur_sel = abap_false.
    RETURN.
  ENDIF.
  DATA lt_rows TYPE lvc_t_row.
  LOOP AT gt_out TRANSPORTING NO FIELDS WHERE rowclr = 'C410'.
    APPEND VALUE #( index = sy-tabix ) TO lt_rows.
  ENDLOOP.
  go_grid->set_selected_rows( it_index_rows = lt_rows ).
  CLEAR gv_pur_sel.
ENDFORM.

" free_controls : 화면을 나갈 때 ALV·카드 컨트롤을 모두 해제한다.
FORM free_controls.
  IF go_grid IS BOUND.
    go_grid->free( ).
    FREE go_grid.
  ENDIF.
  IF go_container IS BOUND.
    go_container->free( ).
    FREE go_container.
  ENDIF.
  FREE go_events.
  IF go_card_html IS BOUND.
    go_card_html->free( ).
    FREE go_card_html.
  ENDIF.
  IF go_card_box IS BOUND.
    go_card_box->free( ).
    FREE go_card_box.
  ENDIF.
  FREE go_card_events.
  CLEAR gv_card_stamp.
ENDFORM.

" ------------------------------------------------------------
" 상단 카드 3장 (CC_SUM). 한글은 HTML 문자참조로 넣어 코드페이지와 무관하게 표시한다.
" ------------------------------------------------------------
FORM show_cards.
  DATA(stamp) = |{ gv_pr_docs }/{ gv_po_docs }/{ gv_sto_docs }/| &&
                |{ gv_pr_late }/{ gv_po_late }/{ gv_view }/{ gv_date }|.
  IF go_card_html IS BOUND AND stamp = gv_card_stamp.
    RETURN.
  ENDIF.
  IF go_card_box IS NOT BOUND.
    CREATE OBJECT go_card_box EXPORTING container_name = 'CC_SUM' EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_card_html IS NOT BOUND.
    CREATE OBJECT go_card_html EXPORTING parent = go_card_box EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CREATE OBJECT go_card_events.
    SET HANDLER go_card_events->on_click FOR go_card_html.
    DATA events TYPE cntl_simple_events.
    events = VALUE #( ( eventid = cl_gui_html_viewer=>m_id_sapevent appl_event = abap_false ) ).
    go_card_html->set_registered_events( EXPORTING events = events EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  DATA html TYPE STANDARD TABLE OF w3html WITH EMPTY KEY.
  APPEND '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' TO html.
  APPEND 'body{margin:0;padding:6px 8px;background:#f7f9fb;font:12px Arial,sans-serif;color:#607ca2}' TO html.
  APPEND 'table{width:100%;table-layout:fixed;border-spacing:8px 0}td{vertical-align:top}' TO html.
  APPEND '.c{background:#fff;border:1px solid #d6e0ee;border-radius:10px;padding:8px 12px}' TO html.
  APPEND '.c.on{border:2px solid #1684bf;background:#edf6ff;padding:7px 11px}' TO html.
  APPEND 'a.m{display:block;text-decoration:none;color:#607ca2}a.m:hover .v{color:#1684bf}' TO html.
  APPEND '.v{font-size:26px;font-weight:bold;color:#243b53}.v small{font-size:13px;font-weight:normal;color:#607ca2}' TO html.
  APPEND '.s{font-size:11px;color:#8090a0}.s.w{color:#d34343}' TO html.
  APPEND '.d{display:inline-block;width:8px;height:8px;border-radius:4px;margin-right:4px}' TO html.
  APPEND '.g{background:#2e9d4f}.y{background:#e3b100}.r{background:#d34343}' TO html.
  APPEND '.l{margin-top:6px}.l a{color:#1684bf;text-decoration:none;border:1px solid #bcd6ea;' TO html.
  APPEND 'border-radius:4px;padding:1px 6px;background:#f6fbff;margin-right:4px}.l a:hover{background:#e3f1fb}' TO html.
  APPEND '</style></head><body><table><tr>' TO html.
  DATA sub TYPE string.
  " 미발주 PR
  IF gv_pr_late > 0.
    sub = |<span class="s w">&#55148;&#47581;&#45225;&#44592; &#51648;&#45212; PR { gv_pr_late }&#44148;</span>|.
  ELSE.
    sub = |<span class="s">&#48156;&#51452; &#45824;&#44592; &#51473;</span>|.
  ENDIF.
  PERFORM card USING 'R' 'PRLIST' 'y' '&#48120;&#48156;&#51452; PR' gv_pr_docs sub
    '<a href="SAPEVENT:PRNEW">&#65291; PR &#49373;&#49457;</a><a href="SAPEVENT:PRALL">PR &#51204;&#52404;&#47785;&#47197;</a>'
    CHANGING html.
  " 진행 중 PO
  IF gv_po_late > 0.
    sub = |<span class="s w">&#46020;&#52265;&#51068; &#44221;&#44284; { gv_po_late }&#44148;</span>|.
  ELSE.
    sub = |<span class="s">&#51077;&#44256; &#45824;&#44592; &#51473;</span>|.
  ENDIF.
  PERFORM card USING 'O' 'POLIST' 'y' '&#51652;&#54665; &#51473; PO' gv_po_docs sub
    '<a href="SAPEVENT:PONEW">&#65291; PO &#49373;&#49457;</a><a href="SAPEVENT:POALL">PO &#51204;&#52404;&#47785;&#47197;</a>'
    CHANGING html.
  " 예약·이동 STO 예약 STO 포함, 아랫줄 '예약 N · 이동 M')
  DATA: lv_sto_rsv TYPE i, lv_sto_mov TYPE i.
  DATA lt_sto_docs TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line.
  LOOP AT gt_sto INTO DATA(ls_sto_card) WHERE rsv_qty > 0.
    INSERT ls_sto_card-docno INTO TABLE lt_sto_docs.
  ENDLOOP.
  lv_sto_rsv = lines( lt_sto_docs ).
  lv_sto_mov = gv_sto_docs - lv_sto_rsv.
  sub = |<span class="s">&#50696;&#50557; { lv_sto_rsv } &#183; &#51060;&#46041; { lv_sto_mov }</span>|.
  PERFORM card USING 'S' 'STLIST' 'y' '&#50696;&#50557;&#183;&#51060;&#46041; STO' gv_sto_docs sub
    '<a href="SAPEVENT:STNEW">&#65291; STO &#49373;&#49457;</a><a href="SAPEVENT:STALL">STO &#51204;&#52404;&#47785;&#47197;</a>'
    CHANGING html.
  " 카드 3장 = 프로그램 3개(PR·PO·STO). 카드마다 [+ 생성] [전체목록] 버튼, PO 도착일 경과 건수는 카드 아래 빨간 글씨.
  APPEND '</tr></table></body></html>' TO html.
  DATA url TYPE c LENGTH 255.
  go_card_html->load_data( EXPORTING type = 'text' subtype = 'html'
    IMPORTING assigned_url = url CHANGING data_table = html EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  go_card_html->show_url( EXPORTING url = url in_place = abap_true EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    gv_card_stamp = stamp.
  ENDIF.
ENDFORM.

" card : 카드 한 장. 본문(건수)을 누르면 목록 전환, 아래 버튼은 프로그램 이동이다.
" HTML 한 줄은 255자 제한이 있어 여러 줄로 나눠 넣는다.
FORM card USING iv_view TYPE clike iv_code TYPE clike iv_dot TYPE clike iv_label TYPE clike
                iv_count TYPE i iv_sub TYPE string iv_links TYPE clike
          CHANGING ct_html TYPE STANDARD TABLE.
  DATA ls_line TYPE w3html.
  IF iv_view = gv_view.
    ls_line-line = '<td><div class="c on">'.
  ELSE.
    ls_line-line = '<td><div class="c">'.
  ENDIF.
  APPEND ls_line TO ct_html.
  ls_line-line = |<a class="m" href="SAPEVENT:{ iv_code }"><span class="d { iv_dot }"></span>{ iv_label }|.
  APPEND ls_line TO ct_html.
  ls_line-line = |<div class="v">{ iv_count NUMBER = RAW } <small>&#44148;</small></div></a>|.
  APPEND ls_line TO ct_html.
  ls_line-line = iv_sub.
  APPEND ls_line TO ct_html.
  ls_line-line = |<div class="l">{ iv_links }</div></div></td>|.
  APPEND ls_line TO ct_html.
ENDFORM.

" sort_only_toolbar : ALV 위쪽 버튼줄에서 [오름차순]·[내림차순] 정렬만 남기고 나머지 버튼을 숨기는 제외 목록을 만든다.
FORM sort_only_toolbar CHANGING et_excl TYPE ui_functions.
  " ALV 위쪽 버튼은 [오름차순 정렬]·[내림차순 정렬] 두 개만 남긴다.
  " 열 머리글을 한 번 눌러 열을 고른 뒤 정렬 버튼을 누르면 그 열 기준으로 정렬된다.
  et_excl = VALUE #(
    ( cl_gui_alv_grid=>mc_fc_detail ) ( cl_gui_alv_grid=>mc_fc_refresh ) ( cl_gui_alv_grid=>mc_fc_check )
    ( cl_gui_alv_grid=>mc_fc_loc_cut ) ( cl_gui_alv_grid=>mc_fc_loc_copy ) ( cl_gui_alv_grid=>mc_mb_paste )
    ( cl_gui_alv_grid=>mc_fc_loc_paste ) ( cl_gui_alv_grid=>mc_fc_loc_paste_new_row ) ( cl_gui_alv_grid=>mc_fc_loc_undo )
    ( cl_gui_alv_grid=>mc_fc_loc_append_row ) ( cl_gui_alv_grid=>mc_fc_loc_insert_row )
    ( cl_gui_alv_grid=>mc_fc_loc_delete_row ) ( cl_gui_alv_grid=>mc_fc_loc_copy_row )
    " 찾기·필터는 쓸 수 있는 기능이라 버튼줄에 남긴다(엑셀·인쇄·레이아웃 등만 숨김).
    ( cl_gui_alv_grid=>mc_mb_sum ) ( cl_gui_alv_grid=>mc_fc_sum ) ( cl_gui_alv_grid=>mc_fc_average )
    ( cl_gui_alv_grid=>mc_fc_maximum ) ( cl_gui_alv_grid=>mc_fc_minimum )
    ( cl_gui_alv_grid=>mc_mb_subtot ) ( cl_gui_alv_grid=>mc_fc_subtot )
    ( cl_gui_alv_grid=>mc_fc_print ) ( cl_gui_alv_grid=>mc_fc_print_back ) ( cl_gui_alv_grid=>mc_fc_print_prev )
    ( cl_gui_alv_grid=>mc_mb_export ) ( cl_gui_alv_grid=>mc_mb_view ) ( cl_gui_alv_grid=>mc_fc_views )
    ( cl_gui_alv_grid=>mc_mb_variant ) ( cl_gui_alv_grid=>mc_fc_current_variant )
    ( cl_gui_alv_grid=>mc_fc_load_variant ) ( cl_gui_alv_grid=>mc_fc_save_variant )
    ( cl_gui_alv_grid=>mc_fc_maintain_variant )
    ( cl_gui_alv_grid=>mc_fc_graph ) ( cl_gui_alv_grid=>mc_fc_info ) ).
ENDFORM.
