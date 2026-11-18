
*-----------------------------------------------------------------

" 1. 히스토리/검수/FI 데이터를 잠시 담아둘 전역 버퍼 클래스
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA:
        gt_hist     TYPE TABLE OF z8ps_proj_hist,
        gt_fi_post  TYPE TABLE OF z8ps_project-pro_id,
        gt_cust_inv TYPE TABLE OF z8ps_custom_inv.

    " 버퍼 전체 초기화
    CLASS-METHODS clear_all.
ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.
  METHOD clear_all.
    CLEAR: gt_hist,
           gt_fi_post,
           gt_cust_inv.
  ENDMETHOD.
ENDCLASS.
*-----------------------------------------------------------------

*-----------------------------------------------------------------

class lhc_Project definition inheriting from cl_abap_behavior_handler.
  private section.
    methods:
*    get_instance_authorizations FOR INSTANCE AUTHORIZATION
*      IMPORTING REQUEST requested_authorizations FOR Projects RESULT result,

    get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Projects RESULT result,

    get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR Projects RESULT result,

    startWork FOR MODIFY
        IMPORTING keys FOR ACTION Projects~startWork RESULT result,

    completeInstall for modify
        importing keys for action Projects~completeInstall result result,

    inspectCustomer for modify
        importing keys for action Projects~completeInspect result result,

    rejectInspect for modify
        importing keys for action Projects~rejectInspect result result.
endclass.

class lhc_Project implementation.

