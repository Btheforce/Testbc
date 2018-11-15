/******************************************************************************************************************************
Name:  BatchNPSPopulateConData
==============================================================================================================================
Purpose: Copy NPS_Recipient__c field from BI_Contact_Data__c object onto Contact's NPS_Recipient__c field
==============================================================================================================================

History:   

VERSION     AUTHOR              DATE        DETAIL     
1.0     Sruthi Kattula          10/2/2018    BAP-7937
2.0		Sruthi Kattula			11/8/2018	 To be created
******************************************************************************************************************************/
global class BatchNPSPopulateConData implements Database.Batchable<sObject>, Database.Stateful {
    public String Query;
    public Map<Id,boolean> conIdNPSRecipientMap;
    public Map<Id, String> npsFailedMap;
    public List<Id> npsSuccessList;
    public List<Contact> contactsToBeUpdated;
    public List<BI_Contact_Data__c> biConsToBeUpdated;
    DateTime currTime;
    DateTime prevTime;
    
    global BatchNPSPopulateConData(String Query1){
        if(Query1.equals('')){
            currTime = system.now();
            prevTime = (system.now().addHours(-25));
  			Query ='select Id, Contact__c, NPS_Recipient__c, LastModifiedDate from BI_Contact_Data__c where LastModifiedDate <=: currTime';
            Query +=' and LastModifiedDate >: prevTime';
        }else{
           Query = Query1; 
        }
        system.debug('Query : '+ Query);
        conIdNPSRecipientMap = new Map<Id,boolean>();
        npsFailedMap = new Map<Id, String>();
        contactsToBeUpdated = new List<contact>();
        npsSuccessList = new List<Id>();
        biConsToBeUpdated = new List<BI_Contact_Data__c>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(Query);
    }
    
    global void execute(Database.BatchableContext bc, List<sObject> scope){
        List<BI_Contact_Data__c> biConList = new List<BI_Contact_Data__c>();
        Set<Id> conIdList = new Set<Id>();
        system.debug('Scope Size : '+ scope.size());
        if(scope != null && scope.size() > 0){
            for(sObject s : scope){
                BI_Contact_Data__c eachBCon = (BI_Contact_Data__c)s;
                conIdList.add(eachBCon.Contact__c);
                conIdNPSRecipientMap.put(eachBCon.Contact__c,eachBCon.NPS_Recipient__c);
            }
        }
        
        contactsToBeUpdated = [select Id, NPSRecipient__c, NPS_Bundle__c  from Contact where Id =: conIdList];
        for(Contact eachC : contactsToBeUpdated){
            eachC.NPSRecipient__c = conIdNPSRecipientMap.get(eachC.Id);
            if(conIdNPSRecipientMap.get(eachC.Id) == False){
                eachC.NPS_Bundle__c = null;
            }
        }
        Database.SaveResult[] results = Database.update(contactsToBeUpdated, false);
        for(Integer i=0; i<contactsToBeUpdated.size(); i++){
            Database.SaveResult re = results[i];
            if(!re.isSuccess()){
                Contact failedCont = contactsToBeUpdated[i];
                String ErrorMsg = '';
                for(Database.Error err : re.getErrors()){
                    Errormsg = Errormsg + ' [' + err.getStatusCode() + ' : ' + err.getFields() + ' : ' + err.getMessage() + '] ';
                }
                npsFailedMap.put(failedCont.Id, Errormsg);
            }else{
                npsSuccessList.add(contactsToBeUpdated[i].Id);
            }
        }
    }
    
    global void finish(Database.BatchableContext bc){
        for(Internal_Email_Notification_Setting__mdt internal : [SELECT DeveloperName, Email__c FROM Internal_Email_Notification_Setting__mdt where role__c = 'Developer']){
            Map<String, string> notify = new Map<String, String>();
            notify.put(internal.DeveloperName, internal.Email__c);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(notify.values());
            //String[] toAddresses = new String[] {'sruthi.kattula@bigcommerce.com'};
            //mail.setToAddresses(toAddresses);
            mail.setSubject('NPS BI Contact Data Sync');
            //Converting GMT to local time
            Datetime now = Datetime.now();
            Integer offset = UserInfo.getTimezone().getOffset(now);
            Datetime local = now.addSeconds(offset/1000);
            //Building email body
            String baseBody = ' The batch finished populating : '+ npsSuccessList.size() + ' NPS Recipient Contact Data today at ' + local + '.';
            if(!npsFailedMap.isEmpty()){
                baseBody = baseBody + ' ALERT while processing the batch encountered ' + npsFailedMap.size() + ' DML failuers : ' + '\n' + npsFailedMap;
            }
            mail.setPlainTextBody(baseBody);
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
            }
        }
        
        //Calling Deduplication Batch
        //BatchNPSDeduplicateContact b = new BatchNPSDeduplicateContact(''); 
		//database.executebatch(b);
    }
}