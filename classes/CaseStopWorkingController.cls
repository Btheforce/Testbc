/***************************************************************************************************************************************
@Author : Akhil Midde
@Date Created : 10/19/2017
@JIRA : BAP-5484, BAP-6928, BAP-7410
@description : changing to use cronsights / Removed buttons related code from this class
@invoked by : buttons on case record
@test-class : TestCaseStopWorkingController
@History 
VERSION 	AUTHOR   		DATE       	DETAIL
1.0			Akhil Midde		10/19/2017	BAP-5484,BAP-6928
2.0			Alakh		
3.0			Sruthi K		06/25/2018	BAP-7410
4.0			Sruthi K		07/03/2018	BAP-7523
5.0			Sruthi K		07/30/2018	BAP-7211, BAP-7446
***************************************************************************************************************************************/
public class CaseStopWorkingController 
{
    private static final Id USERID = UserInfo.getUserId();
    private static final User CURUSER = [SELECT Id, Name, UserRole.Name, Profile.Name, Division FROM User WHERE Id = :UserInfo.getUserId()];
    private ApexPages.StandardController controller;
    private boolean showQueueSelection = false;
    private boolean showError = false;
    private final Case thiscase ;
    
    private map<String, QueueSobject> mpQName2Queue
    {
        get
        {
            if (mpQName2Queue == null)
            {
                mpQName2Queue = new map<String, QueueSobject>();
                
                for (QueueSobject q : [SELECT SobjectType, Queue.Name, QueueId, Id 
                                            FROM QueueSobject
                                            WHERE SobjectType = 'Case'
                                            ORDER BY Queue.Name])
                {
                    mpQName2Queue.put(q.Queue.Name, q);
                }
            }
            
            return mpQName2Queue;
        }
        set;
    }
    
    public Case objCase;
    public Id objCaseId;
    
    public boolean getshowQueueSelection()
    {
        return showQueueSelection;
    }
    
    public boolean getshowError()
    {
        return showError;
    }
    
    public string selectedQueue {get; set;} 
    
    public list<SelectOption> lstCaseQueues
    {
        get
        {
            list<SelectOption> lstOpt = new list<SelectOption>();
            lstOpt.add(new SelectOption('', '-- Select Queue --'));
            // Query for the available case queues
            for (QueueSobject q : mpQName2Queue.values())
            {
                lstOpt.add(new SelectOption(q.Queue.Name, q.Queue.Name));
            }
            
            return lstOpt;
        }
    }
    
    public CaseStopWorkingController(ApexPages.StandardController cntrl) 
    {
        controller = cntrl;
        objCaseId = cntrl.getId();
        objCase = (Case)cntrl.getRecord();
        thisCase = [Select Id, Status, RecordTypeId,Origin, RecordType.Name, Escalated_by__c, Design_Escalated_by__c, Design_Approved_by__c, Design_Denied_by__c, Tier_2_Requested_By__c, Manager_Callback_Requestor__c, Owner.Name, Owner.Type from Case where Id = :objCaseId];
        system.debug('case = '+thisCase);
    }
    
    public pageReference setCaseToBilling()
    {
         pageReference pr = new PageReference('/'+objCaseId);  
         objCase.Department__c = 'Billing';
         objCase.Escalation_Date__c = System.now(); 
         Id PartnerRecordType = Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
         if(objCase.RecordTypeId!=PartnerRecordType){
         objCase.RecordTypeId =  Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Billing').getRecordTypeId();
         }
         changeOwner('Billing Queue');
         
         return pr;
    }
    