*  METHOD get_instance_authorizations.
*  ENDMETHOD.

    METHOD get_global_authorizations.
    " Z8MM_ADMIN 오브젝트에 정의된 필드(예: ACTVT)만 지정합니다.
    AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
      ID 'ACTVT' FIELD '16'. " 실행 권한

    IF sy-subrc <> 0.
      result-%update = if_abap_behv=>auth-unauthorized.

      result-%action-startWork       = if_abap_behv=>auth-unauthorized.
      result-%action-completeInstall = if_abap_behv=>auth-unauthorized.
      result-%action-completeInspect = if_abap_behv=>auth-unauthorized.
      result-%action-rejectInspect   = if_abap_behv=>auth-unauthorized.

      APPEND VALUE #(
                      %msg = new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = '해당 프로그램을 실행할 권한이 없습니다.' )
                    ) TO reported-projects.
    ELSE.
      result-%update = if_abap_behv=>auth-allowed.

      result-%action-startWork       = if_abap_behv=>auth-allowed.
      result-%action-completeInstall = if_abap_behv=>auth-allowed.
      result-%action-completeInspect = if_abap_behv=>auth-allowed.
      result-%action-rejectInspect   = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    " 1. 선택된 프로젝트들의 현재 상태(status)를 DB에서 읽어옵니다.
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      FIELDS ( status del_status ) WITH CORRESPONDING #( keys )
      RESULT DATA(projects).

    " 2. 읽어온 상태값에 따라 각 버튼의 활성화 여부를 결정하여 result에 담습니다.
    result = VALUE #( FOR project IN projects (
      %tky = project-%tky

      " 진행 상태(status) 필드는 UI에서 무조건 읽기 전용(자물쇠)으로 처리
      " %field-status = if_abap_behv=>fc-f-read_only

      " status가 '20' 이상 '50' 이하일 때만 Edit 버튼 활성화
      %update = COND #( WHEN project-status = '40' "BETWEEN '40' AND '50'
                        THEN if_abap_behv=>fc-o-enabled
                        ELSE if_abap_behv=>fc-o-disabled )

      " [작업 시작 버튼] status가 '30'일 때만 활성화 (누를 수 있음)
      %action-startWork       = COND #( WHEN project-status = '30' and project-del_status = '30'
                                        THEN if_abap_behv=>fc-o-enabled
                                        ELSE if_abap_behv=>fc-o-disabled )

      " [설치 완료 버튼] status가 '40'일 때만 활성화
      %action-completeInstall = COND #( WHEN project-status = '40' and project-del_status = '30'
                                        THEN if_abap_behv=>fc-o-enabled
                                        ELSE if_abap_behv=>fc-o-disabled )

      " [고객 검수 버튼] status가 '50'일 때만 활성화
      %action-completeInspect = COND #( WHEN project-status = '50' and project-del_status = '30'
                                        THEN if_abap_behv=>fc-o-enabled
                                        ELSE if_abap_behv=>fc-o-disabled )
      %action-rejectInspect = COND #( WHEN project-status = '50' and project-del_status = '30'
                                        THEN if_abap_behv=>fc-o-enabled
                                        ELSE if_abap_behv=>fc-o-disabled )
    ) ).
  ENDMETHOD.

    METHOD startWork.
    " 1. 오늘 날짜 및 현재 접속자 ID 가져오기 (ABAP Cloud 권장 방식)
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_user)  = cl_abap_context_info=>get_user_technical_name( ).

    " 2. 프로젝트 상태(40) 및 [실제 시작일] 자동 업데이트
    MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      UPDATE FIELDS ( status real_sdate )
      WITH VALUE #( FOR key IN keys ( pro_id = key-pro_id status = '40' real_sdate = lv_today ) ).

    " 3. 자식 데이터(배정 인력) 읽어오기
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects BY \_TechHist
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_tech).

    " 4. 배정 인력의 [실제 투입 시작일] 자동 업데이트
    IF lt_tech IS NOT INITIAL.
      " 주의: 아래 'ENTITY TechHist' 부분은 자식 BDEF의 Alias 이름과 동일하게 맞춰주세요.
      MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY tech_hist
        UPDATE FIELDS ( work_sdate ) " 뷰의 실제 투입 시작일 필드명
        WITH VALUE #( FOR tech IN lt_tech ( %tky = tech-%tky work_sdate = lv_today ) ).
    ENDIF.

    " 5. 화면 갱신 및 히스토리 기록을 위한 최신 데이터 다시 읽기
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(projects).

    " 6. 히스토리 데이터 조립 및 전역 버퍼 테이블에 임시 저장[cite: 5]
    LOOP AT projects INTO DATA(ls_proj).
      DATA ls_hist TYPE z8ps_proj_hist.

      " DB에서 해당 프로젝트의 현재까지 가장 높은 순번(SEQ_NO) 가져오기[cite: 5]
      SELECT SINGLE MAX( seq_no ) FROM z8ps_proj_hist
        INTO @DATA(lv_max_seq)
        WHERE pro_id = @ls_proj-pro_id.

      ls_hist-mandt        = sy-mandt.              " 클라이언트[cite: 5]
      ls_hist-pro_id       = ls_proj-pro_id.        " 프로젝트 ID[cite: 5]
      ls_hist-seq_no       = lv_max_seq + 1.        " 순번 증가[cite: 5]
      ls_hist-status_p     = ls_proj-status.        " Project Status[cite: 5]
      ls_hist-sdate        = ls_proj-sdate.         " 예상 시작일[cite: 5]
      ls_hist-edate        = ls_proj-edate.         " 예상 종료일[cite: 5]
      ls_hist-sdate_a      = ls_proj-real_sdate.    " 실제 공사 시작일[cite: 5]
      ls_hist-edate_a      = ls_proj-real_edate.    " 실제 공사 종료일[cite: 5]
      ls_hist-changed_by   = lv_user.               " 상태 변경자[cite: 5]
      ls_hist-changed_date = lv_today.              " 변경일자[cite: 5]

      " 조립된 이력 데이터를 DB 저장을 위해 버퍼에 보관
      APPEND ls_hist TO lcl_buffer=>gt_hist.
    ENDLOOP.

    " 7. 반환 및 메시지 (기존과 동일)
    result = VALUE #( FOR proj IN projects ( %tky = proj-%tky %param = proj ) ).

    reported-projects = VALUE #( FOR key IN keys (
      %tky = key-%tky
      %msg = new_message_with_text( severity = if_abap_behv_message=>severity-success text = '작업 시작 및 실제 투입일이 오늘로 설정되었습니다.' )
    ) ).
  ENDMETHOD.

  METHOD completeInstall.
    " 1. 유효성 검사를 무사히 통과한 프로젝트 키만 따로 담을 변수 선언
    DATA: valid_keys TYPE TABLE FOR ACTION IMPORT z8r_projects~completeInstall.

    " 2. 선택된 프로젝트들에 속한 자식(배정 인력) 데이터를 Association을 통해 모두 읽어옵니다.
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects BY \_TechHist
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_tech_hist).

    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      FIELDS ( real_sdate real_edate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_projects).

    " 3-1. 선택된 각 프로젝트에 대해 유효성 검사 수행
    LOOP AT lt_projects INTO DATA(ls_project).
      " 유효성 검증 1: 실제 시작일 또는 실제 종료일 누락 체크
      IF ls_project-real_sdate IS INITIAL." OR ls_project-real_edate IS INITIAL.
        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
        APPEND VALUE #( %tky = ls_project-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = '프로젝트의 실제 시작일을 입력해야 검수 승인을 할 수 있습니다.' )
                      ) TO reported-projects.
      ENDIF.
    ENDLOOP.

