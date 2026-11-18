*&---------------------------------------------------------------------*
*& Include          Z8MMDS0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_objects_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECTS_LIST .
  " 화면 전체 자리
  CREATE OBJECT GO_CONT_MAIN
    EXPORTING
      CONTAINER_NAME = 'CC_MAIN'.
  " 위(요약) / 아래(본문) 2칸
  CREATE OBJECT GO_SPLIT_MAIN
    EXPORTING
      PARENT  = GO_CONT_MAIN
      ROWS    = 2
      COLUMNS = 1.
  GO_SPLIT_MAIN->SET_ROW_HEIGHT( ID = 1 HEIGHT = 28 ).
  GO_CONT_KPI  = GO_SPLIT_MAIN->GET_CONTAINER( ROW = 1 COLUMN = 1 ).
  GO_CONT_BODY = GO_SPLIT_MAIN->GET_CONTAINER( ROW = 2 COLUMN = 1 ).

  " 본문을 왼쪽(트리) / 오른쪽(목록) 2칸
  CREATE OBJECT GO_SPLIT_BODY
    EXPORTING
      PARENT  = GO_CONT_BODY
      ROWS    = 1
      COLUMNS = 2.
  GO_SPLIT_BODY->SET_COLUMN_WIDTH( ID = 1 WIDTH = 20 ).

  CALL METHOD GO_SPLIT_BODY->set_column_sash
    EXPORTING
      ID    = 1
      TYPE  = 1
      VALUE = 0.

  GO_CONT_TREE = GO_SPLIT_BODY->GET_CONTAINER( ROW = 1 COLUMN = 1 ).
  GO_CONT_LIST = GO_SPLIT_BODY->GET_CONTAINER( ROW = 1 COLUMN = 2 ).

  GT_SHOW = GT_LIST.
  " 목록 ALV를 오른쪽 칸에 얹는다
  CREATE OBJECT GO_GRID_LIST
    EXPORTING
      I_PARENT = GO_CONT_LIST.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_LIST .
  CLEAR GS_LAYO_LIST.
  GS_LAYO_LIST-EXCP_FNAME = 'LIGHT'.                " LIGHT 칸으로 신호등 표시
  GS_LAYO_LIST-EXCP_LED   = 'X'.
  GS_LAYO_LIST-ZEBRA      = 'X'.
  GS_LAYO_LIST-GRID_TITLE = |전체 { LINES( GT_SHOW ) }건|.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fieldcat_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_LIST .
  DATA LS_FCAT TYPE LVC_S_FCAT.

  CLEAR GT_FCAT_LIST.


  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'LIGHT'.
  LS_FCAT-COLTEXT   = '상태 '.
  LS_FCAT-ICON      = 'X'.                  " 이 열은 아이콘으로 표시
  LS_FCAT-OUTPUTLEN = 4.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MATNR'.
  LS_FCAT-COLTEXT   = '자재'.
  LS_FCAT-OUTPUTLEN = 18.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MAKTX'.
  LS_FCAT-COLTEXT   = '자재명'.
  LS_FCAT-OUTPUTLEN = 20.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'WERKS'.
  LS_FCAT-COLTEXT   = '플랜트'.
  LS_FCAT-OUTPUTLEN = 6.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'PLANT_NAME'.
  LS_FCAT-COLTEXT   = '플랜트명'.
  LS_FCAT-OUTPUTLEN = 10.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'LABST'.
  LS_FCAT-COLTEXT    = '현재고'.
  LS_FCAT-OUTPUTLEN  = 10.
  LS_FCAT-DECIMALS_O = 0.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'ZZRSVQTY'.
  LS_FCAT-COLTEXT    = '예약'.
  LS_FCAT-OUTPUTLEN  = 8.
  LS_FCAT-DECIMALS_O = 0.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'EISBE'.
  LS_FCAT-COLTEXT    = '안전재고'.
  LS_FCAT-OUTPUTLEN  = 8.
  LS_FCAT-DECIMALS_O = 0.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'AVAIL_QTY'.
  LS_FCAT-COLTEXT    = '가용'.
  LS_FCAT-OUTPUTLEN  = 10.
  LS_FCAT-DECIMALS_O = 0.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'MABST'.
  LS_FCAT-COLTEXT    = '목표'.
  LS_FCAT-OUTPUTLEN  = 10.
  LS_FCAT-DECIMALS_O = 0.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'LEVEL_PCT'.
  LS_FCAT-COLTEXT    = '목표대비(%)'.
  LS_FCAT-OUTPUTLEN  = 8.
  LS_FCAT-DECIMALS_O = 1.
  APPEND LS_FCAT TO GT_FCAT_LIST.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MEINS'.
  LS_FCAT-COLTEXT   = '단위'.
  LS_FCAT-OUTPUTLEN = 4.
  APPEND LS_FCAT TO GT_FCAT_LIST.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV_LIST .
  GO_GRID_LIST->SET_TABLE_FOR_FIRST_DISPLAY(
      EXPORTING IS_LAYOUT       = GS_LAYO_LIST
      CHANGING  IT_OUTTAB       = GT_SHOW
                IT_FIELDCATALOG = GT_FCAT_LIST ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FREE_ALV_LIST .
  "가장 바깥 컨테이너 free.
  IF GO_CONT_MAIN IS BOUND.
    GO_CONT_MAIN->FREE( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  FREE: GO_GRID_LIST, GO_CONT_LIST, GO_CONT_TREE, GO_CONT_BODY, GO_CONT_KPI,
        GO_SPLIT_BODY, GO_SPLIT_MAIN, GO_CONT_MAIN, GO_TREE, GO_HTML_KPI.

  IF GO_CONT_DET IS BOUND.
    GO_CONT_DET->FREE( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  FREE: GO_CONT_DET, GO_SPLIT_DET, GO_CONT_FILL, GO_GRID_FILL, GO_CONT_FILL, GO_CONT_DEP, GO_GRID_DEP.
*  FREE: go_cont_det, go_split_det, go_cont_chart, go_cont_fill, go_grid_fill, go_chart.
  "탭3.
  IF GO_CONT_MOVE IS NOT INITIAL.
    GO_CONT_MOVE->FREE( ).
  ENDIF.
  FREE: GO_GRID_MOVE, GO_HTML_MVF, GO_SPLIT_MOVE, GO_CONT_MVF, GO_CONT_MVB, GO_CONT_MOVE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_tree_nodes
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_TREE_NODES.
  DATA: LT_SORT  TYPE STANDARD TABLE OF TY_LIST,
        LS_LIST  TYPE TY_LIST,
        LS_IN    TYPE TY_LIST,
        LS_NODE  TYPE MTREESNODE,
        LS_MAP   TYPE TY_NODEMAP,
        LV_WERKS TYPE Z8MATPLANT_M-WERKS,
        LV_MTART TYPE Z8MATERIAL_M-MTART,
        LV_CNT   TYPE I,
        LV_IDX   TYPE N LENGTH 5,
        LV_PKEY  TYPE TV_NODEKEY,
        LV_TKEY  TYPE TV_NODEKEY,
        LS_TXT   TYPE DD07T,
        LV_MTEXT TYPE STRING.                   " 노드에 보여줄 이름

  " 도메인 고정값 텍스트를 한 번에 읽는다
  SELECT * FROM DD07T
    WHERE DOMNAME    = 'Z8D_MTART'          " 위에서 확인한 도메인 이름으로 바꿔줘
      AND DDLANGUAGE = '3'"@sy-langu
      AND AS4LOCAL   = 'A'                 " 활성 버전
    INTO TABLE @GT_MTART_TXT.

  CLEAR: GT_NODES, GT_NODEMAP.
  LT_SORT = GT_LIST.
  "같은 플랜트,자재유형이 같이 나와야 값이 바뀔 때 새 노드를 만든다.
  SORT LT_SORT BY WERKS MTART MATNR.

  " 맨 위: 전체
  CLEAR LS_NODE.
  LS_NODE-NODE_KEY = 'ROOT'.
  LS_NODE-ISFOLDER = 'X'.
  LS_NODE-TEXT     = '전체'.
  APPEND LS_NODE TO GT_NODES.
  CLEAR LS_MAP.
  LS_MAP-NODE_KEY = 'ROOT'.
  APPEND LS_MAP TO GT_NODEMAP.

  LOOP AT LT_SORT INTO LS_LIST.

    " 플랜트가 바뀌면 플랜트 노드를 만든다
    IF LS_LIST-WERKS <> LV_WERKS.
      LV_WERKS = LS_LIST-WERKS.
      CLEAR LV_MTART.
      LV_CNT = 0.
      LOOP AT LT_SORT INTO LS_IN WHERE WERKS = LV_WERKS AND STATUS = 'R'.
        LV_CNT = LV_CNT + 1.
      ENDLOOP.

      LV_PKEY = LV_WERKS.
      CLEAR LS_NODE.
      LS_NODE-NODE_KEY  = LV_PKEY.
      LS_NODE-RELATKEY  = 'ROOT'.
      LS_NODE-RELATSHIP = CL_GUI_SIMPLE_TREE=>RELAT_LAST_CHILD.
      LS_NODE-ISFOLDER  = 'X'.
      LS_NODE-TEXT      = |{ LV_WERKS } { LS_LIST-PLANT_NAME }|.
      IF LV_CNT > 0.
        LS_NODE-TEXT = |{ LS_NODE-TEXT } (부족 { LV_CNT })|.
      ENDIF.
      APPEND LS_NODE TO GT_NODES.
      CLEAR LS_MAP.
      LS_MAP-NODE_KEY = LV_PKEY.
      LS_MAP-WERKS    = LV_WERKS.
      APPEND LS_MAP TO GT_NODEMAP.
    ENDIF.

    " 자재유형이 바뀌면 자재유형 노드를 만든다
    IF LS_LIST-MTART <> LV_MTART.
      LV_MTART = LS_LIST-MTART.
      LV_TKEY  = |{ LV_WERKS }{ LV_MTART }|.
      " 코드(CBL 등)로 한글명을 찾는다. 없으면 코드를 그대로 쓴다
      READ TABLE GT_MTART_TXT INTO LS_TXT WITH KEY DOMVALUE_L = LV_MTART.
      IF SY-SUBRC = 0.
        LV_MTEXT = LS_TXT-DDTEXT.
      ELSE.
        LV_MTEXT = LV_MTART.
      ENDIF.

      CLEAR LS_NODE.
      LS_NODE-NODE_KEY  = LV_TKEY.
      "relatkey/rlatship->
      "이 노드가 누구의 마지막 자식이냐-> 트리의 부모/자식 관계 정하기
      LS_NODE-RELATKEY  = LV_PKEY.  "
      LS_NODE-RELATSHIP = CL_GUI_SIMPLE_TREE=>RELAT_LAST_CHILD.
      LS_NODE-ISFOLDER  = 'X'.  "펼칠 수 있는 노드(폴더)
      LV_MTEXT = |{ LV_MTART } { LS_TXT-DDTEXT }|.
      LS_NODE-TEXT      = LV_MTEXT."lv_mtart.
      APPEND LS_NODE TO GT_NODES.
      CLEAR LS_MAP.
      LS_MAP-NODE_KEY = LV_TKEY.
      LS_MAP-WERKS    = LV_WERKS.
      LS_MAP-MTART    = LV_MTART.
      APPEND LS_MAP TO GT_NODEMAP.
    ENDIF.

    " 자재 노드 (맨 아래)
    LV_IDX = LV_IDX + 1.
    CLEAR LS_NODE.
    LS_NODE-NODE_KEY  = |L{ LV_IDX }|.
    LS_NODE-RELATKEY  = LV_TKEY.
    LS_NODE-RELATSHIP = CL_GUI_SIMPLE_TREE=>RELAT_LAST_CHILD.
    LS_NODE-TEXT      = |{ LS_LIST-MATNR } { LS_LIST-MAKTX }|.
    APPEND LS_NODE TO GT_NODES.
    CLEAR LS_MAP.
    LS_MAP-NODE_KEY = LS_NODE-NODE_KEY.
    LS_MAP-WERKS    = LV_WERKS.
    LS_MAP-MTART    = LV_MTART.
    LS_MAP-MATNR    = LS_LIST-MATNR.
    APPEND LS_MAP TO GT_NODEMAP.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_tree
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECTS_TREE .
  CREATE OBJECT GO_TREE
    EXPORTING
      PARENT              = GO_CONT_TREE
      NODE_SELECTION_MODE = CL_GUI_SIMPLE_TREE=>NODE_SEL_MODE_SINGLE.
  GO_TREE->ADD_NODES(
    EXPORTING TABLE_STRUCTURE_NAME = 'MTREESNODE'
              NODE_TABLE           = GT_NODES ).
  GO_TREE->EXPAND_NODE( 'ROOT' ).


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_list_by_node
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> NODE_KEY
*&---------------------------------------------------------------------*
FORM SET_LIST_BY_NODE  USING PV_KEY TYPE TV_NODEKEY.
  " 트리 노드 클릭: 노드를 기억하고, 상태는 초기화한 뒤 KPI까지 다시 그린다
  "노드키로 목록 거르기.
  DATA: "ls_map  TYPE ty_nodemap,
            "ls_list TYPE ty_list,
            LS_NODE TYPE MTREESNODE.

  GV_NODE_KEY = PV_KEY.
  CLEAR GV_STATUS.
  PERFORM SET_SHOW_LIST.

  READ TABLE GT_NODES INTO LS_NODE WITH KEY NODE_KEY = PV_KEY.
  PERFORM SET_KPI_HTML USING LS_NODE-TEXT.
  PERFORM SET_GRID_TITLE.
  GO_GRID_LIST->REFRESH_TABLE_DISPLAY( ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_tree
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_EVENT_HANDLER_TREE .
  DATA: LT_EVENTS TYPE CNTL_SIMPLE_EVENTS,
        LS_EVENT  TYPE CNTL_SIMPLE_EVENT.

  LS_EVENT-EVENTID    = CL_GUI_SIMPLE_TREE=>EVENTID_NODE_DOUBLE_CLICK.
  LS_EVENT-APPL_EVENT = 'X'.
  APPEND LS_EVENT TO LT_EVENTS.
  "트리가 어떤 이벤트를 프로그램에 알려줄지 등록-> 더블클릭시.
  GO_TREE->SET_REGISTERED_EVENTS( EVENTS = LT_EVENTS ).
  SET HANDLER LCL_EVENT=>ON_NODE_DBLCLICK FOR GO_TREE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_kpi_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM SET_KPI_HTML USING PV_SCOPE.
  DATA: LS_LIST TYPE TY_LIST,
        LV_R    TYPE I,
        LV_Y    TYPE I,
        LV_G    TYPE I,
        LV_ALL  TYPE I,
        LV_URL  TYPE C LENGTH 255,
        LV_HTML TYPE STRING.
  "도넛차트
*  DATA: lv_circ TYPE f VALUE '251.3',   " 반지름 40인 원의 둘레
*      lv_lr   TYPE f,                 " 부족 구간 길이
*      lv_ly   TYPE f,                 " 주의 구간 길이
*      lv_lg   TYPE f,                 " 정상 구간 길이
*      lv_oy   TYPE f,                 " 주의 시작 위치
*      lv_og   TYPE f.                 " 정상 시작 위치

*  " 현재 보이는 목록(gt_show)에서 신호등별 건수를 센다
  LOOP AT GT_SHOW INTO LS_LIST.
    CASE LS_LIST-LIGHT.
      WHEN '1'. LV_R = LV_R + 1.
      WHEN '2'. LV_Y = LV_Y + 1.
      WHEN OTHERS. LV_G = LV_G + 1.
    ENDCASE.
  ENDLOOP.
  LV_ALL = LINES( GT_SHOW ).

  LV_HTML = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><style>'.
  LV_HTML = LV_HTML && 'body{font-family:Malgun Gothic,sans-serif;margin:8px;background:transparent;}'.
  LV_HTML = LV_HTML && '.t{font-size:12px;color:#777;margin-bottom:8px;}'.
  LV_HTML = LV_HTML && '.g,.s{display:inline-block;vertical-align:top;background:#fff;border:1px solid #e3e6ea;'.
  LV_HTML = LV_HTML && 'border-radius:8px;padding:10px 18px;margin-right:12px;text-align:center;}'.
  LV_HTML = LV_HTML && '.s{padding:30px 22px;}.gl{font-size:12px;color:#555;margin-top:4px;}'.
  LV_HTML = LV_HTML && '.n{font-size:26px;font-weight:bold;color:#444;}</style></head><body>'.

  LV_HTML = LV_HTML && |<div class="t">조회 범위: { PV_SCOPE }</div>|.

  " 상태별 링 게이지 (라벨, 건수, 전체, 색)
  PERFORM SET_GAUGE_HTML USING '정상' 'G' LV_G LV_ALL '#5aa57a' CHANGING LV_HTML.
  PERFORM SET_GAUGE_HTML USING '주의' 'Y' LV_Y LV_ALL '#e8b84a' CHANGING LV_HTML.
  PERFORM SET_GAUGE_HTML USING '부족' 'R' LV_R LV_ALL '#d96459' CHANGING LV_HTML.

  " 총 개수 카드도 클릭하면 전체 보기
  LV_HTML = LV_HTML && |<a href="SAPEVENT:ALL" style="text-decoration:none"><div class="s"><div class="gl">Σ 총 자재 수</div><div class="n">{ LV_ALL }</div></div></a>|.
  LV_HTML = LV_HTML && '</body></html>'.

  " 3. 문자열 → 표 변환 후 HTML 뷰어에 띄운다
  GT_HTML = CL_BCS_CONVERT=>STRING_TO_SOLI( IV_STRING = LV_HTML ).

  " HTML 문서를 한 문자열로 이어 붙인다 (&& 는 문자열 연결)
*  lv_html = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">'.
*  lv_html = lv_html && '<style>body{font-family:Malgun Gothic,sans-serif;margin:8px;}'.
*  lv_html = lv_html && '.t{font-size:12px;color:#555;margin-bottom:6px;}'.
*  lv_html = lv_html && '.c{display:inline-block;width:120px;padding:8px 12px;margin-right:10px;color:#fff;}'.
*  lv_html = lv_html && '.n{font-size:24px;font-weight:bold;}.l{font-size:12px;}'.
*  lv_html = lv_html && '.r{background:#d96459}.y{background:#e8b84a;}.g{background:#5aa57a;}.a{background:#7a8896;}</style></head><body>'.
*
*  lv_html = lv_html && |<div class="t">조회 범위: { pv_scope }</div>|.
*  lv_html = lv_html && |<div class="c r"><div class="l">부족</div><div class="n">{ lv_r }</div></div>|.
*  lv_html = lv_html && |<div class="c y"><div class="l">주의</div><div class="n">{ lv_y }</div></div>|.
*  lv_html = lv_html && |<div class="c g"><div class="l">정상</div><div class="n">{ lv_g }</div></div>|.
*  lv_html = lv_html && |<div class="c a"><div class="l">전체</div><div class="n">{ lv_all }</div></div>|.

  "도넛차트 - 비율대로 잘라서 색 칠하기.
*    IF lv_all > 0.                                    " 0으로 나누기 방지
*    " 전체 둘레를 부족/주의/정상 비율대로 나눈다
*    lv_lr = lv_circ * lv_r / lv_all.
*    lv_ly = lv_circ * lv_y / lv_all.
*    lv_lg = lv_circ * lv_g / lv_all.
*    " 앞 구간 길이만큼 뒤로 밀어서 이어 붙인다 (음수)
*    lv_oy = - lv_lr.
*    lv_og = - ( lv_lr + lv_ly ).

*    lv_html = lv_html && '<svg width="90" height="90" viewBox="0 0 100 100" style="vertical-align:top;transform:rotate(-90deg)">'.
*    lv_html = lv_html && |<circle cx="50" cy="50" r="40" fill="none" stroke="#c0392b" stroke-width="18" stroke-dasharray="{ lv_lr DECIMALS = 1 } 251.3" stroke-dashoffset="0"/>|.
*    lv_html = lv_html && |<circle cx="50" cy="50" r="40" fill="none" stroke="#e6a800" stroke-width="18" stroke-dasharray="{ lv_ly DECIMALS = 1 } 251.3" stroke-dashoffset="{ lv_oy DECIMALS = 1 }"/>|.
*    lv_html = lv_html && |<circle cx="50" cy="50" r="40" fill="none" stroke="#2e8b57" stroke-width="18" stroke-dasharray="{ lv_lg DECIMALS = 1 } 251.3" stroke-dashoffset="{ lv_og DECIMALS = 1 }"/>|.
*        " 도넛 가운데 숫자 (svg를 돌려놔서 글자는 90도 되돌림)
**    lv_html = lv_html && |<text x="50" y="57" text-anchor="middle" font-size="22" font-weight="bold" fill="#555" transform="rotate(90 50 50)">{ lv_all }</text>|.
*    lv_html = lv_html && '</svg>'.
*  ENDIF.

*  lv_html = lv_html && '</body></html>'.

  " 긴 문자열을 HTML 컨트롤이 받는 표(255자 줄)로 바꾼다
*  gt_html = cl_bcs_convert=>string_to_soli( iv_string = lv_html ).

  " HTML 컨트롤은 처음 한 번만 만든다
  IF GO_HTML_KPI IS INITIAL.
    CREATE OBJECT GO_HTML_KPI
      EXPORTING
        PARENT = GO_CONT_KPI.

    " HTML 링크 클릭(SAPEVENT)을 ABAP 이벤트로 받도록 등록
    DATA: LT_EVENTS TYPE CNTL_SIMPLE_EVENTS,
          LS_EVENT  TYPE CNTL_SIMPLE_EVENT.
    LS_EVENT-EVENTID    = CL_GUI_HTML_VIEWER=>M_ID_SAPEVENT.
    LS_EVENT-APPL_EVENT = 'X'.
    APPEND LS_EVENT TO LT_EVENTS.
    GO_HTML_KPI->SET_REGISTERED_EVENTS( EVENTS = LT_EVENTS ).
    SET HANDLER LCL_EVENT=>ON_SAPEVENT FOR GO_HTML_KPI.
  ENDIF.

  " HTML 표를 컨트롤에 올려서 화면에 보여준다
  GO_HTML_KPI->LOAD_DATA(
    IMPORTING ASSIGNED_URL = LV_URL
    CHANGING  DATA_TABLE   = GT_HTML ).
  GO_HTML_KPI->SHOW_URL( URL = LV_URL ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_gauge_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> LV_G
*&      --> LV_ALL
*&      --> P_
*&      <-- LV_HTML
*&---------------------------------------------------------------------*
FORM SET_GAUGE_HTML USING    PV_LABEL TYPE STRING
                             PV_CODE  TYPE STRING          " R / Y / G (클릭 시 넘길 코드)
                             PV_CNT   TYPE I
                             PV_TOTAL TYPE I
                             PV_COLOR TYPE STRING
                    CHANGING PV_HTML  TYPE STRING.
  DATA: LV_PCT TYPE P LENGTH 5 DECIMALS 0,   " 비율(%)
        LV_ARC TYPE F.                       " 색칠할 호 길이

  IF PV_TOTAL > 0.
    LV_PCT = PV_CNT * 100 / PV_TOTAL.
    LV_ARC = '188.5' * PV_CNT / PV_TOTAL.    " 188.5 = 반지름 30인 원의 둘레
  ENDIF.

  " 링 전체를 <a> 링크로 감싸서 클릭하면 SAPEVENT가 발생하게 한다
  PV_HTML = PV_HTML && |<a href="SAPEVENT:{ PV_CODE }" style="text-decoration:none">|
    && |<div class="g"><svg width="70" height="70" viewBox="0 0 70 70">|
    && |<circle cx="35" cy="35" r="30" fill="none" stroke="#e5e8eb" stroke-width="6"/>|
    && |<circle cx="35" cy="35" r="30" fill="none" stroke="{ PV_COLOR }" stroke-width="6" stroke-dasharray="{ LV_ARC DECIMALS = 1 } 188.5" transform="rotate(-90 35 35)"/>|
    && |<text x="35" y="40" text-anchor="middle" font-size="14" font-weight="bold" fill="{ PV_COLOR }">{ LV_PCT }%</text></svg>|
    && |<div class="gl">{ PV_LABEL } { PV_CNT }개</div></div></a>|.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_list_by_status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ACTION
*&---------------------------------------------------------------------*
FORM SET_LIST_BY_STATUS USING PV_CODE.
  IF PV_CODE = 'ALL'.
    CLEAR GV_STATUS.
  ELSE.
    GV_STATUS = PV_CODE.
  ENDIF.

  PERFORM SET_SHOW_LIST.
  PERFORM SET_GRID_TITLE.
  GO_GRID_LIST->REFRESH_TABLE_DISPLAY( ).
*  DATA ls_list TYPE ty_list.
*
*  CLEAR gt_show.
*  LOOP AT gt_list INTO ls_list.
*    " ALL이면 전부, 아니면 상태 코드가 같은 것만
*    IF pv_code = 'ALL' OR ls_list-status = pv_code.
*      APPEND ls_list TO gt_show.
*    ENDIF.
*  ENDLOOP.
*  PERFORM set_grid_title.
*  go_grid_list->refresh_table_display( ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_GRID_TITLE.
  DATA LV_STAT TYPE STRING.

  " 현재 선택한 상태 이름
  CASE GV_STATUS.
    WHEN 'R'. LV_STAT = '부족'.
    WHEN 'Y'. LV_STAT = '주의'.
    WHEN 'G'. LV_STAT = '정상'.
    WHEN OTHERS. LV_STAT = '전체'.
  ENDCASE.

  GS_LAYO_LIST-GRID_TITLE = |{ LV_STAT } { LINES( GT_SHOW ) }건|.
  GO_GRID_LIST->SET_FRONTEND_LAYOUT( IS_LAYOUT = GS_LAYO_LIST ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_show_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_SHOW_LIST.
  "KPI+트리선택 필터 하쳐서 적용.
  DATA: LS_LIST TYPE TY_LIST,
        LS_MAP  TYPE TY_NODEMAP.

  CLEAR GT_SHOW.
  " 선택한 노드의 조건(플랜트/자재유형/자재)을 찾는다. 없으면 조건 없음 = 전체
  READ TABLE GT_NODEMAP INTO LS_MAP WITH KEY NODE_KEY = GV_NODE_KEY.

  LOOP AT GT_LIST INTO LS_LIST.
    IF LS_MAP-WERKS IS NOT INITIAL AND LS_LIST-WERKS <> LS_MAP-WERKS. CONTINUE. ENDIF.
    IF LS_MAP-MTART IS NOT INITIAL AND LS_LIST-MTART <> LS_MAP-MTART. CONTINUE. ENDIF.
    IF LS_MAP-MATNR IS NOT INITIAL AND LS_LIST-MATNR <> LS_MAP-MATNR. CONTINUE. ENDIF.
    " 상태 조건은 선택했을 때만 적용
    IF GV_STATUS IS NOT INITIAL AND LS_LIST-STATUS <> GV_STATUS. CONTINUE. ENDIF.
    APPEND LS_LIST TO GT_SHOW.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Module SET_DROPDOWN_0120 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE SET_DROPDOWN_0120 OUTPUT.

  DATA: LT_VALUES TYPE VRM_VALUES,
        LS_VALUE  TYPE VRM_VALUE.
  CLEAR: LT_VALUES, LS_VALUE.

  LS_VALUE-KEY  = GC_ALL.
  LS_VALUE-TEXT = '전체'.
  APPEND LS_VALUE TO LT_VALUES.

  SELECT DISTINCT T~MATNR, MIN( T~MAKTX ) AS MAKTX              " 목표수량이 있는 자재만 (탭 1과 같은 기준)
    FROM Z8MATERIAL_TXT_M AS T
    INNER JOIN Z8MATPLANT_M AS P ON P~MATNR = T~MATNR
        WHERE T~SPRAS = '3' AND P~MABST > 0 AND P~MATNR IN @S_MATNR
    GROUP BY T~MATNR
    ORDER BY T~MATNR
    INTO TABLE @DATA(LT_MAT).
  IF SY-SUBRC <> 0.
    MESSAGE S022(Z8_MSG) DISPLAY LIKE 'E'.         " 자재 정보를 읽을 수 없습니다.
  ENDIF.

  LOOP AT LT_MAT INTO DATA(LS_MAT).
    LS_VALUE-KEY  = LS_MAT-MATNR.
    LS_VALUE-TEXT = LS_MAT-MAKTX. "|{ ls_mat-matnr } { ls_mat-maktx }|.."LS_MAT-MAKTX.
    APPEND LS_VALUE TO LT_VALUES.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      ID     = 'GV_MATNR_SEL'
      VALUES = LT_VALUES.

  "수정전
*  DATA: lt_values TYPE vrm_values,                        " 드롭다운 목록
*        ls_value  TYPE vrm_value,                               " 한 줄 (key / text)
*        lt_sort   TYPE STANDARD TABLE OF ty_list,
*        ls_list   TYPE ty_list.
*
*  CLEAR lt_values.                       " 다시 그릴 때마다 목록을 비우고 시작
*
*  " 탭 1에서 읽어둔 gt_list에서 자재를 중복 없이 뽑는다
*  lt_sort = gt_list.
*  SORT lt_sort BY matnr.
*  DELETE ADJACENT DUPLICATES FROM lt_sort COMPARING matnr.
*  MESSAGE |자재 { lines( lt_sort ) }건| TYPE 'I'.   " 확인용 (확인 후 지울 것)
*
*  LOOP AT lt_sort INTO ls_list.
*    CLEAR ls_value.
*    ls_value-key  = ls_list-matnr.                               " 선택하면 변수에 들어가는 값
*    ls_value-text = ls_list-maktx .  " 화면에 보이는 글자
*    APPEND ls_value TO lt_values.
*  ENDLOOP.
*
*  " 화면 필드(GV_MATNR_SEL)에 목록을 연결한다
*  CALL FUNCTION 'VRM_SET_VALUES'
*    EXPORTING
*      id     = 'GV_MATNR_SEL'
*      values = lt_values.
*
*  " 처음 들어오면 첫 번째 자재를 기본 선택
*  IF gv_matnr_sel IS INITIAL.
*    READ TABLE lt_sort INTO ls_list INDEX 1.
*    gv_matnr_sel = ls_list-matnr.
*  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_DETAIL_0120 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE SET_DETAIL_0120 OUTPUT.
  " 처음 한 번만: 컨테이너, ALV 객체, 레이아웃, 필드카탈로그, 첫 표시
  IF GO_GRID_FILL IS INITIAL.
    "위칸 ALV: 입고예정문서.
    GV_MATNR_SEL = GC_ALL.
    PERFORM CREATE_OBJECTS_DETAIL.       " CC_DETAIL + 위/아래 칸
    PERFORM CREATE_OBJECTS_FILL.         " 아래 칸에 올릴 ALV 객체
    PERFORM SET_LAYOUT_FILL.
    PERFORM SET_FIELDCAT_FILL.
    PERFORM DISPLAY_ALV_FILL.
    "아래칸 ALV: 소진예상
    PERFORM CREATE_OBJECTS_DEP.
    PERFORM SET_LAYOUT_DEP.
    PERFORM SET_FIELDCAT_DEP.
    PERFORM DISPLAY_ALV_DEP.
    CLEAR GV_MATNR_DRAWN.                " 새로 만들었으니 아직 아무것도 안 그려진 상태
  ENDIF.

  " 선택한 자재가 바뀌었을 때만 표를 다시 만든다
  IF GV_MATNR_SEL <> GV_MATNR_DRAWN.
    "위 ALV
    PERFORM SET_FILL_DATA  USING GV_MATNR_SEL.
    PERFORM SET_GRID_TITLE_FILL.
    GO_GRID_FILL->REFRESH_TABLE_DISPLAY( ).
    "아래 ALV
    PERFORM SET_DEP_DATA USING GV_MATNR_SEL.
    GO_GRID_DEP->REFRESH_TABLE_DISPLAY( ).
    GV_MATNR_DRAWN = GV_MATNR_SEL.
    IF GT_FILL IS INITIAL." AND gv_matnr_sel IS NOT INITIAL.
      MESSAGE S116(Z8_MSG).
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Form set_chart_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_MATNR_SEL
*&---------------------------------------------------------------------*
*FORM set_chart_html USING pv_matnr.
*  DATA: ls_list  TYPE ty_list,
*        ls_fill  TYPE ty_fill,
*        lt_chart TYPE STANDARD TABLE OF ty_list,
*        lv_inb   TYPE z8mm_pr-menge,                " 플랜트별 입고 예정 합계
*        lv_cat   TYPE string,                       " 가로축 (플랜트)
*        lv_s1    TYPE string,                       " 시리즈1: 가용
*        lv_s2    TYPE string,                       " 시리즈2: 입고 예정
*        lv_s3    TYPE string,                       " 시리즈3: 목표
*        lv_xml   TYPE string,
*        lv_xdata TYPE xstring,
*        lv_avail TYPE z8mm_pr-menge.
*
*  " 1. 선택한 자재의 행만 추려서 플랜트 순으로 정렬
*  lt_chart = gt_list.
*  DELETE lt_chart WHERE matnr <> pv_matnr.
*  SORT lt_chart BY werks.
*
*  " 2. 플랜트마다 가로축 이름 1개 + 시리즈별 값 1개씩 XML 조각을 이어 붙인다
*  LOOP AT lt_chart INTO ls_list.
*    CLEAR lv_inb.
*    LOOP AT gt_fill INTO ls_fill WHERE werks = ls_list-werks AND docno IS NOT INITIAL.
*      lv_inb = lv_inb + ls_fill-menge.              " 이 플랜트의 PO+PR 수량 합계
*    ENDLOOP.
*
*    lv_avail = ls_list-avail_qty.
*    IF lv_avail < 0.
*      lv_avail = 0.
*    ENDIF.
*
*    lv_cat = lv_cat && |<Category>{ ls_list-werks }  가용 { ls_list-avail_qty NUMBER = USER DECIMALS = 0 } · 입고 +{ lv_inb NUMBER = USER DECIMALS = 0 } · 목표 { ls_list-mabst NUMBER = USER DECIMALS = 0 }</Category>|.
*    lv_s1 = lv_s1 && |<Point><Value type="y">{ lv_avail DECIMALS = 0 }</Value></Point>|.
*    lv_s2  = lv_s2  && |<Point><Value type="y">{ lv_inb DECIMALS = 0 }</Value></Point>|.
*    lv_s3  = lv_s3  && |<Point><Value type="y">{ ls_list-mabst DECIMALS = 0 }</Value></Point>|.
*  ENDLOOP.
*
*  " 3. 데이터 XML 조립 (구조: ChartData > Categories / Series > Point > Value)
*  lv_xml = |<?xml version="1.0" encoding="utf-8"?><ChartData>|
*        && |<Categories>{ lv_cat }</Categories>|
*        && |<Series label="가용">{ lv_s1 }</Series>|
*        && |<Series label="입고 예정">{ lv_s2 }</Series>|
*        && |<Series label="목표">{ lv_s3 }</Series>|
*        && |</ChartData>|.
*
*  " 4. 차트 엔진은 XML을 바이트(XSTRING)로 받는다 (UTF-8)
*  lv_xdata = cl_abap_codepage=>convert_to( source = lv_xml codepage = 'UTF-8' ).
*
*  " 5. 처음 한 번만 차트 객체를 만들고, 이후에는 데이터만 바꿔서 다시 그린다
*  IF go_chart IS INITIAL.
*    CREATE OBJECT go_chart EXPORTING parent = go_cont_chart.
*  ENDIF.
*  go_chart->set_data( xdata = lv_xdata ).
*  go_chart->render( ).
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_bar_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> LS_LIST_LABST
*&      --> LV_MAX
*&      --> P_
*&      <-- LV_HTML
*&---------------------------------------------------------------------*
*FORM set_bar_html USING    pv_label
*                           pv_val
*                           pv_max   TYPE f
*                           pv_color TYPE string
*                  CHANGING pv_html  TYPE string.
*  DATA: lv_val TYPE p LENGTH 15 DECIMALS 3,    " 값을 타입이 정해진 변수에 옮겨 담는다
*        lv_w   TYPE f.                         " 막대 길이 (%)
*
*  lv_val = pv_val.
*
*  " 가장 큰 값을 100%로 놓고 비율로 길이를 정한다. 음수는/ 0 은 막대 없음..
*  IF lv_val > 0.
*    lv_w = lv_val * 100 / pv_max.
*    IF lv_w < 1.                 " 값이 있는데 너무 짧으면 최소 길이를 줘서 보이게 한다
*      lv_w = 1.
*    ENDIF.
*  ENDIF.
*  pv_html = pv_html && |<div class="r"><span class="n">{ pv_label }</span>|
*    && |<span class="w"><span class="b" style="width:{ lv_w DECIMALS = 1 }%;background:{ pv_color }"></span></span>|
*    && |<span class="v">{ lv_val NUMBER = USER DECIMALS = 0 }</span></div>|.
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECTS_DETAIL . "컨테이너, 스플릿
  " 탭2: ALV./ 막대그래프
  CREATE OBJECT GO_CONT_DET
    EXPORTING
      CONTAINER_NAME              = 'CC_DETAIL'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.
  "소진예상 ALV 스플릿.
  CREATE OBJECT GO_SPLIT_DET
    EXPORTING
      PARENT            = GO_CONT_DET
      ROWS              = 2
      COLUMNS           = 1
    EXCEPTIONS
      CNTL_ERROR        = 1
      CNTL_SYSTEM_ERROR = 2
      OTHERS            = 3.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.
  GO_SPLIT_DET->SET_ROW_HEIGHT( ID = 1 HEIGHT = 60 ).        " 위 60% / 아래 40%
  GO_CONT_FILL = GO_SPLIT_DET->GET_CONTAINER( ROW = 1 COLUMN = 1 ).
  GO_CONT_DEP  = GO_SPLIT_DET->GET_CONTAINER( ROW = 2 COLUMN = 1 ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_fill
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECTS_FILL.
  CREATE OBJECT GO_GRID_FILL
    EXPORTING
      I_PARENT          = GO_CONT_FILL                 " 스플리터 칸이 아니라 CC_DETAIL 바로 위
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_fill
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV_FILL.
  GO_GRID_FILL->SET_TABLE_FOR_FIRST_DISPLAY(
    EXPORTING IS_LAYOUT       = GS_LAYO_FILL
    CHANGING  IT_OUTTAB       = GT_FILL
              IT_FIELDCATALOG = GT_FCAT_FILL ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fill_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_MATNR_SEL
*&---------------------------------------------------------------------*
FORM SET_FILL_DATA USING PV_MATNR TYPE Z8E_MATNR.
  DATA: LT_PO   TYPE STANDARD TABLE OF Z8MM_PO_I,
        LS_PO   TYPE Z8MM_PO_I,
        LT_PR   TYPE STANDARD TABLE OF Z8MM_PR,
        LS_PR   TYPE Z8MM_PR,
        LS_FILL TYPE TY_FILL,
        LS_LIST TYPE TY_LIST.

  CLEAR GT_FILL.

  " 1. 이 자재의 미입고 PO와 PO 전환 전 PR을 읽는다 (모든 플랜트)
  SELECT * FROM Z8MM_PO_I
    WHERE ( MATNR = @PV_MATNR OR @PV_MATNR = @GC_ALL )
    AND MATNR IN @S_MATNR AND WERKS IN @S_WERKS
    AND ELIKZ = '' AND LOEKZ = ''
    INTO TABLE @LT_PO.
  SELECT * FROM Z8MM_PR
    WHERE ( MATNR = @PV_MATNR OR @PV_MATNR = @GC_ALL )
    AND MATNR IN @S_MATNR AND WERKS IN @S_WERKS
    AND EBELN = '' AND LOEKZ = ''
    INTO TABLE @LT_PR.

  " 2. PO 한 건 = 한 줄 (예정일이 지났으면 지연, 아니면 입고 대기)
  LOOP AT LT_PO INTO LS_PO.
    READ TABLE GT_LIST TRANSPORTING NO FIELDS
    WITH KEY MATNR = LS_PO-MATNR WERKS = LS_PO-WERKS.
    IF SY-SUBRC <> 0.
      CONTINUE.
    ENDIF.
    CLEAR LS_FILL.
    LS_FILL-WERKS = LS_PO-WERKS.
    LS_FILL-KIND  = 'PO'.
    LS_FILL-DOCNO = LS_PO-EBELN.
    LS_FILL-ITEM  = LS_PO-EBELP.
    LS_FILL-MENGE = LS_PO-MENGE.
    LS_FILL-MEINS = LS_PO-MEINS.
    LS_FILL-LFDAT = LS_PO-LFDAT.
    LS_FILL-MATNR = LS_PO-MATNR.
    IF LS_PO-LFDAT IS NOT INITIAL AND LS_PO-LFDAT < SY-DATUM.
      LS_FILL-STAGE = '지연'.
      LS_FILL-LIGHT = '1'.
      LS_FILL-DELAY = SY-DATUM - LS_PO-LFDAT.     " 지연 일수
    ELSE.
      LS_FILL-STAGE = '입고 대기'.
      LS_FILL-LIGHT = '3'.
    ENDIF.
    APPEND LS_FILL TO GT_FILL.
  ENDLOOP.

  " 3. PR 한 건 = 한 줄 (예정일이 지났으면 지연, 아니면 발주 대기)
  LOOP AT LT_PR INTO LS_PR.
    READ TABLE GT_LIST TRANSPORTING NO FIELDS
    WITH KEY MATNR = LS_PR-MATNR WERKS = LS_PR-WERKS.
    IF SY-SUBRC <> 0.
      CONTINUE.
    ENDIF.
    CLEAR LS_FILL.
    LS_FILL-WERKS = LS_PR-WERKS.
    LS_FILL-KIND  = 'PR'.
    LS_FILL-DOCNO = LS_PR-BANFN.
    LS_FILL-ITEM  = LS_PR-BNFPO.
    LS_FILL-MENGE = LS_PR-MENGE.
    LS_FILL-MEINS = LS_PR-MEINS.
    LS_FILL-LFDAT = LS_PR-LFDAT.
    LS_FILL-MATNR = LS_PR-MATNR.
    IF LS_PR-LFDAT IS NOT INITIAL AND LS_PR-LFDAT < SY-DATUM.
      LS_FILL-STAGE = '지연'.
      LS_FILL-LIGHT = '1'.
      LS_FILL-DELAY = SY-DATUM - LS_PR-LFDAT.
    ELSE.
      LS_FILL-STAGE = '발주 대기'.
      LS_FILL-LIGHT = '2'.
    ENDIF.
    APPEND LS_FILL TO GT_FILL.
  ENDLOOP.

  " 4. 부족(R)인데 PO·PR이 하나도 없는 플랜트 = 요청 없음 (문서가 없으니 번호는 비움)
*      LOOP AT gt_list INTO ls_list WHERE matnr = pv_matnr AND status = 'R'.
*        READ TABLE gt_fill TRANSPORTING NO FIELDS WITH KEY werks = ls_list-werks.
*        IF sy-subrc <> 0.
*          CLEAR ls_fill.
*          ls_fill-werks = ls_list-werks.
*          ls_fill-meins = ls_list-meins.
*          ls_fill-stage = '요청 없음'.
*          ls_fill-light = '1'.
*          APPEND ls_fill TO gt_fill.
*        ENDIF.
*      ENDLOOP.

  " 5. 플랜트 표시 글자 채우기
  SELECT MATNR, MAKTX
    FROM Z8MATERIAL_TXT_M
WHERE SPRAS = '3'
    INTO TABLE @DATA(LT_TXT).

  LOOP AT GT_FILL INTO LS_FILL.
    READ TABLE LT_TXT INTO DATA(LS_TXT) WITH KEY MATNR = LS_FILL-MATNR.
    IF SY-SUBRC = 0.
      LS_FILL-MAKTX = LS_TXT-MAKTX.
    ENDIF.
    READ TABLE GT_LIST INTO LS_LIST WITH KEY WERKS = LS_FILL-WERKS.   " 플랜트만 맞으면 이름은 같다
    IF SY-SUBRC = 0.
      LS_FILL-PLANT_TXT = |{ LS_LIST-WERKS } { LS_LIST-PLANT_NAME }|.
    ENDIF.
    MODIFY GT_FILL FROM LS_FILL.
  ENDLOOP.
*      LOOP AT gt_fill INTO ls_fill.
*        READ TABLE gt_list INTO ls_list WITH KEY matnr = pv_matnr werks = ls_fill-werks.
*        IF sy-subrc = 0.
*          ls_fill-plant_txt = |{ ls_list-werks } { ls_list-plant_name }|.
*          MODIFY gt_fill FROM ls_fill.
*        ENDIF.
*      ENDLOOP.

*      SORT gt_fill BY light werks lfdat.            " 빨강이 맨 위, 같은 색이면 플랜트·예정일 순
  SORT GT_FILL BY LIGHT ASCENDING DELAY DESCENDING WERKS MATNR LFDAT. "지연이 큰 순으로 정렬
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_fill
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_FILL .
  CLEAR GS_LAYO_FILL.
  GS_LAYO_FILL-EXCP_FNAME = 'LIGHT'.           " 신호등 열
  GS_LAYO_FILL-EXCP_LED   = 'X'.
  GS_LAYO_FILL-ZEBRA      = 'X'.
  GS_LAYO_FILL-NO_TOOLBAR = 'X'.
  GS_LAYO_FILL-GRID_TITLE = '입고예정문서'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fieldcat_fill
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_FILL.
  DATA LS_FCAT TYPE LVC_S_FCAT.
  CLEAR GT_FCAT_FILL.


  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'LIGHT'.
  LS_FCAT-COLTEXT   = '상태 '.
  LS_FCAT-ICON      = 'X'.                  " 이 열은 아이콘으로 표시
  LS_FCAT-OUTPUTLEN = 4.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'STAGE'.
  LS_FCAT-COLTEXT   = '문서상태'.
  LS_FCAT-OUTPUTLEN = 14.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MATNR'.
  LS_FCAT-COLTEXT   = '자재코드'.
  LS_FCAT-OUTPUTLEN = 12.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MAKTX'.
  LS_FCAT-COLTEXT   = '자재명'.
  LS_FCAT-OUTPUTLEN = 22.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'PLANT_TXT'.
  LS_FCAT-COLTEXT   = '플랜트'.
  LS_FCAT-OUTPUTLEN = 20.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'KIND'.
  LS_FCAT-COLTEXT   = '구분'.
  LS_FCAT-OUTPUTLEN = 4.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'DOCNO'.
  LS_FCAT-COLTEXT   = '문서 번호'.
  LS_FCAT-OUTPUTLEN = 12.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME  = 'MENGE'.
  LS_FCAT-COLTEXT    = '수량'.
  LS_FCAT-OUTPUTLEN  = 10.
  LS_FCAT-DECIMALS_O = 0.
  LS_FCAT-NO_ZERO    = 'X'.                      " 0이면 빈칸
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MEINS'.
  LS_FCAT-COLTEXT   = '단위'.
  LS_FCAT-OUTPUTLEN = 4.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'LFDAT'.
  LS_FCAT-COLTEXT   = '도착 예정일'.
  LS_FCAT-OUTPUTLEN = 12.
  APPEND LS_FCAT TO GT_FCAT_FILL.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'DELAY'.
  LS_FCAT-COLTEXT   = '지연(일)'.
  LS_FCAT-OUTPUTLEN = 8.
  LS_FCAT-NO_ZERO   = 'X'.                       " 0이면 빈칸
  APPEND LS_FCAT TO GT_FCAT_FILL.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_fill
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_GRID_TITLE_FILL.
  DATA LV_LATE TYPE I.
  LOOP AT GT_FILL TRANSPORTING NO FIELDS WHERE LIGHT = '1'. "지연건수
    LV_LATE = LV_LATE + 1.
  ENDLOOP.
  IF LV_LATE > 0.
    GS_LAYO_FILL-GRID_TITLE = |입고 예정 문서 { LINES( GT_FILL ) }건· 지연 { LV_LATE }건|.
  ELSE.
    GS_LAYO_FILL-GRID_TITLE = |입고 예정 문서 { LINES( GT_FILL ) }건|.
  ENDIF.
  GO_GRID_FILL->SET_FRONTEND_LAYOUT( IS_LAYOUT = GS_LAYO_FILL ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_col_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_LIST_WERKS
*&      --> LS_LIST_PLANT_NAME
*&      --> LS_LIST_AVAIL_QTY
*&      --> LV_INB
*&      --> LS_LIST_MABST
*&      --> LV_SCALE
*&      <-- LV_HTML
*&---------------------------------------------------------------------*
FORM SET_COL_HTML USING    PV_WERKS
                           PV_NAME
                           PV_AVAIL
                           PV_INB
                           PV_TARGET
                           PV_SCALE TYPE F
                  CHANGING PV_HTML  TYPE STRING.
  DATA: LV_A    TYPE P LENGTH 15 DECIMALS 3,    " 가용
        LV_I    TYPE P LENGTH 15 DECIMALS 3,    " 입고 예정
        LV_T    TYPE P LENGTH 15 DECIMALS 3,    " 목표
        LV_AV   TYPE F,                         " 막대로 그릴 가용 (음수는 0)
        LV_TOP  TYPE F,                         " 가용 + 입고 예정 (눈금까지만)
        LV_HAV  TYPE F,                         " 가용 막대 높이(px)
        LV_HIB  TYPE F,                         " 입고 예정 막대 높이(px)
        LV_HTG  TYPE F,                         " 목표선 위치(px)
        LV_OVER TYPE C LENGTH 1.                " 눈금을 넘었는가

  LV_A = PV_AVAIL.                              " 타입이 정해진 변수로 옮겨 담는다
  LV_I = PV_INB.
  LV_T = PV_TARGET.

  IF LV_A > 0.
    LV_AV = LV_A.
  ENDIF.
  LV_TOP = LV_AV + LV_I.
  IF LV_TOP > PV_SCALE.                         " 눈금을 넘으면 꽉 채우고 ▲ 표시
    LV_TOP = PV_SCALE.
    LV_OVER = 'X'.
  ENDIF.
  IF LV_AV > PV_SCALE.
    LV_AV = PV_SCALE.
  ENDIF.

  " 높이 계산: 차트 높이 170px 중 몇 px인가
  LV_HAV = LV_AV * 170 / PV_SCALE.
  LV_HIB = ( LV_TOP - LV_AV ) * 170 / PV_SCALE.
  LV_HTG = LV_T * 170 / PV_SCALE.
  IF LV_HTG > 170.
    LV_HTG = 170.
  ENDIF.
  IF LV_AV > 0 AND LV_HAV < 2.                  " 값이 있는데 너무 낮으면 최소 높이
    LV_HAV = 2.
  ENDIF.

  PV_HTML = PV_HTML && |<div class="col"><div class="plot">|.
  IF LV_HAV >= 1.
    PV_HTML = PV_HTML && |<div class="av" style="height:{ LV_HAV DECIMALS = 0 }px"></div>|.
  ENDIF.
  IF LV_HIB >= 1.
    PV_HTML = PV_HTML && |<div class="ib" style="height:{ LV_HIB DECIMALS = 0 }px"></div>|.
  ENDIF.
  IF LV_OVER = 'X'.
    PV_HTML = PV_HTML && |<div class="up">▲</div>|.
  ENDIF.
  PV_HTML = PV_HTML && |<div class="tg" style="bottom:{ LV_HTG DECIMALS = 0 }px"></div></div>|
    && |<div class="w">{ PV_WERKS }</div><div class="n">{ PV_NAME }</div>|
    && |<div class="s">가용 { LV_A NUMBER = USER DECIMALS = 0 }</div>|
    && |<div class="s">입고 +{ LV_I NUMBER = USER DECIMALS = 0 }</div>|
    && |<div class="s">목표 { LV_T NUMBER = USER DECIMALS = 0 }</div></div>|.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_move_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_MOVE_DATA.

*  CLEAR gt_move_all.
  SELECT I~MBLNR, I~ZEILE, I~BWART, I~MATNR, I~WERKS, I~MENGE, I~MEINS,
         I~ZZREFTYPE, I~ZZREFDOC, H~BUDAT
    FROM Z8MM_MATDOC_I AS I
    INNER JOIN Z8MM_MATDOC_H AS H
       ON H~MBLNR = I~MBLNR AND H~MJAHR = I~MJAHR
    WHERE H~BUDAT BETWEEN @GV_BUDAT_FR AND @GV_BUDAT_TO
      AND ( I~WERKS = @GV_WERKS_MV OR @GV_WERKS_MV = @SPACE )
      AND ( I~MATNR = @GV_MATNR_MV OR @GV_MATNR_MV = @SPACE )
    INTO TABLE @DATA(LT_DOC).

  IF LT_DOC IS INITIAL.
    MESSAGE S050(Z8_MSG) DISPLAY LIKE 'E'.   " 조건에 맞는 이동 내역이 없습니다
    RETURN.                                  " 이전 목록 유지
  ENDIF.

  CLEAR GT_MOVE_ALL.

  SELECT MATNR, MAKTX FROM Z8MATERIAL_TXT_M
    WHERE SPRAS = '3' INTO TABLE @DATA(LT_TXT).


  LOOP AT LT_DOC INTO DATA(LS_DOC).
    "1000번 스크린 조건에 해당하는 것들만.
    READ TABLE GT_LIST TRANSPORTING NO FIELDS
    WITH KEY MATNR = LS_DOC-MATNR WERKS = LS_DOC-WERKS.
    IF SY-SUBRC <> 0.
      CONTINUE.
    ENDIF.
    CLEAR GS_MOVE.
    GS_MOVE-BUDAT = LS_DOC-BUDAT.
    GS_MOVE-MATNR = LS_DOC-MATNR.
    GS_MOVE-WERKS = LS_DOC-WERKS.
    GS_MOVE-MEINS = LS_DOC-MEINS.
    GS_MOVE-MBLNR = LS_DOC-MBLNR.
    READ TABLE LT_TXT INTO DATA(LS_TXT) WITH KEY MATNR = LS_DOC-MATNR.
    IF SY-SUBRC = 0.
      GS_MOVE-MAKTX = LS_TXT-MAKTX.
    ENDIF.

    " 이동유형으로 구분과 부호를 정한다
*    CASE ls_doc-bwart.
*      WHEN '101' OR '103' OR '105'.
*        gs_move-kind = '입고'.        gs_move-qty =   ls_doc-menge.
*        gs_move-reftx = |PO { ls_doc-zzrefdoc }|.
*      WHEN '124'.
*        gs_move-kind = '반품'.        gs_move-qty = - ls_doc-menge.
*        gs_move-reftx = |PO { ls_doc-zzrefdoc }|.
*      WHEN '601'.
*        gs_move-kind = '출고·설치'.   gs_move-qty = - ls_doc-menge.
*        gs_move-reftx = |납품 { ls_doc-zzrefdoc }|.
*      WHEN '301'.
*        gs_move-kind = '지사이동'.    gs_move-qty = - ls_doc-menge.
*        gs_move-reftx = ls_doc-zzrefdoc.
*      WHEN '351'.
*        gs_move-kind = '이동중'.      gs_move-qty = - ls_doc-menge.
*        gs_move-reftx = ls_doc-zzrefdoc.
*      WHEN OTHERS.
*        gs_move-kind = '기타'.        gs_move-qty =   ls_doc-menge.
*        gs_move-reftx = ls_doc-zzrefdoc.
*    ENDCASE.
    GS_MOVE-REFTX = LS_DOC-ZZREFDOC.             " 참조 문서는 번호만 (유형 열이 이미 구분해줌)

    CASE LS_DOC-BWART.
      WHEN '101' OR '103' OR '105'.
        GS_MOVE-KIND = '입고'.        GS_MOVE-QTY =   LS_DOC-MENGE.
      WHEN '124'.
        GS_MOVE-KIND = '반품'.        GS_MOVE-QTY = - LS_DOC-MENGE.
      WHEN '601'.
        GS_MOVE-KIND = '출고·설치'.   GS_MOVE-QTY = - LS_DOC-MENGE.
      WHEN '301'.
        GS_MOVE-KIND = '지사이동'.    GS_MOVE-QTY = - LS_DOC-MENGE.
      WHEN '351'.
        GS_MOVE-KIND = '이동중'.      GS_MOVE-QTY = - LS_DOC-MENGE.
      WHEN OTHERS.
        GS_MOVE-KIND = '기타'.        GS_MOVE-QTY =   LS_DOC-MENGE.
    ENDCASE.
    GS_MOVE-QTY_TXT = |{ GS_MOVE-QTY SIGN = LEFTPLUS DECIMALS = 0 }|.
    APPEND GS_MOVE TO GT_MOVE_ALL.
  ENDLOOP.

  IF GT_MOVE_ALL IS INITIAL.
    MESSAGE S131(Z8_MSG) DISPLAY LIKE 'E'.
  ENDIF.

  SORT GT_MOVE_ALL BY BUDAT DESCENDING MBLNR DESCENDING.   " 최신순
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECTS_MOVE .
  CREATE OBJECT GO_CONT_MOVE
    EXPORTING
      CONTAINER_NAME              = 'CC_MOVE'
    EXCEPTIONS
      CNTL_ERROR                  = 1
      CNTL_SYSTEM_ERROR           = 2
      CREATE_ERROR                = 3
      LIFETIME_ERROR              = 4
      LIFETIME_DYNPRO_DYNPRO_LINK = 5
      OTHERS                      = 6.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.

  CREATE OBJECT GO_SPLIT_MOVE                      " 2행 1열로 나눈다
    EXPORTING
      PARENT            = GO_CONT_MOVE
      ROWS              = 2
      COLUMNS           = 1
    EXCEPTIONS
      CNTL_ERROR        = 1
      CNTL_SYSTEM_ERROR = 2
      OTHERS            = 3.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.

  GO_SPLIT_MOVE->SET_ROW_HEIGHT( ID = 1 HEIGHT = 10 ).     " 위 칸(칩)은 10%

  CALL METHOD GO_SPLIT_MOVE->SET_ROW_SASH
    EXPORTING
      ID    = 1
      TYPE  = 1
      VALUE = 0.

  GO_SPLIT_MOVE->GET_CONTAINER( EXPORTING
    ROW = 1
    COLUMN = 1
    RECEIVING
    CONTAINER = GO_CONT_MVF ).
  GO_SPLIT_MOVE->GET_CONTAINER( EXPORTING
    ROW = 2
    COLUMN = 1
    RECEIVING
    CONTAINER = GO_CONT_MVB ).

  CREATE OBJECT GO_GRID_MOVE
    EXPORTING
      I_PARENT          = GO_CONT_MVB                       " ← 이제 아래 칸에 올린다
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_layout_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_MOVE .
  GS_LAYO_MOVE-ZEBRA      = 'X'.
*  gs_layo_move-cwidth_opt = 'X'.
  GS_LAYO_MOVE-NO_TOOLBAR = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fieldcat_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_MOVE.
  CLEAR GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'BUDAT'.
  GS_FCAT_MOVE-COLTEXT   = '일자'.
  GS_FCAT_MOVE-OUTPUTLEN = 11.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'KIND'.
  GS_FCAT_MOVE-COLTEXT   = '유형'.
  GS_FCAT_MOVE-OUTPUTLEN = 11.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'MATNR'.
  GS_FCAT_MOVE-COLTEXT   = '자재코드'.
  GS_FCAT_MOVE-OUTPUTLEN = 12.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'MAKTX'.
  GS_FCAT_MOVE-COLTEXT   = '자재명'.
  GS_FCAT_MOVE-OUTPUTLEN = 22.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

*  CLEAR gs_fcat_move.
*  gs_fcat_move-fieldname  = 'QTY'.
*  gs_fcat_move-coltext    = '수량'.
*  gs_fcat_move-outputlen  = 10.
*  gs_fcat_move-qfieldname = 'MEINS'.      " 단위 필드 연결
*  gs_fcat_move-decimals_o = 0.            " 소수점 안 보이게
*  APPEND gs_fcat_move TO gt_fcat_move.
  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'QTY_TXT'.
  GS_FCAT_MOVE-COLTEXT   = '수량'.
  GS_FCAT_MOVE-OUTPUTLEN = 10.
  GS_FCAT_MOVE-JUST      = 'R'.                 " 오른쪽 정렬
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'MEINS'.
  GS_FCAT_MOVE-COLTEXT   = '단위'.
  GS_FCAT_MOVE-OUTPUTLEN = 4.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'WERKS'.
  GS_FCAT_MOVE-COLTEXT   = '플랜트'.
  GS_FCAT_MOVE-OUTPUTLEN = 8.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'REFTX'.
  GS_FCAT_MOVE-COLTEXT   = '참조 문서'.
  GS_FCAT_MOVE-OUTPUTLEN = 22.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.

  CLEAR GS_FCAT_MOVE.
  GS_FCAT_MOVE-FIELDNAME = 'MBLNR'.
  GS_FCAT_MOVE-COLTEXT   = '자재문서'.
  GS_FCAT_MOVE-OUTPUTLEN = 12.
  APPEND GS_FCAT_MOVE TO GT_FCAT_MOVE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV_MOVE .
  GO_GRID_MOVE->SET_TABLE_FOR_FIRST_DISPLAY(
    EXPORTING IS_LAYOUT = GS_LAYO_MOVE
    CHANGING  IT_OUTTAB = GT_MOVE
              IT_FIELDCATALOG = GT_FCAT_MOVE ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_grid_title_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_GRID_TITLE_MOVE .
  GS_LAYO_MOVE-GRID_TITLE = |이동 내역 { LINES( GT_MOVE ) }건|.
  GO_GRID_MOVE->SET_FRONTEND_LAYOUT( IS_LAYOUT = GS_LAYO_MOVE ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_kind_dropdown
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_KIND_DROPDOWN.
  DATA: LT_VALUES TYPE VRM_VALUES,
        LS_VALUE  TYPE VRM_VALUE,
        LT_KIND   TYPE STRING_TABLE,
        LV_KIND   TYPE STRING,
        LV_CNT    TYPE I.

  CLEAR LT_VALUES.
  LS_VALUE-KEY  = '전체'.
  LS_VALUE-TEXT = |전체 { LINES( GT_MOVE_ALL ) }건|.
  APPEND LS_VALUE TO LT_VALUES.

  LT_KIND = VALUE #( ( `입고` ) ( `출고·설치` ) ( `반품` ) ( `지사이동` ) ( `이동중` ) ).
  LOOP AT LT_KIND INTO LV_KIND.
    LV_CNT = 0.
    LOOP AT GT_MOVE_ALL TRANSPORTING NO FIELDS WHERE KIND = LV_KIND.
      LV_CNT = LV_CNT + 1.
    ENDLOOP.
    IF LV_CNT > 0.                             " 0건인 유형은 목록에서 뺀다
      LS_VALUE-KEY  = LV_KIND.
      LS_VALUE-TEXT = |{ LV_KIND } { LV_CNT }건|.
      APPEND LS_VALUE TO LT_VALUES.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      ID     = 'GV_KIND_SEL'
      VALUES = LT_VALUES.   " id는 대문자

  " 선택값이 목록에 없으면 전체로
  READ TABLE LT_VALUES TRANSPORTING NO FIELDS WITH KEY KEY = GV_KIND_SEL.
  IF SY-SUBRC <> 0.
    GV_KIND_SEL = '전체'.
  ENDIF.
ENDFORM.

FORM FILTER_MOVE.
  GT_MOVE = GT_MOVE_ALL.
  IF GV_KIND_SEL <> '전체'.
    DELETE GT_MOVE WHERE KIND <> GV_KIND_SEL.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_move_by_chip
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ACTION
*&---------------------------------------------------------------------*
FORM SET_MOVE_BY_CHIP USING PV_ACTION TYPE C.
  CASE PV_ACTION.
    WHEN 'K_ALL'.
      GV_KIND_SEL = '전체'.
    WHEN 'K_IN'.
      GV_KIND_SEL = '입고'.
    WHEN 'K_OUT'.
      GV_KIND_SEL = '출고·설치'.
    WHEN 'K_RET'.
      GV_KIND_SEL = '반품'.
    WHEN 'K_STO'.
      GV_KIND_SEL = '지사이동'.
    WHEN 'K_TRN'.
      GV_KIND_SEL = '이동중'.
  ENDCASE.
  GV_MV_FILTER = 'X'.                           " 다음 PBO에서 필터 다시 적용
  CL_GUI_CFW=>SET_NEW_OK_CODE( NEW_CODE = 'MVFLT' ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_EVENT_HANDLER_MOVE .
  SET HANDLER LCL_EVENT=>ON_SAPEVENT FOR GO_HTML_MVF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_html_mvf
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_HTML_MVF.
  DATA: LT_EV TYPE CNTL_SIMPLE_EVENTS,
        LS_EV TYPE CNTL_SIMPLE_EVENT.
*
*  CREATE OBJECT go_cont_mvf
*    EXPORTING
*      container_name              = 'CC_MVFLOW'
*    EXCEPTIONS
*      cntl_error                  = 1
*      cntl_system_error           = 2
*      create_error                = 3
*      lifetime_error              = 4
*      lifetime_dynpro_dynpro_link = 5
*      OTHERS                      = 6.
*  IF sy-subrc <> 0.
*    MESSAGE a012(z8_msg).
*  ENDIF.

  CREATE OBJECT GO_HTML_MVF
    EXPORTING
      PARENT = GO_CONT_MVF.

  LS_EV-EVENTID    = CL_GUI_HTML_VIEWER=>M_ID_SAPEVENT.     " 링크 클릭 이벤트 등록
  LS_EV-APPL_EVENT = 'X'.
  APPEND LS_EV TO LT_EV.
  GO_HTML_MVF->SET_REGISTERED_EVENTS( EVENTS = LT_EV ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_mv_html
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_MV_HTML.
  DATA: LV_HTML TYPE STRING,
        LV_CLS  TYPE STRING,
        LV_CODE TYPE STRING,
        LV_KIND TYPE STRING,
        LT_KIND TYPE STRING_TABLE,
        LV_CNT  TYPE I,
        LT_HTML TYPE SOLI_TAB,
        LV_URL  TYPE C LENGTH 255.

  LV_HTML = `<html><head><meta charset="utf-8"><style>`
    && `body{margin:0;padding:6px 4px;font-family:'Malgun Gothic',Arial,sans-serif;font-size:13px;color:#44505c;background:#e6e6e6}`
    && `.chip{display:inline-block;margin-right:8px;padding:7px 14px;border:1px solid #d5dbe1;border-radius:3px;color:#44505c;text-decoration:none;background:#fff}`
    && `.sel{border-color:#5b7ea0;background:#e8f0f7}`
    && `.chip b{margin-left:6px;color:#1f2d3a}`
    && `</style></head><body>`.

  LV_CLS  = COND #( WHEN GV_KIND_SEL = '전체' THEN `chip sel` ELSE `chip` ).
  LV_HTML = LV_HTML && `<a class="` && LV_CLS && `" href="SAPEVENT:K_ALL">전체<b>`
         && |{ LINES( GT_MOVE_ALL ) }| && `</b></a>`.

  LT_KIND = VALUE #( ( `입고` ) ( `출고·설치` ) ( `반품` ) ( `지사이동` ) ( `이동중` ) ).
  LOOP AT LT_KIND INTO LV_KIND.
    CLEAR LV_CNT.
    LOOP AT GT_MOVE_ALL TRANSPORTING NO FIELDS WHERE KIND = LV_KIND.
      LV_CNT = LV_CNT + 1.
    ENDLOOP.
    CHECK LV_CNT > 0.
    CASE LV_KIND.
      WHEN `입고`.
        LV_CODE = `K_IN`.
      WHEN `출고·설치`.
        LV_CODE = `K_OUT`.
      WHEN `반품`.
        LV_CODE = `K_RET`.
      WHEN `지사이동`.
        LV_CODE = `K_STO`.
      WHEN `이동중`.
        LV_CODE = `K_TRN`.
    ENDCASE.
    LV_CLS  = COND #( WHEN GV_KIND_SEL = LV_KIND THEN `chip sel` ELSE `chip` ).
    LV_HTML = LV_HTML && `<a class="` && LV_CLS && `" href="SAPEVENT:` && LV_CODE && `">`
           && LV_KIND && `<b>` && |{ LV_CNT }| && `</b></a>`.
  ENDLOOP.

  LV_HTML = LV_HTML && `</body></html>`.
  LT_HTML = CL_BCS_CONVERT=>STRING_TO_SOLI( IV_STRING = LV_HTML ).
  GO_HTML_MVF->LOAD_DATA( IMPORTING ASSIGNED_URL = LV_URL CHANGING DATA_TABLE = LT_HTML ).
  GO_HTML_MVF->SHOW_URL( URL = LV_URL ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form add_box
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> `기간 시작`
*&      --> LV_TXT
*&      --> ``
*&      <-- LV_HTML
*&---------------------------------------------------------------------*
*FORM add_box USING    pv_label TYPE string
*                      pv_txt   TYPE string
*                      pv_cls   TYPE string
*             CHANGING cv_html  TYPE string.
*  cv_html = cv_html && `<div class="box ` && pv_cls && `"><span class="lb">` && pv_label
*         && `</span><span class="v">` && pv_txt && `</span></div>`.
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_dep
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_OBJECTS_DEP .
  CREATE OBJECT GO_GRID_DEP
    EXPORTING
      I_PARENT          = GO_CONT_DEP
    EXCEPTIONS
      ERROR_CNTL_CREATE = 1
      ERROR_CNTL_INIT   = 2
      ERROR_CNTL_LINK   = 3
      ERROR_DP_CREATE   = 4
      OTHERS            = 5.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_layout_dep
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_LAYOUT_DEP .
  CLEAR GS_LAYO_DEP.
*  gs_layo_dep-excp_fname =  'LIGHT'.
*  gs_layo_dep-excp_led = 'X'.
  GS_LAYO_DEP-NO_TOOLBAR = 'X'.
  GS_LAYO_DEP-ZEBRA = 'X'.
  "(가용 ÷ 최근 30일 일평균 출고)'.
  GS_LAYO_DEP-GRID_TITLE = '소진 예상 자재'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_fieldcat_dep
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM SET_FIELDCAT_DEP .
  DATA LS_FCAT TYPE LVC_S_FCAT.
  CLEAR GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'LIGHT'.
  LS_FCAT-COLTEXT   = '상태 '.
  LS_FCAT-ICON      = 'X'.                  " 이 열은 아이콘으로 표시
  LS_FCAT-OUTPUTLEN = 4.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MATNR'.
  LS_FCAT-COLTEXT = '자재코드'.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'MAKTX'.
  LS_FCAT-COLTEXT = '자재명'.
  LS_FCAT-OUTPUTLEN = 20.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'PLANT_TXT'.
  LS_FCAT-COLTEXT = '플랜트'.
  LS_FCAT-OUTPUTLEN = 15.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'AVAIL'.
  LS_FCAT-COLTEXT = '가용 재고'.
  LS_FCAT-DECIMALS_O = 0.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'OUT30'.
  LS_FCAT-COLTEXT = '최근 30일 출고'.
  LS_FCAT-DECIMALS_O = 0.
  LS_FCAT-NO_ZERO = 'X'.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.  LS_FCAT-FIELDNAME = 'MEINS'.
  LS_FCAT-COLTEXT = '단위'.
  APPEND LS_FCAT TO GT_FCAT_DEP.

  CLEAR LS_FCAT.
  LS_FCAT-FIELDNAME = 'DAYS_TXT'.
  LS_FCAT-COLTEXT = '소진 예상'.
  LS_FCAT-JUST = 'R'.
  APPEND LS_FCAT TO GT_FCAT_DEP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_dep
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_ALV_DEP .
  CALL METHOD GO_GRID_DEP->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING
      IS_LAYOUT                     = GS_LAYO_DEP
    CHANGING
      IT_OUTTAB                     = GT_DEP
      IT_FIELDCATALOG               = GT_FCAT_DEP
    EXCEPTIONS
      INVALID_PARAMETER_COMBINATION = 1
      PROGRAM_ERROR                 = 2
      TOO_MANY_LINES                = 3
      OTHERS                        = 4.
  IF SY-SUBRC <> 0.
    MESSAGE A012(Z8_MSG).
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_dep_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_MATNR_SEL
*&---------------------------------------------------------------------*
FORM SET_DEP_DATA USING PV_MATNR TYPE Z8E_MATNR.
  DATA: LS_DEP    TYPE TY_DEP,
        LS_LIST   TYPE TY_LIST,
        LV_FROM   TYPE D,
        LV_PERDAY TYPE P LENGTH 15 DECIMALS 3.

  CLEAR GT_DEP.
  LV_FROM = SY-DATUM - 30.

  " 1. 가용 재고 = 현재고 - 예약 - 안전재고 (탭 1 CDS와 같은 계산)
  SELECT P~MATNR, P~WERKS, P~MEINS, P~EISBE, S~LABST, S~ZZRSVQTY
    FROM Z8MATPLANT_M AS P
    INNER JOIN Z8MATERIAL_STK_M AS S
       ON S~MATNR = P~MATNR AND S~WERKS = P~WERKS AND S~LGORT = '0001'
    WHERE P~MABST > 0
      AND ( P~MATNR = @PV_MATNR OR @PV_MATNR = @GC_ALL )
    AND P~MATNR IN @S_MATNR AND P~WERKS IN @S_WERKS
    INTO TABLE @DATA(LT_STK).

  " 2. 최근 30일 출고 합계 (이동유형 601)
  SELECT I~MATNR, I~WERKS, SUM( I~MENGE ) AS OUT_QTY
    FROM Z8MM_MATDOC_I AS I
    INNER JOIN Z8MM_MATDOC_H AS H
       ON H~MBLNR = I~MBLNR AND H~MJAHR = I~MJAHR
    WHERE I~BWART = '601'
      AND H~BUDAT >= @LV_FROM
      AND ( I~MATNR = @PV_MATNR OR @PV_MATNR = @GC_ALL )
    AND I~MATNR IN @S_MATNR AND I~WERKS IN @S_WERKS
    GROUP BY I~MATNR, I~WERKS
    INTO TABLE @DATA(LT_OUT).

  SELECT MATNR, MAKTX FROM Z8MATERIAL_TXT_M
    WHERE SPRAS = '3' INTO TABLE @DATA(LT_TXT).

  LOOP AT LT_STK INTO DATA(LS_STK).
    READ TABLE GT_LIST TRANSPORTING NO FIELDS
    WITH KEY MATNR = LS_STK-MATNR WERKS = LS_STK-WERKS.
    IF SY-SUBRC <> 0.
      CONTINUE.
    ENDIF.
    CLEAR LS_DEP.
    LS_DEP-MATNR = LS_STK-MATNR.
    LS_DEP-WERKS = LS_STK-WERKS.
    LS_DEP-MEINS = LS_STK-MEINS.
    LS_DEP-AVAIL = LS_STK-LABST - LS_STK-ZZRSVQTY - LS_STK-EISBE.

    READ TABLE LT_TXT INTO DATA(LS_TXT) WITH KEY MATNR = LS_STK-MATNR.
    IF SY-SUBRC = 0.
      LS_DEP-MAKTX = LS_TXT-MAKTX.
    ENDIF.
    READ TABLE GT_LIST INTO LS_LIST WITH KEY WERKS = LS_STK-WERKS.
    IF SY-SUBRC = 0.
      LS_DEP-PLANT_TXT = |{ LS_LIST-WERKS } { LS_LIST-PLANT_NAME }|.
    ENDIF.

    READ TABLE LT_OUT INTO DATA(LS_OUT) WITH KEY MATNR = LS_STK-MATNR WERKS = LS_STK-WERKS.
    IF SY-SUBRC = 0 AND LS_OUT-OUT_QTY <> 0.
      LS_DEP-OUT30 = ABS( LS_OUT-OUT_QTY ).
      LV_PERDAY    = LS_DEP-OUT30 / 30.                    " 일평균 출고
      IF LS_DEP-AVAIL <= 0.
        LS_DEP-DAYS = 0.
      ELSE.
        LS_DEP-DAYS = TRUNC( LS_DEP-AVAIL * 30 / LS_DEP-OUT30 ).   " 곱하기 먼저 → 오차 없음
*        LS_DEP-DAYS = TRUNC( LS_DEP-AVAIL / LV_PERDAY ).   " 며칠 버티나 (소수점 버림)
      ENDIF.
      LS_DEP-DAYS_TXT = |약 { LS_DEP-DAYS }일|.
      IF LS_DEP-DAYS <= 7.
        LS_DEP-LIGHT = ICON_LED_RED. "7일 이내: 빨강
      ELSEIF LS_DEP-DAYS <= 14.
        LS_DEP-LIGHT = ICON_LED_YELLOW. "14일 이내: 노랑랑
      ELSE.
        LS_DEP-LIGHT = ICON_LED_GREEN.  "그외: 초록
      ENDIF.

    ELSE.
      LS_DEP-DAYS     = 99999.                              " 출고 이력 없음: 맨 아래로
      LS_DEP-DAYS_TXT = '-'.
    ENDIF.
    APPEND LS_DEP TO GT_DEP.
  ENDLOOP.

  SORT GT_DEP BY DAYS ASCENDING MATNR WERKS.                " 빨리 떨어질 것이 위.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_day_move
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CHECK_DAY_MOVE .
  CLEAR GV_DAY_ERR.

  IF GV_BUDAT_FR IS INITIAL OR GV_BUDAT_TO IS INITIAL.
    MESSAGE S046(Z8_MSG) DISPLAY LIKE 'E'.   " 조회 기간을 입력하세요
    GV_DAY_ERR = ABAP_TRUE.
  ELSEIF GV_BUDAT_FR > GV_BUDAT_TO.
*    MESSAGE '조회 시작일은 종료일보다 클 수 없습니다' TYPE 'S' DISPLAY LIKE 'E'.
   MESSAGE S047(Z8_MSG) DISPLAY LIKE 'E'.   " 시작일이 종료일보다 클 수 없습니다
    GV_DAY_ERR = ABAP_TRUE.
  ENDIF.

ENDFORM.
