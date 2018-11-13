@isTest
public class BatchNPSRemainderEmailSendTest {

    @testSetup
    static void init(){
        
        List<Account> accounts = TestDataFactory.createTestAccounts(1, false, 
                                   RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        for(Account acc :accounts){
            acc.Type = 'Client';
        }
        
        update accounts;
        
		
        List<Contact> contacts = TestDataFactory.createTestContacts(5, accounts);
    
        for(Contact cont :contacts){
            cont.NPSRecipient__c = true;
            cont.NPS_Send_Reminder__c = true;
            cont.Do_not_send_NPS_Survey__c = false; 
            cont.NPS_Reminder_Date__c = DateTime.now();
            cont.Email = 'testbc@bctest.com';
        }
        
        update contacts;
    }
    
    @isTest
    static void NPSRemainderEmailSendTestOne(){
             
        List<Contact> beforConts = [select NPS_Send_Reminder__c from contact where NPS_Send_Reminder__c = true];
        System.assertEquals(5, beforConts.size());
        
        Test.startTest();
        BatchNPSRemainderEmailSend job = new BatchNPSRemainderEmailSend();
        Database.executeBatch(job, 200);
        Test.stopTest();
        
        //Test to make sure flage is set to flase
        List<Contact> afterConts = [select NPS_Send_Reminder__c from contact where NPS_Send_Reminder__c = false];
        System.assertEquals(3, afterConts.size()); // the reason 3 because 2 out of 5 contact would fail      
    }
    
    @isTest
    static void NPSRemainderEmailSendTestTwo(){
        
        List<Contact> beforConts = [select NPS_Send_Reminder__c from contact where NPS_Send_Reminder__c = true];
        System.assertEquals(5, beforConts.size());
            
    String  outrQuery =	' SELECT Id, Email, NPS_Send_Reminder__c, NPS_Reminder_Date__c, Do_not_send_NPS_Survey__c, MBAClientID__c '
            		+ 	' FROM Contact '
            		+ 	' WHERE NPS_Send_Reminder__c = true '
            		+   ' AND NPS_Reminder_Date__c = Today '
            		+	' AND Do_not_send_NPS_Survey__c != true '
            		+	' AND NPSRecipient__c = True ';
        
        Test.startTest();
        BatchNPSRemainderEmailSend job = new BatchNPSRemainderEmailSend(outrQuery);
        Database.executeBatch(job, 200);
        Test.stopTest();
        
         //Test to make sure flage is set to flase
        List<Contact> afterConts = [select NPS_Send_Reminder__c from contact where NPS_Send_Reminder__c = false];
        System.assertEquals(3, afterConts.size()); // the reason 3 because 2 out of 5 contact would fail   
        
    }
    
    
}