// z8c_projects
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PROJECT - SO_H - CUSTOMER Projection view'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity z8c_projects
  provider contract transactional_query
  as projection on z8r_projects
{
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8V_PROJECT', element: 'ProId' } }]
    key pro_id,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8V_PROJECT', element: 'Vbeln' } }]
    vbeln,
    
    @ObjectModel.text.element: ['status_text']
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8I_STATUS_TEXT', element: 'StatusCode' } }]
    //@Consumption.valueHelpDefinition: [{ entity: { name: 'Z8V_PROJECT', element: 'StatusP' } }]
    @Consumption.filter: { defaultValue: '30' }
    status,
    status_text,
    
    @ObjectModel.text.element: ['del_stat_text']
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8I_DELIV_TEXT', element: 'StatusCode' } }]
    @Consumption.filter: { defaultValue: '30' }
    del_status,
    del_stat_text,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8V_CUSOMER', element: 'Name1' } }]
    name,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8R_PLANT_TEXT', element: 'Bupla' } }]
    branch, 
    branch_name,
    
    address,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'Z8V_PROJECT', element: 'Sdate' } }]
    sdate,
    
    edate,
    
    real_sdate,
    real_edate,
    
    hide_start_btn,
    hide_comp_btn,
    hide_insp_btn,
    hide_rej_btn,

    /* Associations */
    _TechHist : redirected to composition child Z8C_tech_hist,
    _Materials
}
