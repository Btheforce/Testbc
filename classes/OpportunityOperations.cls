/**********************************************************************
Name:  OpportunityOperations
======================================================
 Purpose: Perform action on OpportunityOperations.
======================================================
 
History:   
                                                      
VERSION AUTHOR   DATE       DETAIL     
 
1.0 Maggie Frederick   12/3/2014   update owner on account.
2.0 Maggie Frederick   12/4/2014   change opp name
3.0 Maggie Frederick   12/4/2014   set revenue rep from upgrade opp
4.0 Maggie Frederick   12/9/2014    add product button logic
5.0 Maggie Frederick   12/13/2014   add strategic partner and same month downgrade
5.1 Maggie Frederick   1/22/2015    add change account logic and report checkboxes on history
5.2 Maggie Frederick   2/11/2015    remove revenue rep for upgrade opportunity - use owner instead
5.3 Maggie Frederick   7/1/2015     changes for bmp
5.4 Maggie Frederick   11/1/2015    implement 90 day rule
5.5 Maggie Frederick   11/17/2015   changes for sbd  
***********************************************************************/

public without sharing Class OpportunityOperations
{
    

    /**
     * Modernized references to get Record Type Ids 
     * @author Steve O'Neal
     * @date   2018-01-23
     * @ticket link         https://jira.bigcommerce.com/browse/BAP-6754
     */
    public static Id StoreRecordTypeId = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Store_Purchase').Id;
    public static Id TrialRecordTypeId = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Trial').Id;
    public static Id UpgradeRecordTypeId = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'Upgrade_Store').Id;
    public static Id OneTimeProductRecordTypeId = RecordTypeTools.GetRecordTypeByDeveloperName(Opportunity.getSObjectType(), 'One_Time_Product').Id;

    // Map to hold OwnerId and Departement Value.
    public Map<String,String> mpOwnerIdToDepartment = new Map<String,String>();
    
    public static map<string,PricebookEntry> getPricebookEntry(String strPricebook, List<String> strProdCodes)
    {
        map<string,PricebookEntry> mpProductcodeToPricebook = new map<string,PricebookEntry>();

        try
        {
            for(PricebookEntry obj:[SELECT Id,IsActive,Name,Pricebook2Id,Product2Id,ProductCode, UnitPrice FROM PricebookEntry WHERE Pricebook2Id =: strPricebook AND ProductCode IN:strProdCodes])
            {              
                mpProductcodeToPricebook.put(obj.ProductCode,obj);
            }
        }
        catch(Exception ex)
        {
            System.Debug('Error:'+ex.getMessage());
        }

        return mpProductcodeToPricebook;
    }
    
    // Method to query Contact on the basis of AccountID.
    public map<Id,Contact> querycontact(Set<Id> setAccid)
    {
        Set<Id> primaryContacts = new Set<Id>();
        Set<Id> mbaContacts = new Set<Id>();
        
        Map<Id,Contact> mpAccountIdToContact = new Map<Id,Contact>();
        for(Contact obj:[SELECT Id, AccountId, Account.Name, Name, MBAAccountID__c,Email,Phone, Primary_MBA_Contact__c, Type__C From CONTACT WHERE AccountId IN:setAccid order by createddate desc])
        {
            // if it is a primary contact this is the One !!      
            if (obj.Type__c == 'Primary Contact')
            {
                if (!mpAccountIdToContact.containsKey(obj.AccountID))
                {   
                    mpAccountIdToContact.put(obj.AccountID,obj); 
                }
                else
                {
                    mpAccountIdToContact.remove(obj.AccountID);
                    mpAccountIdToContact.put(obj.AccountID,obj);
                }

                primaryContacts.add(obj.AccountID);
                system.debug('Primary Contact found' );
            }
            // otherwise if no primary was found add the first mba contact
            else if ( !mpAccountIdToContact.containsKey(obj.AccountID) )
            {
                mpAccountIdToContact.put(obj.AccountID,obj);
                if (obj.Primary_MBA_Contact__c == true) 
                {
                    mbaContacts.add(obj.AccountID);
                }
            }   
            else if (mpAccountIdToContact.containsKey(obj.AccountID)  
                     && !primaryContacts.contains(obj.AccountId)
                     && !mbaContacts.contains(obj.AccountId)
                     && obj.Primary_MBA_Contact__c == true)
            {
                mpAccountIdToContact.remove(obj.AccountID);
                mpAccountIdToContact.put(obj.AccountID,obj);
            }
        }
            
        return mpAccountIdToContact;
    }
 

    public void AfterInsert(List<Opportunity>lstopp)
    {   

    // Handle situation where a lead with MBA trial was mnaully converted to create the Opportunity.
    // Populate MBA subscription ID and sync with MBA Sub
    // When a new opportunity is created by MBA staging add th eproducts.

        map<String, Id> mpSubOppIds = new  map<String, Id>();
        Map<String, Id> mpMBASubOppIds = new Map<String,Id>();
        // Map to hold OpportunityIds and Opportunity Value.
        Map<Id,Opportunity> mpOppIdToOpportunity = new Map<Id,Opportunity>();

        // Map to store ProductId and Opportunity Id.
        Map<Id,String> mpOppIdToProId = new map<Id,String>();
        Set<Id> oppIds = new Set<Id>();
 
        if(lstopp.size()>0)
        {
            for(Opportunity opp:lstopp)
            {          
                if((opp.MBAAccountID__c ==null || opp.MBASubscriptionId__c == null) && opp.MostRecentSubscription__c <> null )
                {   
               
                    if (opp.MBASubscriptionId__c == null)   
                    {
                        mpSubOppIds.put(opp.MostRecentSubscription__c, opp.Id);
                    }
                    else
                    {
                        mpMBASubOppIds.put(opp.MBASubscriptionId__c, opp.Id);
                    }
                }

                if (opp.MBASubscriptionId__c <> null && opp.ProductID__c <> null)
                {
                    if ( opp.Source__c == 'BMP')  
                    {
                        system.debug( 'Insert with BMP');
                    }
                    else
                    {     
                        mpOppIdToOpportunity.put(opp.Id,opp);    
                        mpOppIdToProId.put(opp.Id, opp.ProductID__c);    
                    }
                }    

                oppIds.add(opp.Id); 
            }
        }
    
        if(mpOppIdToOpportunity.size()>0)
        {
            handleOppProducts(mpOppIdToOpportunity.keySet());
        } 

        // calling future methods       
        if (!mpSubOppIds.isEmpty()) 
        {
            syncOppwithStagingSub(mpSubOppIds);
        }

        if (!mpMBASubOppIds.isEmpty()) 
        {
            syncOppwithMBASub(mpMBASubOppIds);
        }

    }


    public void beforeInsertUpdate(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isDelete, Boolean isUpdate, List<Opportunity> lstnew,List<Opportunity> lstold)
    {
    
        // Map To Hold AAccount
        Map<Id,Account> mpAccounts = new Map<Id,Account>();
        Set<Id> AccountIds = new Set<Id> ();
    
        // List To Hold All Opportunity OwnerId.
        List<String> lstOppOwnerId = new List<String>();
 
        // To find the related subscription
    
        // Map to collect MBAAccountIDAccount
        Map<String,String> mpMBAAccountIdToMBASubId =  new Map<String,String>();
    
        // Map To Get Subscription Id For MBASubscription.
        Map<String,Subscription__c> mpMBASubIDToSubId = new Map<String,Subscription__c>();
    
        List <Opportunity> sbdopps = new  List <Opportunity> ();
     
        if(lstnew.size()>0)
        {
            for(Opportunity obj:lstnew)
            {   
                lstOppOwnerId.add(obj.OwnerID); //--------------------- Addition
                // populate subscription if empty           
                if(obj.MBA_Account_ID__c!=null && obj.MBASubscriptionID__c!=null
                    && obj.Subscription__c  == null)
                {
                    mpMBAAccountIdToMBASubId.put(obj.MBA_Account_ID__c,obj.MBASubscriptionID__c);
                }
 
                // populate contact           
                if (obj.Contact__c == null)
                {
                    AccountIds.add(obj.AccountID);
                }

                if ( obj.Strategic_Partner__c ==null 
                    && (obj.LandingPage__c <> null && (obj.LandingPage__c <> '/' ) || obj.referral_id__c <> null) )
                {
                    sbdopps.add(obj);
                }
            }
        }
    
        // Query to get the Departement on the basis of OwnerId.
        if(lstOppOwnerId.size()>0)
        {
            for(User obj:[SELECT Department,Id FROM User WHERE Id IN:lstOppOwnerId]) 
            {
                mpOwnerIdToDepartment.put(obj.Id,obj.Department);
            } 
        }
    
        if(mpMBAAccountIdToMBASubId.values().size()>0)
        {  
            for(Subscription__c objs:[SELECT Id, Account__r.Id, MBASubscriptionID__c FROM Subscription__c WHERE MBASubscriptionID__c IN:mpMBAAccountIdToMBASubId.values() and Account__c <> null])
            {
                mpMBASubIDToSubId.put(objs.MBASubscriptionID__c,objs);
            }
        }    

        // Map to Hold AccountID and Contact Id.
        Map<Id, Contact> mpAccountIdToContact = new Map<Id,Contact>();
        
        if(AccountIds.size()>0)
        {
            mpAccountIdToContact = querycontact(AccountIds);
        }
    
        // List to collect  Opportunity.
        List<Opportunity> trialOpps = new List<Opportunity>();
        List<Opportunity> paidOpps = new List<Opportunity>();
        List<Opportunity> paidOppsOld = new List<Opportunity>();
        List<Opportunity> updOpps = new List<Opportunity>();
    
    
        for(Integer i=0;i<lstnew.size();i++)
        {   
            if(lstnew[i].Subscription__c == null && mpMBASubIDToSubId.get(lstnew[i].MBASubscriptionID__c)!=null)
            {
                Subscription__c s = mpMBASubIDToSubId.get(lstnew[i].MBASubscriptionID__c);
                if (s.Account__r.Id == lstnew[i].AccountId)
                {
                    lstnew[i].Subscription__c = s.Id;
                }
            }
            
            if(lstnew[i].Contact__c == null && mpAccountIdToContact.containskey(lstnew[i].AccountID))
            {
                lstnew[i].Contact__c = mpAccountIdToContact.get(lstnew[i].AccountId).Id ;
            }
            
            if (lstnew[i].Source__c == 'BMP' && lstnew[i].MonthlyRecurringRevenue__c  == null )
            {
                if (lstnew[i].Zuora_MRR__c <> null) 
                {
                    lstnew[i].MonthlyRecurringRevenue__c = lstnew[i].Zuora_MRR__c;
                }
                else
                {
                    lstnew[i].MonthlyRecurringRevenue__c = 0.0;
                }
            }
            
            // Assigning Revenue Rep as the Opportunity Owner.
            if( (isInsert && !lstnew[i].isTrial__c) 
                || (isUpdate && !lstnew[i].isTrial__c 
                    && (lstnew[i].MonthlyRecurringRevenue__c <> lstold[i].MonthlyRecurringRevenue__c || lstnew[i].ProductId__c <>  lstold[i].ProductID__c)))
            {
                system.debug('setting revenue rep ' );
                if (lstnew[i].Revenue_Rep__c == null || lstnew[i].Revenue_Rep__c <> lstnew[i].OwnerId) 
                {
                    lstnew[i].Revenue_Rep__c = lstnew[i].OwnerId;
                }

                if(mpOwnerIdToDepartment.get(lstnew[i].OwnerId)!=null)       
                {   
                    lstnew[i].Revenue_Team__c = mpOwnerIdToDepartment.get(lstnew[i].OwnerID);
                } 
            }

            /**
             * Changed to set close date
             * @author Steve O'Neal
             * @date   2017-04-21
             * @ticket link         https://jira.bigcommerce.com/browse/BAP-5492
             */
            if(lstnew[i].IsTrial__c)
            {
                trialOpps.add(lstnew[i]);
                if (lstnew[i].CloseDate == null)
                {
                    if (lstnew[i].ExpirationDate__c != null)
                    { 
                        lstnew[i].CloseDate = lstnew[i].ExpirationDate__c;
                    }
                    else
                    {
                        lstnew[i].CloseDate = Date.Today();
                    }
                }
                
                /**
                 * Moved trial close date code to BatchStagingSubscription
                 * @author Steve O'Neal
                 * @date   2017-05-02
                 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5538
                 */
            }
            else if (lstnew[i].RecordtypeId == UpgradeRecordTypeId)
            {
                updOpps.add(lstnew[i]);
            }
            else 
            { 
                paidOpps.add(lstnew[i]);
                if (lstold.size() > 0)
                {
                    paidOppsOld.add(lstold[i]);
                }
            }
        }

        if (!trialOpps.isEmpty()) 
        {
            setTrialValues(trialOpps);
        }

        if (!paidOpps.isEmpty())
        {
            setPurchaseValues(paidOpps, paidOppsOld);
        }

        if (!sbdopps.isEmpty())
        {
            updateStrategicPartner(sbdopps);
        }

    }


    public void afterUpdate(List<Opportunity> lstnew,List<Opportunity> lstold)
    {
        Set<ID> oppIDsNeedingProducts = new Set<ID>();
       
        // Compare If Any Of The Product Field On The Opportunity have been Updated.
        if(lstnew.size()>0)
        {
            for(Integer i=0;i<lstnew.size();i++)
            {    
                system.debug('*** source '+lstnew[i].Source__c);
                if (lstnew[i].MonthlyRecurringRevenue__c!= lstold[i].MonthlyRecurringRevenue__c
                    || lstnew[i].ProductID__c != lstold[i].ProductID__c
                    || lstnew[i].Status__c != lstold[i].Status__c)
                {
                    oppIDsNeedingProducts.add(lstnew[i].ID);
                }
            }
        }
    
        if(oppIDsNeedingProducts.size() > 0)
        {
            handleOppProducts(oppIDsNeedingProducts);
        }
    }

    
    /**
     * [AddOppsToDialer description]
     * @author Steve O'Neal
     * @date   2018-02-20
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-6817
     * @param  lstNew     Current version of opportunities
     * @param  lstold     Old version of opportunities
     */
    public void AddOppsToDialer(List<Opportunity> newOpps, List<Opportunity> oldOpps)
    {
        User bigCommerceTeamUser = [select Id, firstName, lastName, userName, email from User where username like 'team@bigcommerce.com%' and isActive = true limit 1];

        Map<string, Id> five9ListNameToIdMap = new Map<string, Id>();
        for (Five9LSP__Five9_List__c five9List : [select Id, Name from Five9LSP__Five9_List__c])
        {
            five9ListNameToIdMap.put(five9List.name, five9List.Id);
        }

        List<Dialer_Schedule__mdt> dialerScheduleMetadataList = [Select Id, MasterLabel, Active__c, Five9_List_Name__c, Maximum_Opportunity_Probability__c, Minimum_Opportunity_Probability__c, Opportunity_Size__c, Sales_Team__c
                                                                         FROM Dialer_Schedule__mdt
                                                                         Where Active__c = true
                                                                         Order by MasterLabel asc];

        System.debug(dialerScheduleMetadataList);
        System.debug(newOpps);

        for (integer index = 0; index < newOpps.size(); index++)
        {
            Opportunity currOpp = newOpps[index];
            Opportunity oldOpp = oldOpps[index];

            // only add opportunities where the ownership has changed from the BigCommerce team and there is a demo requested
            if (currOpp.OwnerId != oldOpp.OwnerId && currOpp.OwnerId != bigCommerceTeamUser.Id)
            {
                if (currOpp.Demo_Requested_Date__c != null)
                {
                    // determine which dialer to add the opp to
                    for (Dialer_Schedule__mdt dsMeta : dialerScheduleMetadataList)
                    {
                        if (currOpp.Account_Sales_Team_Calculated__c.EqualsIgnoreCase(dsMeta.Opportunity_Size__c) && currOpp.Probability >= dsMeta.Minimum_Opportunity_Probability__c && currOpp.Probability <= dsMeta.Maximum_Opportunity_Probability__c)
                        {
                            System.debug(currOpp);
                            currOpp.Add_to_f9list_id__c = five9ListNameToIdMap.get(dsMeta.Five9_List_Name__c);
                            break;
                        }
                    }
                }
            }
        }

    }


    //Method to sync manual leads
    @future
    public static void syncOppwithStagingSub(Map<String,String> mpSubOppIds)
    {   
        Map<String,String> lstMBASubTOSub = new Map<String,String>();
        
        for(Subscription__c obj:[Select Id,MBASubscriptionID__c from Subscription__c Where Id IN:mpSubOppIds.keyset()])
        {
            lstMBASubTOSub.put(obj.MBASubscriptionID__c ,obj.Id);
        }

        string soqlWHERE_SubIDs = '';
        // Query the Fields of MBA Staging Subscription.
        for (String mba : lstMBASubTOSub.keyset())
        {
            // Grab all the MBA Subscription Ids
            if (mba != null)
            {
                soqlWHERE_SubIDs += (soqlWHERE_SubIDs.length() == 0 ? '' : ', ') + '\'' + mba + '\'';
            }
        }

        System.Debug('soqlWHERE_SubIDs '+soqlWHERE_SubIDs );
    
        string soql_Opp = SObjectUtils.SubscriptionStagingSelect + ' WHERE MBASubscriptionID__c IN (' + soqlWHERE_SubIDs  + ')';
    
        database.Dmloptions dml = new database.Dmloptions();

        //Map Sobject for MBASubscription and Opportunity.
        Map<Sobject,Sobject> mpMBASubToOpp = new Map<Sobject,Sobject>();

        for(MBA_Staging_Subscription__c obj:database.query(soql_Opp))
        {
            Opportunity opp = new Opportunity(Id=mpSubOppIds.get(lstMBASubTOSub.get(obj.MBASubscriptionID__c)));  
            mpMBASubToOpp.put(obj,opp);
        }
        
        system.debug('User21 mpMBASubToOpp'+mpMBASubToOpp);
    
        // Calling SyncObjects Method To Do the Logic.
        if(mpMBASubToOpp.size()>0)
        {
            SObjectUtils.SyncObjects('MBA_Staging_Subscription__c', 'Opportunity', mpMBASubToOpp, dml);
        }
        
        system.debug('User21 Method Exit from querySubForManualLeads');
    }
    

    //Method to sync manual leads
    @future
    public static void syncOppwithMBASub(Map<String,Id> mpMBASubOppIds)
    {   
    
        string soqlWHERE_SubIDs = '';
        
        // Query the Fields of MBA Staging Subscription.
        for (String mba : mpMBASubOppIds.keyset())
        {
            // Grab all the MBA Subscription Ids
            if (mba != null)
            {
                soqlWHERE_SubIDs += (soqlWHERE_SubIDs.length() == 0 ? '' : ', ') + '\'' + mba + '\'';
            }
        }
    
        System.Debug('soqlWHERE_SubIDs '+soqlWHERE_SubIDs );
    
        string soql_Opp = SObjectUtils.SubscriptionStagingSelect + ' WHERE MBASubscriptionID__c IN (' + soqlWHERE_SubIDs  + ')';
    
        database.Dmloptions dml = new database.Dmloptions();

        //Map Sobject for MBASubscription and Opportunity.
        Map<Sobject,Sobject> mpMBASubToOpp = new Map<Sobject,Sobject>();
        
        for(MBA_Staging_Subscription__c obj:database.query(soql_Opp))
        {
            Opportunity opp = new Opportunity(Id=mpMBASubOppIds.get(obj.MBASubscriptionID__c));  
            mpMBASubToOpp.put(obj,opp);
        }
    
        // Calling SyncObjects Method To Do the Logic.
        if(mpMBASubToOpp.size()>0)
        {
            SObjectUtils.SyncObjects('MBA_Staging_Subscription__c', 'Opportunity', mpMBASubToOpp, dml);
        }
    
        system.debug('User21 Method Exit from querySubForManualLeads');
    }


    public static void handleOppProducts(Set<ID> oppIds)
    {
        createOpportunityMessageQueue(oppIds, MessageQueueUtilities.taskStringCreateOpportunityLineItems);
    }
    

    private void setTrialValues(List<Opportunity> trialOpps)
    {
        

        for (Opportunity o :trialOpps)
        {
            // Assigning RecordtypeId,StageName,CloseDate to the Opportunity.
            o.RecordTypeId = TrialRecordTypeId;

            if ((o.Status__c == 'Trial Expired' || o.Status__c == 'Cancelled')
                && o.StageName <> 'Closed Lost')
            {
                if (o.OwnerId == Label.BCT_Id)
                {
                    o.StageName = 'Closed Lost';
                    o.Closed_Lost_Reason__c = Label.Opportunity_ClosedLost;
                }
                else if (o.Status__c == 'Trial Expired') 
                {
                    o.StageName=Label.Opportunity_Stage_TrialExpired;
                }
                else if (o.Status__c ==Label.Opportunity_Status_Cancelled)
                {
                    o.StageName=Label.Opportunity_Stage_Cancelled;
                } 
            }
        }   
    }


    /**
     * Sets values for purchased stores/products
     * Changed the interface to identify records that have changed, rather than setting the close date every time the record was saved.
     * @author Steve O'Neal
     * @date   2017-04-25
     * @ticket link        https://jira.bigcommerce.com/browse/BAP-5523
     * @param  paidOpps    List of opportunities that are in the Paid status
     * @param  paidOppsOld List of the previous values of the paidOpps
     */
    private void setPurchaseValues(List<Opportunity> paidOpps, List<Opportunity> paidOppsOld)
    {       
        Map<Id, string> mpOppProd = new Map<Id, string>();
        
        for (integer oppIndex = 0; oppIndex < paidOpps.size(); oppIndex++)
        {
            Opportunity o = paidOpps[oppIndex];

            if (o.Master_Agreement_Date__c <> null )
            {
                o.CloseDate = o.Master_Agreement_Date__c;
            }
            else if (o.PurchaseDate__c <> null)
            {
                if (o.CloseDate <> o.PurchaseDate__c) 
                {
                    o.CloseDate = o.PurchaseDate__c;
                }
            }
            else if (paidOpps[oppIndex].IsClosed && (paidOppsOld.size() == 0 || (paidOppsOld.size() > 0 && !paidOppsOld[oppIndex].isClosed)))
            {
                // if the opp is new OR the opp was moved to closed, then and only then do we set the close date to today
                o.CloseDate = System.Today();
            }
            
            if(o.SubscriptionType__c == 'Store')
            {
                o.RecordTypeId = StoreRecordTypeId;
                o.StageName = Label.Opportunity_Stage_Purchased;
                     
                if(o.Purchase_Rep__c == null)
                {               
                    o.Purchase_Rep__c = o.OwnerID;
                    if (mpOwnerIdToDepartment.containsKey(o.Purchase_Rep__c))
                    {
                        o.Purchase_Team__c = mpOwnerIdToDepartment.get(o.Purchase_Rep__c);
                    }
                }

                // Assigning Revenue Rep as the Opportunity Owner.
                if (o.Revenue_Rep__c == null)
                { 
                    o.Revenue_Rep__c = o.OwnerId;
                    if (mpOwnerIdToDepartment.containskey(o.Revenue_Rep__c))       
                    {   
                        o.Revenue_Team__c = mpOwnerIdToDepartment.get(o.Revenue_Rep__c);
                    } 
                }

                if (o.Original_Plan_Purchased__c==null)
                {
                    o.Original_Plan_Purchased__c = o.Product__c;
                    o.Original_Plan_Value__c = o.MonthlyRecurringRevenue__c;
                }

                // handle sbd opps
                //if (o.SBD_Store_ID__c != null  && o.Franchise_Code__c != 'Bigcommerce' &&  o.Franchise_Code__c != null          //BAP-6590:Change agency__c to Franchise_Code__c
                if (o.SBD_Store_ID__c != null  && o.Agency__c != 'Bigcommerce' &&  o.Agency__c != null
                    && o.Source__c <> 'BMP'&& o.MonthlyRecurringRevenue__c == 0  && o.ProductId__c <> null )
                {
                    mpOppProd.put(o.Id, o.ProductId__c);
                    
                }
                
            } //store
            else if (o.SubscriptionType__c <> '')
            {
                o.RecordTypeId = OneTimeProductRecordTypeId;
                if (o.Status__c ==Label.Opportunity_Status_Active)
                {
                    o.StageName = 'Closed Won';
                }
            }
        }   
        
        if (!mpOppProd.isEmpty())
        {
            map<string,PricebookEntry> mpProductcodeToPricebook1 = new map<string,PricebookEntry>();
            
            mpProductcodeToPricebook1 = OpportunityOperations.getPricebookEntry(Label.Sales_Pricebook,mpOppProd.values());
        
            for (Opportunity o : paidopps)
            {
                PricebookEntry pe = mpProductcodeToPricebook1.get(o.ProductId__c);
                if (pe == null || pe.UnitPrice ==null)
                {
                    system.debug(' product '+o.ProductId__c);
                } 
                else 
                {
                    o.Product_Price__c = pe.UnitPrice;
                    if (o.Original_Plan_Value__c == null && o.Product__c == o.Original_Plan_Purchased__c) 
                    {
                        o.Original_Plan_Value__c = o.Product_Price__c;
                    }
                }
            }
        }
    }
    

    /**
     * Method to create OpportunityContactRole on set of Opportunity ids.  Creates a record to be handled by a batch process.
     * @author Steve O'Neal
     * @date   2017-02-20
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-4927
     * @param  oppIds     Opportunity Ids that require a contact role update
     */
    public static void createOpportunityContactRole(Set<Id> oppIds)
    {
        createOpportunityMessageQueue(oppIds, MessageQueueUtilities.taskStringCreateOpportunityContactRoles);
    }



    /**
     * Method to create Cases related to an opportunity.  Createsa a record to be handled by a batch process.
     * @author Steve O'Neal
     * @date   2018-04-06
     * @ticket link       https://jira.bigcommerce.com/browse/BAP-7040
     * @param  oppIds     Opportunity Ids that require a case
     */
    public static void createOpportunityCases(Set<Id> oppIds)
    {
        createOpportunityMessageQueue(oppIds, MessageQueueUtilities.taskStringCreateCase);
    }


    /**
     * Creates a Opportunity Message Queue record
     * @author Steve O'Neal
     * @date   2017-02-28
     * @ticket link        https://jira.bigcommerce.com/browse/BAP-4927
     * @param  oppIds      Opportunity Ids that require an update
     * @param  messageType The type of queue to create
     */
    private static void createOpportunityMessageQueue(Set<Id> oppIds, string messageType)
    {
        List<Opportunity_Message_Queue__c> oppMessageQueues = new List<Opportunity_Message_Queue__c>();


        for (Id oppId : oppIds)
        {
            // create a message queue record
            Opportunity_Message_Queue__c oppMessageQueueUpdateOpp = new Opportunity_Message_Queue__c();
            oppMessageQueueUpdateOpp.Status__c = 'New';
            oppMessageQueueUpdateOpp.Task__c = messageType;
            oppMessageQueueUpdateOpp.Opportunity__c = oppId;
            oppMessageQueueUpdateOpp.Attempt_Number__c = 1;
            oppMessageQueues.add(oppMessageQueueUpdateOpp);
        }

        System.debug(oppMessageQueues);
        
        if (oppMessageQueues.size() > 0)
        {
            insert oppMessageQueues;
        }
    }


      
    // Method to query Account on The basis of MBAAccountID.
    public void queryAccount(map<String,Opportunity> mpMBAAccountIdToOpp)
    {
        for(Account obj:[SELECT Id,MBAAccountID__c FROM Account WHERE MBAAccountID__c IN:mpMBAAccountIdToOpp.keyset()])
        {
            if(mpMBAAccountIdToOpp.containskey(obj.MBAAccountID__c))
            {
                mpMBAAccountIdToOpp.get(obj.MBAAccountID__c).AccountID = obj.Id;
            }
        }
    }
  
    //Method to get upgrade opportunity owner
    
    public static Map<Id, Opportunity> getUpgradeOpps(Set<Id> PoppIds)
    { 
          
        Map<Id, Opportunity> mpOppRep = new Map<Id, Opportunity>();
     
        for (Opportunity opp :[select Id, StageName, CloseDate, ParentOpportunity__c, OwnerId, Owner.Department
                               from Opportunity 
                               where ParentOpportunity__c in :PoppIds 
                                 and isClosed = false])
        {      
            mpOppRep.put(opp.ParentOpportunity__c, opp);
        }    
           
        return  mpOppRep;                                        
    }

    /**
     * Updating the interface to updateUpgradeOpps to include the correct close date
     * @author Steve O'Neal
     * @date   2017-04-05
     * @ticket link                        https://jira.bigcommerce.com/browse/BAP-4327
     * @param  parentOppIdWithCloseDateMap Map of Parent Opportunity Ids and the related start date from the OPH record that initialized this change
     */
    public static void updateUpgradeOpps(Map<Id, Date> parentOppIdWithCloseDateMap)
    {   
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> upgOpps = getRelatedOpenUpgradeOpportunities(parentOppIdWithCloseDateMap.keySet());
        Map <id, Id> mapOppParentId = new Map <id, Id>();
        
        if (!upgOpps.isEmpty())
        {
            for (Opportunity opp :upgOpps)
            {
                oppIds.add(opp.Id);
                mapOppParentId.put(opp.Id, opp.ParentOpportunity__c);
                opp.StageName = 'Closed Won';
                opp.CloseDate =  parentOppIdWithCloseDateMap.get(opp.ParentOpportunity__c);
            }
            
            deleteUpgradeForecastProducts(OppIds);
            addUpgradeProducts(mapOppParentId);
            update upgOpps;
        }
    }


    /**
     * Gets all open upgrade opportunities that are related to the passed-in store opportunity Ids
     * @author Steve O'Neal
     * @date   2017-03-24
     * @ticket link                https://jira.bigcommerce.com/browse/BAP-4327
     * @param  storeOpportunityIds List of Ids representing store opportunities
     * @return                     List of related open upgrade opportunities
     */
    public static List<Opportunity> getRelatedOpenUpgradeOpportunities(Set<Id> storeOpportunityIds)
    {
        return [select Id, Name, StageName, CloseDate, ParentOpportunity__c, OwnerId, Owner_Team__c
                from Opportunity 
                where ParentOpportunity__c in :storeOpportunityIds 
                  and isClosed = false
                  and RecordTypeId = :UpgradeRecordTypeId];
    }

    /**
     * Gets all open upgrade opportunities or opportunities closed within the last x days related to the passed-in store opportunities ids
     * @author Steve O'Neal
     * @date   2017-04-05
     * @ticket link                  https://jira.bigcommerce.com/browse/BAP-4327
     * @param  storeOpportunityIds   List of Ids representing store opportunities
     * @param  closedWithinLastXDays Number of days to look backwards on the close date of closed upgrade opportunities
     * @return                       List of related upgrade opportunties
     */
    public static List<Opportunity> getRelatedUpgradeOpportunitiesLastXDays(Set<Id> storeOpportunityIds, integer closedWithinLastXDays)
    {
        Date neededCloseDate = Date.today().addDays(-1 * closedWithinLastXDays);
        return [select Id, Name, StageName, CloseDate, ParentOpportunity__c, OwnerId, Owner_Team__c
                from Opportunity 
                where ParentOpportunity__c in :storeOpportunityIds 
                  and (isClosed = false or (isClosed = true and CloseDate > :neededCloseDate))
                  and RecordTypeId = :UpgradeRecordTypeId];        
    }


    public static void deleteUpgradeForecastProducts(Set<Id> upgOppIds)
    {
        //List to hold Opportunity Line Item which are going to delete.
        List <OpportunityLineItem> lstopproidTodel  = new List<OpportunityLineItem>();
   
        // query the Opportunity Product Line Item.
        for(OpportunityLineItem oppl:[SELECT Id, OpportunityId, Family__c FROM OpportunityLineItem WHERE OpportunityId IN:upgOppIds])
        {
            if (oppl.Family__c == 'Forecast')
            {
                lstopproidTodel.add(oppl);
            }
        }
       
        // Opportunity Line Item Going To Delete.
        if(!lstopproidTodel.isEmpty())
        {
            delete lstopproidTodel;
        }
    }    
     
    public static void addUpgradeProducts(Map <id, Id> mapOppParentId)
    {

        String upgradeProdcode = Label.UpgradeProduct;
        String upgradePricebook = Label.UpgradePricebook;

        List<OpportunityLineItem> lstNewOppLnItm = new List<OpportunityLineItem>();
        List<Opportunity_Product__c> parentproducts = new List<Opportunity_Product__c> ([select Id, RevenueChange__c, OpportunityID__c from Opportunity_Product__c where OpportunityID__c in :mapOppParentId.Values() and LastVersion__c = true]);

        Map<Id, Opportunity_Product__c> mapOppProdHist = new Map<Id, Opportunity_Product__c>(); 
        for (Opportunity_Product__c op :parentproducts )
        {
            mapOppProdHist.put(op.OpportunityID__c, op);
        }   
        
        PricebookEntry obj = [SELECT Id,IsActive,Name,Pricebook2Id,Product2Id,ProductCode FROM PricebookEntry WHERE Pricebook2Id =: upgradePricebook AND ProductCode =:upgradeProdcode];
            
        for (Id oId :mapOppParentId.KeySet())   
        {            
            OpportunityLineItem opplnt = new OpportunityLineItem();
            opplnt.OpportunityId=oid;
            opplnt.PricebookEntryId = obj.Id;
            opplnt.Quantity=1;
            Opportunity_Product__c op =  mapOppProdHist.get(mapOppParentId.get(oId));        
            opplnt.UnitPrice = op.RevenueChange__c;

            lstNewOppLnItm.add(opplnt);
        }
        
        //New Opportunity Line Item Going To Insert.
        if(!lstNewOppLnItm.isEmpty())
        {
            insert lstNewOppLnItm;
        }
    }


    // Method to query partner Account on The basis of MBAPartnerID.
    public void updatePartnerAccount(List<Opportunity> Opps)
    {
        string soqlWHERE_IDevPartnerIDs = '';
        // Set to hold MBA Partner Ids
        set<string> stMBAPartnerId = new set<string>();
        
        for (Opportunity o :Opps)     
        {  
            // Grab all the MBA Partner Ids
            if (o.MBAPartnerID__c != null && o.MBAPartnerID__c.trim().length() > 0)
            {
                if (stMBAPartnerId.add(o.MBAPartnerID__c))
                {
                    soqlWHERE_IDevPartnerIDs += (soqlWHERE_IDevPartnerIDs.length() == 0 ? '' : ', ')  + o.MBAPartnerID__c;
                }
            }
        }           
               
        system.debug(' Find channel partner '+soqlWHERE_IDevPartnerIDs);
 
        if (soqlWHERE_IDevPartnerIDs == '') 
        {
            return;
        }
        
        Subscription_Utility.LoadAcctByIDevPartnerIdMap(soqlWHERE_IDevPartnerIDs);  
        
        for (Opportunity o :Opps)     
        {  
            // If the subscription has a Partner Id then use the Account Owner of that partner account record to own the subscription
            if (o.MBAPartnerID__c != null && Subscription_Utility.mpAcctByIDevPartnerId.containsKey(o.MBAPartnerID__c))
            {
                Account partneracc = Subscription_Utility.mpAcctByIDevPartnerId.get(o.MBAPartnerID__c);
                if (partneracc.OwnerId != UserInfo.getUserId())
                { 
                    o.OwnerId = partneracc.OwnerId;
                }
                o.Channel_Partner__c = partneracc.Id;
            }
            else if (o.MBAPartnerID__c != null)
            {
                o.OwnerId = Label.Partner_Default_Owner;
            }
        }
    }
   

    public void UpdateAccountOwner( Set<Id> OppIds)
    {    
        Id ClientRecordTypeId = Account.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Client Record Type').getRecordTypeId();
        Id bmpRecordTypeId = Account.getSObjectType().getDescribe().getRecordTypeInfosByName().get('BMP Client').getRecordTypeId();
            
        List<Opportunity> opps = new List<Opportunity>([Select Id, OwnerId, Account.Owner_Team__c, Account.OwnerId, AccountId,  Account.RecordTypeId From Opportunity where Id in :OppIds]);
        List<Account> updaccts = new List<Account>();  
        
        for ( Opportunity opp:opps)
        {
            if (opp.Account.OwnerId <> opp.OwnerId
                && (opp.Account.OwnerId == Label.Account_Default_Owner || opp.Account.OwnerId == Label.Marketing_Test_Queue)
                && (opp.Account.RecordTypeId == ClientRecordTypeId || opp.Account.RecordTypeId == bmpRecordTypeId ))
            {
                
                Account a = new Account(Id=opp.AccountId, OwnerId = opp.OwnerId);
                updaccts.add(a);
            }
        }
            
        try
        {
            update updaccts;
        }
        catch(Exception exc)
        {
            ErrorEmailHelper.notifyOnError('Opportunity Trigger Handler', 'after update', 'Error in OpportunityTrigger Handler - update ', ': update Account' + updaccts[0].Id);
            system.debug('***ERROR: AccountTrigger:: ' + exc.getStackTraceString());
        }
    }
    

    public void createExpectedProd(Map <Id, String> oppProdPlan)
    {
        List<OpportunityLineItem> oppitems = new List<OpportunityLineItem>();
        
        map<string,PricebookEntry> mpProductcodeToPricebook1 = new map<string,PricebookEntry>();
           
        mpProductcodeToPricebook1 = getPricebookEntry(Label.Sales_Pricebook,oppProdPlan.values());
        system.debug('In AFter Update mpProductcodeToPricebook1'+mpProductcodeToPricebook1);
        
        for (Id oppId :oppProdPlan.KeySet())
        {
            OpportunityLineItem opplnt = new OpportunityLineItem();
            opplnt.OpportunityId=oppId;
            String productPlan = oppProdPlan.get(oppId);
            
            system.debug('**** '+productPlan);
                
            PricebookEntry pbe= mpProductcodeToPricebook1.get(productPlan);
            opplnt.PricebookEntryId = pbe.Id;
            opplnt.Quantity=1;
            opplnt.UnitPrice = pbe.UnitPrice;
            oppItems.add(opplnt);
        }

        insert oppItems;
    }


    public static void updateStrategicPartner(List<Opportunity> oppList)   
    {
    
        Map<String, ID> mpLpValueId = new Map <string, Id>();
        Map<String, ID> mpRValueId = new Map <string, Id>();

        List<StrategicPartner__c> strpar = StrategicPartner__c.getall().Values();
        for (StrategicPartner__c sp :strpar)
        {
            if (sp.LandingPage__c <> null)
            {
                mpLpValueID.put(sp.LandingPage__c, sp.Strategic_Partner__c);
            }

            if (sp.Referral_ID__c <> null)
            {
                mpRValueID.put(sp.Referral_ID__c, sp.Strategic_Partner__c);
            }
        }
        
        for (Opportunity o :oppList)
        {
            if (o.Strategic_Partner__c == null
                && ((o.LandingPage__c <> null && o.LandingPage__c <> '/' ) || o.referral_id__c <> null))
            {
                for (String str :mpLpValueId.KeySet())
                {
                    if (o.LandingPage__c <> null && o.LandingPage__c.contains(str))
                    {
                        o.Strategic_Partner__c = mpLpValueID.get(str);
                        system.debug(' found sub '+o.Name);
                    }
                }

                for (String str :mpRValueId.KeySet())
                {
                    if (o.Referral_ID__c <> null && o.referral_id__c.contains(str))
                    {
                        o.Strategic_Partner__c  = mpRValueID.get(str);    
                        system.debug(' found sub '+o.Name);
                    }   
                }
            }
        }
    }
}