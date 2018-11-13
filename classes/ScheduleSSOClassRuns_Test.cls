/**
 * ScheduleSSOClassRuns_Test
 * Author: Bala Rajagopal
 * Purpose: Test class to run all SSO related controllers 
 * regularly toavoid cache clearing issues that results in 
 * slow performance and response times
 */
@isTest()
public class ScheduleSSOClassRuns_Test {
    
    static testmethod void testschedule() {
	/**
     * Remove See All Data and created data for the test class
     * @author Bala Rajagopal
     * @date   2018-05-13
     * @ticket link    https://jira.bigcommerce.com/browse/BAP-7275
     **/                
      List<Account> Accounts = new List<Account>(TestDataFactory.createTestAccounts(1, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type')));
      List<Subscription__c> Subscriptions = new List<Subscription__c>(TestDataFactory.createTestSubscriptions(1, Accounts, RecordTypeTools.GetRecordTypeByDeveloperName(Subscription__c.GetSObjectType(), 'MBA_Subscription')));
        Subscription__c sub = Subscriptions[0];
        sub.ProductID__c = '119';
        update sub;
      List<Contact> Contacts = new List<Contact>(TestDataFactory.createTestContacts(1, Accounts));
        Contact con = Contacts[0];
        con.email = 'shcedulerun@testschedulerun123.com';
        con.LastName = '9988334455';
        con.Type__c = 'Add On';
        update con;
      List<Opportunity> Opportunities = new List<Opportunity>(TestDataFactory.createTestOpportunities(1, Accounts, RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSObjectType(), 'Store_Purchase')));
        Opportunity opp = Opportunities[0];
        opp.Amount = 100;
        opp.Status__c = 'Active';
        opp.Product__c = 'Test Pro Plan';
        opp.StoreURL__c = 'teststore1.com';
        opp.TemporaryStoreURL__c = 'store-teststore1.mybigcommerce.com';
        update opp;  
        Test.StartTest();
            ScheduleSSOClassRuns.RunSSOClassesEveryHr();
        Test.stopTest();
    }
}