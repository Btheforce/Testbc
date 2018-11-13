@isTest
public class BatchNPSDeduplicateContact_Test {
    
    @testSetup
    static void init(){
        List<Account> accounts = TestDataFactory.createTestAccounts(1, false, 
                                   RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        List<Contact> contacts = TestDataFactory.createTestContacts(5, accounts);
        for(Contact cont :contacts){
            cont.NPSRecipient__c = true;
            cont.NPS_Send_Reminder__c = true;
            cont.Do_not_send_NPS_Survey__c = false; 
            cont.NPS_Reminder_Date__c = DateTime.now();
            cont.Email = 'testbc@bctest.com';
        }
        contacts[4].Email = 'stest@stest.com';
        update contacts;
    }
    
    @isTest
    static void BatchNPSDeduplicateContact_TestOne(){
        Test.startTest();
        BatchNPSDeduplicateContact b = new BatchNPSDeduplicateContact(''); 
		database.executebatch(b,200);
        Test.stopTest();
        AggregateResult[] arList = [select email, count(id) from contact where NPSRecipient__c = true and Do_Not_Send_NPS_Survey__c != true group by email
                                 having count(id)>1 limit 200];
        system.assertEquals(0, arList.size());
    }
}