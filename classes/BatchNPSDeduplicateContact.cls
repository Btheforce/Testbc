/******************************************************************************************************************************
Name:  BatchNPSDeduplicateContact
==============================================================================================================================
Purpose: Deduplicate the contacts if they have same email in one or more contacts by tagging the rest as Do_Not_Send_NPS_Survey__C = false
==============================================================================================================================

History:   

VERSION     AUTHOR              					DATE        DETAIL     
1.0     	Sruthi Kattula/ Bala Rajagopal          11/8/2018   https://jira.bigcommerce.com/browse/BAP-8462
******************************************************************************************************************************/
global class BatchNPSDeduplicateContact implements Database.Batchable<sObject>, Database.Stateful{
    public String Query; 
    public Set<String> uniqueEmailIdsSuperSet; 
	public Map<Id, String> npsDedupeFailedMap;
    public Integer npsSuccesListSize;
    
    global BatchNPSDeduplicateContact(String Query1){

        uniqueEmailIdsSuperSet = new Set<String>();
        npsDedupeFailedMap = new Map<Id, String>();
        npsSuccesListSize = 0;
        AggregateResult[] arList = [select email, count(id) from contact where NPSRecipient__c = true and Do_Not_Send_NPS_Survey__c != true AND email !=null 
                                    group by email having count(id)>1 limit 200];
        for(AggregateResult ar : arList ){
            uniqueEmailIdsSuperSet.add(ar.get('email').toString());
        }
        if(Query1.equals('')){
            Query ='select Id, Email, NPSRecipient__c, Do_Not_Send_NPS_Survey__c, Last_NPS_Survey_Sent_Date__c  from contact where email IN :  uniqueEmailIdsSuperSet'; 
              Query +=  ' order by Email,Last_NPS_Survey_Sent_Date__c desc nulls last ';
        }
        else{
            Query = Query1;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        Set<String> npsEmailsSet = new Set<String>();
        List<Contact> deactivateNPS = new List<Contact>();
        if(scope != null && scope.size() > 0){
            for(sObject s : scope){
                Contact eachCon = (Contact)s;
                if(npsEmailsSet.contains(eachCon.email)){
                    eachCon.NPSRecipient__c = false;
                    eachCon.Do_not_send_NPS_Survey__c = true;
                    deactivateNPS.add(eachCon);
                }else{
                    npsEmailsSet.add(eachCon.email);
                }
            }
        }
        
        if(deactivateNPS != null && deactivateNPS.size()>0){
            Database.SaveResult[] results = Database.update(deactivateNPS, false);
            for(Integer i=0; i<deactivateNPS.size(); i++){
            	Database.SaveResult re = results[i];
            	if(!re.isSuccess()){
                	Contact failedCont = deactivateNPS[i];
                	String ErrorMsg = '';
                	for(Database.Error err : re.getErrors()){
                    	Errormsg = Errormsg + ' [' + err.getStatusCode() + ' : ' + err.getFields() + ' : ' + err.getMessage() + '] ';
                	}
                	npsDedupeFailedMap.put(failedCont.Id, Errormsg);
                }else{
                    npsSuccesListSize += 1;
                }
         	}
        }
    }
    
    global void finish(Database.BatchableContext bc){        
        AggregateResult[] arList = [select email, count(id) from contact where NPSRecipient__c = true and Do_Not_Send_NPS_Survey__c != true group by email
                                 having count(id)>1 limit 200];
        if(arList.size()>0){
            BatchNPSDeduplicateContact b = new BatchNPSDeduplicateContact(''); 
			database.executebatch(b);
        } else {
            for(Internal_Email_Notification_Setting__mdt internal : [SELECT DeveloperName, Email__c FROM Internal_Email_Notification_Setting__mdt where role__c = 'Developer']){
                Map<String, string> notify = new Map<String, String>();
                notify.put(internal.DeveloperName, internal.Email__c);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(notify.values());
                //String[] toAddresses = new String[] {'sruthi.kattula@bigcommerce.com'};
                //mail.setToAddresses(toAddresses);
                mail.setSubject('NPS Deduplication Batch');
                //Converting GMT to local time
                Datetime now = Datetime.now();
                Integer offset = UserInfo.getTimezone().getOffset(now);
                Datetime local = now.addSeconds(offset/1000);
                //Building email body
                String baseBody = ' The batch finished Deduplicating : '+ npsSuccesListSize + ' NPS Recipient Contacts Data today at ' + local + '. Query used : '+ Query;
                if(!npsDedupeFailedMap.isEmpty()){
                    baseBody = baseBody + '\n ALERT while processing the batch encountered ' + npsDedupeFailedMap.size() + ' DML failuers : ' + '\n' + npsDedupeFailedMap;
                }
                mail.setPlainTextBody(baseBody);
                if(!Test.isRunningTest()){
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
                }
            } 
        }
    }
}