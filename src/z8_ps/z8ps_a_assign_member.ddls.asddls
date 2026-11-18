@EndUserText.label: '인력배정 선택 직원'
define abstract entity Z8PS_A_ASSIGN_MEMBER
{
    key ProjectId : z8e_pro_id;
    key PersonalNumber: z8e_pernr;
    
    _Batch: association to parent Z8PS_A_ASSIGN_BATCH on $projection.ProjectId = _Batch.ProjectId;
}
