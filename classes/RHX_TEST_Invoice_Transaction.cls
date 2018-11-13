/**
 * Refactored RollupHelper API Test class
 * @author Alakh Biniwale
 * @date  07/03/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7498
 */
@isTest(isParallel = true)
public class RHX_TEST_Invoice_Transaction {
    
    /**
     * Test Class data setup 
     * @author Alakh Biniwale
     * @date  07/03/2018
     */
    @testSetup static void init(){
        
        //create 3 Accounts
        List<Account> lstAccounts = TestDataFactory.createTestAccounts(3, false, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        //create 3 opps per Account -> total 9 opps
        List<Opportunity> lstOpps = TestDataFactory.createTestOpportunities(3, lstAccounts, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSobjectType(), 'Store_Purchase'));
        
        //create 1 invoice transaction per Opp -> 9 invoice transaction
        List<Invoice_Transaction__c> lstInvTrans = TestDataFactory.createTestInvoiceTransactions(1, lstOpps);
    }
    
	static testMethod void RHX_Testmethod() {
        
        List<sObject> sourceList = [SELECT Id 
                                    FROM Invoice_Transaction__c LIMIT 1];
        
        if(sourceList.size() == 0) {
            sourceList.add(
                new Invoice_Transaction__c()
            );
        }
    	
        rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}