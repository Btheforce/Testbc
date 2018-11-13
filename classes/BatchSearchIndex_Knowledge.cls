global class BatchSearchIndex_Knowledge implements Database.Batchable<sObject>, Database.Stateful
{
	global Search_Index_Object__c currentSearchObject = null;
	global Set<string> knowledgeArticleBodyFieldSet = new Set<string>();
	global string knowledgeTableName = '';
	global string lastModifiedDate = null;
	global Set<string> knowledgeFieldNameSet = new Set<string>();
	global sObjectType knowledgeArticleSObjectType = null;
	private DateTime processingStarted;
	
	public String query;
	
	/**
	 * Instantiates a BatchSearchIndex_Knowledge
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-5098
	 */
	global BatchSearchIndex_Knowledge() 
	{
   		System.debug('Instantiating');

   		// when adding to this list, always add as lowercase
   		knowledgeFieldNameSet.add('id');
   		knowledgeFieldNameSet.add('articlenumber');
   		knowledgeFieldNameSet.add('knowledgearticleid');
   		knowledgeFieldNameSet.add('urlname');

   		processingStarted = DateTime.now();
	}
	

	/**
	 * Gets the records from the DB
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5098
   	 * @param  BC         Batchable Context
	 */
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
   		System.debug('Starting');
		if (currentSearchObject == null)
		{
			List<Search_Index_Object__c> activeSearchObjects = getActiveSearchObjects();
		 	if (activeSearchObjects.size() > 0)
		 	{
			 	// if no index was assigned, start with the first active record in the list
				currentSearchObject = activeSearchObjects[0];
			}
		}

		if (currentSearchObject == null)
		{
			System.debug('There are no active Knowledge article types associated with a Search Index');
			return null;
		}
		else
		{
			System.debug(currentSearchObject);
		}

		// create an sObject based on the Search Object
		knowledgeArticleSObjectType = Schema.getGlobalDescribe().get(currentSearchObject.Name);

		// see if there is a Field Set that matches
		if (knowledgeArticleSObjectType.getDescribe().FieldSets.getMap().containsKey('Search_Index'))
		{
			FieldSet knowledgeArticleFieldSet = knowledgeArticleSObjectType.getDescribe().FieldSets.getMap().get('Search_Index');

			for (Schema.FieldSetMember fsMember : knowledgeArticleFieldSet.getFields())
			{
				knowledgeFieldNameSet.add(fsMember.getFieldPath().ToLowerCase());

				if (fsMember.getRequired())
				{
					knowledgeArticleBodyFieldSet.add(fsMember.getFieldPath().ToLowerCase());
				}
			}
		}

		knowledgeTableName = currentSearchObject.Name;
		lastModifiedDate = formatDateTimeForQuery(currentSearchObject.Index_Last_Updated__c);

		// build the query
		query = 'SELECT ';
		string comma = '';
		for (string fieldName : knowledgeFieldNameSet)
		{
			query += comma + fieldName;
			comma = ', ';
		}
		query += ' FROM ' + knowledgeTableName;
		query += ' WHERE isdeleted = false and PublishStatus=\'Online\' and Language=\'en_US\' and islatestversion = true and lastmodifieddate >= ' + lastModifiedDate;
		//query += ' AND articleNumber = \'000016135\'';
		System.debug(query);

		return Database.getQueryLocator(query);
	}


	/**
   	 * Processes a subset of the records
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5098
   	 * @param  BC         Batchable Context
   	 * @param  scope      The subset of records to be processed
	 */
   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
   		System.debug('Executing');
		// loop through all of the recently updated knowledge articles and create a serialized JSON message for the search engine

		Set<Id> knowledgeArticleIds = new Set<Id>();
		Set<Id> knowledgeArticleVersionIds = new Set<Id>();

		// collect all of the article ids
		string datacategoryquery = 'Select Id, ParentId, toLabel(dataCategoryName), dataCategoryGroupName from ' + knowledgeTableName.ToLowerCase().Replace('__kav', '__DataCategorySelection') + ' where ParentId in (';
		string comma = '';
		for (sObject sobj : scope)
		{
			datacategoryquery += comma + '\'' + String.valueOf(sobj.get('Id')) + '\'';
			comma = ', ';
			knowledgeArticleVersionIds.add((Id)sobj.get('id'));
			knowledgeArticleIds.add((Id)sobj.get('knowledgearticleid'));
		}
		datacategoryquery += ')';

		// collect all of the votes and views associated with the articles
		List<KnowledgeArticleViewStat> viewStats = [Select Id, ParentId, NormalizedScore, ViewCount from KnowledgeArticleViewStat where ParentId = :knowledgeArticleIds order by ParentId, Id asc];
		List<KnowledgeArticleVoteStat> voteStats = [Select Id, ParentId, NormalizedScore from KnowledgeArticleVoteStat where ParentId = :knowledgeArticleIds order by ParentId, Id asc];

		// add data categories and map them to the article id
		system.debug(datacategoryquery);
		List<sObject> dataCategories = Database.query(datacategoryquery);
		Map<Id, List<sObject>> mapDataCategories = new Map<Id, List<sObject>>();
		for (sObject sobj : dataCategories)
		{
			if (!mapDataCategories.containsKey((id)sobj.get('ParentId')))
			{
				mapDataCategories.put((id)sobj.get('ParentId'), new List<sObject>());
			}
			mapDataCategories.get((id)sobj.get('ParentId')).add(sobj);
		}
		System.debug(mapDataCategories);

		// get a list of all available topics
		List<TopicAssignment> topicAssignments = [Select Id, EntityId, EntityKeyPrefix, EntityType, NetworkId, TopicId, Topic.Name from TopicAssignment where EntityId = :knowledgeArticleVersionIds];
		// store topics in a map by article Id
		Map<Id, List<TopicAssignment>> mapTopicAssignments = new Map<Id, List<TopicAssignment>>();
		for (TopicAssignment ta : topicAssignments)
		{
			if (!mapTopicAssignments.containsKey((id)ta.get('EntityId')))
			{
				mapTopicAssignments.put((id)ta.get('EntityId'), new List<TopicAssignment>());
			}
			mapTopicAssignments.get((id)ta.get('EntityId')).add(ta);
		}

		// query the db to get the related 


		string regex_DivTag = Label.Search_Index_Regex_Knowledge;
		System.debug(regex_DivTag);
		Pattern divTagPattern = Pattern.compile(regex_DivTag);


		List<Search_Index_Record__c> searchIndexRecordsUpsert = new List<Search_Index_Record__c>();

		for (sObject sobj : scope)
		{
			boolean entryCreated = false;
			decimal voteNormalizedScore = 0;
			decimal viewNormalizedScore = 0;
			decimal viewCount = 0;

			// get vote and view counts
			for (KnowledgeArticleViewStat viewStat : viewStats)
			{
				if (viewStat.ParentId == (Id)sobj.get('knowledgearticleid'))
				{
					viewNormalizedScore = viewStat.NormalizedScore;
					viewCount = viewStat.ViewCount;
					break;
				}
			}

			for (KnowledgeArticleVoteStat voteStat : voteStats)
			{
				if (voteStat.ParentId == (Id)sobj.get('knowledgearticleid'))
				{
					voteNormalizedScore = voteStat.NormalizedScore;
					break;
				}
			}

			// parse the knowledge article body
			for (string articleBodyFieldName : knowledgeArticleBodyFieldSet)
			{
				string kaBodyString = String.valueOf(sobj.get(articleBodyFieldName));

				try
				{
					//System.debug(kaBodyString);
					Matcher divMatcher = divTagPattern.matcher(kaBodyString);

					// loop through the matches and make a search index for each match
					while (divMatcher.find())
					{
						System.debug('Found a regex match');
						entryCreated = true;
						searchIndexRecordsUpsert.add(fillSearchIndexRecord(String.valueOf(sobj.get('Id')), String.valueOf(sobj.get('knowledgearticleid')) + '-' + divMatcher.group(1), currentSearchObject.Id, makeKnowledgeJSON(sobj, divMatcher.group(1), divMatcher.group(3), divMatcher.group(4), voteNormalizedScore, viewNormalizedScore, viewCount, mapDataCategories.get((id)sobj.get('Id')), mapTopicAssignments.get((id)sobj.get('Id')))));
					}
				}
				catch (Exception e)
				{
					System.debug(e);
				}

				// no matches found in the article body!
				if (!entryCreated)
				{
					System.debug('"Split" fields were defined in the fieldset, but the contents did not match the regex');
					entryCreated = true;
					searchIndexRecordsUpsert.add(fillSearchIndexRecord(String.valueOf(sobj.get('Id')), String.valueOf(sobj.get('knowledgearticleid')), currentSearchObject.Id, makeKnowledgeJSON(sobj, '', '', kaBodyString, voteNormalizedScore, viewNormalizedScore, viewCount, mapDataCategories.get((id)sobj.get('Id')), mapTopicAssignments.get((id)sobj.get('Id')))));
				}
			}

			// no article body defined!
			if (!entryCreated)
			{
				System.debug('No split fields were defined in the fieldset');
				entryCreated = true;
				searchIndexRecordsUpsert.add(fillSearchIndexRecord(String.valueOf(sobj.get('Id')), String.valueOf(sobj.get('knowledgearticleid')), currentSearchObject.Id, makeKnowledgeJSON(sobj, '', '', '', voteNormalizedScore, viewNormalizedScore, viewCount, mapDataCategories.get((id)sobj.get('Id')), mapTopicAssignments.get((id)sobj.get('Id')))));
			}
		}


		Database.upsert(searchIndexRecordsUpsert, Search_Index_Record__c.fields.Search_Index_Record_Key__c, false);


		currentSearchObject.Index_Last_Updated__c = processingStarted;
		update currentSearchObject;
	}

	
	/**
	 * Post-processing functionality
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5098
	 * @param  BC         Batchable Context
	 */
	global void finish(Database.BatchableContext BC) 
	{
		System.debug('Finishing');
		List<Search_Index_Object__c> activeSearchObjects = getActiveSearchObjects();
		Search_Index_Object__c nextSearchObject = null;

		for (integer i = 0; i < activeSearchObjects.size() - 1; i++)
		{
			if (currentSearchObject.Id == activeSearchObjects[i].Id)
			{
				nextSearchObject = activeSearchObjects[i + 1];
			}
		}

		// see if there are any more search index objects for Knowledge.  If there are, process the next item in the list.  If there aren't, try calling the next batch job in the sequence.
		if (nextSearchObject != null)
		{
			BatchSearchIndex_Knowledge bsik = new BatchSearchIndex_Knowledge();
			bsik.currentSearchObject = nextSearchObject;
			Database.ExecuteBatch(bsik);
		}
		else
		{
			BatchableChain.Execute(this);
		}
		
	}


	/**
	 * Creates a Search_Index_Record__c
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link                    https://jira.bigcommerce.com/browse/BAP-5098
	 * @param  strSalesforceRecordId   The ID of the object in Salesforce
	 * @param  strSearchIndexRecordKey The key for the search index record
	 * @param  idSearchIndexObject     The key for the search index
	 * @param  strBody                 Body of the search index record
	 * @return                         Instance of a search index record
	 */
	private static Search_Index_Record__c fillSearchIndexRecord(string strSalesforceRecordId, string strSearchIndexRecordKey, Id idSearchIndexObject, string strBody)
	{
		Search_Index_Record__c searchIndexRecord = new Search_Index_Record__c();
		searchIndexRecord.Action__c = 'Upsert Record';
		searchIndexRecord.Status__c = 'New';
		searchIndexRecord.Salesforce_Record_ID__c = strSalesforceRecordId;
		searchIndexRecord.Search_Index_Record_Key__c = strSearchIndexRecordKey;
		searchIndexRecord.Search_Index_Object__c = idSearchIndexObject;
		searchIndexRecord.Body__c = strBody;
		return searchIndexRecord;
	}


	/**
	 * Gets all of the active search index objects
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-5098
	 * @return A list of all active search index objects
	 */
	private List<Search_Index_Object__c> getActiveSearchObjects()
	{
		List<Search_Index_Object__c> retVal =  [Select Search_Index__r.Id, Search_Index__r.Name, Search_Index__r.Active__c, 
											     	   Id, Name, Active__c, Is_Knowledge_Article__c, Index_Last_Updated__c, Root_URL__c
										  		from Search_Index_Object__c 
										  		where Search_Index__r.Active__c = true 
										  		  and Active__c = true
										  		  and Is_Knowledge_Article__c = true
										  		Order By Search_Index__r.Name, Name];

	  	return retVal;
	}


	/**
	 * Formats a datetime for making a SOQL call
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5098
	 * @param  dttm       The datetime to format
	 * @return            A string representing the datetime
	 */
	global static string formatDateTimeForQuery(DateTime dttm)
	{
		Datetime dt = dttm;
		if (dt == null)
		{
			dt = Datetime.newInstance(1900,1,1,0,0,0);
		}
		string yearVal = String.valueOf(dt.yearGmt());
		string monthVal = String.valueOf('00' + String.valueOf(dt.monthGmt())).right(2);
		string dayVal = String.valueOf('00' + String.valueOf(dt.dayGmt())).right(2);
		string hourVal = String.valueOf('00' + String.valueOf(dt.hourGmt())).right(2);
		string minuteVal = String.valueOf('00' + String.valueOf(dt.minuteGmt())).right(2);
		string secondVal = String.valueOf('00' + String.valueOf(dt.secondGmt())).right(2);

		return yearVal + '-' + monthVal + '-' + dayVal + 'T' + hourVal + ':' + minuteVal + ':' + secondVal + 'z';
	}


	/**
	 * Builds a JSON string from a knowledge article section
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link                   https://jira.bigcommerce.com/browse/BAP-5098
	 * @param  kaSobj                 The generic sObject representing the knowledge article
	 * @param  sectionId              The unique id of the section
	 * @param  section                The section name
	 * @param  sectionContent         The content of the section
	 * @param  voteNormalizedScore    The vote score
	 * @param  viewNormalizedScore    The view score
	 * @param  viewCount              The view count
	 * @param  dataCategorySelections The categories associated with the article
	 * @param  topicAssignments       The topics associated with the article
	 * @return                        A JSON string
	 */
	private string makeKnowledgeJSON(sObject kaSobj, string sectionId, string section, string sectionContent, decimal voteNormalizedScore, decimal viewNormalizedScore, decimal viewCount, List<sObject> dataCategorySelections, List<TopicAssignment> topicAssignments)
	{
		string retVal = '';
		//System.debug(kaSobj);
		DescribeSObjectResult kaSObjectDescribe = kaSobj.getSObjectType().getDescribe();

		JSONGenerator jsonGen = JSON.createGenerator(true);
		jsonGen.writeStartObject();

		// add the standard fields that every KA must have in the search results
		jsonGen.writeStringField('objectID', String.valueOf(kaSobj.get('Id')));
		string rootURL = currentSearchObject.Root_URL__c;
		if (String.isEmpty(rootURL))
		{
			rootURL = 'https://login.salesforce.com/';
		}
		// make sure the URL ends in a slash
		if (rootURL.Right(1) != '/')
		{
			rootURL += '/';
		}
		if(sectionId.equalsIgnoreCase('intro')){ //By Sruthi K - BAP 7450
            jsonGen.writeStringField('url', rootURL + String.valueOf(kaSobj.get('urlname')));
        }else{
            jsonGen.writeStringField('url', rootURL + String.valueOf(kaSobj.get('urlname')) + '#' + sectionId);
        }

		jsonGen.writeStringField('Section', StripHTML(section));

		jsonGen.writeStringField('Section_Content', StripHTML(sectionContent));
		
		jsonGen.writeNumberField('voteNormalizedScore', voteNormalizedScore);

		jsonGen.writeNumberField('viewCount', viewCount);
		
		jsonGen.writeNumberField('viewNormalizedScore', viewNormalizedScore);

		// loop through the entire collection of fields
		for (string fieldName : knowledgeFieldNameSet)
		{
			// ignore any "split" fields to avoid entering the field data twice
			if (!knowledgeArticleBodyFieldSet.contains(fieldName))
			{
				// add the field to the JSON
                DisplayType sourceFieldType = kaSObjectDescribe.fields.getMap().get(fieldName).getDescribe().getType();

                if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.String_Type)
                {
                	jsonGen.writeStringField(fieldName, (String)kaSobj.get(fieldName));
                } 
                else if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.Integer_Type)
                {
                	jsonGen.writeNumberField(fieldName, (Integer)kaSobj.get(fieldName));
                } 
                else if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.ID_Type)
                {
                	jsonGen.writeIdField(fieldName, (Id)kaSobj.get(fieldName));
                } 
                else if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.Double_Type)
                {
                	jsonGen.writeNumberField(fieldName, (Double)kaSobj.get(fieldName));
                } 
                else if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.DateTime_Type)
                {
                	jsonGen.writeDateTimeField(fieldName, (DateTime)kaSobj.get(fieldName));
                } 
                else if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.Date_Type)
                {
                	jsonGen.writeDateField(fieldName, (Date)kaSobj.get(fieldName));
                } 
                else if(SObjectUtils.getGenericType(sourceFieldType) == SObjectUtils.GenericFieldDisplayType.Boolean_Type)
                {
                	jsonGen.writeBooleanField(fieldName, (Boolean)kaSobj.get(fieldName));
                } 
                else
                {
                    system.debug(LoggingLevel.WARN, 'NO TYPE MATCH for ' + sourceFieldType);
                }
			}
		}

		// write the topics
		List<string> listStrTopicAssignments = new List<string>();
		if (topicAssignments != null)
		{
			for (TopicAssignment ta : topicAssignments)
			{
				listStrTopicAssignments.add(ta.Topic.Name);
			}
		}
		jsonGen.writeObjectField('Topics', listStrTopicAssignments);


		// write the data categories
		List<string> listStrDataCategories = new List<string>();
		if (dataCategorySelections != null)
		{
			for (sobject dcs : dataCategorySelections)
			{
				listStrDataCategories.add(String.valueOf(dcs.get('dataCategoryName')));
			}
		}
		jsonGen.writeObjectField('Data_Category', listStrDataCategories);

		// end the enclosing object
		jsonGen.writeEndObject();

		retVal = jsonGen.getAsString();

		//System.debug(retVal);
		return retVal;
	}


	/**
	 * Removes any HTML tags from a string
	 * @author Steve O'Neal
	 * @date   2017-07-26
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-5098
	 * @param  strBody    The text to remove tags from
	 * @return            The formatted strBody
	 */
	public static string StripHTML(string strBody)
	{
		if (strBody == null)
		{
			return '';
		}
		else
		{
			return strBody.replaceAll('<[^>]+>','');
		}
	}

}