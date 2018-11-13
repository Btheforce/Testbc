/**
 * Refactored RollupHelper API Test class
 * @author Alakh Biniwale
 * @date  07/03/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7498
 */
@isTest(isParallel=true)
public class RHX_TEST_BI_Data {   
     /**
     * Test Class data setup 
     * @author Alakh Biniwale
     * @date  07/03/2018
     */
    @testSetup static void init(){
        
        //create 1 Accounts
        List<Account> lstAccounts = TestDataFactory.createTestAccounts(1, false, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        //create 2 opps per Account -> total 2 opps
        List<Opportunity> lstOpps = TestDataFactory.createTestOpportunities(2, lstAccounts, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.GetSobjectType(), 'Store_Purchase'));
        
       //create 2 subscription per account -> 2 subscription 
       List<Subscription__c> lstSubs = TestDataFactory.createTestSubscriptions(2, lstAccounts, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Subscription__c.GetSobjectType(), 'MBA_Subscription'));
        
        //create 2 BIdata per opps and subs -> total 4 
        List<BI_Data__c> lstBIdata = TestDataFactory.createTestBIData(lstOpps, lstSubs, 2);
        
    }
    
	static testMethod void RHX_Testmethod() {
        
        List<sObject> sourceList = [SELECT Id 
                                    FROM BI_Data__c LIMIT 1];
        
        if(sourceList.size() == 0) {
            sourceList.add(
                new BI_Data__c()
            );
        }
        
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}