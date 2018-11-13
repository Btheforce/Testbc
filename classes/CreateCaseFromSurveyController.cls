/***************************************************************************************************************************************
@Author : Sruthi Kattula
@Date Created : 5/11/2018
@JIRA : BAP-7408, BAP-7289
@description : Modify the button 'create a case' on survey object such that, if Survey Name = 'NPS Survey', 
			   then new case of case rec type - 'Corporate Merchant NPS' has to be created with Case Owner as 'NPS Responders' and 
			   it has to carry the 'NPS Campaign Name' field.
@invoked by : 'Create Case' button on survey record
@test-class : CreateCaseFromSurveyTest
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Sruthi K		5/11/2018	BAP-7408, BAP-7289
2.0			Sruthi K		9/5/2018	BAP-7896

***************************************************************************************************************************************/
public class CreateCaseFromSurveyController {
    
    public String descByUser{get;set;}
    public String errorMsg{get;set;} 
    public ApexPages.StandardController controller;
    public Id surveyId;
    //public Survey__c surveyObj;
    private final Survey__c thisSurvey ;
    public Id clientSuccessRecTypeId;
    public Id corporateNPSRecTypeId; 
    public Id tier2QueueId;
    public Id npsRespQueueId;
        
    public CreateCaseFromSurveyController(ApexPages.StandardController con) {
        controller = con;
        surveyId = con.getId();
        //surveyObj = (Survey__c)con.getRecord();
        thisSurvey = [select Id, Name, createdDate, Survey_Name__c, First_Response__c, Contact__c, NPSCampaignName__c, Feedback__c from Survey__c where Id =: surveyId]; 
        clientSuccessRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Client_Success').getRecordTypeId();
        corporateNPSRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Corporate_Merchant_NPS').getRecordTypeId();
        tier2QueueId=[select Id from Group where Name = 'Support - Tier 2' and Type = 'Queue'].Id;
        npsRespQueueId=[select Id from Group where Name = 'NPS Responders' and Type = 'Queue'].Id;
        errorMsg = '';
        descByUser = '';
    }
    
    public PageReference createCase(){
        
        Case newCase = new Case();
        newCase.Subject = 'NPS Survey Response'; 
        newCase.Status = 'New'; 
        newCase.priority = 'High'; 
        newCase.contactid = thisSurvey.Contact__c; 
        newCase.Survey__c = thisSurvey.Id;
        String feedback = '\n\n Customer Feedback\n\n---------\n'+ thisSurvey.Feedback__c +'\n---------'; 
        newCase.Description = descByUser+feedback;
        newCase.Reason = 'Surveys'; 
        newCase.Category__c = 'Company NPS'; 
        newCase.Origin = 'NPS Survey'; 
        if(thisSurvey.Survey_Name__c.equalsIgnoreCase('NPS Survey')){
            newCase.OwnerId = npsRespQueueId;
            newCase.RecordTypeId=corporateNPSRecTypeId;
        }else{
            newCase.OwnerId = tier2QueueId;
            newCase.RecordTypeId=clientSuccessRecTypeId;
            newCase.Escalated__c = true;
        }try{
            insert newCase;
            if(thisSurvey.First_Response__c == null){//BAP - 7896
                thisSurvey.First_Response__c = system.now(); 
            	update thisSurvey; 
            }
            PageReference pg = new PageReference('/'+newCase.Id);
            pg.setRedirect(true);
            return pg;
        }catch(Exception e){
            system.debug('Failed while inserting new case/updating survey First Response time from CreateCaseFromSurveyController with exception : '+e);
            errorMsg = 'Failed while inserting new case/updating survey First Response time from CreateCaseFromSurveyController with exception : ' + e +'. Please contact System Administrator.';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,errorMsg);
        }
        return null;
    }

}