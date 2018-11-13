/**
 * Refactored RollupHelper API Test class
 * @author Alakh Biniwale
 * @date  07/03/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7498
 */
@isTest(isParallel=true)
public class RHX_TEST_Opportunity {
    
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
        
    }
    
	static testMethod void RHX_Testmethod() {
        
        List<sObject> sourceList = [SELECT Id 
                                    FROM Opportunity LIMIT 1];
        
        if(sourceList.size() == 0) {
            
            sourceList.add(
                new Opportunity()
            );
        }
    	
        rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}