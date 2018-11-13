/******************************************************************************************************************************
Name:  Professional Opportunity Updates
==============================================================================================================================
Purpose: Perform Professional Opportunity updates.
==============================================================================================================================

History:   

VERSION     AUTHOR              DATE        DETAIL     

1.0     Maggie Frederick        9/1/2013    Initial development
2.0     Maggie Frederick        2/17/2015   Prevent recursive action
3.0     Maggie Frederick        3/17/2015   Store opportunity for PS Opps
4.0     Maggie Frederick        9/27/2015   RemoveConsulting services opps
5.0     Sruthi Kattula          4/2/2018    BAP-6756
6.0		Sruthi Kattula			4/29/2018	BAP-7201 : Logic to add feed comment on opportunity whenever an 
												Onboarding transactional survey is sent out to the designated contact.
7.0		Sruthi Kattula			8/7/2018	BAP-7702
8.0		Sruthi Kattula			9/4/2018	BAP-8019
******************************************************************************************************************************/

public class OpportunityTriggerHandler 
{
    
    private static Id idOppProfessionalServicesRecordType =  RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Professional_Services').Id;
    public Id idOppStorePurchasRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Store_Purchase').Id;

    /**
     * Runs after update for Opportunities
     * @author Steve O'Neal
     * @date   2018-01-15
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-6722
     * @param  OpportunityNewMap New version of opp records
     * @param  OpportunityOldMap Old version of opp records
     * @version 2.0 modified by Sruthi K as part of BAP - 6756
     */
    public void OnAfterUpdate(Map<ID, Opportunity> OpportunityNewMap, Map<ID, Opportunity> OpportunityOldMap)
    {
        System.debug('OpportunityTriggerHandler.OnAfterUpdate:');
        System.debug(OpportunityNewMap);
        Set <Id> closedwonOpps = new Set <Id>();

        for (Opportunity newOpp : OpportunityNewMap.values())
        {
            Opportunity oldOpp = OpportunityOldMap.get(newOpp.Id);
            System.debug(newOpp.IsClosed);
            System.debug(newOpp.IsWon);
            System.debug(newOpp.RecordTypeId == idOppProfessionalServicesRecordType);
            System.debug(oldOpp.StageName);
            System.debug(newOpp.StageName);
            // add for is changed....
            if (newOpp.IsClosed
                && newOpp.IsWon
                && newOpp.RecordTypeId == idOppProfessionalServicesRecordType
                && oldOpp.StageName <> newOpp.StageName)
            {
                closedwonOpps.add(newOpp.Id);
            }
        }

            
        /**
         * Removed logic to create cases and moved to a batch job.
         * @author Steve O'Neal
         * @date   2018-04-06
         * @ticket link              https://jira.bigcommerce.com/browse/BAP-7040
         */
        if (!closedwonOpps.isEmpty() && !TriggerRecursionController.casesCreatedFromPSOpp) 
        {
            OpportunityOperations.createOpportunityCases(closedwonOpps);
            TriggerRecursionController.casesCreatedFromPSOpp = true;
        }

        Set<Id> callCompletedOpps = new Set<Id>();
        for (Opportunity newOpp : OpportunityNewMap.values())
        {
            Opportunity oldOpp = OpportunityOldMap.get(newOpp.Id);
            
            if (
                    (newOpp.IsClosed && !oldOpp.IsClosed)
                    || newOpp.Number_of_Successfully_Completed_Calls__c > oldOpp.Number_of_Successfully_Completed_Calls__c
               )
            {
                callCompletedOpps.add(newOpp.Id);
            }
        }
        
        removeOpportunitiesFromFive9sDialer(callCompletedOpps);



        /**
         * Added functionality to copy the qualifier to the Account
         * @author Steve O'Neal
         * @date   2018-07-03
         * @ticket link              https://jira.bigcommerce.com/browse/BAP-7304
         */
        Set<ID> AccountIds_SalesQualifierNeeded = new Set<ID>();
        for (Opportunity newOpp : OpportunityNewMap.values())
        {
            if (newOpp.Sales_Qualifier__c != null && newOpp.Sales_Qualifier__c != OpportunityOldMap.get(newOpp.Id).Sales_Qualifier__c)
            {
                AccountIds_SalesQualifierNeeded.add(newOpp.AccountId);
            }
        }

        AccountIds_SalesQualifierNeeded.remove(null);

        if (AccountIds_SalesQualifierNeeded.size() > 0)
        {
            List<Account> Accounts_SalesQualifierNeeded = [Select Id, Qualifier__c, Qualified_Date__c from Account where Id = :AccountIds_SalesQualifierNeeded];

            for (Account acct : Accounts_SalesQualifierNeeded)
            {
                for (Opportunity newOpp : OpportunityNewMap.values())
                {
                    if (newOpp.AccountId == acct.Id)
                    {
                        acct.Qualifier__c = newOpp.Sales_Qualifier__c;
                        acct.Qualified_Date__c = Date.today();
                        break;
                    }
                }
            }

            update Accounts_SalesQualifierNeeded;
        }
    }
    
