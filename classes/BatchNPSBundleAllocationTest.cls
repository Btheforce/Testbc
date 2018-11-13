/**
 * Test Class to cover BatchNPSBundleAllocation
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
@isTest(isParallel = true)
public class BatchNPSBundleAllocationTest {


    public static void init(){
        
    	List<NPS_Bundle__c> npsBundleList = NPSBundleHelper.generateNPSBundles();
        
        List<Account> accounts = TestDataFactory.createTestAccounts(1, false, 
                                   RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        for(Account acc :accounts){
            acc.Type = 'Client';
            acc.Client_Start_Date__c = Date.newInstance(System.today().year()-1, System.today().month(), System.today().day());
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

         Integer i=0;
        for(Contact cont :contacts){
            cont.NPSRecipient__c = true;
            if(i<2){
                cont.Next_NPS_Survey_Date__c = System.today();
        		cont.Last_NPS_Survey_Sent_Date__c = Date.newInstance(System.today().year(), System.today().month()-6, System.today().day());
                i++;
          }
        }
        
         update contacts;

    }
    
    @isTest
    static void BundleAllocationTestOne(){
        
        init();
        
        //Selecting net new contacts to be allocated to a NPS Bundle
        String outerQuery =	'SELECT Id, NPS_Bundle__c, Email, Account.Client_Age__c, Do_not_send_NPS_Survey__c, Last_NPS_Survey_Sent_Date__c, Next_NPS_Survey_Date__c, CreatedDate, '
            			+	' MBAClientID__c '
            			+ 	' FROM Contact '
            			+ 	' WHERE NPS_Bundle__c = null '
            			+	' AND NPSRecipient__c = True '
            			+	' AND Do_not_send_NPS_Survey__c != True '
                		+	' AND Email != null '
                		+	' AND (NOT Email  LIKE \'%@bigcommerce.com\') '
                		+	' AND Account.Active_Stores_Opp__c > 0 '
                		+	' AND Account.Active_MRR_Value_Opp__c > 0 '
                		+	' AND Account.Type IN(\'Client\',\'Existing BC Client\') '
            			+	' AND ((Account.Active_Enterprise_Account_Mgmt_Stores__c > 0 AND Account.Client_Age__c >= 180) OR (Account.Active_Enterprise_Account_Mgmt_Stores__c = 0 AND Account.Client_Age__c >= 60)) '
            			+ 	' ORDER BY Account.Client_Age__c DESC LIMIT :dailyLimit ';
        
        Test.startTest();
        BatchNPSBundleAllocation job = new BatchNPSBundleAllocation(outerQuery);
        Database.executeBatch(job, 200);
        Test.stopTest();
    }
    
    @isTest
    static void BundleAllocationTestTwo(){
        
        init();
        
        List<NPS_Bundle__c> npsBundleList = [SELECT Id, Size__c, Limit__c FROM NPS_Bundle__c];
        
        for(NPS_Bundle__c bundle : npsBundleList){
            
            bundle.Size__c = bundle.Limit__c;
        }
        
        update npsBundleList;
        
        Test.startTest();
        BatchNPSBundleAllocation job = new BatchNPSBundleAllocation();
        Database.executeBatch(job, 200);
        Test.stopTest();
    }

}