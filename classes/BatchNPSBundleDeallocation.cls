/**
 * Batch to Remove contacts from NPS Bundle when its no more NPS recipient
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
global class BatchNPSBundleDeallocation implements Database.Batchable<sObject>, Database.Stateful{

    public String query;
    public Integer dailyLimit;
    public Map<Id, Id> mpIds;
    public List<nps_bundle__c> npsNew;

    
    global BatchNPSBundleDeallocation(){
        
    	//get all completed nps
    	npsNew = new List<nps_bundle__c>();
        
		npsNew = [select id, Previous_Bundle__c
              		from nps_bundle__c 
              		where Previous_Bundle__c != null
              		order by send_date__c asc];

        
     	mpIds = new Map<Id, Id>();
        
        for(nps_bundle__c newbundle : npsNew){
            
            mpIds.put(newbundle.Previous_Bundle__c, newbundle.Id);
        }
        
        dailyLimit = (Integer) [SELECT MasterLabel, Batch_Size__c FROM Batch_Apex_Setting__mdt
                           			 WHERE DeveloperName = 'BatchNPSBundleDeallocation'].Batch_Size__c;
        
        
        query = ' select id, nps_bundle__c '
				+ ' from contact ' 
      			+ ' where nps_bundle__c != null limit :dailyLimit';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        
        List<contact> npsConts = new List<contact>();
        
        for(SObject obj : scope){
            
            contact cont = (contact)obj;
            
            if(mpIds.containsKey(cont.nps_bundle__c)){
                
                cont.nps_bundle__c = mpIds.get(cont.nps_bundle__c);            
            	npsConts.add(cont);
            }

        }
        
        update npsConts;
      }
    
    global void finish(Database.BatchableContext bc){
        
    } 
}