*    " 3-2. 선택된 각 프로젝트에 대해 유효성 검사 수행
*    LOOP AT keys INTO DATA(ls_key).
*      DATA(lv_has_error) = abap_false.
*
*      " 현재 프로젝트에 매핑되는 배정 인력들만 순회하며 날짜 입력 여부 확인
*      LOOP AT lt_tech_hist INTO DATA(ls_tech) WHERE pro_id = ls_key-pro_id.
*        " 실제 투입 시작일 또는 종료일이 하나라도 비어있는지(00000000) 체크
*        IF ls_tech-work_sdate IS INITIAL OR ls_tech-work_edate IS INITIAL.
*          lv_has_error = abap_true.
*          EXIT. " 하나라도 비어있으면 더 볼 필요 없이 에러 처리
*        ENDIF.
*      ENDLOOP.
*
*      " 4. 에러가 있는 경우: 상태 변경 취소 및 에러 메시지 반환
*      IF lv_has_error = abap_true.
*        " failed에 키를 담으면 프레임워크가 UPDATE를 강제로 취소(Rollback)합니다.
*        APPEND VALUE #( %tky = ls_key-%tky ) TO failed-projects.
*
*        " 사용자에게 붉은색 에러 팝업창을 띄워 수정하도록 유도합니다.
*        APPEND VALUE #( %tky = ls_key-%tky
*                        %msg = new_message_with_text(
*                                 severity = if_abap_behv_message=>severity-error
*                                 text     = '모든 직원의 실제 투입 시작일과 종료일을 입력해야 다음 단계로 넘어갈 수 있습니다.' )
*                      ) TO reported-projects.
*      ELSE.
*        " 5. 에러가 없는 경우: 업데이트 대상 변수에 키 추가
*        APPEND ls_key TO valid_keys.
*      ENDIF.
*    ENDLOOP.

" 3-2. 선택된 각 프로젝트에 대해 유효성 검사 수행 (배정 인력 기준)
    LOOP AT keys INTO DATA(ls_key).
      DATA(lv_has_error) = abap_false.
      " 텍스트 변수(lv_error_text) 삭제됨

      " 현재 프로젝트에 매핑되는 배정 인력들만 순회하며 날짜 입력 여부 확인
      LOOP AT lt_tech_hist INTO DATA(ls_tech) WHERE pro_id = ls_key-pro_id.

        " 유효성 검증 1: 실제 투입 시작일 또는 종료일 누락 체크
        IF ls_tech-work_sdate IS INITIAL OR ls_tech-work_edate IS INITIAL.
          lv_has_error = abap_true.
          " 변수를 거치지 않고 곧바로 failed와 reported에 꽂아 넣습니다.
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-projects.
          APPEND VALUE #( %tky = ls_key-%tky
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = '모든 직원의 실제 투입 시작일과 종료일을 입력해야 다음 단계로 넘어갈 수 있습니다.' )
                        ) TO reported-projects.
          EXIT. " 에러 발생 시 즉시 루프 탈출
        ENDIF.

        " ★ 추가된 로직: 직원의 실제 종료일이 시작일보다 앞서는지(과거인지) 체크
        IF ls_tech-work_edate < ls_tech-work_sdate.
          lv_has_error = abap_true.
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-projects.
          APPEND VALUE #( %tky = ls_key-%tky
                          %msg = new_message_with_text(
                                   severity = if_abap_behv_message=>severity-error
                                   text     = '직원의 실제 종료일이 시작일보다 앞설 수 없습니다.' )
                        ) TO reported-projects.
          EXIT.
        ENDIF.

      ENDLOOP.

      " 4 & 5. 에러가 없는 경우에만 업데이트 대상 변수에 키 추가
      IF lv_has_error = abap_false.
        " 3-1에서 프로젝트 유효성에 실패한 경우 valid_keys에 들어가지 않도록 방어 로직 추가
        READ TABLE failed-projects WITH KEY %tky = ls_key-%tky TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          APPEND ls_key TO valid_keys.
        ENDIF.
      ENDIF.
    ENDLOOP.

    " 6. 유효성 검사를 통과한 항목만 기존처럼 상태값을 '50'으로 변경합니다.
    IF valid_keys IS NOT INITIAL.
      MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY Projects
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR valid_key IN valid_keys ( pro_id = valid_key-pro_id status = '50' ) ).

        " 성공적으로 60 상태로 넘어간 프로젝트 ID를 버퍼에 적재
