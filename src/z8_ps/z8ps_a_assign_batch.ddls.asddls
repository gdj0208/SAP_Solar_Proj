@EndUserText.label: '인력 일괄배정 입력'
define root abstract entity Z8PS_A_ASSIGN_BATCH
{
    
    key ProjectId: z8e_pro_id; // 일괄배정 요청이 어떤 프로젝트에 속하는지 나타내는 필드
    
    //한 번의 Action 요청에 직원 여러 명을 담을 수 있음
    _Members: composition [0..*] of Z8PS_A_ASSIGN_MEMBER;
    
}
