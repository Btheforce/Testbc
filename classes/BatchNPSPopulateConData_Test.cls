@isTest
public class BatchNPSPopulateConData_Test {
    
    public static testmethod void testBacth(){
        //Insert NPS Bundles
        List<NPS_Bundle__c> npsBundleList = NPSBundleHelper.generateNPSBundles();
        //Insert Account and Contact Data
        List<Account> accounts = TestDataFactory.createTestAccounts(1, false, 
                                   RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));		
        List<Contact> contacts = TestDataFactory.createTestContacts(10, accounts);
        //Assign NPS Bundles to Contacts
        NPS_Bundle__c activeBundle = [SELECT Id, Name FROM NPS_Bundle__c WHERE Active__c = true];
        for(Contact cont: contacts){
            cont.NPSRecipient__c = true;
            cont.NPS_Bundle__c = activeBundle.Id;
        }
        update contacts;
        //Insert BI Contact Data
        List<BI_Contact_Data__c> biCons = new List<BI_Contact_Data__c>();
        for(Contact cont : contacts){
            BI_Contact_Data__c biC = new BI_Contact_Data__c(Account__c = cont.accountId, Contact__c = cont.Id, NPS_Recipient__c =false);
            biCons.add(biC);
        }
        insert biCons;
        //Run the scheduler class
       	Test.StartTest();
		BatchNPSPopulateConData_Schedule sh1 = new BatchNPSPopulateConData_Schedule();      
 		String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);
		Test.stopTest();
    }

}