*        LOOP AT valid_keys INTO DATA(ls_valid).
*          APPEND ls_valid-pro_id TO lcl_buffer=>gt_fi_post.
*        ENDLOOP.

      " 7. 화면 갱신을 위해 데이터 다시 읽기
      READ ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY Projects
        ALL FIELDS WITH CORRESPONDING #( valid_keys )
        RESULT DATA(projects).

      " 8. 성공한 항목 결과 반환 및 성공 메시지 출력
      result = VALUE #( FOR proj IN projects ( pro_id = proj-pro_id %param = proj ) ).

      reported-projects = VALUE #( BASE reported-projects
                                   FOR valid_key IN valid_keys (
        %tky = valid_key-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-success
                 text     = '설치가 완료되었습니다. 고객의 검수를 받으십시오.' )
      ) ).


    " 9. 히스토리 데이터 조립 및 전역 버퍼에 임시 저장
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    DATA(lv_user)  = cl_abap_context_info=>get_user_technical_name( ).

    LOOP AT projects INTO DATA(ls_proj).
      DATA ls_hist TYPE z8ps_proj_hist.

      SELECT SINGLE MAX( seq_no ) FROM z8ps_proj_hist
        INTO @DATA(lv_max_seq)
        WHERE pro_id = @ls_proj-pro_id.

      ls_hist-mandt        = sy-mandt.
      ls_hist-pro_id       = ls_proj-pro_id.
      ls_hist-seq_no       = lv_max_seq + 1.
      ls_hist-status_p     = ls_proj-status.
      ls_hist-sdate        = ls_proj-sdate.
      ls_hist-edate        = ls_proj-edate.
      ls_hist-sdate_a      = ls_proj-real_sdate.
      ls_hist-edate_a      = ls_proj-real_edate.
      ls_hist-changed_by   = lv_user.
      ls_hist-changed_date = lv_today.

      APPEND ls_hist TO lcl_buffer=>gt_hist.
    ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD inspectcustomer.
    " 1. 유효성 검사를 통과한 프로젝트 키만 담을 변수 선언
    DATA valid_keys TYPE TABLE FOR ACTION IMPORT z8r_projects~completeInspect.

*    " 2. 선택된 프로젝트들의 실제 시작일, 실제 종료일 데이터를 읽어옵니다.
*    READ ENTITIES OF z8r_projects IN LOCAL MODE
*      ENTITY Projects
*      FIELDS ( real_sdate real_edate ) WITH CORRESPONDING #( keys )
*      RESULT DATA(lt_projects).
*
*    " 3. 선택된 각 프로젝트에 대해 유효성 검사 수행
*    LOOP AT lt_projects INTO DATA(ls_project).
*      DATA(lv_inspector) = VALUE #( keys[ %tky = ls_project-%tky ]-%param-InspectorName OPTIONAL ).
*      DATA(lv_customer)  = VALUE #( keys[ %tky = ls_project-%tky ]-%param-CustomerName OPTIONAL ).
*
*      " 유효성 검증 1: 실제 시작일 또는 실제 종료일 누락 체크
*      IF ls_project-real_sdate IS INITIAL." OR ls_project-real_edate IS INITIAL.
*        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
*        APPEND VALUE #( %tky = ls_project-%tky
*                        %msg = new_message_with_text(
*                                 severity = if_abap_behv_message=>severity-error
*                                 text     = '프로젝트의 실제 시작일과 실제 종료일을 모두 입력해야 검수 승인을 할 수 있습니다.' )
*                      ) TO reported-projects.
*
*      " 유효성 검증 2: 담당자 및 고객 검수자 서명 누락 체크
*      ELSEIF lv_inspector IS INITIAL OR lv_customer IS INITIAL.
*        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
*        APPEND VALUE #( %tky = ls_project-%tky
*                        %msg = new_message_with_text(
*                                 severity = if_abap_behv_message=>severity-error
*                                 text     = '담당자 및 고객 검수자 서명(이름)을 모두 입력해야 승인할 수 있습니다.' )
*                      ) TO reported-projects.
*
*      ELSE.
*        APPEND VALUE #( %tky = ls_project-%tky pro_id = ls_project-pro_id ) TO valid_keys.
*      ENDIF.
*    ENDLOOP.

