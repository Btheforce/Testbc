/**
 * Used in vForce page RoundRobinOpportunity
 * @author Steve O'Neal
 * @date   2018-01-03
 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6573
 */
public with sharing class RoundRobinOpportunityController 
{
	public final Opportunity opp;

	private Account prvAccountToRoundRobin = null;

	private ApexPages.StandardController stdController = null;
	private ApexPages.StandardSetController stdSetController = null;
	private boolean okToAutoSubmit = true;

	public boolean getOkToAutoSubmit()
	{
		return okToAutoSubmit;
	}

	public FieldSet acctFieldSet
	{
		get
		{
			return sObjectType.Account.FieldSets.Round_Robin_Fields_For_Opportunity;
		}
	}

	public FieldSet oppFieldSet
	{
		get
		{
			return sObjectType.Opportunity.FieldSets.Round_Robin_Fields;
		}
	}

	public Opportunity opportunityToRoundRobin
	{
		get
		{
			return (Opportunity)stdController.getRecord();
		}
	}


	public Account accountToRoundRobin
	{
		get
		{
			return prvAccountToRoundRobin;
		}
	}

	private User bigCommerceTeamUser;

	public List<FieldSetMember> getAcctFieldSetMembers()
	{
		return acctFieldSet.getFields();
	}

	public List<FieldSetMember> getOppFieldSetMembers()
	{
		return oppFieldSet.getFields();
	}


	private Set<string> getAcctFieldsToFetch()
	{
		// be sure to use lwercase when adding new fields
		Set<string> fieldsToFetch = new Set<string>();
		fieldsToFetch.add('id');
		fieldsToFetch.add('name');
		fieldsToFetch.add('ownerid');
		fieldsToFetch.add('transfer_via_round_robin__c');
		fieldsToFetch.add('transfer_date__c');
		fieldsToFetch.add('round_robin_user__c');
		fieldsToFetch.add('sales_team_calculated__c');

		for (Schema.FieldSetMember fsMember : acctFieldSet.getFields())
		{
			fieldsToFetch.add(fsMember.getFieldPath().ToLowerCase());
		}
		return fieldsToFetch;
	}


	private Set<string> getOppFieldsToFetch()
	{
		// be sure to use lwercase when adding new fields
		Set<string> fieldsToFetch = new Set<string>();
		fieldsToFetch.add('id');
		fieldsToFetch.add('name');
		fieldsToFetch.add('ownerid');
		fieldsToFetch.add('accountid');
		fieldsToFetch.add('n2de__is_trigger_enabled__c');
		fieldsToFetch.add('transfer_via_round_robin__c');
		fieldsToFetch.add('transfer_date__c');
		fieldsToFetch.add('round_robin_user__c');
		fieldsToFetch.add('account.name');
		fieldsToFetch.add('account.ownerid');
		fieldsToFetch.add('account.owner.isactive');
		fieldsToFetch.add('account.sales_team_calculated__c');
		fieldsToFetch.add('account.territory__c');

		for (Schema.FieldSetMember fsMember : oppFieldSet.getFields())
		{
			fieldsToFetch.add(fsMember.getFieldPath().ToLowerCase());
		}

		return fieldsToFetch;		
	}

	private void Initialize()
	{
		bigCommerceTeamUser = [select Id, firstName, lastName, userName, email from User where username like 'team@bigcommerce.com%' and isActive = true limit 1];
		prvAccountToRoundRobin = getAccount();
	}


	private Account getAccount()
	{
		Account retVal = null;
		string accountSelect = 'select ';
		string comma = '';
		for (string fieldName : getAcctFieldsToFetch())
		{
			accountSelect += comma + fieldName;
			comma = ',';
		}
		accountSelect += ' from Account where Id = \'' + opportunityToRoundRobin.AccountId + '\' limit 1';
		System.debug(accountSelect);

		retVal = (Account)Database.Query(accountSelect);

		return retVal;
	}


	public RoundRobinOpportunityController(ApexPages.StandardController controller) 
	{
		stdController = controller;

        if(!Test.isRunningTest())
        {
           stdController.addFields(new List<string>(getOppFieldsToFetch()));
        }
        

		Initialize();
	}


	public PageReference saveOpportunityAutomatic()
	{
		if (okToAutoSubmit)
		{
			return saveOpportunity();
		}		
		else
		{
			return null;
		}
	}


	public PageReference saveOpportunityFinal()
	{
        Boolean assignAccountOwnerToOpportunityOwner = Boolean.valueOf(ApexPages.currentPage().getParameters().get('assignAccountOwnerToOpportunityOwner'));
        opportunityToRoundRobin.Transfer_via_Round_Robin__c = true;
		opportunityToRoundRobin.Transfer_Date__c = DateTime.now();
		opportunityToRoundRobin.Round_Robin_User__c = UserInfo.getUserId();
		opportunityToRoundRobin.n2de__is_trigger_enabled__c = true;

		stdController.save();

        // if no errors occurred, save the account
		// last check - accounts should always be owned by the BigCommerce Team if the Sales Team is Small Business
		if (opportunityToRoundRobin.Account.Sales_Team_Calculated__c == 'Small Business')
		{
            assignAccountOwner(accountToRoundRobin, bigCommerceTeamUser.Id);
        }
        else if (assignAccountOwnerToOpportunityOwner)
        {
            assignAccountOwner(accountToRoundRobin, opportunityToRoundRobin.OwnerId);
        }

        return stdController.cancel();
	}

    public void assignAccountOwner(Account accountToRoundRobin, Id OwnerId)
    {
        accountToRoundRobin.OwnerId = OwnerId;
        accountToRoundRobin.Transfer_Date__c = Datetime.now();
        accountToRoundRobin.Qualifier__c = UserInfo.getUserId();
        update accountToRoundRobin;
    }


	/**
	 * Triggered by the button click, this has some additional functionality than the automated save on page load.
	 * @author Steve O'Neal
	 * @date   2018-01-10
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6573
	 */
	public PageReference saveOpportunityManual()
	{
		okToAutoSubmit = false;

		// first, just save the Acconut and Opportunity.  It may be that we've updated some fields on the account to clear an error
		opportunityToRoundRobin.n2de__is_trigger_enabled__c = false;

		stdController.save();
		update prvAccountToRoundRobin;
		prvAccountToRoundRobin = getAccount();

		return saveOpportunity();
	}

	public PageReference saveOpportunity()
	{
		//throw new ApplicationException('Opportunity:' + opportunityToRoundRobin + ' Account:' + opportunityToRoundRobin.Account);

		/**
		 * if:
		 * 		a) The Account and Opportunity have the same owner
		 * 		b) -or- The owner is The BigCommerce Team
		 * 		c) -or- The Account owner is inactive
		 * 		d) -or- The Account owner does not belong to the sales team 
		 * 		e) -or- The Account owner does not belong to the territory of the Account
		 * then:
		 * 		a) Immediately round robin the Opportunity
		 * 		b) Copy the new Opportunity owner to the Account
		 * else:
		 * 		a) Assign the Opportunity owner to the Account's owner
		 */
		
		// Initialize the variables
		okToAutoSubmit = false;
		boolean roundRobinTheOpportunity = false;
		boolean assignAccountOwnerToOpportunityOwner = false;
		boolean assignOpportunityOwnerToAccountOwner = false;
		boolean assignAccountToBigCommerceTeam = false;

		opportunityToRoundRobin.Transfer_via_Round_Robin__c = false;
		opportunityToRoundRobin.Transfer_Date__c = null;
		opportunityToRoundRobin.Round_Robin_User__c = null;
		opportunityToRoundRobin.n2de__is_trigger_enabled__c = false;

		// Check to see if the Opportunity should be round robin'ed
		if (opportunityToRoundRobin.OwnerId == opportunityToRoundRobin.Account.OwnerId)
		{
			roundRobinTheOpportunity = true;
			assignAccountOwnerToOpportunityOwner = true;
		}
		else if (opportunityToRoundRobin.Account.OwnerId == bigCommerceTeamUser.Id)
		{
			roundRobinTheOpportunity = true;
			assignAccountOwnerToOpportunityOwner = true;
		}
		else if (opportunityToRoundRobin.Account.Owner.IsActive == false)
		{
			roundRobinTheOpportunity = true;
			assignAccountOwnerToOpportunityOwner = true;
		}
        else
		{
			// we need to check if the account owner is in the right spot based on territory and sales team
			boolean territoryIsOK = true;
			boolean salesTeamIsOK = true;
	
            if (opportunityToRoundRobin.Account.Territory__c != null)
			{
				territoryIsOK = UserHasFlag(opportunityToRoundRobin.Account.Territory__c, 'Territory', opportunityToRoundRobin.Account.OwnerId);
			}

			if (opportunityToRoundRobin.Account.Sales_Team_Calculated__c != null)
			{
				salesTeamIsOK = UserHasFlag(opportunityToRoundRobin.Account.Sales_Team_Calculated__c, 'Sales Team', opportunityToRoundRobin.Account.OwnerId);
			}

			if (territoryIsOK && salesTeamIsOK)
			{
				assignOpportunityOwnerToAccountOwner = true;
			}
			else
			{
				roundRobinTheOpportunity = true;
				assignAccountOwnerToOpportunityOwner = true;
			}
		}

        // assign ownership
		if (assignOpportunityOwnerToAccountOwner)
		{
			opportunityToRoundRobin.OwnerId = opportunityToRoundRobin.Account.OwnerId;
		}
		else if (roundRobinTheOpportunity)
		{
			opportunityToRoundRobin.Transfer_via_Round_Robin__c = true;
			opportunityToRoundRobin.Transfer_Date__c = DateTime.now();
			opportunityToRoundRobin.Round_Robin_User__c = UserInfo.getUserId();
		}

		PageReference retVal = stdController.save();
		// if errors happened, display them onscreen
		if (retVal == null)
		{
			return retVal;
		}

		// if we've gotten this far, there must have been no errors.  Go to the final round robin page.
		retVal = Page.RoundRobinOpportunityFinal;
		retVal.getParameters().put('id', stdController.getId());
		retVal.getParameters().put('assignAccountOwnerToOpportunityOwner', string.valueOf(assignAccountOwnerToOpportunityOwner));
        retVal.setRedirect(true);
		return retVal;
	}
	
	public PageReference Cancel()
	{
		return stdController.cancel();
	}


	private boolean UserHasFlag(string flag, string category, ID userId)
	{
		boolean retVal = false;

		List<n2de__Tag_User__c> tagUserList = [Select Id from n2de__Tag_User__c where n2de__User__c = :userId and n2de__Tag_Value__r.Name = :flag and n2de__Tag_Value__r.n2de__Tag_Category__r.Name = :category];
		if (tagUserList.size() > 0)
		{
			retVal = true;
		}

		return retVal;
	}

}