    /***************************************************************************************************************************************
    @author : Sruthi Kattula
    @Date Created : 4/2/2018
    @JIRA : BAP - 6756
    @description : Triggers on AfterUpdate from Opportunity Trigger (Opportunity.apxt)
    @param : new opportunities map, old opportunities map
    @History 
    VERSION     AUTHOR              DATE        DETAIL
    1.0         Sruthi K            4/2/2018    BAP - 6756
    ***************************************************************************************************************************************/
    public void OnAfterUpdateSendEmail(Map<ID, Opportunity> OpportunityNewMap, Map<ID, Opportunity> OpportunityOldMap){
        List<Opportunity> queryForContactOpps = new List<Opportunity>(); 
        
        for (Opportunity newOpp : OpportunityNewMap.values()){
            Opportunity oldOpp = OpportunityOldMap.get(newOpp.Id);
            boolean isNewOppLaunchStatusNull = true;
            boolean isOldOppLaunchStatusNull = true;
            system.debug('oldopp : '+oldOpp);
            system.debug('checking for potential opportunities');
            system.debug('newOpp.Onboarding_Specialist_lookup__c  '+ newOpp.Onboarding_Specialist_lookup__c );
            if(newOpp.recordtypeId == idOppStorePurchasRecordType){
                if(newOpp.status__c!= null && newOpp.status__c.equalsIgnoreCase('Active') && newOpp.Onboarding_Specialist_lookup__c != null ){
                    if(newOpp.launch_status__c != null){
                        isNewOppLaunchStatusNull = false;
                    }
                    if(oldOpp.Launch_Status__c != null){
                        isOldOppLaunchStatusNull = false;
                    }
                    if(isNewOppLaunchStatusNull == false && isOldOppLaunchStatusNull == false){
                        if(newOpp.launch_status__c.equalsIgnoreCase('Launched') && oldOpp.Launch_Status__c != newOpp.launch_status__c){
                            queryForContactOpps.add(newOpp);
                        }
                    }else if(isNewOppLaunchStatusNull == false && isOldOppLaunchStatusNull == true){
                        if(newOpp.launch_status__c.equalsIgnoreCase('Launched')){
                            queryForContactOpps.add(newOpp);
                        }
                    }
                }
            }
        }
       if(queryForContactOpps != null && queryForContactOpps.size() > 0){
           system.debug('calling the sendSurveyToOppContactRoles');
           system.debug('queryForContactOpps : '+queryForContactOpps);
            sendSurveyToOppContactRoles(queryForContactOpps);
       } 
    }


    /**
     * Removes any Five9s dialer records when an Opportunity logs a new call
     * @author Steve O'Neal
     * @date   2018-01-15
     * @ticket link              https://jira.bigcommerce.com/browse/BAP-6722
     * @param  callCompletedOpps List of opp IDs where the successfully completed call list has updated
     */
    private void removeOpportunitiesFromFive9sDialer(Set<Id> callCompletedOpps)
    {
        if (callCompletedOpps.size() > 0)
        {
            List<Five9LSP__Five9_List_Item__c> five9ListItemList = [Select Id, Name, Five9LSP__Opportunity__c from Five9LSP__Five9_List_Item__c where Five9LSP__Opportunity__c = :callCompletedOpps];
            if (five9ListItemList.size() > 0)
            {
                /**
                 * Delete records gracefully - if the record no longer exists, the batch job does not need to fail as a result
                 * @author Steve O'Neal
                 * @date   2018-04-12
                 * @ticket link              https://jira.bigcommerce.com/browse/BAP-6886
                 * @param  callCompletedOpps [description]
                 */
                Database.delete(five9ListItemList, false);
            }
        }
    }
    
    

