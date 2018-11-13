/***************************************************************************************************************************************
@Author : Akhil Midde
@Date Created : 10/19/2017
@JIRA : BAP-5484, BAP-6928, BAP-7410
@description : Test Class
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Akhil Midde		10/19/2017	BAP-5484,BAP-6928
2.0			Sruthi K		06/25/2018	BAP-7410
***************************************************************************************************************************************/
@isTest(SeeAllData=true)
private class TestCaseStopWorkingController
{   
    static testMethod void testStopWorking1() 
    {
        TestDataGenerator td = new TestDataGenerator();
        
        list<Account> lstAcct = td.getAccounts(true);
        Case c = td.createCase(lstAcct[0].Id, '', true);
        Id resultId;
        // Make sure the case is associated to the correct account and user
        c.AccountId = lstAcct[0].Id;
        c.OwnerId = UserInfo.getUserId();
        update c;           
        Test.startTest();
        PageReference pageRef = Page.CaseStopWorking;
        Test.setCurrentPage(pageRef);                    
        ApexPages.StandardController sc = new ApexPages.Standardcontroller(c);           
        CaseStopWorkingController cont = new CaseStopWorkingController(sc);
        cont.getshowQueueSelection();
        cont.getshowError();
        cont.setCaseToAPI();
        cont.setCaseToLegal();
        cont.setCaseToBilling();
        cont.setCaseToMgrCallback();
        cont.setCaseToEscalated1();
        cont.setCaseToSupport();
        cont.setCaseTier2Actions(); 
        resultId = cont.objCaseId;
        Test.stopTest();
        boolean answer = false;
        List<case> resultCase = [select Id, OwnerId from case where Id =: resultId];
        if(resultCase!=null && resultCase.size()>0){
            answer = true;
        }
        system.assertEquals(true, answer);
    }
    
    static testMethod void testStopWorking2(){
        TestDataGenerator td = new TestDataGenerator();
        list<Account> lstAcct = td.getAccounts(true);
        Case c = td.createCase(lstAcct[0].Id, '', true);
        Id resultId;
        // Make sure the case is associated to the correct account and user
        c.AccountId = lstAcct[0].Id;
        c.OwnerId = UserInfo.getUserId();
        update c;   
        Test.startTest();
        PageReference pageRef = Page.CaseStopWorking;
        Test.setCurrentPage(pageRef);           
        ApexPages.StandardController sc = new ApexPages.Standardcontroller(c);      
        CaseStopWorkingController cont = new CaseStopWorkingController(sc);
        cont.setCaseToTrash();
        cont.setCaseToCallbackDesign();
        cont.setCaseToPartnerCaseQueue();
        cont.setCaseToBillingMgrCallback();
        cont.setCaseToAccountServices();
        cont.setCaseToCancel();
        cont.changeOwner('Support - Tier 2');
        cont.setCaseToTier2();
        resultId = cont.objCaseId;
        Test.stopTest();
        boolean answer = false;
        List<case> resultCase = [select Id, OwnerId from case where Id =: resultId];
        if(resultCase!=null && resultCase.size()>0){
            answer = true;
        }
        system.assertEquals(true, answer);
    } 
        
}