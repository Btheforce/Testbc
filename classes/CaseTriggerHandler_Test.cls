/***************************************************************************************************************************************
@Author : Sruthi Kattula
@Date Created : 07/12/2018
@JIRA : BAP-7270
@description : test Class
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Sruthi K		07/12/2018	BAP-7270
***************************************************************************************************************************************/
@isTest
public class CaseTriggerHandler_Test {
    
    static testmethod void test1(){
        RecordType recType = [select Id from RecordType where sObjecttype ='Account' and name='Client Record Type'];
        List<Account> acc = TestDataFactory.createTestAccounts(1,false, recType);
        List<Contact> con = TestDataFactory.createTestContacts(1, acc);
        test.startTest();
        List<Case> cas = TestDataFactory.createTestCases(1, con);
        cas[0].Description = 'New Decsription';
        cas[0].Troubleshooting__c = 'New Trouble shooting';
        cas[0].Resolution__c = 'New Resolution';
        update cas[0];
        cas[0].Description = null;
        cas[0].Troubleshooting__c = null;
        cas[0].Resolution__c = 'changed';
        update cas[0];
        test.stopTest();
        List<case> result = [select Id, Resolution__c from case where Id=: cas[0].Id];
        system.assertEquals('changed', result[0].Resolution__c);
    }

}