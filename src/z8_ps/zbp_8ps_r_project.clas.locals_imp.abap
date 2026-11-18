CLASS lhc_Project DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Project RESULT result.

    METHODS confirmation FOR MODIFY
      "Behavior에서 alias Project에 정의한 ConfirmAssignment Action의 요청을 처리하는 Method
      IMPORTING keys FOR ACTION Project~confirmationAssignment.

    "프로젝트의 현재 상태를 보고 Action 사용 가능 여부 판단
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features "keys: Fiori에서 선택한 Project의 키
      FOR Project RESULT result. "RAP Framework에 활성/비활성 결과 반환

ENDCLASS.

CLASS lsc_Z8PS_R_PROJECT DEFINITION
  INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lhc_Project IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD confirmation. "실제 버튼을 클릭하면 실행되는 메서드

    "1. Action 대상 프로젝트 상태 조회
    READ ENTITIES OF z8ps_r_project IN LOCAL MODE
        ENTITY Project
        FIELDS ( ProjectStatus  WorkDays TotalArea StartDate EndDate SalesOrderId )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_projects)
        FAILED DATA(lt_read_failed).

    "2. Action 요청 프로젝트별 검증
    LOOP AT keys INTO DATA(ls_key).

      READ TABLE lt_projects INTO DATA(ls_project) WITH KEY ProjectId = ls_key-ProjectId.

      "프로젝트를 찾지 못한 경우
      IF sy-subrc <> 0.

        APPEND VALUE #(
          %tky = ls_key-%tky "해당 프로젝트 인스턴스를 식별하는 기술 키
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = '프로젝트를 찾을 수 없습니다.'
          )
        ) TO reported-project.

        CONTINUE.
      ENDIF.

      "3. 프로젝트 상태 검증
      IF ls_project-ProjectStatus <> '20'.

        APPEND VALUE #(
          %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = '인력배정 대기 상태가 아닙니다.'
          )
        ) TO reported-project.

        CONTINUE.
      ENDIF.

      "연결된 SO의 현재 상태 확인
      SELECT SINGLE FROM z8sd_so_h
        FIELDS status_s
        WHERE vbeln_s = @ls_project-SalesOrderId
        INTO @DATA(lv_so_status).


      IF sy-subrc <> 0 OR lv_so_status <> '20'.

        APPEND VALUE #(
          %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'SO가 없거나 인력배정 대기 상태가 아닙니다.'
          )
        ) TO reported-project.

        CONTINUE.
      ENDIF.

      DATA lv_elec_count TYPE i.
      DATA lv_invalid_member TYPE abap_bool.
      DATA lv_total_capacity TYPE z8_r_employee-Capacity.
      " Key를 기반으로 데이터를 검색하는 인터널 테이블, 한 행 저체를 KEY로 사용 (같은 사원 번호를 가질 수 없음)
      DATA lt_seen_pernr TYPE HASHED TABLE OF z8e_pernr WITH UNIQUE KEY table_line.
      DATA: BEGIN OF ls_selected_tech,
              PersonalNumber TYPE z8e_pernr,
              Stell          TYPE z8_r_employee-Stell,
              Grade          TYPE z8_r_employee-Grade,
              DailyCost      TYPE z8ps_r_tech_hist-DailyCost,
              Waers          TYPE z8ps_r_tech_hist-Waers,
            END OF ls_selected_tech.

      DATA lt_selected_tech LIKE STANDARD TABLE OF ls_selected_tech WITH EMPTY KEY.

      CLEAR: lv_elec_count, lv_invalid_member, lv_total_capacity, lt_seen_pernr, lt_selected_tech.

      "4. 상태 20인 경우 직원 목록 확인
      LOOP AT ls_key-%param-_Members INTO DATA(ls_member).

        "동일 직원 중복 선택 검증
        INSERT ls_member-PersonalNumber INTO TABLE lt_seen_pernr.

        IF sy-subrc <> 0.

          APPEND VALUE #(
            %tky = ls_key-%tky
          ) TO failed-project.

          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text = |중복 선택된 직원: { ls_member-PersonalNumber }|
            )
          ) TO reported-project.

          lv_invalid_member = abap_true.

          EXIT.

        ENDIF.

        SELECT SINGLE FROM z8_r_employee
        FIELDS PersonalNumber, Stat2, IsEng, Stell, Capacity, Grade, Salary, Waers
        WHERE PersonalNumber = @ls_member-PersonalNumber
        INTO @DATA(ls_employee).

        IF sy-subrc <> 0.
          APPEND VALUE #(
              %tky = ls_key-%tky
          ) TO failed-project.

          APPEND VALUE #(
              %tky = ls_key-%tky
              %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = |존재하지 않는 사원번호: { ls_member-PersonalNumber }|
          )
         ) TO reported-project.
          lv_invalid_member = abap_true.
          EXIT. "반복문을 완전히 종료
        ENDIF.

        "재직 상태 또는 기술자가 아닌 경우에 대한 예외처리
        IF ls_employee-Stat2 <> '1' OR ls_employee-IsEng <> 'X'.
          APPEND VALUE #(
            %tky = ls_key-%tky
          ) TO failed-project.

          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text = |배정 불가능한 직원: { ls_member-PersonalNumber }|
            )
          ) TO reported-project.
          lv_invalid_member = abap_true.
          EXIT. "반복문을 완전히 종료
        ENDIF.

        "5. 설치기사 또는 전기기사 여부 확인
        IF ls_employee-Stell <> '설치기사' AND ls_employee-Stell <> '전기기사'.

          APPEND VALUE #(
            %tky = ls_key-%tky
          ) TO failed-project.

          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text = |배정 대상 직무가 아닙니다: { ls_member-PersonalNumber }|
            )
          ) TO reported-project.

          lv_invalid_member = abap_true.
          EXIT.

        ENDIF.

        "전기기사 인원 계산
        IF ls_employee-stell = '전기기사'.
          lv_elec_count = lv_elec_count + 1.
        ENDIF.

        "설치기사의 일 생산성 합산
        IF ls_employee-stell = '설치기사'.
          lv_total_capacity = lv_total_capacity + ls_employee-Capacity.
        ENDIF.

        "6. 선택 직원의 기존 프로젝트 배정 이력 조회
        SELECT FROM z8ps_tech_hist
          FIELDS pro_id,
                 pernr,
                 sdate,
                 edate,
                 sdate_a,
                 edate_a
          WHERE pernr = @ls_member-PersonalNumber
          INTO TABLE @DATA(lt_hist).

        "7. 기존 배정 이력과 기간 충돌 검증
        DATA(lv_date_conflict) = abap_false.

        LOOP AT lt_hist INTO DATA(ls_hist).

          "실제 시작일, 종료일 모두 없는 경우
          IF ls_hist-sdate_a IS INITIAL AND ls_hist-edate_a IS INITIAL.

            "계획 기간 비교
            IF ls_hist-sdate <= ls_project-EndDate AND ls_hist-edate >= ls_project-StartDate.

              lv_date_conflict = abap_true.

            ENDIF.

            "실제 시작일은 있지만 종료일은 없는 경우
          ELSEIF ls_hist-sdate_a IS NOT INITIAL AND ls_hist-edate_a IS INITIAL.

            "현재 공사 진행 중
            lv_date_conflict = abap_true.

            "③ 실제 시작일과 종료일 모두 있는 경우
          ELSEIF ls_hist-sdate_a IS NOT INITIAL AND ls_hist-edate_a IS NOT INITIAL.

            "실제 작업 기간 비교
            IF ls_hist-sdate_a <= ls_project-EndDate AND ls_hist-edate_a >= ls_project-StartDate.

              lv_date_conflict = abap_true.

            ENDIF.

          ELSE.
            "실제 종료일만 있는 비정상 이력은 안전하게 차단
            lv_date_conflict = abap_true.

          ENDIF.

          "충돌 이력을 하나라도 발견하면 검사 종료
          IF lv_date_conflict = abap_true.
            EXIT.
          ENDIF.

        ENDLOOP.


        "8. 기간 충돌 발견 시 Action 실패 처리
        IF lv_date_conflict = abap_true.

          APPEND VALUE #(
            %tky = ls_key-%tky
          ) TO failed-project.

          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text = |이미 배정되었거나 작업 중인 직원: { ls_member-PersonalNumber }|
            )
          ) TO reported-project.

          lv_invalid_member = abap_true.
          EXIT.
        ENDIF.


        "검증 완료 직원 정보를 저장용 내부 테이블에 수집
        APPEND VALUE #(
          PersonalNumber = ls_employee-PersonalNumber
          Stell          = ls_employee-Stell
          Grade          = ls_employee-Grade
          DailyCost      = ls_employee-Salary / 240 "연봉을 기준으로 일일 인건비 계산 (연간 기준 작업일수 240일)
          Waers          = ls_employee-Waers
        ) TO lt_selected_tech.

      ENDLOOP.


      "앞선 직원 검증이 실패했다면 다음 프로젝트로
      IF lv_invalid_member = abap_true.
        CONTINUE.
      ENDIF.

      IF lv_elec_count < 1.
        APPEND VALUE #(
            %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
                severity = if_abap_behv_message=>severity-error
                text = '전기기사는 최소 1명 이상 배정해야 합니다.'
            )
        ) TO reported-project.

        CONTINUE.
      ENDIF.

      "설치기사 총 일일 생산성이 0 이하인 경우
      IF lv_total_capacity <= 0.

        APPEND VALUE #(
          %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = '설치기사의 총 작업능력이 부족합니다.'
          )
        ) TO reported-project.

        CONTINUE.
      ENDIF.

      "예상 작업일수 계산
      DATA(lv_est_work_days) = ceil( "소수점 이하를 올림하는 함수
          CONV decfloat34( ls_project-TotalArea )
          / CONV decfloat34( lv_total_capacity )
      ).

      "계획 공사일수 충족 여부 검증
      IF lv_est_work_days > ls_project-WorkDays.

        APPEND VALUE #(
          %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = '현재 선택 인력으로 계획 공사기간 내 작업 완료가 불가능합니다. 추가 인력을 배정해주세요.'
          )
        ) TO reported-project.

        CONTINUE.

      ENDIF.

      "9. 선택 직원 Lock 처리

      "여러 직원의 잠금 순서를 일정하게 유지 (사원번호 순으로 잠금 유지)
      "직원 3명을 배정할 때 담당자 A는 1 → 5 → 8, 담당자 B는 8 → 5 → 1 순서로 잠그면 서로 상대방의 잠금을 기다리는 상황이 생길 수 있으므로

      SORT lt_selected_tech BY PersonalNumber.

      DATA lt_locked_pernr TYPE STANDARD TABLE OF z8e_pernr WITH EMPTY KEY.
      DATA lv_lock_failed TYPE abap_bool.

      CLEAR: lt_locked_pernr, lv_lock_failed.

      LOOP AT lt_selected_tech INTO DATA(ls_lock_tech).

        CALL FUNCTION 'ENQUEUE_EZ8_EMPLOYEE'
          EXPORTING
            mode_z8employee_m = 'E' "Exclusive Lock은 다른 트랜잭션이 같은 자원에 충돌하는 Lock을 걸지 못하게 하는 방식
            mandt             = sy-mandt
            pernr             = ls_lock_tech-PersonalNumber
            _scope            = '1' "잠금의 소유권을 Dialog Owner에 둔다는 의미. Update Task에 잠금을 넘기지 않고, 명시적인 DEQUEUE 또는 해당 Dialog 트랜잭션 종료 시 해제
            _wait             = space
          EXCEPTIONS
            foreign_lock      = 1 "이미 잠겨 있을 때 기다리지 않고 즉시 foreign_lock 예외를 발생
            system_failure    = 2
            OTHERS            = 3.

        IF sy-subrc <> 0. "Lock 실패 시 기존 Lock 해제

          "앞에서 잠금에 성공한 직원들만 잠금 해제
          LOOP AT lt_locked_pernr INTO DATA(lv_locked_pernr).

            CALL FUNCTION 'DEQUEUE_EZ8_EMPLOYEE'
              EXPORTING
                mode_z8employee_m = 'E'
                mandt             = sy-mandt
                pernr             = lv_locked_pernr
                _scope            = '1'.

          ENDLOOP.

          APPEND VALUE #(
            %tky = ls_key-%tky
          ) TO failed-project.

          APPEND VALUE #(
            %tky = ls_key-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text = |현재 다른 사용자가 배정 처리 중인 직원: { ls_lock_tech-PersonalNumber }|
            )
          ) TO reported-project.

          lv_lock_failed = abap_true.
          EXIT.

        ENDIF.

        "잠금 성공한 직원 번호 기록
        APPEND ls_lock_tech-PersonalNumber TO lt_locked_pernr.

      ENDLOOP.

      "직원 잠금 실패 시 해당 프로젝트의 배정 중단
      IF lv_lock_failed = abap_true.
        CONTINUE.
      ENDIF.

      "10. 검증 완료 직원들의 인력배정 이력 생성
      MODIFY ENTITIES OF z8ps_r_project IN LOCAL MODE
        ENTITY Project
          CREATE BY \_Tech
          FIELDS ( PersonalNumber StartDate EndDate
                   Stell Grade DailyCost Waers )
          WITH VALUE #(
            (
              %tky = ls_key-%tky "어느 프로젝트에 인력을 배정할지 지정

              %target = VALUE #( "해당 프로젝트에 생성할 직원 목록을 전달
                FOR ls_tech IN lt_selected_tech INDEX INTO lv_idx
                (
                  %cid           = |TECH_{ lv_idx }| "RAP에서 새로 생성하는 데이터를 임시로 식별하기 위한 ID 예) TECH_1
                  PersonalNumber = ls_tech-PersonalNumber
                  StartDate      = ls_project-StartDate
                  EndDate        = ls_project-EndDate
                  Stell          = ls_tech-Stell
                  Grade          = ls_tech-Grade
                  DailyCost      = ls_tech-DailyCost
                  Waers          = ls_tech-Waers
                )
              )
            )
          )
        MAPPED DATA(lt_cba_mapped)
        FAILED DATA(lt_cba_failed)
        REPORTED DATA(lt_cba_reported).

      "인력배정 이력 생성 실패 여부 확인
      IF lt_cba_failed IS NOT INITIAL.

        APPEND VALUE #(
          %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = '인력배정 이력 생성에 실패했습니다.'
          )
        ) TO reported-project.

        CONTINUE.

      ENDIF.

      "11. 인력배정 완료 시 프로젝트 상태 변경 (20 -> 30)
      MODIFY ENTITIES OF z8ps_r_project IN LOCAL MODE
        ENTITY Project
          UPDATE FIELDS ( ProjectStatus )
          WITH VALUE #(
            (
              %tky          = ls_key-%tky
              ProjectStatus = '30'
            )
          )
        FAILED DATA(lt_update_failed)
        REPORTED DATA(lt_update_reported).

      "프로젝트 상태 변경 실패 처리
      IF lt_update_failed IS NOT INITIAL.

        APPEND VALUE #(
          %tky = ls_key-%tky
        ) TO failed-project.

        APPEND VALUE #(
          %tky = ls_key-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = '프로젝트 상태 변경에 실패했습니다.'
          )
        ) TO reported-project.

        CONTINUE.

      ENDIF.


    ENDLOOP.

  ENDMETHOD.

  "1. 현재 Project의 상태 조회
  METHOD get_instance_features.
    READ ENTITIES OF z8ps_r_project "RAP BO를 통해 읽기
    IN LOCAL MODE "같은 BO 내부에서 권한 검사 등을 일부 우회하는 내부 접근 방식
    ENTITY Project "Root Entity 선택
    FIELDS ( ProjectStatus ) "해당 필드 요청
    WITH CORRESPONDING #( keys ) "전달 받은 프로젝트 키 사용
    RESULT DATA(lt_projects) "읽은 프로젝트를 인터널 테이블에 저장
    FAILED failed.

    "2. 상태에 따라 Action 활성/비활성
    result = VALUE #(
      FOR ls_project IN lt_projects "lt_projects의 각 행을 반복
      (
          "%RAP의 트랜잭션 키 (어떤 프로젝트에 대한 활성화 결과인지 식별할 수 있도록 조회 결과의 키를 넘겨줌)
          %tky = ls_project-%tky

          "Action의 사용 가능 여부 반환
          %features-%action-confirmationAssignment = "이 프로젝트의 Action 사용 가능 여부
          COND #(
              WHEN ls_project-ProjectStatus = '20'
                  THEN if_abap_behv=>fc-o-enabled
              ELSE if_abap_behv=>fc-o-disabled
          )
       )

     ).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z8PS_R_PROJECT IMPLEMENTATION.

  METHOD save_modified.

    "프로젝트 변경 요청 확인
    LOOP AT update-project INTO DATA(ls_updated_project). "앞에서 EML로 실행한 UPDATE FIELDS ( ProjectStatus ) <- 이 요청이 여기 반영 됨

      "프로젝트 상태가 30으로 변경된 경우만 처리
      IF ls_updated_project-%control-ProjectStatus = if_abap_behv=>mk-on "단순히 상태 값이 30인지 확인하는 것과는 달라. RAP은 %control로 어떤 필드가 실제 변경 요청에 포함되었는지 구분
         AND ls_updated_project-ProjectStatus = '30'. "인력배정 완료 상태로 변경된 프로젝트만 처리하려는 조건

        "1. 해당 프로젝트의 마지막 이력 순번 조회
        SELECT FROM z8ps_proj_hist
          FIELDS MAX( seq_no )
          WHERE pro_id = @ls_updated_project-ProjectId
          INTO @DATA(lv_last_seq).

        "2. 다음 이력 순번 계산
        DATA(lv_next_seq) = CONV i( lv_last_seq ) + 1.

        "3. 현재 프로젝트 데이터 조회
        SELECT SINGLE FROM z8ps_project
          FIELDS sdate, edate, sdate_a, edate_a, vbeln "vbeln: SO 번호
          WHERE pro_id = @ls_updated_project-ProjectId
          INTO @DATA(ls_project).

        "4. 프로젝트 상태 변경 이력 데이터 구성
        DATA(ls_new_hist) = VALUE z8ps_proj_hist(
          pro_id       = ls_updated_project-ProjectId
          seq_no       = lv_next_seq
          status_p     = '30'
          sdate        = ls_project-sdate
          edate        = ls_project-edate
          sdate_a      = ls_project-sdate_a
          edate_a      = ls_project-edate_a
          changed_by   = sy-uname
          changed_date = sy-datum
        ).

        "RAP는 일반적으로 프레임워크가 저장과 트랜잭션 종료를 관리하기 때문에 직접 COMMIT WORK, ROLLBACK WORK를 넣으면 안 됨

        "5. 프로젝트 상태 변경 이력 저장
        INSERT z8ps_proj_hist FROM @ls_new_hist.
        DATA(lv_hist_subrc) = sy-subrc.


        "6. 연결된 SO 상태 변경 (20 -> 30)
        UPDATE z8sd_so_h
          SET status_s = '30'
          WHERE vbeln_s = @ls_project-vbeln AND status_s = '20'.
          DATA(lv_so_subrc) = sy-subrc.



      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
