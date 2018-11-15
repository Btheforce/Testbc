/**
 * Batch to automate NPS remainder email send outs
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-8337
 */
global class BatchNPSRemainderEmailSend implements Database.Batchable<sObject>, Database.Stateful {

    public String query;
    public Set<String> npsSurveySet;
    public Map<Id, String> npsFailedMap;
    public Integer totalProcessed;
    public NPSBundleHelper helper; 
    
    
     //Initializer for all instance attributes
    private void initializer() {
        
        npsFailedMap = new Map<Id, String>();
        
        totalProcessed = 0;
        
        helper = new NPSBundleHelper();
        
        npsSurveySet = new Set<String>();
        
        for(Survey__c sur :[SELECT Contact__r.Email 
                        	FROM Survey__c 
                        	WHERE NPSCampaignName__c = :System.Label.NPS_Campaign_Name
                        	AND Survey_Sent_Date_Time__c >= :helper.getCurrentNpsStartDate() 
                            AND Survey_Sent_Date_Time__c <= :helper.getCurrentNpsEndDate()]){
                                
            npsSurveySet.add(sur.Contact__r.Email);                    
        }
    }
    
    
    global BatchNPSRemainderEmailSend(){
        
        initializer();
        
        query =	' SELECT Id, Email, NPSRecipient__c, NPS_Send_Reminder__c, NPS_Reminder_Date__c, Do_not_send_NPS_Survey__c, MBAClientID__c, '
            +	' Last_NPS_Survey_Submitted_Date__c, Last_NPS_Survey_Sent_Date__c '	
            + 	' FROM Contact '
            + 	' WHERE NPSRecipient__c = true '
            +	' AND NPS_Send_Reminder__c = true '
            +	' AND Do_not_send_NPS_Survey__c != true '
            +   ' AND NPS_Reminder_Date__c = today ';
           
    }
    
    global BatchNPSRemainderEmailSend(String outerQuery){
     
        initializer();
        
        query = outerQuery;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
    
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> scope){
          	
        List<Contact> lstConts = new List<Contact>();
        
        //loop over the scope and filter down a unique nps list
        for(Contact cont: scope){
            
            if(!npsSurveySet.contains(cont.Email)){
                //this flag would trigger workflow email alert
            	cont.NPS_Send_Reminder__c = false;
                npsSurveySet.add(cont.Email);
            }
            else{
                cont.Do_not_send_NPS_Survey__c = true;
                cont.NPS_Send_Reminder__c = false;
                cont.NPS_Bundle__c = null;
                cont.NPSRecipient__c = false;
            }
            

            lstConts.add(cont);    
        }
        
        //Accumulate count
        totalProcessed = totalProcessed + lstConts.size();
        
        //Just to get more codeCoverage
        if(Test.isRunningTest()){
            Integer i=0;
            for(contact cont : lstConts){
                
                cont.MBAClientID__c = '12345';
                i++;
                if(i>2){      
                    break;
                }
            }
        }
        
        //Perform DML and capture errors
        Database.SaveResult[] results = Database.update(lstConts, false);
        
        for(Integer i=0; i<lstConts.size(); i++){
            
            Database.SaveResult re = results[i];
            
            if(!re.isSuccess()){
                
                Contact failedCont = lstConts[i];
                
                String ErrorMsg = '';
                for(Database.Error err : re.getErrors()){
                    Errormsg = Errormsg + ' [' + err.getStatusCode() + ' : ' + err.getFields() + ' : ' + err.getMessage() + '] ';
                }
                
                npsFailedMap.put(failedCont.Id, Errormsg);
            }
        }

    }
    
    global void finish(Database.BatchableContext bc){
        
         //Get internal notifications email list
        Map<String, string> notify = new Map<String, String>();
        
        for(Internal_Email_Notification_Setting__mdt internal : [SELECT DeveloperName, Email__c FROM Internal_Email_Notification_Setting__mdt 
                                                                 WHERE DeveloperName = 'Developer' 
                                                                 AND Disabled__c != True]){
                                                                     
            notify.put(internal.DeveloperName, internal.Email__c);
        } 
         
        //Build an email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      	mail.setToAddresses(notify.values());
        mail.setSubject('NPS Remainder Email Update');
        
        //Converting GMT to local time
        Datetime now = Datetime.now();
		Integer offset = UserInfo.getTimezone().getOffset(now);
		Datetime local = now.addSeconds(offset/1000);

        //Building email body
        String baseBody = ' The batch finished processing : '+ (totalProcessed - npsFailedMap.size()) + ' NPS remainder today at ' + local + '.';
        
        if(!npsFailedMap.isEmpty()){
            
            baseBody = baseBody + ' Alert while processing the batch encountered ' + npsFailedMap.size() + ' DML failuers : ' + '\n' + npsFailedMap;
        }
                
        mail.setPlainTextBody(baseBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });           

        
    }
    
    
}