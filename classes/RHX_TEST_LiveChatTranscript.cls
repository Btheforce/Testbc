/**
 * Refactored RollupHelper API Test class
 * @author Alakh Biniwale
 * @date  07/03/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7498
 */
@isTest(isParallel=true)
public class RHX_TEST_LiveChatTranscript {
    
     /**
     * Test Class data setup 
     * @author Alakh Biniwale
     * @date  07/03/2018
     */
    @testSetup static void init(){
        
        //create 1 Accounts
        List<Account> lstAccounts = TestDataFactory.createTestAccounts(1, false, 
                    RecordTypeTools.GetRecordTypeByDeveloperName(Account.GetSObjectType(), 'Client_Record_Type'));
        
        //create 2 conts per Account -> total 2 conts
        List<Contact> lstConts = TestDataFactory.createTestContacts(2, lstAccounts);
        
        //create 2 cases per conts -> total 4 cases
        List<Case> lstCase = TestDataFactory.createTestCases(2, lstConts);
        
        //create 2 transcript per case -> total 8 transcripts
        List<LiveChatTranscript> liveChatTrans = TestDataFactory.createTestLiveChatTranscripts(lstCase, 2);
        
    }
    
	static testMethod void RHX_Testmethod() {
        
        List<sObject> sourceList = [SELECT Id 
                                    FROM LiveChatTranscript LIMIT 1];
        
        if(sourceList.size() == 0) {
            sourceList.add(
                new LiveChatTranscript()
            );
        }
        
    	rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}