    /***************************************************************************************************************************************
    @Author : Sruthi Kattula
    @Date Created : 4/2/2018
    @JIRA : BAP - 6756 
    @param : List of opportunities
    @description : Find the designated contact to send the survey email in the following order.
                    1.Search for 'NPS Recipient' contact role. (If there are multiple NPS recipients, pick any one of them )
                    2.If nothing, then search for 'Primary MBA contact Role' (If there are multiple Primary MBA contacts, pick any one of them )
                    3.If nothing, pick the contact which is checked as Primary on the contact Roles
                    4.If nothing, then the designated contact would be with any associated contact role. 
    @History 
    VERSION     AUTHOR              DATE        DETAIL
    1.0         Sruthi K            4/2/2018    BAP - 6756
	2.0 		Sruthi K			4/29/2018	BAP - 7201 : Logic to add feed comment on opportunity whenever an 
												Onboarding transactional survey is sent out to the designated contact.
    ***************************************************************************************************************************************/
    public void sendSurveyToOppContactRoles(List<Opportunity> queryForContactOpps){
        Map<Id,Opportunity> queryForContactOppsMap = new Map<Id,Opportunity>(queryForContactOpps);
        Set<Id>queryForContacts = queryForContactOppsMap.keySet();
        Map<Id,List<Id>> oppConIdMap = new Map<Id,List<Id>>();//Map holding oppIds with List of contactIds
        List<Id>designatedconatctIds = new List<Id>(); //List holding contact Ids to whom the survey email has to be sent
        Map<Id,List<String>>conIdStoreMap = new Map<Id,List<String>>(); //Map holding contact Ids along with the store of stores associated with that contact.
		Map<Id,Id>oppandDesConIdMap = new Map<Id,Id>(); //Map holding Opportunity and its designated contact Id to whom the survey has to be sent out.
        List<OpportunityContactRole> oppcon1 = [Select OpportunityId,contactId,role,IsPrimary From OpportunityContactRole where OpportunityId =: queryForContacts];
        //search associated contact roles an prepare the oppConIdMap
        if(oppcon1 != null && oppcon1.size() > 0){
            for(OpportunityContactRole eachOCR : oppcon1){
                if(oppConIdMap.get(eachOCR.OpportunityId)!=null){
                    List<Id>existConIds = oppConIdMap.get(eachOCR.OpportunityId);
                    existConIds.add(eachOCR.contactId);
                    oppConIdMap.put(eachOCR.OpportunityId,existConIds);
                }else{
                    List<Id>existConIds = new List<Id>();
                    existConIds.add(eachOCR.contactId);
                    oppConIdMap.put(eachOCR.OpportunityId,existConIds);
                }
            }
            system.debug('oppconIdMap : '+ oppConIdMap);
        }
        //retrieving oppcontact roles in each opp
        for(Opportunity eachOpp : queryForContactOpps){
            List<Id> conRelated = oppConIdMap.get(eachOpp.Id);
            boolean contactAdded = false; //boolean variable to make sure only one designated contact is added for every opportunity
            List<opportunityContactRole> OCRList = [select contactId, opportunityId, role, IsPrimary from OpportunityContactRole 
                                                  where opportunityId=: eachOpp.Id and contactId=: conRelated];
            List<Id> NPSIds = new List<Id>(); //List holding contact Ids having 'NPS Recipient' role
            List<Id> PrimaryMBAIds = new List<Id>(); //List holding contact Ids having 'Primary MBA contact' role
            List<Id> PrimaryIds = new List<Id>(); //List holding contact Ids which are primary contacts (IsPrimary = true)
            for(opportunityContactRole eachOCR : OCRList){
                if(eachOCR.Role.equalsIgnoreCase('NPS Recipient') ){
                    NPSIds.add(eachOCR.ContactId);
                    system.debug('NPS Recipient is present and contact Id : '+eachOCR.contactID);
                }else if(eachOCR.Role.equalsIgnoreCase('Primary MBA Contact') ){
                    PrimaryMBAIds.add(eachOCR.ContactId);
                    system.debug('Primary MBA Contact is present and contact Id : '+eachOCR.contactID);
                }else if(eachOCR.IsPrimary ){
                    PrimaryIds.add(eachOCR.ContactId);
                    system.debug('Primary Contact is present and contact Id : '+eachOCR.contactID);
                }
                
                if(conIdStoreMap.get(eachOCR.ContactId)!=null){
                    List<String>existStoreURLs = conIdStoreMap.get(eachOCR.ContactId);
                    existStoreURLs.add(eachOpp.storeURL__c);
                    conIdStoreMap.put(eachOCR.ContactId,existStoreURLs);
                }else{
                    List<String>existStoreURLs = new List<String>();
                    existStoreURLs.add(eachOpp.storeURL__c);
                    conIdStoreMap.put(eachOCR.ContactId,existStoreURLs);
                }
            }
            /***************
                    Find the designated contact to send the survey email in the following order.
                    1. search for 'NPS Recipient' contact role. (If there are multiple NPS recipients, pick any one of them )
                    2. If nothing, then search for 'Primary MBA contact Role' (If there are multiple Primary MBA contacts, pick any one of them )
                    3.If nothing, pick the contact which is checked as Primary on the contact Roles
                    4.If nothing, then the designated contact would be with any associated contact role. 
            ***************/
            if(NPSIds != null && NPSIds.size() > 0 && contactAdded==false){
                designatedconatctIds.add(NPSIds[0]);
                oppandDesConIdMap.put(eachOpp.Id,NPSIds[0]);
                contactAdded = true;
                system.debug('in 1st condition');
            }else if(PrimaryMBAIds != null && PrimaryMBAIds.size() > 0 && contactAdded==false){
                designatedconatctIds.add(PrimaryMBAIds[0]);
                oppandDesConIdMap.put(eachOpp.Id,PrimaryMBAIds[0]);
                contactAdded = true;
            }else if(PrimaryIds != null && PrimaryIds.size() > 0 && contactAdded==false){
                designatedconatctIds.add(PrimaryIds[0]);
                oppandDesConIdMap.put(eachOpp.Id,PrimaryIds[0]);
                contactAdded = true;
                system.debug('in 2nd condition');
            }else if(contactAdded==false){
                List<Id>conIds = oppConIdMap.get(eachOpp.Id);
                designatedconatctIds.add(conIds[0]);
                oppandDesConIdMap.put(eachOpp.Id,conIds[0]);
                contactAdded = true;
                system.debug('in 3rd condition');
            }
        }
        //Send the email to the designated contacts
        if(designatedconatctIds != null && designatedconatctIds.size()>0){
            //send the email 
            List<contact> finalList = [select Id,FirstName,LastName,email from contact where ID=: designatedconatctIds];
            system.debug('final contact List : '+ finalList);
            sendSurveyEmail(finalList,conIdStoreMap,oppandDesConIdMap);
        }
    }    
    
