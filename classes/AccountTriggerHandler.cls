public class AccountTriggerHandler {
  
    /**
     * Removed all code related to re-assigning opportunity ownership to match the account
     * @author Steve O'Neal
     * @date   2018-01-03
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-6573
     */
    
   	/**
     * @author Alakh Biniwale
     * @date 03/20/2018
     * @description Sync related cases if Enterprise Account Manager
     * 				field is changed/populated.
     * @param Map<Id, Account> contains the Trigger.newMap
     * @param Map<Id, Account> Contains the Trigger.oldMap
     * @ticket	https://jira.bigcommerce.com/browse/BAP-6585
     * @return void
     */
    public static void updateEAMCases(Map<Id, Account> mpNewAccounts, Map<Id, Account> mpOldAccounts){    
        
        Map<Id, Id> mpAccountIdToUserId = new Map<Id, Id>();
        
        for(Account newAccount : mpNewAccounts.values()){
            
            if(newAccount.SSC__c != mpOldAccounts.get(newAccount.Id).SSC__c){
                mpAccountIdToUserId.put(newAccount.Id, newAccount.SSC__c);
            }
        }
        
        if(!mpAccountIdToUserId.isEmpty() && !System.isBatch() && !System.isFuture()){
            
            updateRelatedCases(mpAccountIdToUserId);
        }
        
    }
    
    /**
     * @author Alakh Biniwale
     * @date 03/20/2018
     * @description Used to perform Async update on realted cases
     * @param Set<Id> contains the Account Ids
     * @return void
     */
    @future
    private static void updateRelatedCases(Map<Id, Id> mpAccountIdToUserId){
                
        List<Case> lstCases = new List<Case>([SELECT Id, AccountId, Enterprise_Account_Manager__c 
                                              	FROM Case 
                                              	WHERE AccountId IN :mpAccountIdToUserId.keySet()
                                             		AND Status != 'Closed']);
        
        
        for(Case cs : lstCases){
            cs.Enterprise_Account_Manager__c = mpAccountIdToUserId.get(cs.AccountId);
        }
            
        try{ 
            
            update lstCases;
            
        }catch(DMLException ex){
               
            //Need some better custom logging for future methods
            System.debug('DMLException On Cases AccountTriggerErr:' + ex.getMessage());
        }
        
    }
    /**
     * Changing the interface to accept Account instead of just owner Id to make it consistent with other methods
     * @author Steve O'Neal
     * @date   2017-03-23
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-5277
     * @param
     */
    public static void UpdateContactOwner( Map<Id, Account> mapAccOwner)
    {    
    	List<Contact> cons = new List<Contact>([select Id, OwnerId, AccountId from Contact where  AccountId in :mapaccOwner.KeySet()]);
        List<Contact> updcons = new List<Contact>();  
        
        for (Contact con :cons)
        {
        	if (con.OwnerId <> mapaccOwner.get(con.AccountId).OwnerId)
        	{
        		con.OwnerId = mapaccOwner.get(con.AccountId).OwnerId;
        		system.debug('Contact Owner '+con.OwnerId);
        		updcons.add(con);
        	}
        }
        
        try
        {
            update updcons;
        }
        catch(Exception exc)
        {
           ErrorEmailHelper.notifyOnError('Account Trigger Handler', 'after update', 'Error in Account Trigger Handler - update ', ': update Contact' + cons[0].Id);

           system.debug('***ERROR: AccountTrigger:: ' + exc.getStackTraceString());
        }
    }
}