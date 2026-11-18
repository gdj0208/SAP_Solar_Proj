@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '자재·재고 통합현황'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z8MM_C_MATSTOCK
  as select from    z8matplant_m     as p
    inner join      z8material_m     as m on m.matnr = p.matnr
    left outer join z8material_txt_m as t on  t.matnr = p.matnr
                                          and t.spras = '3'
    left outer join z8plant_m        as w on w.werks = p.werks
    left outer join z8material_stk_m as s on  s.matnr = p.matnr
                                          and s.werks = p.werks
                                          and s.lgort = '0001'
{
  key p.matnr,
  key p.werks,
      t.maktx                                as maktx,
      w.name1                                as plant_name,
      m.mtart,
      m.meins,
      @Semantics.quantity.unitOfMeasure: 'meins'
      p.mabst,
      @Semantics.quantity.unitOfMeasure: 'meins'
      p.eisbe,
      @Semantics.quantity.unitOfMeasure: 'meins'
      s.labst,
      @Semantics.quantity.unitOfMeasure: 'meins'
      s.zzrsvqty,
      //  가용재고 계산
      coalesce(cast(s.labst as abap.dec(15,3)),
               cast(0 as abap.dec(15,3)))
      - coalesce(cast(s.zzrsvqty as abap.dec(15,3)),
               cast(0 as abap.dec(15,3)))
      - cast(p.eisbe as abap.dec(15,3))      as avail_qty,
      //  재고 수준(%)과 상태
      case when p.mabst > 0 then
        cast( division(
          ( coalesce( cast( s.labst as abap.dec( 15, 3 ) ), cast( 0 as abap.dec( 15, 3 ) ) )
          - coalesce( cast( s.zzrsvqty as abap.dec( 15, 3 ) ), cast( 0 as abap.dec( 15, 3 ) ) )
          - cast( p.eisbe as abap.dec( 15, 3 ) ) ) * 100,
          cast( p.mabst as abap.dec( 15, 3 ) ), 1 ) as abap.dec( 7, 1 ) )
      else cast( 0 as abap.dec( 7, 1 ) ) end as level_pct, //level_pct = 가용재고/목표수량 x 100.

      case
        when cast( p.mabst as abap.dec( 15, 3 ) ) * 30 >
          ( coalesce( cast( s.labst as abap.dec( 15, 3 ) ), cast( 0 as abap.dec( 15, 3 ) ) )
          - coalesce( cast( s.zzrsvqty as abap.dec( 15, 3 ) ), cast( 0 as abap.dec( 15, 3 ) ) )
          - cast( p.eisbe as abap.dec( 15, 3 ) ) ) * 100  then 'R'
        when cast( p.mabst as abap.dec( 15, 3 ) ) * 50 >
          ( coalesce( cast( s.labst as abap.dec( 15, 3 ) ), cast( 0 as abap.dec( 15, 3 ) ) )
          - coalesce( cast( s.zzrsvqty as abap.dec( 15, 3 ) ), cast( 0 as abap.dec( 15, 3 ) ) )
          - cast( p.eisbe as abap.dec( 15, 3 ) ) ) * 100  then 'Y'
        else 'G'
      end                                    as status 
      //status: 30% 미만 = R(부족), 50% 미만 = Y(주의), 그이상 = G(정상)
}
where
//목표수량이 없는 자재를 뺌.
  p.mabst > 0 
  
