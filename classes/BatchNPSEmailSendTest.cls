/**
 * Test class to cover BatchNPSEmailSend
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
@isTest
public class BatchNPSEmailSendTest {

    public static void init(){

		List<NPS_Bundle__c> npsBundleList = NPSBundleHelper.generateNPSBundles();
        
        List<Account> accounts = TestDataFactory.createTestAccounts(1, false, 
                                   RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        for(Account acc :accounts){
            acc.Type = 'Client';
        }
        
        update accounts;
        
        List<Opportunity> opps = TestDataFactory.createTestOpportunities(3, accounts, 
                                                                         RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSobjectType(), 'Store_Purchase'));
        for(Opportunity opp :opps){
            opp.Account_Management_Services__c = 'Enterprise Account Management';
            opp.StageName = 'Purchased';
            opp.Status__c = 'Active';
            opp.MonthlyRecurringRevenue__c = 29.99;
            
        }
        
        update opps;
        
		
        List<Contact> contacts = TestDataFactory.createTestContacts(10, accounts);
        
        NPS_Bundle__c activeBundle = [SELECT Id, Name FROM NPS_Bundle__c WHERE Active__c = true];
    
        for(Contact cont :contacts){
            cont.NPSRecipient__c = true;
            cont.NPS_Bundle__c = activeBundle.Id;
            cont.Email = 'testbc@bctest.com';
        }
        
         update contacts;

    }
    
    @isTest
    static void NPSEmailSendTestOne(){
        
        init();
        
        Test.startTest();
        BatchNPSEmailSend job = new BatchNPSEmailSend();
        Database.executeBatch(job, 200);
        Test.stopTest();
    }
    
     @isTest
    static void NPSEmailSendTestTwo(){
        
        init();
        
        String outerQuery =	' SELECT Id, Email, NPS_Bundle__c, NPS_Email_Eligible__c, Last_NPS_Survey_Sent_Date__c, Next_NPS_Survey_Date__c, ' 
            			+ 	' NPS_Reminder_Date__c, Do_not_send_NPS_Survey__c, MBAClientID__c '
            			+ 	' FROM Contact '
            			+ 	' WHERE NPS_Bundle__r.Active__c = true '
                		+	' AND Do_not_send_NPS_Survey__c != true '
            			+	' AND NPSRecipient__c = True '
                		+	' AND Email != null '
                		+	' AND (NOT Email  LIKE \'%@bigcommerce.com\') '
                		+	' AND Account.Active_Stores_Opp__c > 0 '
                		+	' AND Account.Active_MRR_Value_Opp__c > 0 '
                		+	' AND Account.Type IN(\'Client\',\'Existing BC Client\') '
                		+	' Order By createdDate ASC ';
        
        Test.startTest();
        BatchNPSEmailSend job = new BatchNPSEmailSend(outerQuery);
        Database.executeBatch(job, 200);
        Test.stopTest();
    }
    
}