" 2. 선택된 프로젝트들의 실제 시작일, 실제 종료일 데이터를 읽어옵니다.
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      FIELDS ( real_sdate real_edate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_projects).

    " ★ 추가: 선택된 프로젝트들에 속한 자식(배정 인력) 데이터를 읽어옵니다.
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects BY \_TechHist
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_tech_hist).

    " 에러 체크 플래그 선언 (텍스트 변수는 사용하지 않음)
    DATA lv_has_error TYPE abap_bool.

    " 3. 선택된 각 프로젝트에 대해 유효성 검사 수행
    LOOP AT lt_projects INTO DATA(ls_project).
      lv_has_error = abap_false. " 매 루프마다 에러 상태 초기화

      DATA(lv_inspector) = VALUE #( keys[ %tky = ls_project-%tky ]-%param-InspectorName OPTIONAL ).
      DATA(lv_customer)  = VALUE #( keys[ %tky = ls_project-%tky ]-%param-CustomerName OPTIONAL ).

      " 유효성 검증 1: 프로젝트 실제 시작일 누락 체크
      IF ls_project-real_sdate IS INITIAL.
        lv_has_error = abap_true.
        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
        APPEND VALUE #( %tky = ls_project-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = '프로젝트의 실제 시작일과 실제 종료일을 모두 입력해야 검수 승인을 할 수 있습니다.' )
                      ) TO reported-projects.

      " 유효성 검증 2: 담당자 및 고객 검수자 서명 누락 체크
      ELSEIF lv_inspector IS INITIAL OR lv_customer IS INITIAL.
        lv_has_error = abap_true.
        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
        APPEND VALUE #( %tky = ls_project-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = '담당자 및 고객 검수자 서명(이름)을 모두 입력해야 승인할 수 있습니다.' )
                      ) TO reported-projects.
      ENDIF.

      " ★ 유효성 검증 3: 배정 인력(직원) 투입일자 누락 및 역전 체크 (앞의 에러가 없을 때만 수행)
      IF lv_has_error = abap_false.
        LOOP AT lt_tech_hist INTO DATA(ls_tech) WHERE pro_id = ls_project-pro_id.

          " 직원의 투입 시작일 또는 종료일이 비어있는지 체크
          IF ls_tech-work_sdate IS INITIAL OR ls_tech-work_edate IS INITIAL.
            lv_has_error = abap_true.
            APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
            APPEND VALUE #( %tky = ls_project-%tky
                            %msg = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-error
                                     text     = '모든 직원의 실제 투입 시작일과 종료일을 입력해야 승인할 수 있습니다.' )
                          ) TO reported-projects.
            EXIT. " 에러 발생 시 즉시 직원 루프 탈출

          " 직원의 실제 종료일이 시작일보다 과거인지(역전되었는지) 체크
          ELSEIF ls_tech-work_edate < ls_tech-work_sdate.
            lv_has_error = abap_true.
            APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
            APPEND VALUE #( %tky = ls_project-%tky
                            %msg = new_message_with_text(
                                     severity = if_abap_behv_message=>severity-error
                                     text     = '직원의 실제 종료일이 시작일보다 앞설 수 없습니다.' )
                          ) TO reported-projects.
            EXIT. " 에러 발생 시 즉시 직원 루프 탈출
          ENDIF.

        ENDLOOP.
      ENDIF.

      " 에러가 전혀 없는 경우에만 업데이트 대상 변수에 키 추가
      IF lv_has_error = abap_false.
        APPEND VALUE #( %tky = ls_project-%tky pro_id = ls_project-pro_id ) TO valid_keys.
      ENDIF.
   ENDLOOP.

    " 4. 검수 승인('Y') 처리: 상태값 '60' 변경 및 모든 테이블 저장
    IF valid_keys IS NOT INITIAL.
      DATA(lv_today_insp) = cl_abap_context_info=>get_system_date( ).

        MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
          ENTITY Projects
          UPDATE FIELDS ( status real_edate )
          WITH VALUE #(
              FOR valid_key IN valid_keys (
                  %tky       = valid_key-%tky
                  status     = '60'
                  real_edate = lv_today_insp
              )
          ).

      LOOP AT valid_keys INTO DATA(ls_valid).
        APPEND ls_valid-pro_id TO lcl_buffer=>gt_fi_post.
      ENDLOOP.


      READ ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY Projects
        ALL FIELDS WITH CORRESPONDING #( valid_keys )
        RESULT DATA(projects).

      result = VALUE #( FOR proj IN projects ( pro_id = proj-pro_id %param = proj ) ).

      DATA(lv_user_insp)  = cl_abap_context_info=>get_user_technical_name( ).

      LOOP AT projects INTO DATA(ls_proj_insp).
        DATA(ls_param) = VALUE #( keys[ %tky = ls_proj_insp-%tky ]-%param OPTIONAL ).


        " (1) 고객 검수 내역(z8ps_custom_inv) 저장 - 결과는 무조건 'Y'
        DATA ls_cust_inv TYPE z8ps_custom_inv.
        SELECT SINGLE MAX( inv_no ) FROM z8ps_custom_inv
          INTO @DATA(lv_max_inv_no)
          WHERE pro_id = @ls_proj_insp-pro_id.

        ls_cust_inv-mandt        = sy-mandt.
        ls_cust_inv-pro_id       = ls_proj_insp-pro_id.
        ls_cust_inv-inv_no       = lv_max_inv_no + 1.
        ls_cust_inv-insp_name    = ls_param-CustomerName.
        ls_cust_inv-insp_res     = 'Y'. " 승인 버튼이므로 'Y' 고정
        ls_cust_inv-inspect_date = lv_today_insp.
        ls_cust_inv-rej_reason   = ''.  " 승인 시 반려 사유는 공백

        APPEND ls_cust_inv TO lcl_buffer=>gt_cust_inv.

        " (2) 프로젝트 히스토리(z8ps_proj_hist) 저장
        DATA ls_hist_insp TYPE z8ps_proj_hist.
        SELECT SINGLE MAX( seq_no ) FROM z8ps_proj_hist
          INTO @DATA(lv_max_seq_insp)
          WHERE pro_id = @ls_proj_insp-pro_id.

        ls_hist_insp-mandt        = sy-mandt.
        ls_hist_insp-pro_id       = ls_proj_insp-pro_id.
        ls_hist_insp-seq_no       = lv_max_seq_insp + 1.
        ls_hist_insp-status_p     = ls_proj_insp-status.
        ls_hist_insp-sdate        = ls_proj_insp-sdate.
        ls_hist_insp-edate        = ls_proj_insp-edate.
        ls_hist_insp-sdate_a      = ls_proj_insp-real_sdate.
        ls_hist_insp-edate_a      = ls_proj_insp-real_edate.
        ls_hist_insp-changed_by   = lv_user_insp.
        ls_hist_insp-changed_date = lv_today_insp.

        APPEND ls_hist_insp TO lcl_buffer=>gt_hist.

        " (3) 승인 성공 메시지
        APPEND VALUE #( %tky = ls_proj_insp-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = '고객 검수가 승인되었습니다.' )
                      ) TO reported-projects.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD rejectInspect.
    " 1. 유효성 검사를 통과한 프로젝트 키만 담을 변수 선언
    DATA valid_keys TYPE TABLE FOR ACTION IMPORT z8r_projects~rejectInspect.

    " 2. 선택된 프로젝트들의 실제 시작일, 실제 종료일, 그리고 현재 상태(status)를 읽어옵니다.
    " (주의: 상태 변경 트리거 후 원래 상태로 복구하기 위해 status 필드를 반드시 함께 읽어야 합니다!)
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      FIELDS ( real_sdate real_edate status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_projects).

    " 3. 선택된 각 프로젝트에 대해 유효성 검사 수행
    LOOP AT lt_projects INTO DATA(ls_project).
      DATA(lv_inspector)  = VALUE #( keys[ %tky = ls_project-%tky ]-%param-InspectorName OPTIONAL ).
      DATA(lv_customer)   = VALUE #( keys[ %tky = ls_project-%tky ]-%param-CustomerName OPTIONAL ).
      DATA(lv_rej_reason) = VALUE #( keys[ %tky = ls_project-%tky ]-%param-RejReason OPTIONAL ).

      " 유효성 검증 1: 실제 시작일 또는 실제 종료일 누락 체크 ( 반려이기에 해당 항목을 볼 필요 없다 )
