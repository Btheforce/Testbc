@isTest
private class RVMemberTriggerHandlerTest {
	/**
	 * Moved the creation of RV Account and RV Member to the TestDataFactory
	 * @author Steve O'Neal
	 * @date   2018-04-30
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-7204
	 */

	
	@testSetup static void dataSetup(){

		// Create users by profile name => API User: Treehouse 
		TestDataGenerator td = new TestDataGenerator();

        List<string> profiles = new List<String>();
        
        Profiles.add('API User: Treehouse');

        List<User> apiUsers = td.getUsers(Profiles);
        
        Integer counter = 1;
        for (User u : apiUsers){
            
            	u.firstName = 'BCTreehouse' + counter;
            	u.lastName =  'apiUser'+ counter;
            	
            	counter = counter + 1;
        }

        update apiUsers;

	} 

	@isTest static void prePopulateTestOne(){

		/**
		 * Test scenario When a new RVMember record is created the ownerId of that record
		 * should be equal to the associated RVAccount ownerId.
		 */
		
        User testUser = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'BCTreehouse1' 
							AND LastName = 'apiUser1' limit 1]; 

		// Create RVAccounts running as API User: Treehouse(firstName = BCTreehouse1, LastName = apiUser1)
        List<rvpe__RVAccount__c> lstRVAccounts;
        system.runAs(testUser){
			 
			lstRVAccounts = TestDataFactory.createTestRVAccounts(1);
        }

        lstRVAccounts = [Select id, name, OwnerId from rvpe__RVAccount__c where Id = :lstRVAccounts[0].Id];
		
		//Create 10 New RVMembers records, associating with lstRVAccounts
		TestDataFactory.createTestRVMembers(10, lstRVAccounts);

		List<rvpe__RVMember__c> lstRVMembers =  [SELECT Id, rvpe__RVAccount__c, OwnerId 
													FROM rvpe__RVMember__c 
													WHERE rvpe__RVAccount__c IN :lstRVAccounts];
		
		//Compare ownerIds
		for(rvpe__RVMember__c rvm : lstRVMembers){

			system.assertEquals(lstRVAccounts[0].OwnerId, rvm.OwnerId);
		}

		/**
		 * Test scenario When an existing RVMember record is edited the ownerId of that record 
		 * should be updated based associated RVAccount ownerId.
		 */
		
