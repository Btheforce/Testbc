/**
 * TerritoryUtil - used for calculating a record's territory based on their address information
 * @author Steve O'Neal
 * @date   2017-12-19
 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6573
 */
public with sharing class TerritoryUtil 
{
    // define a default Territory
    String defaultTerritory = 'Other';
	// define the "Match on Field" value and character to truncate (eg, "truncate 'Zip Code' before the hyphen")
	String sTruncateMatchVal = 'Zip Code';
    
    List<Territory_Mapping__mdt> TerritoryMappings;
	
	/**
	 * Instantiator
	 * @author Steve O'Neal
	 * @date   2017-12-19
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-6573
	 */
	public TerritoryUtil()
	{
		TerritoryMappings = [SELECT MasterLabel, Match_On_Field__c, Territory__c, Territory__r.MasterLabel, Parent_Territory__c, Parent_Territory__r.MasterLabel, Range_Max__c
                             FROM Territory_Mapping__mdt 
                             ORDER BY Match_On_Field__c ASC, MasterLabel ASC];
	}


	/**
	 * Sets a territory on an Account
	 * @author Steve O'Neal
	 * @date   2017-12-19
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6573
	 */
	public void SetTerritory(List<Account> accounts)
	{
		SetTerritoryGeneric(accounts);
	}


	/**
	 * Sets a territory on a Lead
	 * @author Steve O'Neal
	 * @date   2017-12-19
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6573
	 */
	public void SetTerritory(List<Lead> leads)
	{
		SetTerritoryGeneric(leads);
	}
	

	/**
	 * Sets a territory on an sObject (currently only supports leads and accounts)
	 * @author Steve O'Neal
	 * @date   2017-12-19
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-6573
	 */
	private void SetTerritoryGeneric(List<sObject> sObjects)
	{
		// API name of the territory field of the current object type
		String territoryField = '';

		// Create a map of fields that we want to allow the code to search against to identify territory.
		// Order of maps within the list is important. First map entered should be considered more important, anything entered after the first map will be only be used if no address information was found.
		List<Map<String, String>> ListOfMap_AddressType_FieldName = new List<Map<String, String>>();

		if (sObjects.size() > 0)
		{
			Schema.SObjectType sobjType = sObjects[0].getSObjectType();

			// identify what the field names are on each object.  Make sure to put the less reliable field first and the most reliable field on the bottom.
			// This technique allows us to get more precise as we move down the fields, but if the more precise data does not exist we can fall back on the existing value without a bunch of nested if/else statements.
			if (Schema.Account.getSObjectType() == sobjType)
			{
				// 1st Tier Address Info - Account Billing Address
				ListOfMap_AddressType_FieldName.add(new Map<String, String>());
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Country', 'BillingCountry');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('State', 'BillingState');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Zip Code', 'BillingPostalCode');		

				// 2nd Tier Address Info - Account Datanyze Address
				ListOfMap_AddressType_FieldName.add(new Map<String, String>());
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Country', 'Datanyze_Country__c');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('State', 'Datanyze_State__c');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Zip Code', 'Datanyze_Zip__c');		
				
				territoryField = 'Territory__c';
			}
			else if (Schema.Lead.getSObjectType() == sobjType)
			{
				// 1st Tier Address Info - Lead Address
				ListOfMap_AddressType_FieldName.add(new Map<String, String>());
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Country', 'Country');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('State', 'State');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Zip Code', 'PostalCode');		

				// 2nd Tier Address Info - Lead Datanyze Address
				ListOfMap_AddressType_FieldName.add(new Map<String, String>());
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Country', 'Datanyze_Country__c');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('State', 'Datanyze_State__c');		
				ListOfMap_AddressType_FieldName[ListOfMap_AddressType_FieldName.size() - 1].put('Zip Code', 'Datanyze_Zip__c');		
				
				territoryField = 'Territory__c';
			}
			else
			{
				throw new ApplicationException(sobjType.getDescribe().Name);
			}
		}

		for (sObject sobj : sObjects)
		{
            // default Territory to Other, changed by Ezra Kenigsberg 2018-08-08
			sobj.put(territoryField, defaultTerritory);

			// Fields will be tested in the order their type is defined here.
			Set<String> orderOfFieldTypes = new Set<String>();
			// we loop through the least specific to the most specific, and overwrite the territory information if a more detailed piece of data is found
			orderOfFieldTypes.add('Country');
			orderOfFieldTypes.add('State');
			orderOfFieldTypes.add('Zip Code');
			
			// loop through all of the defined address tiers
			for (Map<String, String> map_AddressType_FieldName : ListOfMap_AddressType_FieldName)
			{
                /* REMMED: I THINK IT RECAPITULATES parentTerrIsValid LOGIC BELOW --ejk 2018-08-10
                if ((string)sobj.get(territoryField) != defaultTerritory)
                {
                    // if we've already found address information in a higher tier and mapped it to a territory, stop processing this record, even if no match was found
                    break;
                }
                */
				for (String fieldType : orderOfFieldTypes)
				{
					// only loop through the fields if we've defined a value for this address type
					if (map_AddressType_FieldName.containsKey(fieldType))
					{
						String sObjFieldValue = (string)sobj.get(map_AddressType_FieldName.get(fieldType));

						// if there's no value in this address field, there's no need to see if it's a match
						if (String.isNotBlank(sObjFieldValue))
						{
							// loop through the matching values and see if there's a match
							for (Territory_Mapping__mdt territoryMapping : TerritoryMappings)
							{
								// this is the same field type we're looking for (ie Zip Code, Country or State)
								if (territoryMapping.Match_On_Field__c == fieldType)
								{
									boolean mapIsAMatch = false;
                                    boolean parentTerrIsValid = true;
                                    if(string.isNotBlank(territoryMapping.Parent_Territory__c))
                                    {
                                        /* DIAGOSTIC SYSTEM.DEBUG STUFF
                                        System.debug('ggg defaultTerritory: ' + defaultTerritory);
                                        System.debug('ggg sobj.get(territoryField): ' + sobj.get(territoryField));
                                        System.debug('ggg territoryMapping.Parent_Territory__r.MasterLabel: ' + territoryMapping.Parent_Territory__r.MasterLabel);
                                        System.debug('ggg test equals: ' + (territoryMapping.Parent_Territory__r.MasterLabel == sobj.get(territoryField)));
										*/
                                        parentTerrIsValid = 
                                            (
                                                sobj.get(territoryField) == defaultTerritory ||
                                                territoryMapping.Parent_Territory__r.MasterLabel == sobj.get(territoryField)
                                            );
                                    }
                                    if(parentTerrIsValid)
                                    {
                                        String sObjFieldValuePart = sObjFieldValue;
                                        if (territoryMapping.Match_On_Field__c == sTruncateMatchVal)
                                        {
                                            sObjFieldValuePart = sObjFieldValue.left(territoryMapping.MasterLabel.length());
                                        }
                                        if (string.isNotBlank(territoryMapping.Range_Max__c))
                                        {
                                            
                                            mapIsAMatch =
                                                ( 
                                                    sObjFieldValuePart >= territoryMapping.MasterLabel &&
                                                    sObjFieldValuePart <= territoryMapping.Range_Max__c
                                                );
                                        }
                                        else
                                        {
                                            mapIsAMatch = 
                                                (
                                                    sObjFieldValuePart.equalsIgnoreCase(territoryMapping.MasterLabel)
                                                );
                                        }
                                    }                                 
									// update the territory
									if (mapIsAMatch)
									{
										sobj.put(territoryField, territoryMapping.Territory__r.MasterLabel);
										break;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}