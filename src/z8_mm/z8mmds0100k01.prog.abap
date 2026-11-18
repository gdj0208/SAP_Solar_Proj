*&---------------------------------------------------------------------*
*& Include          Z8MMDS0100K01
*&---------------------------------------------------------------------*
CLASS lcl_event DEFINITION.                      " 트리 이벤트를 받는 클래스
  PUBLIC SECTION.
    CLASS-METHODS on_node_dblclick
      FOR EVENT node_double_click OF cl_gui_simple_tree
      IMPORTING node_key.
    "링/ 카드 클릭시 -> 목록 ALV에 해당 상태만 뜨도록.
    CLASS-METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
    IMPORTING action sender.
    "탭3- 이동흐름
*    CLASS-METHODS on_sapevent FOR EVENT sapevent OF cl_gui_html_viewer
*      IMPORTING action.
ENDCLASS.

CLASS lcl_event IMPLEMENTATION.
  METHOD on_node_dblclick.
    PERFORM set_list_by_node USING node_key.     " 노드가 눌리면 이 서브루틴을 부른다
  ENDMETHOD.

  METHOD on_sapevent.
*  PERFORM set_list_by_status USING action.     " action = 클릭한 코드 (R/Y/G/ALL)
    IF sender = go_html_mvf.                      " 탭 3 칩/흐름 뷰어에서 눌렀으면
    PERFORM set_move_by_chip USING action.
  ELSE.                                         " 아니면 탭 1 칩
    PERFORM set_list_by_status USING action.
  ENDIF.
ENDMETHOD.

ENDCLASS.