*      IF ls_project-real_sdate IS INITIAL OR ls_project-real_edate IS INITIAL.
*        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
*        APPEND VALUE #( %tky = ls_project-%tky
*                        %msg = new_message_with_text(
*                                 severity = if_abap_behv_message=>severity-error
*                                 text     = '프로젝트의 실제 시작일과 실제 종료일이 입력되어 있어야 검수 반려 처리를 할 수 있습니다.' )
*                      ) TO reported-projects.

      " 유효성 검증 2: 담당자 및 고객 검수자 서명 누락 체크
      IF lv_inspector IS INITIAL OR lv_customer IS INITIAL.
        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
        APPEND VALUE #( %tky = ls_project-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = '담당자 및 고객 검수자 서명(이름)을 모두 입력해야 반려 처리할 수 있습니다.' )
                      ) TO reported-projects.

      " 유효성 검증 3: 반려 사유 누락 체크 (반려 시 사유 필수 입력)
      ELSEIF lv_rej_reason IS INITIAL.
        APPEND VALUE #( %tky = ls_project-%tky ) TO failed-projects.
        APPEND VALUE #( %tky = ls_project-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = '검수 반려 사유를 반드시 입력해야 합니다.' )
                      ) TO reported-projects.

      ELSE.
        APPEND VALUE #( %tky = ls_project-%tky pro_id = ls_project-pro_id ) TO valid_keys.
      ENDIF.
    ENDLOOP.

    " 4. 검수 반려('N') 처리: 프로젝트 상태는 그대로 유지하고 고객 검수 내역만 저장
        IF valid_keys IS NOT INITIAL.
      DATA(lv_today_insp) = cl_abap_context_info=>get_system_date( ).
      DATA(lv_user_insp)  = cl_abap_context_info=>get_user_technical_name( ).

      " (1) 상태를 바로 40(설치 진행)으로 되돌림 - '99' 경유 제거
      MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY Projects
        UPDATE FIELDS ( status )
        WITH VALUE #( FOR valid_key IN valid_keys ( %tky = valid_key-%tky status = '40' ) ).

      " (2) 재작업 기간 동안 인력이 묶여 있도록 실제 투입 종료일 초기화
      READ ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY Projects BY \_TechHist
        FIELDS ( work_edate ) WITH CORRESPONDING #( valid_keys )
        RESULT DATA(lt_tech).

      IF lt_tech IS NOT INITIAL.
        MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
          ENTITY tech_hist
          UPDATE FIELDS ( work_edate )
          WITH VALUE #( FOR tech IN lt_tech ( %tky = tech-%tky work_edate = VALUE #( ) ) ).
      ENDIF.

      READ ENTITIES OF z8r_projects IN LOCAL MODE
        ENTITY Projects
        ALL FIELDS WITH CORRESPONDING #( valid_keys )
        RESULT DATA(projects).

      result = VALUE #( FOR proj IN projects ( pro_id = proj-pro_id %param = proj ) ).

      LOOP AT projects INTO DATA(ls_proj_insp).
        DATA(ls_param) = VALUE #( keys[ %tky = ls_proj_insp-%tky ]-%param OPTIONAL ).

        " (3) 고객 검수 내역 - 결과 'N' + 반려 사유 (기존과 동일)
        DATA ls_cust_inv TYPE z8ps_custom_inv.
        SELECT SINGLE MAX( inv_no ) FROM z8ps_custom_inv
          INTO @DATA(lv_max_inv_no)
          WHERE pro_id = @ls_proj_insp-pro_id.

        ls_cust_inv-mandt        = sy-mandt.
        ls_cust_inv-pro_id       = ls_proj_insp-pro_id.
        ls_cust_inv-inv_no       = lv_max_inv_no + 1.
        ls_cust_inv-insp_name    = ls_param-CustomerName.
        ls_cust_inv-insp_res     = 'N'.
        ls_cust_inv-inspect_date = lv_today_insp.
        ls_cust_inv-rej_reason   = ls_param-RejReason.
        APPEND ls_cust_inv TO lcl_buffer=>gt_cust_inv.

        " (4) 상태 이력 - 반려(50 → 40)도 기록
        DATA ls_hist TYPE z8ps_proj_hist.
        SELECT SINGLE MAX( seq_no ) FROM z8ps_proj_hist
          INTO @DATA(lv_max_seq)
          WHERE pro_id = @ls_proj_insp-pro_id.

        ls_hist-mandt        = sy-mandt.
        ls_hist-pro_id       = ls_proj_insp-pro_id.
        ls_hist-seq_no       = lv_max_seq + 1.
        ls_hist-status_p     = ls_proj_insp-status.      " 40
        ls_hist-sdate        = ls_proj_insp-sdate.
        ls_hist-edate        = ls_proj_insp-edate.
        ls_hist-sdate_a      = ls_proj_insp-real_sdate.
        ls_hist-edate_a      = ls_proj_insp-real_edate.
        ls_hist-changed_by   = lv_user_insp.
        ls_hist-changed_date = lv_today_insp.
        APPEND ls_hist TO lcl_buffer=>gt_hist.

        APPEND VALUE #( %tky = ls_proj_insp-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-information
                                 text     = '검수 반려가 등록되었습니다. 배정 인력의 실제 투입 종료일이 초기화되었으니 재작업 후 다시 입력하십시오.' )
                      ) TO reported-projects.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

