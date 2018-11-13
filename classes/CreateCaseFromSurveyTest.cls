/***************************************************************************************************************************************
@Author : Sruthi Kattula
@Date Created : 5/11/2018
@JIRA : BAP-7408, BAP-7289
@description : Test class for CreateCaseFromSurveyController
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Sruthi K		5/11/2018	BAP-7408, BAP-7289
***************************************************************************************************************************************/
@isTest
public class CreateCaseFromSurveyTest {
    
    public static testmethod void test1(){
        Id corporateNPSRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Corporate_Merchant_NPS').getRecordTypeId();
        List<Account> acc = TestDataFactory.createTestAccounts(1,false,RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Contact> con = TestDataFactory.createTestContacts(1,acc);
        Survey__c  vSurvey = new Survey__c();
        vSurvey.Survey_Name__c = 'NPS Survey';
        vSurvey.Feedback__c = 'good';
        vSurvey.Satisfaction__c = 10;
        vSurvey.Recommendation__c = 10;
        vSurvey.Recommendation_Feedback__c = 'good';
        vSurvey.Contact__c = con[0].Id;
        insert vSurvey;
        
        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(vSurvey);
        CreateCaseFromSurveyController ccs = new CreateCaseFromSurveyController(sc);
        ccs.createCase();
        test.stopTest();
        List<Case> c = [select Id,recordTypeId from Case where Survey__c =: vSurvey.Id and recordTypeId=:corporateNPSRecTypeId];
        boolean result = false;
        if(c != null && c.size() >0){
            result = true;
        }
        system.assertEquals(true, result);  
    }

}