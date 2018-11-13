/***************************************************************************************************************************************
    @Author : Sruthi Kattula
	@Date Created : 4/4/2018
    @JIRA : BAP - 6756 
    @description : test coverage for OpportunityTriggerHandler 
	@History 
	VERSION 	AUTHOR   			DATE       	DETAIL
	1.0			Sruthi K			4/4/2018	BAP - 6756
***************************************************************************************************************************************/
@isTest
public class OpportunityTriggerHandlerTest {
    
    public static testMethod void OnAfterUpdateTest(){
        Id devRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Store Purchase').getRecordTypeId();
        Profile p = [select Id from Profile where Name='System Administrator'];
        
        TestDataGenerator td = new TestDataGenerator();
        
        User user1 = td.getUser(p,'abcdefgh');
        insert user1;
        
    	list<Contact> lstCon = td.getContacts(true);
        
        list<Account> lstAcc = td.getAccounts(true);
        lstAcc[0].ltc__c = user1.Id;
        update lstAcc[0];
        
        test.startTest();
        Opportunity o = new Opportunity();
        o.Name = 'Test ';
        o.CloseDate = Date.today().addDays(1);
        o.StageName = 'Purchased';
        o.status__c = 'Active';
        o.RecordTypeId = devRecordTypeId;
        o.launch_status__c = 'Unlaunched';
        o.Onboarding_Specialist_lookup__c = user1.Id;
        insert o;
        
        opportunitycontactrole ocr1 = new opportunitycontactrole(opportunityId = o.Id,contactId = lstCon[0].Id, role='Economic Buyer',IsPrimary=false);
        insert ocr1;
        
        o.Launch_Status__c = 'Launched';
        o.Launch_Date__c = system.today();
        update o;  
        test.stopTest();
    } 

}