    /***************************************************************************************************************************************
    @author : Sruthi Kattula
    @Date Created : 4/2/2018
    @JIRA : BAP - 6756
    @description : Sending the email to List of contacts using single email messaging
    @param : List of contacts, Map of contact Ids and theor associated store URLs
    @History 
    VERSION     AUTHOR              DATE        DETAIL
    1.0         Sruthi K            4/2/2018    BAP - 6756
	2.0			Sruthi K			4/29/2018	BAP - 7201 : Logic to add feed comment on opportunity whenever an 
												Onboarding transactional survey is sent out to the designated contact.
	3.0 		Sruthi K						BAP - 7702
	4.0			Sruthi K			9/4/2018	BAP-8019	
    ***************************************************************************************************************************************/
    public void sendSurveyEmail(List<contact> conList,Map<Id,List<String>>conIdStoreMap, Map<Id,Id>oppandDesConIdMap){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<FeedItem> postList = new List<FeedItem>();
        Map<Id,String> conIdNameMap = new Map<Id,String>();
        for(contact con : conList){
            List<String> storeURLsL = conIdStoreMap.get(con.Id);
            Set<String> storeURLs = new Set<String>(storeURLsL);
            system.debug('storeURLS : '+ storeURLs);
            if(storeURLs != null && storeURLs.size()>0){
                for(String eachStore : storeURLs){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(con.email);
                    mail.setToAddresses(sendTo);
                    mail.setReplyTo('no-reply@bigcommerce.com'); 
                    mail.setSenderDisplayName('Bigcommerce');
                    //retrieving the email template - 'Onboarding_Specialist_Survey'
                    EmailTemplate[] tpls=[SELECT HtmlValue,Body,Subject FROM EmailTemplate
                                              WHERE DeveloperName = 'Onboarding_Specialist_Survey'];
                    mail.setWhatId(con.Id); //Added by sruthi
                    mail.setSaveAsActivity(false);//Added by sruthi
                    mail.setSubject(tpls[0].subject);
                    //String body = tpls[0].HtmlValue;
                    //body = body.replace(']]>','');
                    //body = body.replace('FirstName', con.FirstName);
                    //body = body.replace('{!Contact.Id}',con.Id);
                    if(Test.isRunningTest()){
                        eachStore = 'testStore'+math.random();
                    }
                    //body = body.replace('StoreURL', eachStore);
                    //START : BAP - 7702 - Sruthi K
                    String pbody = 'Dear '+ con.FirstName +', \n';
                    pbody += 'Thank you for choosing BigCommerce.  In order to continue improving our service and to serve you better in future Implementations, we would appreciate your feedback. \n';
                    pbody += 'We would be so grateful to you if you could complete the 4 question survey (link below) to evaluate your BigCommerce Project Managers service to you for your newly launched store : ';
                    pbody += eachStore + '\n'+'We value your feedback. Thank you, in advance, for helping us grow into a better version of ourselves!';
                    pbody += ' Please click on the below link to take the survey \n';
                    pbody += 'https://bigcommerce.getfeedback.com/r/r3QrmxFD?contact_id='+EncodingUtil.urlEncode(con.Id, 'UTF-8'); 
                    //END : BAP - 7702 - Sruthi K
                    //system.debug('body is : '+ body);
                    //mail.setHtmlBody(body);
                    mail.setPlainTextBody(pbody);
                    mails.add(mail); 
                    conIdNameMap.put(con.Id,con.FirstName+','+con.lastName);
                }
                //preparing the feeditem posts on opportunity
                Set<Id> oppIds = oppandDesConIdMap.keyset();
                List<contact> contactList = [select Id, firstName, lastName from contact where Id=:oppandDesConIdMap.values()];
                for(Id eachOppId : oppIds){
                    //posting to opportunity feed
                    Id conIdDesignated = oppandDesConIdMap.get(eachOppId);
                    String conName = conIdNameMap.get(conIdDesignated);
                    String feedmessage = 'Onboarding Transactional Survey has been sent out to the contact : '+conName;
                    feedmessage += ' for the launch of the store. ';
                    feedmessage += 'Link to view the contact : ';
                    feedmessage += System.URL.getSalesforceBaseURL().toExternalForm()+'/'+conIdDesignated;
                    //BAP - 8019 : Add Link of the surevy to the feed item.
                    feedmessage += ' Link of the survey : ';
                    feedmessage += ' - https://bigcommerce.getfeedback.com/r/r3QrmxFD?contact_id='+EncodingUtil.urlEncode(conIdDesignated, 'UTF-8'); 
                    //Adding a Text post
                    FeedItem post = new FeedItem();
                    post.ParentId = eachOppId; //eg. any recordId or userId where the feed has to be posted.
                    post.Body = feedmessage;
                    postList.add(post);
                }
            }
        }
        if(mails != null && mails.size()>0){
            try{
                system.debug('mails list : '+ mails);
                Messaging.sendEmail(mails);//please set the email deliverability settings to 'all emails' if in case you are tsting from sandbox.
            	system.debug('emails sent');
                insert postList;
            }
            catch(Exception e){
                system.debug('Exception occured while sedning emails to designated contact role\'s email when a store is launched');
            }
        }
    }

    /**
     * Removed logic to set the Opportunity owner to the Account owner.  This is now handled by Distribution Engine.
     * @author Steve O'Neal
     * @date   2017-08-09
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-5980
     */

}