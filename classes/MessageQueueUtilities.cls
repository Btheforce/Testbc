global with sharing class MessageQueueUtilities 
{
	global static string taskStringCreateOpportunityProductHistory = 'Create Opportunity Product History';
	global static string taskStringCreateOpportunityContactRoles = 'Create Opportunity Contact Roles';
	global static string taskStringCreateOpportunityLineItems = 'Create Opportunity Line Items';
	global static string taskStringDeleteOpportunityLineItems = 'Delete Opportunity Line Items';
	global static string taskStringUpdateOpportunity = 'Update Opportunity';
	/**
	 * New functionality for creating cases when an opportunity closes
	 * @author Steve O'Neal
	 * @date   2018-04-06
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-7040
	 */
	global static string taskStringCreateCase = 'Create Case';

	public static void setStatusForMessageQueue(Opportunity_Message_Queue__c OMQRecord, Database.UpsertResult saveResult)
	{
		setStatusForMessageQueueGeneric(OMQRecord, saveResult.getErrors(), saveResult.getId());
	}

	public static void setStatusForMessageQueue(Opportunity_Message_Queue__c OMQRecord, Database.SaveResult saveResult)
	{
		setStatusForMessageQueueGeneric(OMQRecord, saveResult.getErrors(), saveResult.getId());
	}

	public static void setStatusForMessageQueue(Staging_Object_Message_Queue__c SOMQRecord, Database.UpsertResult saveResult)
	{
		setStatusForMessageQueueGeneric(SOMQRecord, saveResult.getErrors(), saveResult.getId());
	}

	public static void setStatusForMessageQueue(Staging_Object_Message_Queue__c SOMQRecord, Database.SaveResult saveResult)
	{
		setStatusForMessageQueueGeneric(SOMQRecord, saveResult.getErrors(), saveResult.getId());
	}

	private static void setStatusForMessageQueueGeneric(sObject MQRecord, List<Database.Error> errors, Id salesforceRecordId)
	{

		if (errors.size() == 0)
		{
			// only update the record if it's still in the 'New' state.
			if (String.valueOf(MQRecord.get('Status__c')).equalsIgnoreCase('New'))
			{
				MQRecord.put('Status__c', 'Success');
				MQRecord.put('Message__c', '');
				MQRecord.put('Salesforce_Record_Id__c', salesforceRecordId);
			}
		}
		else
		{
			MQRecord.put('Status__c', 'Error');
			string errorMessage = 'Failed to save record\r\n';
			for (Database.Error dbError : errors)
			{
				errorMessage += 'Status Code: ' + dbError.getStatusCode() + '\r\n';
				errorMessage += 'Fields: ' + dbError.getFields() + '\r\n';
				errorMessage += 'Message: ' + dbError.getMessage() + '\r\n\r\n';
			}

			if (errorMessage.length() > 32000)
			{
    			errorMessage = errorMessage.Left(32000);
			}

			MQRecord.put('Message__c', errorMessage);
		}

		System.debug(MQRecord);
	}


	/**
	 * Creates retry messages for any Message Queue and sets their status to New
	 * @author Steve O'Neal
	 * @date   2017-04-26
	 * @ticket link             https://jira.bigcommerce.com/browse/BAP-5473
	 * @param  originalMessages The messages to retry
	 */
	public static void createRetryMessages(List<sObject> originalMessages)
	{
		System.debug(originalMessages);
		createRetryMessages(originalMessages, 'New');
	}


	/**
	 * For weirdo message queues that want to set their retries at a different status, this lets you explicitly set the desired Status.
	 * @author Steve O'Neal
	 * @date   2017-04-26
	 * @ticket link             https://jira.bigcommerce.com/browse/BAP-5473
	 * @param  originalMessages The messages to retry
	 * @param  nextStatus       The desired status for the retry messages
	 */
	public static void createRetryMessages(List<sObject> originalMessages, string nextStatus)
	{
		System.debug(originalMessages);
		List<sObject> mqsToRetryList = new List<sObject>();

		for (sObject sobj : originalMessages)
   		{
   			if (String.valueOf(sobj.get('Status__c')).equalsIgnoreCase('Error') && Boolean.valueOf(sobj.get('Retry_Processing_On_Error__c')))
   			{
   				System.debug(sobj);
   				sObject MQRetry = sobj.clone();
                MQRetry.put('Status__c', nextStatus);
                MQRetry.put('Message__c', '');
                integer attemptNumber = (Integer.valueOf(MQretry.get('Attempt_Number__c')) == null)?1:Integer.valueOf(MQretry.get('Attempt_Number__c'));
                attemptNumber++;
                MQretry.put('Attempt_Number__c', attemptNumber);
                mqsToRetryList.add(MQretry);
   			}
		}

		if (mqsToRetryList.size() > 0)
		{
			/**
			 * Made the insert not fail the entire batch if one of the queue records was deleted
			 * @author Steve O'Neal
			 * @date   2018-02-09
			 * @ticket link             https://jira.bigcommerce.com/browse/BAP-6775
			 */
			Database.insert(mqsToRetryList, False);
		}

		System.debug(mqsToRetryList);
	}
}