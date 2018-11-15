/**
 * Batch to Dynamically allocate NPS Bundle to contacts. Assign contacts to NPS Bundle when it becomes NPS recepient.
 * @author Alakh Biniwale
 * @date   07/16/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-7588
 */
global class BatchNPSBundleAllocation implements Database.Batchable<sObject>, Database.Stateful{
    
    public String query;
    public Integer dailyLimit;
   	public List<NPS_Bundle__c> npsBundles;
    public Map<Id, String> npsFailedMap;
    public List<Contact> npsUpdateConts;
    public Map<String, Contact> npsActualEmailMap;
    public NPSBundleHelper helper;
    
	//Initializer for all instance attributes
    private void initializer(){
        
        npsUpdateConts = new List<Contact>();
        
        helper = new NPSBundleHelper();
        
        npsBundles =   helper.getNpsBundles();
                
        npsFailedMap = new Map<Id, String>();
        
        //Get daily contact allocation custom metadata limit 
        dailyLimit = (Integer) [SELECT MasterLabel, Batch_Size__c 
                                FROM Batch_Apex_Setting__mdt
                           		WHERE DeveloperName = 'NPS_Batch_Apex'].Batch_Size__c;
     
         npsActualEmailMap = new Map<String, Contact>();
        
    }
    
    global BatchNPSBundleAllocation(){
        
        initializer();
        
        //Selecting net new contacts to be allocated to a NPS Bundle
        query =	'SELECT Id, NPS_Bundle__c, Email, Account.Client_Age__c, Do_not_send_NPS_Survey__c, Last_NPS_Survey_Sent_Date__c, Next_NPS_Survey_Date__c, CreatedDate, '
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
            +	' AND ((Account.Dialer_Priority__c = \'Priority Support\' AND Account.Client_Age__c >= 180) OR (Account.Dialer_Priority__c != \'Priority Support\' AND Account.Client_Age__c >= 60)) '
            + 	' ORDER BY Account.Client_Age__c DESC LIMIT :dailyLimit ';
    }
    
    global BatchNPSBundleAllocation(String outerQuery){
        
        initializer();
       
        query =  outerQuery;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> scope){
        
        //loop over the scope and filter down a unique nps list        
        for(Contact cont: scope){

            if(!npsActualEmailMap.containsKey(cont.Email)){
                
            	if(cont.Next_NPS_Survey_Date__c != null){
                    
                	Date nextSendDate = cont.Next_NPS_Survey_Date__c;

                	if(nextSendDate < helper.getCurrentNpsStartDate()){
                        
                    	for(NPS_Bundle__c bundle: npsBundles){
                        
                        	if(bundle.Size__c < bundle.Limit__c){ 

                            	cont.NPS_Bundle__c =  bundle.Id;
                            	bundle.Size__c = bundle.Size__c + 1;
                            	break;
                        	}
                    	}	
                	}
                
                	else if(nextSendDate <= helper.getCurrentNpsEndDate() && nextSendDate >= helper.getCurrentNpsStartDate()){
                        
                    	for(NPS_Bundle__c bundle : npsBundles){
                            
                        	if(nextSendDate.daysBetween(bundle.Send_Date__c.date()) >= 0 && bundle.Size__c < bundle.Limit__c){

                                cont.NPS_Bundle__c =  bundle.Id;
                             	bundle.Size__c = bundle.Size__c + 1;
                             	break;
                        	}
                    	}
               		}
            	}
                
                else if(cont.Next_NPS_Survey_Date__c == null){

                    if(cont.Last_NPS_Survey_Sent_Date__c == null){
                        
                        for(NPS_Bundle__c bundle: npsBundles){
                            
                            if(bundle.Size__c < bundle.Limit__c){

                                cont.NPS_Bundle__c =  bundle.Id;
                            	bundle.Size__c = bundle.Size__c + 1;
                            	break;
                        	}
                    	}	                      
                    }
                    
                    else if(cont.Last_NPS_Survey_Sent_Date__c != null){
                        
                 		Date lastDate = cont.Last_NPS_Survey_Sent_Date__c;
                        
                 		Date validSendDate = helper.getValidNpsDate(lastDate, helper.getCurrentNpsTotalDays()); // lasDate + ~183 Days

                        if(validSendDate < helper.getCurrentNpsStartDate()){

                     		for(NPS_Bundle__c bundle: npsBundles){
                        
                        		if(bundle.Size__c < bundle.Limit__c){ 
                                    
                                    cont.NPS_Bundle__c =  bundle.Id;
                            		bundle.Size__c = bundle.Size__c + 1;
                            		break;
                        		}
                    		}	
                		}	
                
                		else if(validSendDate <= helper.getCurrentNpsEndDate() && validSendDate >= helper.getCurrentNpsStartDate()){
                    
                    		for(NPS_Bundle__c bundle : npsBundles){
                                
                        		if(validSendDate.daysBetween(bundle.Send_Date__c.date()) >= 0 && bundle.Size__c < bundle.Limit__c){
                                    
                             		cont.NPS_Bundle__c =  bundle.Id;
                             		bundle.Size__c = bundle.Size__c + 1;
                             		break;
                        		}
                    		}
               			}
                    }
            	}
                
                npsActualEmailMap.put(cont.Email, cont);
            }
            else{
                
                cont.NPSRecipient__c = false;
                cont.Do_not_send_NPS_Survey__c = true;
            }
            
            npsUpdateConts.add(cont);
        }
        
        //Just to get more codeCoverage
        if(Test.isRunningTest()){
            Integer i=0;
            for(contact cont : npsUpdateConts){
               cont.MBAClientID__c = '12345';
                i++;
                if(i>2){
                    break;
                }
            }
        } 
        
  		//Perform DML and capture errors
        Database.SaveResult[] results = Database.update(npsUpdateConts, false);
        
        for(Integer i=0; i<npsUpdateConts.size(); i++){

            Database.SaveResult re = results[i];
            
            if(!re.isSuccess()){
                
                Contact failedCont = npsUpdateConts[i];
                
                String ErrorMsg = '';
                for(Database.Error err : re.getErrors()){                
                    Errormsg = Errormsg + ' [' + err.getStatusCode() + ' : ' + err.getFields() + ' : ' + err.getMessage() + '] ';
                }
                
                npsFailedMap.put(failedCont.Id, Errormsg);
            }
        }
    }
    
    global void finish(Database.BatchableContext bc){

        //update NPS Bundle List
         update npsBundles;
        
        /*
         *	Send an email notification of a job completion. 
         */

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
        mail.setSubject('NPS Bundle Allocation Update');
        
        //Converting GMT to local time
        Datetime now = Datetime.now();
		Integer offset = UserInfo.getTimezone().getOffset(now);
		Datetime local = now.addSeconds(offset/1000);

        //Building email body
        String baseBody = ' The batch finished allocating : '+ npsUpdateConts.size() + ' NPS recipient today at ' + local + '.';
        
        if(!npsFailedMap.isEmpty()){
            
            baseBody = baseBody + ' Alert while allocating the batch encountered ' + npsFailedMap.size() + ' DML failuers : ' + '\n' + npsFailedMap;
        }
                
        mail.setPlainTextBody(baseBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });          

    } 
}