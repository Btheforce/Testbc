public without sharing class Lead_TriggerHandler {

    public static void updateSubAccountandContact(Map<Id,Lead> mpLeadIdToLead)
    {
      system.debug('Inside updateAccountandContact Method'+mpLeadIdToLead);
      // Map to hold LeadId and Subscription.
      // List to hold Account to Update.
      List<Subscription__c> lstsub = new List<Subscription__c>();
        
      for(Subscription__c sub:[SELECT Id,Lead__c, OwnerId FROM Subscription__c WHERE Lead__c IN : mpLeadIdToLead.keyset()])
      {
        Lead clead = mpLeadIdToLead.get(sub.Lead__c);
        sub.Contact__c = cLead.ConvertedContactId;
        sub.Account__c = cLead.ConvertedAccountId;
 
        lstsub.add(sub);
      }

      system.debug('Subscription Data Need to update'+lstsub);

      if(!lstsub.isEmpty())
      {
        SObjectUtils.ManualLeadConvert = true;
        try
        {
          Update(lstsub);
        }
        catch(Exception exc)
        {
           system.debug('***ERROR: LeadTrigger:update Sub: ' + exc.getStackTraceString());
        }
        SObjectUtils.ManualLeadConvert = false;
      }
    }   



    /**
     * Creates a partner case for duplicate leads
     * @author Steve O'Neal
     * @date   2016-11-21
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-4221
     * @param  leads      The list of leads that require a case
     */
    public static void CreateDuplicatePartnerCases(list<Lead> leads)
    {
      System.debug('Creating duplicate partner cases');
      List<Case> casesToCreate = new List<Case>();

      // all duplicate lead cases go to partner support for now, and will be assigned to the Channel Account Manager (CAM) associated with the Partner's RV Account
      Schema.RecordType partnerCaseRecordType = RecordTypeTools.GetRecordTypeByDeveloperName(Case.getSObjectType(), 'Partner_Support');

      // get the Partner RV Accounts
      List<string> rvAccountIds = new List<string>();
      for (Lead dupeLead : leads)
      {
          rvAccountIds.add(dupeLead.rvpe__RVAccount__c);
      }

      // create a map of the related RV Accounts and their owner id
      Map<Id, rvpe__RVAccount__c> rvAccounts = new Map<Id, rvpe__RVAccount__c>([Select Id, Name, OwnerId from rvpe__RVAccount__c where Id in :rvAccountIds]);


      // loop through the leads and create a case for each
      for (Lead dupeLead : leads)
      {
          rvpe__RVAccount__c RVAccount = rvAccounts.get(dupeLead.rvpe__RVAccount__c);

          Case newPartnerCase = new Case();
          newPartnerCase.RecordTypeID = partnerCaseRecordType.Id;
          newPartnerCase.Subject = 'Duplicate Lead Registered by ' + RVAccount.Name;
          newPartnerCase.OwnerId = RVAccount.OwnerId;
          newPartnerCase.rvpe__RVAccount__c = RVAccount.Id;
          newPartnerCase.rvpe__RVMember__c = dupeLead.rvpe__RVMember__c;
          newPartnerCase.Origin = 'Partner Deal Registration';
          newPartnerCase.Status = 'New';
          newPartnerCase.Reason = 'Deal Registration';
          newPartnerCase.Reason_Code__c = 'Duplicate';
          newPartnerCase.Lead__c = dupeLead.Id;
          newPartnerCase.Description = 'The attached partner created a lead which duplicates a lead or contact in our system.  The following record(s) have the same email address:\n' + dupeLead.Duplicate_of__c;
          newPartnerCase.Description += '\n\nPlease determine if the newly created lead is a valid registration and respond to the partner.';

          casesToCreate.add(newPartnerCase);
      }

      if (casesToCreate.size() > 0)
      {
          System.debug('Inserting cases');
          System.debug(casesToCreate);
          // create the cases
          insert casesToCreate;
      }
    }


    public static void checkForDuplicates(List<Lead> newLeads)
    {
      Duplicate_Record_Handling__c duplicateSettings = Duplicate_Record_Handling__c.getinstance();
      System.debug(duplicateSettings);


      Set<String> setLeadEmail = new Set<String>();
      Set<String> setLeadPhone = new Set<String>();
    
      for ( Lead objLead : newLeads){ 
        // Fetch the Email, needed for SOQL
        if (objLead.Email <> null ) setLeadEmail.add(objLead.Email);
        if (objLead.Phone <> null) setLeadPhone.add(objLead.Phone);
      }

      Map<String, Account> mapAccount = new Map<String, Account>();
      // Create a map of Email, Contact
      Map<String, List<Contact>> mapContact = new Map<String, List<Contact>>();
      Map<String, Contact> mapPhoneContact = new Map<String, Contact>();
    
      for(Contact c : [SELECT Id, email,OwnerId, Phone FROM Contact WHERE email in :setLeadEmail AND IsDeleted = false ORDER BY CreatedDate DESC])
      {
        if (c.Email != null)
        {
          if (!mapContact.containsKey(c.Email))
          {
            mapContact.put(c.Email, new List<Contact>());
          }
          mapContact.get(c.email).add(c);
        }

        if (c.Phone != null)
        {
          mapPhoneContact.put(c.Phone, c);
        }
      }

      //Create a map of Email, Lead
      Map<String, List<Lead>> mapLead = new Map<String, List<Lead>>();
      Map<String, Lead> mapPhoneLead = new Map<String, Lead>();
      for(Lead l : [SELECT Id, email, Phone FROM Lead WHERE isConverted = false and (email in :setLeadEmail or phone in :setLeadPhone)]){
        if (l.Email <> null)
        {
          if (!mapLead.containsKey(l.Email))
          {
            mapLead.put(l.Email, new List<Lead>());
          }
          mapLead.get(l.Email).add(l);
        }

        if (l.Phone <> null) 
        {
          mapPhoneLead.put(l.phone, l);
        }
      }


      boolean TriggeredByAPIUser = false;
  
      for(Lead l : newLeads)
      {
        if (l.Duplicate_of__c == null)
        {
          l.Duplicate_of__c = '';
        }

        // Check if Email is present in map
        if(mapContact.containsKey(l.Email) )
        {
          System.debug('Found duplicate contact');
          if (duplicateSettings.Lead_Duplicate_create_case__c)
          {
            /**
             * When the Treehouse user inserts a duplicate lead, add URLs for the existing records into the lead details.
             * These will be used when creating a case for account managers to resolve the duplicate
             * @author Steve O'Neal
             * @date   2016-11-21
             * @ticket link       https://jira.bigcommerce.com/browse/BAP-4451
             */
            for (Contact dupeContact : mapContact.get(l.Email))
            {
              l.Duplicate_of__c += URL.getSalesforceBaseUrl().toExternalForm() + '/' + dupeContact.Id + '\n';
              System.debug('Adding duplicate contact info');
            }
          }
          
          if (duplicateSettings.Lead_Duplicate_flag_Is_Duplicate__c)
          {
            l.is_Duplicate__c = true;
          }
          
          if (duplicateSettings.Lead_Duplicate_throw_error__c && String.isNotBlank(duplicateSettings.Lead_Duplicate_error_message__c) && !Test.isRunningTest())
          {
            l.Email.addError(duplicateSettings.Lead_Duplicate_error_message__c);
          }
        }
        //Check if Email is present in map
        else if(mapLead.containsKey(l.Email) && !l.isConverted)
        {
          System.debug('Found duplicate lead');
          for (Lead dupeLead : mapLead.get(l.Email))
          {
            if (dupeLead.Id <> l.Id)
            {
              system.debug('*** Test'+userinfo.getLastName());
              if (duplicateSettings.Lead_Duplicate_create_case__c)
              {
                /**
                 * When the Treehouse user inserts a duplicate lead, add URLs for the existing records into the lead details.
                 * These will be used when creating a case for account managers to resolve the duplicate
                 * @author Steve O'Neal
                 * @date   2016-11-21
                 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4451
                 */
                l.Duplicate_of__c += URL.getSalesforceBaseUrl().toExternalForm() + '/' + dupeLead.Id + '\n';
                System.debug('Adding duplicate lead info');
              }
              
              if (duplicateSettings.Lead_Duplicate_flag_Is_Duplicate__c)
              {
                l.is_Duplicate__c = true;
              }

              if (duplicateSettings.Lead_Duplicate_throw_error__c && String.isNotBlank(duplicateSettings.Lead_Duplicate_error_message__c) && !Test.isRunningTest())
              {
                // standard duplicate error messaging
                l.Email.addError(duplicateSettings.Lead_Duplicate_error_message__c);
              }

            }
          }
        }
        if(mapPhoneLead.containsKey(l.Phone) && mapPhoneLead.get(l.Phone).Id <> l.Id)
        {
          system.debug('*** Test'+userinfo.getLastName());
          
          l.phone_match__c = true;
        }

        if (l.Duplicate_of__c.length() > 255)
        {
          l.Duplicate_of__c = l.Duplicate_of__c.left(250) + ' ...';
        }

      }

      System.debug(newLeads);
    }
    
    public static void changeLeadOwner(List<Lead> newList, List<Lead> oldList)
    {
    Map<Id,Id> mapLeadOwner = new Map<Id,Id>(); 
    for (integer i =0; i < newList.size(); i++)
        {
        if (newList[i].Take_Ownership__C && !oldList[i].Take_Ownership__C)
        {
             if (newList[i].OwnerId <> Label.Lead_Default_Owner)
              {
                newList[i].Take_Ownership__C.addError('Not allowed to change owner.');
                
              }
              else 
                {
                  mapLeadOwner.put(newList[i].Id, UserInfo.getuserId());
             }
         }
    }
    changeOwner(mapLeadOwner);
    }
  
  @future
    public static void changeOwner(Map<Id,Id> mapLeadOwner)
    {
    List<Lead> updLeads = new List<Lead>(); 
    for ( Lead obj : [select Id, OwnerId from Lead where Id in:mapLeadOwner.KeySet()])
    { 
        
                  obj.OwnerId= mapLeadOwner.get(obj.Id);
                  system.debug('*** user' +obj.OwnerId);
                  obj.Take_Ownership__C = false;
                  updLeads.add(obj);
               
         
    }
    update updLeads;
    }
     
    public static void updateChatTranscript(Map<Id,Lead> mpLeadIdToLead)
    {
        
        //List to hold ChatTranscript to Update
        List<LiveChatTranscript> updlst = new List<LiveChatTranscript>();
        
        List<LiveChatTranscript> lstlct = new List<LiveChatTranscript>([SELECT Id, LeadId FROM LiveChatTranscript WHERE LeadId  IN :mpLeadIdToLead.keyset()]);
        
        for(LiveChatTranscript l: lstlct)
        {
      Lead clead = mpLeadIdToLead.get(l.LeadId);
      l.ContactId = cLead.ConvertedContactId;
            l.AccountId__c = cLead.ConvertedAccountId;
            l.AccountId = cLead.ConvertedAccountId;
            l.Opportunity__c = cLead.ConvertedOpportunityId;
            updlst.add(l);
           
        }

        if(!lstlct.isEmpty())
        {
          try
            {
                
               Update(updlst);
            }
          catch(Exception exc)
            {
               system.debug('***ERROR: LeadTrigger:update Sub: ' + exc.getStackTraceString());
            }
          
        }
       
    
    }   
    
    public static void changePRMLeadOwner(List<Lead> newList)
    {
    Map<Id,Id> mapLeadOwner = new Map<Id,Id>(); 
    Set<Id> rvaccts = new Set<Id>();
    for (integer i =0; i < newList.size(); i++)
        {
        if (newList[i].rvpe__RVAccount__c <> null
            && newList[i].OwnerId == Label.Lead_PRM_Owner
            )
              {
                rvaccts.add(newList[i].rvpe__RVAccount__c);
              }
              
         
    }
    
    if (!rvaccts.isEmpty())
    {
      Map<Id, rvpe__RVAccount__c> mapRVAccount = new Map<Id, rvpe__RVAccount__c>([Select Id, OwnerId from rvpe__RVAccount__c
                               where Id in :rvaccts]);
      
      for (integer i =0; i < newList.size(); i++)
          {
          if (mapRVAccount.get(newList[i].rvpe__RVAccount__c) <> null
              && newList[i].OwnerId == Label.Lead_PRM_Owner
              )
                {
                  rvpe__RVAccount__c rva = mapRVAccount.get(newList[i].rvpe__RVAccount__c);
                  newList[i].OwnerId = rva.OwnerId; 
                  newList[i].No_Assign__c = true;
                }
                
           
      }                        
    }                        
                             
    }
    public static void accountGAUpdate(List<Lead> newList)
    {
       System.debug('Entering the GA account update criteria on lead convert' );
        Set<Id> setAccountIds = new Set<Id>();
        for (Lead l : newList) {
           if (l.isConverted && l.ConvertedAccountId != null) setAccountIds.add(l.ConvertedAccountId);
        }
       
        Map<Id, Account> mapAccounts = new Map<Id, Account>([select Id, GAClientId__c, galastTouchDate__c, gafirstTouchDate__c, gaTotalTouchCount__c from Account where Id in : setAccountIds]);
        Map<Id, Account> mapAccountsToupdate = new Map<Id, Account>();
       
        for (Lead l : newList) {
            if (l.isConverted && mapAccounts.containsKey(l.ConvertedAccountId)) {
                Account a = mapAccounts.get(l.ConvertedAccountId);
                if ( a.GAClientId__c == null) a.GAClientId__c = l.GAClientId__c;
                else a.GAClientId__c = a.GAClientId__c +','+ l.GAClientId__c;
                            
                // MH - Start lead mapping for BAP-3498 - this logic sets or updates the account's first touch and/or last touch details if the lead's first touch and/or last touch details are more accurate
                                
                // If the lead's last Touch Date is later than the Account's last touch date or the Account doesn't have a last touch date set... 
                System.debug('Account galastTouchdate' + a.galasttouchdate__c);
                System.debug('Lead galastTouchDate' + l.galasttouchdate__c);
                
                
                if (l.galastTouchDate__c != null && (a.galastTouchDate__c == null || l.galastTouchDate__c > a.galastTouchDate__c))
                {
                    System.debug('Entering the logic for galastTouch data');
                    a.galastTouchCampaign__c = l.galastTouchCampaign__c;
                    a.galastTouchChannel__c = l.galastTouchChannel__c;
                    a.galastTouchKeyword__c = l.galastTouchKeyword__c;
                    a.galastTouchMedium__c = l.galastTouchMedium__c;
                    a.galastTouchSource__c = l.galastTouchSource__c;
                    a.galastTouchDate__c = l.galastTouchDate__c;  
                }
                
                // If the lead's first Touch Date is earlier than the Account's first touch date or the Account doesn't have a first touch date set...
                System.debug('Account gafirstTouchDate__c' + a.gafirstTouchDate__c);
                System.debug('Lead gafirstTouchDate__c' + l.gafirstTouchDate__c);
                if (l.gafirstTouchDate__c != null && (a.gafirstTouchDate__c == null || l.gafirstTouchDate__c < a.gafirstTouchDate__c))
                {
                    System.debug('Entering the logic for gafirstTouch data');
                    a.gafirstTouchCampaign__c = l.gafirstTouchCampaign__c;
                    a.gafirstTouchChannel__c = l.gafirstTouchChannel__c;
                    a.gafirstTouchKeyword__c = l.gafirstTouchKeyword__c;
                    a.gafirstTouchMedium__c = l.gafirstTouchMedium__c;
                    a.gafirstTouchSource__c = l.gafirstTouchSource__c;
                    a.gafirstTouchDate__c = l.gafirstTouchDate__c;   
                }
                
                // MH - BAP-3498 - Aggregate the Account's TouchCount total by adding the lead's TouchCount value to the account's TouchCount value 
                
             if (l.gatotalTouchCount__c != null) 
                {
                  System.debug('Account gatotalTouch Count is' + a.gatotalTouchCount__c);
                    System.debug('Entering the logic for gatotalTouchCount data');
                    if(a.gatotalTouchCount__c == null) 
                    {
                        System.debug('Entering the logic for gatotalTouchCount data ACCOUNT TOUCH COUNT IS NULL');
                        a.gatotalTouchCount__c = l.gatotalTouchCount__c;
                    }

                    else 
                     {
                        System.debug('Entering the logic for gatotalTouchCount data ACCOUNT TOUCH COUNT IS ' +a.gatotalTouchCount__c);
                        a.gatotalTouchCount__c = a.gatotalTouchCount__c + l.gatotalTouchCount__c;       
                    }
                    
                }
         mapAccountsToupdate.put(a.Id, a);
       if (!mapAccountsToupdate.isEmpty()) update mapAccountsToupdate.values();
   
            }
        }
    }
    
     /**
     * @author Alakh Biniwale
     * @date 03/28/2018
     * @ticket https://jira.bigcommerce.com/browse/BAP-6748
     * @description Method generates message digest usgin SHA1 algorithm 
     * 				and populates Email_Domain_SHA1__c with encoded hash value 
     * @param List<Lead> Contains the Trigger.new
     * @return void
     */ 
     public static void hashEmailDomain(List<Lead> newList){
        
        for(Lead led : newList){
            
            if(led.Email != null){
				 led.Email_Domain_SHA1__c = EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(led.Email.substringAfter('@'))));
            }else{
                led.Email_Domain_SHA1__c = null;
            }
            
        }
    }
}