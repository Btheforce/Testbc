/**
 * Test Class to cover BatchNPSBundleDeallocation
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
@isTest(isParallel = true)
public class BatchNPSBundleDeallocationTest {


    @testSetup static void init(){
        
        List<Account> accounts = TestDataFactory.createTestAccounts(1, false, 
                                 RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
		
        List<Contact> contacts = TestDataFactory.createTestContacts(3, accounts);
        
        
      	NPSBundleHelper helper = new NPSBundleHelper();
        
        	NPS_Bundle__c firstbundle = new NPS_Bundle__c();
            firstbundle.Send_Date__c = DateTime.now();
        	firstbundle.Next_Send_Date__c = helper.getValidNpsDateTime(firstbundle.Send_Date__c, 180);
            firstbundle.Size__c = 3;
            firstbundle.Processed__c = 3;
            firstbundle.Failed__c = 0;
        	firstbundle.is_complete__c = true;
        
        	insert firstbundle;
        
        for(contact cont : contacts){
            
            cont.NPS_Bundle__c = firstbundle.Id;
            cont.NPS_Recipient__c = true;
        }
        
        	update contacts;
        
        	NPS_Bundle__c newbundle = new NPS_Bundle__c();
        	newbundle.Send_Date__c = firstbundle.Next_Send_Date__c;
        	newbundle.Next_Send_Date__c = helper.getValidNpsDateTime(newbundle.Send_Date__c, 180);
            newbundle.Size__c = 3;
            newbundle.Processed__c = 0;
            newbundle.Failed__c = 0;
            newbundle.Previous_Bundle__c = firstbundle.Id;
        
        	insert newbundle;
  

    }
    
    @isTest
    static void BundleDeallocationTestOne(){
        
        List<Contact> beforeConts = [select id, nps_bundle__c, nps_bundle__r.Previous_Bundle__c from contact];
        
        Map<Id, Id> mpIds = new Map<Id, Id>();

        for(contact cont : beforeConts){
             
            system.assert(cont.nps_bundle__r.Previous_Bundle__c == null);
            mpIds.put(cont.Id, cont.NPS_Bundle__c);
        }
        
        Test.startTest();
        BatchNPSBundleDeallocation job = new BatchNPSBundleDeallocation();
        Database.executeBatch(job, 200);
        Test.stopTest();
        
        List<Contact> afterConts = [select id, nps_bundle__c, nps_bundle__r.Previous_Bundle__c from contact];
        
        for(contact cont : afterConts){
            system.assert(cont.nps_bundle__r.Previous_Bundle__c != null);
            system.assertEquals(mpIds.get(cont.id), cont.nps_bundle__r.Previous_Bundle__c);
        }
        
    }

}