		User testUser2 = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'BCTreehouse2' 
							AND LastName = 'apiUser2' limit 1]; 

		// Create RVAccounts running as API User: Treehouse(firstName = BCTreehouse2, LastName = apiUser2)
		List<rvpe__RVAccount__c> lstRVAccounts2;
        system.runAs(testUser2){
			 
			lstRVAccounts2 = TestDataFactory.createTestRVAccounts(1);
        }

        lstRVAccounts2 = [Select id, name, OwnerId from rvpe__RVAccount__c where Id = :lstRVAccounts2[0].Id];

		//Update previous lstRVMembers with new lstRVAccounts2 									
		for(rvpe__RVMember__c rvm : lstRVMembers){	

			rvm.rvpe__RVAccount__c = lstRVAccounts2[0].Id;
		}

		update lstRVMembers;

		List<rvpe__RVMember__c> lstRVMembers2 =  [SELECT Id, rvpe__RVAccount__c, OwnerId 
													FROM rvpe__RVMember__c 
													WHERE rvpe__RVAccount__c IN :lstRVAccounts2];

		//Compare ownerIds
		for(rvpe__RVMember__c rvm : lstRVMembers2){

			system.assertEquals(lstRVAccounts2[0].OwnerId, rvm.OwnerId);
		}

	}

	@isTest static void contactSyncTest(){

		/**
		 * Test scenario When a new RVMember record is created, create a new contact
		 * if does not exists one. And set the contact fields with following details.
		 * contact.AccountId <= rvpe__RVMember__c.RV_Account_SF_Account__c;
		 * contact.RV_Account__c <= rvpe__RVMember__c.rvpe__RVAccount__c;
		 * contact.Type__c <='Partner RV Member'; 
		 */
		
		User testUser = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'BCTreehouse1' 
							AND LastName = 'apiUser1' limit 1]; 

		// Create RVAccounts running as API User: Treehouse(firstName = BCTreehouse1, LastName = apiUser1)
		List<rvpe__RVAccount__c> lstRVAccounts;
        system.runAs(testUser){
			 
			lstRVAccounts = TestDataFactory.createTestRVAccounts(1);
        }

		//Create 10 New RVMembers records, associating with lstRVAccounts
		List<rvpe__RVMember__c> lstRVMembers = TestDataFactory.createTestRVMembers(10, lstRVAccounts);
		
		//Check for Contacts created for each RV_Member__c
		List<Contact> lstContacts = [SELECT Id, RV_Member__c, RV_Account__c, Type__c 
										FROM Contact WHERE RV_Member__c IN :lstRVMembers];

		System.assertEquals(lstRVMembers.size(), lstContacts.size());

		for(Contact con : lstContacts){

			System.assertEquals(lstRVAccounts[0].Id, con.RV_Account__c );
		}

		/**
		 * Test scenario When an existing RVMember record is edited, update the 
		 * related contacts.
		 */
		
		User testUser2 = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'BCTreehouse2' 
							AND LastName = 'apiUser2' limit 1]; 

		// Create RVAccounts running as API User: Treehouse(firstName = BCTreehouse2, LastName = apiUser2)
		List<rvpe__RVAccount__c> lstRVAccounts2;
        system.runAs(testUser2){
			 
			lstRVAccounts2 = TestDataFactory.createTestRVAccounts(1);
        }

		//Update previous lstRVMembers with new lstRVAccounts2 									
		for(rvpe__RVMember__c rvm : lstRVMembers){	

			rvm.rvpe__RVAccount__c = lstRVAccounts2[0].Id;
		}

		update lstRVMembers;


		//Check for updated Contacts with new lstRVAccounts2[0].Id for each RV_Member__c
		List<Contact> lstContacts2 = [SELECT Id, RV_Member__c, RV_Account__c, Type__c 
										FROM Contact WHERE RV_Member__c IN :lstRVMembers];

		for(Contact con : lstContacts2){

			System.assertEquals(lstRVAccounts2[0].Id, con.RV_Account__c );
		}

	}

	@isTest static void convertLeadsTestOne(){

		/**
		 * Test scenario When a RVMember record is created, Look for Partner Prospect Type Leads 
		 * with the same Email and convert them.
		 */

        // Label.Lead_Type_Partner_Prospect.Split(', ').[0] ==> 'Partner_Prospect' ==> DeveloperName value
        // Label.Lead_Type_Partner_Prospect.Split(', ').[1] ==> 'Partner Prospect' ==> Type__c value
        
        List<String> labelValues = Label.Lead_Type_Partner_Prospect.Split(', ');

		//Create some leads to test LeadCoversion logic
		Schema.RecordType recordType = RecordTypeTools.GetRecordTypeByDeveloperName(Lead.getSObjectType(), labelValues[0]);

		List<Lead> lstLeads = TestDataFactory.createTestLeads(20, true, recordType);
		
		
		User testUser = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'BCTreehouse1' 
							AND LastName = 'apiUser1' limit 1]; 

		// Create RVAccounts running as API User: Treehouse(firstName = BCTreehouse1, LastName = apiUser1)
        system.runAs(testUser){
			 
			 TestDataFactory.createTestRVAccounts(1);
        }
		
		List<rvpe__RVAccount__c> lstRVAccounts = [SELECT Id, Name, OwnerId, Owner.Name
													FROM rvpe__RVAccount__c 
													WHERE OwnerId =: testUser.Id limit 1];

		// Update email and type to match the selection process
		Integer counter = 1;
		for(Lead led : lstLeads){
			led.rvpe__RVAccount__c = lstRVAccounts[0].Id;
			led.Type__c = labelValues[1];
            led.Email = 'BCtestEmail+' + counter + '@BCtestEmail.com'; // Email same as RVMember
            counter = counter + 1;
		}

		update lstLeads;

		//Check leads are not converted so far
		for(Lead led : lstLeads){

			System.assertNotEquals(true, led.IsConverted);
		}

		//Create 20 New RVMembers records, associating with lstRVAccounts
		List<rvpe__RVMember__c> lstRVMembers = new List<rvpe__RVMember__c>();

        counter = 1;
        Set<Integer> extIds = new Set<Integer>();

        for (Integer i = 0; i < 20; i++){

        	Integer extId;

        	rvpe__RVMember__c rvm = new rvpe__RVMember__c();
        
        	rvm.rvpe__RVAccount__c = lstRVAccounts[0].Id;
        	rvm.rvpe__FirstName__c = 'FirstName';
        	rvm.rvpe__LastName__c = 'LastName';
        	rvm.rvpe__UserName__c = 'BCtestEmail+' + counter + '@BCtestEmail.com';
        	rvm.rvpe__Email__c = 'BCtestEmail+' + counter + '@BCtestEmail.com'; // Email same as Leads

        	do{

        		extId = MathUtility.RandomInteger(1000, 9999);

        	}while(extIds.contains(extId));
        	
        	extIds.add(extId);

        	rvm.rvpe__ExtMemberId__c = extId;

        	counter = counter + 1;

        	lstRVMembers.add(rvm);
        }

        Test.startTest();

		insert lstRVMembers;

		Test.stopTest();


		//Pull all the leads and chekc for isConverted
		List<Lead> lstLeadsConverted = [SELECT Id, Email, Type__c, rvpe__RVAccount__c, IsConverted
											FROM Lead 
											WHERE rvpe__RVAccount__c IN :lstRVAccounts];

		for(Lead led : lstLeadsConverted){

			System.assertEquals(true, led.IsConverted);
		}
	}

	@isTest static void convertLeadsTestTwo(){
		/**
		 * Test scenario When a RVMember record is edited, Look for Partner Prospect Type Leads 
		 * with the same Email and convert them. 
		 */
		
		User testUser = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'BCTreehouse1' 
							AND LastName = 'apiUser1' limit 1]; 

		// Create RVAccounts running as API User: Treehouse(firstName = BCTreehouse1, LastName = apiUser1)
        
        List<rvpe__RVAccount__c> lstRVAccounts;

        system.runAs(testUser){
			 
			 lstRVAccounts = TestDataFactory.createTestRVAccounts(1);
        }

        List<rvpe__RVMember__c> lstRVMembers = TestDataFactory.createTestRVMembers(1, lstRVAccounts);
		
		// Label.Lead_Type_Partner_Prospect.Split(', ').[0] ==> 'Partner_Prospect' ==> DeveloperName value
        // Label.Lead_Type_Partner_Prospect.Split(', ').[1] ==> 'Partner Prospect' ==> Type__c value
        
        List<String> labelValues = Label.Lead_Type_Partner_Prospect.Split(', ');
        //Create a leads to test LeadConvert on update 
		Schema.RecordType recordType = RecordTypeTools.GetRecordTypeByDeveloperName(Lead.getSObjectType(), labelValues[0]);

		List<Lead> lstLeads = TestDataFactory.createTestLeads(1, true, recordType);

		for(Lead led : lstLeads){
			led.rvpe__RVAccount__c = lstRVAccounts[0].Id;
			led.Type__c = labelValues[1];
            led.Email = 'BCtestEmail+update@BCtestEmail.com'; // Email same as RVMember
		}
		
		update lstLeads;

		//Check leads are not converted so far
		for(Lead led : lstLeads){

			System.assertNotEquals(true, led.IsConverted);
		}

		//Update an eixsting RVMember to meet the Lead matching criteria 
		for(rvpe__RVMember__c rv : lstRVMembers){
			rv.rvpe__Email__c = 'BCtestEmail+update@BCtestEmail.com'; // Email same as Leads
		}


		Test.startTest();

		update lstRVMembers;

		Test.stopTest();

		//Pull the converted lead and chekc for isConverted
		Boolean isLeadConverted = [SELECT Id, Email, Type__c, IsConverted
											FROM Lead 
											WHERE Email = 'BCtestEmail+update@BCtestEmail.com'].IsConverted;


		System.assertEquals(true, isLeadConverted);


	}
	
}