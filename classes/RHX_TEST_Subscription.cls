/**
 * Refactored RollupHelper API Test class
 * @author Alakh Biniwale
 * @date  07/03/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7498
 */
@isTest(isParallel = true)
public class RHX_TEST_Subscription {
    
    /**
     * Test Class data setup 
     * @author Alakh Biniwale
     * @date  07/03/2018
     */
    @testSetup static void init(){
       
      //create 3 accounts  
      List<Account> lstAccounts = TestDataFactory.createTestAccounts(3, false, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
     
     //create 3 subscription per account -> 9 subscription 
     List<Subscription__c> lstSubs = TestDataFactory.createTestSubscriptions(3, lstAccounts, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Subscription__c.GetSobjectType(), 'MBA_Subscription'));
    }
    
	static testMethod void RHX_Testmethod() {
        
        List<sObject> sourceList = [SELECT Id 
									FROM Subscription__c LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Subscription__c()
            );
        }
        
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}