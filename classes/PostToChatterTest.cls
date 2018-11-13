// activated SeeAllData because ConnectApi methods are not supported in data siloed tests.
// see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_TestingApex.htm
@isTest(SeeAllData=True) 
/**
* Test class for "PostToChatter" on Case object
* @author 		Ezra Kenigsberg
* @date   		2018-08-01
* @ticket link  https://jira.bigcommerce.com/browse/BAP-7803
*/
private class PostToChatterTest {
    static testMethod void postToChatterTest() 
    {
        // create two ea: Accounts, Contacts, Cases
        List<Account> lstAcc = TestDataFactory.createTestAccounts(2, false, RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Contact> lstCon = TestDataFactory.createTestContacts(1, lstAcc); // this creates two Contacts because lstAcc has two records
        List<Case> lstCas = TestDataFactory.createTestCases(1, lstCon); // this creates two Cases because lstCon has two records
        
        Test.startTest();
        // populate the Cases' "Post to Chatter" fields
        for (Case cas : lstCas)
        {
            cas.Post_to_Chatter__c = '<b>check out this bold carriage return!</b>\n' + cas.Id;
        }
        update lstCas;
        Test.stopTest();
        
        // confirm that "Post to Chatter" fields were nulled out
        for (Case cas : [SELECT Id, Post_to_Chatter__c FROM Case WHERE Id in :lstCas])
        {
            System.debug('*** Case: ' + cas);
            System.assertEquals(cas.Post_to_Chatter__c, null);
        }
        
        // confirm that messages were added to the CaseFeed. 
        // I only query the last 2
        for (CaseFeed cf : [SELECT Id, Body, CreatedDate, ParentId
                            FROM CaseFeed
                            WHERE ParentId IN :lstCas
                            ORDER BY CreatedDate DESC
                            LIMIT 2])
        {
			System.debug('*** Here\'s cf: ' + cf.CreatedDate + ',' + cf.ParentId + ',' + cf.Body);
            System.assert(cf.Body.Contains(cf.ParentId));
        }
    }
}