endclass.

* -----------------------------------------------------------------------------


CLASS lhc_tech_hist DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR tech_hist RESULT result.
ENDCLASS.

CLASS lhc_tech_hist IMPLEMENTATION.
  METHOD get_instance_features.
    " 1. 자식 데이터의 Key(pro_id)를 이용해 부모(Project)의 현재 상태값을 읽어옵니다.
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Projects
      FIELDS ( status ) WITH CORRESPONDING #( keys )
      RESULT DATA(projects).

    " 2. 부모 상태값이 '40'일 때만 자식의 Update(수정) 기능을 활성화합니다.
    result = VALUE #( FOR tech IN keys
      LET ls_project = VALUE #( projects[ pro_id = tech-pro_id ] OPTIONAL )
      IN ( %tky    = tech-%tky
           %update = COND #( WHEN ls_project-status = '40' or ls_project-status = '50'
                             THEN if_abap_behv=>fc-o-enabled
                             ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.
ENDCLASS.


CLASS lsc_Z8R_PROJECTS DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified    REDEFINITION.
    "METHODS cleanup REDEFINITION.  " 저장 완료 후 호출
    METHODS cleanup_finalize REDEFINITION.  " finalize/check_before_save 실패 시 호출
ENDCLASS.

CLASS lsc_Z8R_PROJECTS IMPLEMENTATION.

  METHOD save_modified.
    " 1. 프로젝트 이력 저장
    IF lcl_buffer=>gt_hist IS NOT INITIAL.
      INSERT z8ps_proj_hist FROM TABLE @lcl_buffer=>gt_hist.
    ENDIF.

    " 2. 고객 검수 내역 저장
    IF lcl_buffer=>gt_cust_inv IS NOT INITIAL.
      MODIFY z8ps_custom_inv FROM TABLE @lcl_buffer=>gt_cust_inv.
    ENDIF.

    " 3. FI 회계 전표 생성
    LOOP AT lcl_buffer=>gt_fi_post INTO DATA(lv_pro_id).

      UPDATE z8ps_project
        SET status_p = '60'
      WHERE pro_id = @lv_pro_id.

      CALL FUNCTION 'Z8FI_POST_INSPECTION'
        EXPORTING
          iv_pro_id                = lv_pro_id
        EXCEPTIONS
          project_not_found        = 1
          inspection_not_completed = 2
          data_error               = 3
          already_posted           = 4
          invalid_amount           = 5
          posting_failed           = 6
          OTHERS                   = 7.

      IF sy-subrc = 0.
        APPEND VALUE #( pro_id = lv_pro_id
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = |프로젝트 { lv_pro_id } 전표 생성 성공| )
                      ) TO reported-projects.
      ELSE.
        APPEND VALUE #( pro_id = lv_pro_id
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |프로젝트 { lv_pro_id } 전표 생성 실패 (sy-subrc: { sy-subrc })| )
                      ) TO reported-projects.
      ENDIF.
    ENDLOOP.

    " 4. 저장 완료 후 버퍼 정리 (다음 트랜잭션에 잔여 데이터가 섞이지 않도록)
    lcl_buffer=>clear_all( ).
  ENDMETHOD.

  METHOD cleanup_finalize.
    " 저장 직전 검증 실패 시 호출: 저장되지 않은 잔여 데이터를 제거합니다.
    lcl_buffer=>clear_all( ).
  ENDMETHOD.

ENDCLASS.

"