    //Sruthi K - BAP 7523, BAP 7446
    public pageReference setCaseToAccountServices(){
        pageReference pr = new PageReference('/'+objCaseId);
        objCase.RecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Billing').getRecordTypeId();
        objCase.OwnerId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'account_services_cs'].Id; 
        try{
            // Make sure to set the DML Options to not send any emails
            database.Dmloptions dml = new database.Dmloptions();
            dml.emailHeader.triggerAutoResponseEmail = false;
            dml.emailHeader.triggerUserEmail = false;
            dml.emailHeader.triggerOtherEmail = false;        
            objCase.setOptions(dml);
            update objCase;
        }catch(DmlException ex){
          	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()+' '+'Please Contact Salesforce Administrator.'));
            return null;  
        }   
        return pr;
    }
    
    //Sruthi K - BAP 7211
    public pageReference setCaseToPartnerCommissions(){
        pageReference pr = new PageReference('/'+objCaseId);
        objCase.OwnerId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'Partner_Commission_Case_Queue'].Id;
        objCase.RecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Support').getRecordTypeId();
        try{
            // Make sure to set the DML Options to not send any emails
            database.Dmloptions dml = new database.Dmloptions();
            dml.emailHeader.triggerAutoResponseEmail = false;
            dml.emailHeader.triggerUserEmail = false;
            dml.emailHeader.triggerOtherEmail = false;        
            objCase.setOptions(dml);
            update objCase;
        }catch(DmlException ex){
          	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()+' '+'Please Contact Salesforce Administrator.'));
            return null;  
        }   
        return pr;
    }
    
     public pageReference setCaseToAPI()
    {
         pageReference pr = new PageReference('/'+objCaseId);  
         if (thisCase.Escalated_By__c == null)
         {
             objCase.Escalated_By__c = UserInfo.getName();
             objCase.Escalation_Date__c = System.now(); 
         }
         changeOwner('Support - API');
         return pr;
    }
    
    public pageReference setCaseToTier2()
    {
         pageReference pr = new PageReference('/'+objCaseId);  
         if (thisCase.Tier_2_Requested_By__c == null)
         {
             objCase.Tier_2_Requested_By__c = UserInfo.getName();
             objCase.Tier_2_Request_Date__c = System.now();     
         }
         Id clientSuccessRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Client_Success').getRecordTypeId();
         Id corporateNPSRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Corporate_Merchant_NPS').getRecordTypeId();
         if(thisCase.RecordTypeId == corporateNPSRecTypeId && thisCase.Origin.equalsIgnoreCase('NPS Survey')){ //By Sruthi K - BAP 7410
            objCase.RecordTypeId = clientSuccessRecTypeId;
            objCase.isEscalated = true;
        }
         changeOwner('Support - Tier 2');//BAP 6298 Change in queue name by Akhil on 10-25-2017 
         return pr;
    }
    
    public pageReference setCaseToSupport()
    {
         pageReference pr = new PageReference('/'+objCaseId);  
         Id PartnerRecordType = Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
         if(objCase.RecordTypeId!=PartnerRecordType){
         objCase.RecordTypeId =  Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Client Success').getRecordTypeId();
         }
          objCase.Department__c = 'Support';
         changeOwner('Support'); 
         return pr;
    }
    
     public pageReference setCaseToCancel()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         objCase.Department__c = 'Cancellations';
         objCase.RecordTypeId =  Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Cancellations').getRecordTypeId();
         changeOwner('Cancellation Queue');
          return pr;
    }
     
     public pageReference setCaseToTrash()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         objCase.Do_Not_Send_Survey__c = true;
         objCase.RecordTypeId =  Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Trash').getRecordTypeId();
         changeOwner('Support - Trash');
          return pr;
    }
  
    public pageReference setCaseToCallbackDesign()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         changeOwner('Support - Design Callback');
         return pr;
    }
    
    public pageReference setCaseToEscalated1()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         if (thisCase.Escalated_By__c == null)
         {
             objCase.Escalated_By__c = UserInfo.getName();
             objCase.Escalation_Date__c = System.now(); 
         }
         Id PartnerRecordType = Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
         if(objCase.RecordTypeId!=PartnerRecordType){
         objCase.RecordTypeId =  Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Client Success').getRecordTypeId();
         }
         objCase.Department__c = 'Support';
         objCase.Escalated__c = true;
         changeOwner('Support - Escalated Level 1');
          return pr;
    }
    
    public pageReference setCaseToPartnerCaseQueue()
    {
		 pageReference pr = new PageReference('/'+objCaseId);  
        objCase.RecordTypeId =  Case.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Partner Support').getRecordTypeId();
		 changeOwner('Partner Case Queue');
		 return pr;
    }
    
     public pageReference setCaseToLegal()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         objCase.Do_Not_Send_Survey__c = true;
         objCase.Department__c = 'Legal/Abuse';
         changeOwner('Support - Legal/Abuse');
         return pr;
    }
    
     public pageReference setCaseToMgrCallback()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         if (thisCase.Manager_Callback_Requestor__c == null)
         {
            objCase.Manager_Callback_Requestor__c = UserInfo.getName();
            objCase.Manager_Callback__c = true;
            objCase.Manager_Callback_Date__c = System.Now();    
         }
         changeOwner('Support - Manager Callback');
         return pr;
    }
    
    //Added by Alakh BAP-7200
    public pageReference setCaseToBillingMgrCallback(){
        pageReference pageRef = new PageReference('/'+objCaseId);
        objCase.RecordTypeId = RecordTypeTools.GetRecordTypeByDeveloperName(Case.getSObjectType(), 'Billing').Id;
        objCase.OwnerId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'Billing_Manager_Callback'].Id; 
        try{
           update objCase;
        }catch(DmlException ex){
          	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()+' '
                                                       +'Please Contact Salesforce Administrator.'));
            return null;  
        }   
       return pageRef;
    }
 
    public pageReference setCaseTier2Actions()
    {
         pageReference pr = new PageReference('/'+objCaseId);    
         objCase.Tier_2_Requested_By__c = thisCase.Owner.Name;
         objCase.Tier_2_Agent__c = UserInfo.getName();
         objCase.Tier_2_Request_Date__c = System.now();
         
         // Make sure to set the DML Options to not send any emails
                        database.Dmloptions dml = new database.Dmloptions();
                        dml.emailHeader.triggerAutoResponseEmail = false;
                        dml.emailHeader.triggerUserEmail = false;
                        dml.emailHeader.triggerOtherEmail = false;
         list<Case> lstCaseToUpdate = new list<Case>();
                        objCase.setOptions(dml);
                        system.debug(' *** testing  '+objCase.Tier_2_Requested_By__c);
                        lstCaseToUpdate.add(objCase);
                        database.update(lstCaseToUpdate, dml);
         return pr;
    }
    
    public void changeOwner(String SelectedQueue){ 
        StaticVariables.caseOwnerButtonUpdate = true;
        system.debug('***CaseStopWorkingController:changeOwner - objCaseId: ' + objCaseId);
        boolean updateCase = false;
        // Ensure a case exists
        if (objCaseId != null){
          	updateCase = true;
            // Check if user selected a queue
            if (selectedQueue != null && mpQName2Queue.containsKey(selectedQueue)){
                system.debug('***CaseStopWorkingController:changeOwner - user selected Queue');
                objCase.OwnerId = mpQName2Queue.get(selectedQueue).QueueId;         
                CaseOwnerQueue__mdt caseOwner = [select ChangeOwner_Value__c, Queue_Name__c from CaseOwnerQueue__mdt where Queue_Name__c =:SelectedQueue limit 1];
                objCase.Change_Owner__c= caseOwner.ChangeOwner_Value__c;
                updateCase = true;
            }else{
                system.debug('***CaseStopWorkingController:changeOwner - User not previously with queue and no queue selected');
            }         
         }
         if (updateCase){
            try{
                system.debug('***CaseStopWorkingController: - Updating Case');                      
                // Make sure to set the DML Options to not send any emails
                database.Dmloptions dml = new database.Dmloptions();
                dml.emailHeader.triggerAutoResponseEmail = false;
                dml.emailHeader.triggerUserEmail = false;
                dml.emailHeader.triggerOtherEmail = false;        
                list<Case> lstCaseToUpdate = new list<Case>();
                objCase.setOptions(dml);
                lstCaseToUpdate.add(objCase);
                database.update(lstCaseToUpdate, dml); 
            }catch(Exception exc){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error, 'An error occurred returing Case to Queue....Please contact your support department');
                ApexPages.addMessage(myMsg);
                system.debug('***ERROR: CaseStopWorkingController:changeOwner: ' + exc.getStackTraceString());
            }
        }
    }
}