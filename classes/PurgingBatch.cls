global class PurgingBatch implements Database.Batchable<sObject>,Database.stateful {
    
    global final string query;
    global Integer successCount;
    global Integer failureCount;
    
    global PurgingBatch (String q){
        query = q;
        successCount=0;
        failureCount=0;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        database.deleteResult[] results = database.delete(scope,false);
        for (Database.deleteResult sr : results) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                successCount++;
            }
            else {
                // Operation failed, so get all errors 
                failureCount++; 
            }
        }
    }

	global void finish(Database.BatchableContext BC){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'bizapps@bigcommerce.com'});
        //mail.setReplyTo('batch@acme.com');
        mail.setSenderDisplayName('Purge Batch Processing');
        mail.setSubject('Batch Process Completed');
        mail.setPlainTextBody('Records Deleted : '+successCount+' and Records Failed : '+failureCount);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }

}