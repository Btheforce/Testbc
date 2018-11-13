global class UserHelper {

	private static User currentUser;
	private static Map<Id,User> userMap;
	private static Map<Id, Profile> profileMap = new Map<Id, Profile>();

	public static Integer getUserMapSize(){
		if(userMap != null) {
			return userMap.size();
		} else {
			return -1;
		}
	}
  
	public static User getCurrentUser() {
		if(currentUser == null) {
			currentUser = [SELECT Id,Email FROM User WHERE Id = :UserInfo.getUserId()];
			if(userMap == null) userMap = new Map<Id,User>();
			userMap.put(currentUser.Id,currentUser);
		}
		return currentUser;
	}
	
	//This method will cache requests to get users in an attempt to reduce the number of queries
	//If the user is in the cache there is no need for a new query
	public static List<User> getUsersFromIds(Set<Id> userIds){
		
		if(userMap == null) userMap = new Map<Id,User>();
		
		List<Id> userIdsNotFound = new List<Id>();
		List<User> users = new List<User>();
		
		for(Id userId : userIds) {
			if(userMap.containsKey(userId)) {
				users.add(userMap.get(userId));
			} else {
				userIdsNotFound.add(userId);
			}
		}
		
		if(userIdsNotFound.size() > 0) {
			//if(Limits.getQueries() < Limits.getLimitQueries()) {			
			Map<Id,User> tmpUserMap = new Map<Id,User>([SELECT Id,Email FROM User WHERE Id IN :userIdsNotFound]);
			if(tmpUserMap != null && tmpUserMap.size() > 0) {
				users.addAll(tmpUserMap.values());
				userMap.putAll(tmpUserMap);
			}
			//} //ELSE ERROR! Can't do any more queries
		}
		
		return users;
	}


	/**
	 * Gets the current user's profile object
	 * @author Steve O'Neal
	 * @date   2016-10-27
	 * @ticket link          https://jira.bigcommerce.com/browse/BAP-4221
	 * @return Current user's profile
	 */
	public static Profile getCurrentUserProfile()
	{
		return getProfileById(UserInfo.getProfileId());
	}

	/**
	 * Gets a profile by its ID
	 * @author Steve O'Neal
	 * @date   2016-10-27
	 * @ticket link       https://jira.bigcommerce.com/browse/BAP-4221
	 * @param  profileId  The ID of the profile requested
	 * @return            The profile matching profileId
	 */
	public static Profile getProfileById(Id profileId)
	{
		if (!profileMap.containsKey(profileId))
		{
		    profileMap.put(profileId, [SELECT Id, Name, PermissionsEmailSingle, PermissionsEmailMass, PermissionsEditTask, PermissionsEditEvent, PermissionsExportReport, PermissionsImportPersonal, PermissionsDataExport, PermissionsManageUsers, PermissionsEditPublicTemplates, PermissionsModifyAllData, PermissionsManageCases, PermissionsMassInlineEdit, PermissionsEditKnowledge, PermissionsManageKnowledge, PermissionsManageSolutions, PermissionsCustomizeApplication, PermissionsEditReadonlyFields, PermissionsRunReports, PermissionsViewSetup, PermissionsTransferAnyEntity, PermissionsNewReportBuilder, PermissionsManageSelfService, PermissionsManageCssUsers, PermissionsActivateContract, PermissionsImportLeads, PermissionsManageLeads, PermissionsTransferAnyLead, PermissionsViewAllData, PermissionsEditPublicDocuments, PermissionsViewEncryptedData, PermissionsEditBrandTemplates, PermissionsEditHtmlTemplates, PermissionsChatterInternalUser, PermissionsDeleteActivatedContract, PermissionsChatterInviteExternalUsers, PermissionsSendSitRequests, PermissionsOverrideForecasts, PermissionsViewAllForecasts, PermissionsApiUserOnly, PermissionsManageRemoteAccess, PermissionsCanUseNewDashboardBuilder, PermissionsManageCategories, PermissionsConvertLeads, PermissionsPasswordNeverExpires, PermissionsUseTeamReassignWizards, PermissionsInstallMultiforce, PermissionsPublishMultiforce, PermissionsManagePartners, PermissionsChatterOwnGroups, PermissionsEditOppLineItemUnitPrice, PermissionsCreateMultiforce, PermissionsBulkApiHardDelete, PermissionsInboundMigrationToolsUser, PermissionsSolutionImport, PermissionsManageCallCenters, PermissionsIPRestrictRequests, PermissionsPortalSuperUser, PermissionsManageSynonyms, PermissionsOutboundMigrationToolsUser, PermissionsDelegatedPortalUserAdmin, PermissionsViewContent, PermissionsManageEmailClientConfig, PermissionsEnableNotifications, PermissionsIsSsoEnabled, PermissionsManageDataIntegrations, PermissionsDistributeFromPersWksp, PermissionsViewDataCategories, PermissionsManageDataCategories, PermissionsAuthorApex, PermissionsManageMobile, PermissionsApiEnabled, PermissionsManageCustomReportTypes, PermissionsEditCaseComments, PermissionsTransferAnyCase, PermissionsContentAdministrator, PermissionsCreateWorkspaces, PermissionsManageContentPermissions, PermissionsManageContentProperties, PermissionsManageContentTypes, PermissionsScheduleJob, PermissionsManageExchangeConfig, PermissionsManageAnalyticSnapshots, PermissionsScheduleReports, PermissionsManageBusinessHourHolidays, PermissionsManageDynamicDashboards, PermissionsManageInteraction, PermissionsViewMyTeamsDashboards, PermissionsModerateChatter, PermissionsResetPasswords, PermissionsFlowUFLRequired, PermissionsCanInsertFeedSystemFields, PermissionsManageKnowledgeImportExport, PermissionsEmailTemplateManagement, PermissionsEmailAdministration, PermissionsManageChatterMessages, PermissionsAllowEmailIC, PermissionsChatterFileLink, PermissionsForceTwoFactor, PermissionsViewEventLogFiles, PermissionsManageNetworks, PermissionsManageAuthProviders, PermissionsRunFlow, PermissionsViewGlobalHeader, PermissionsManageQuotas, PermissionsCreateCustomizeDashboards, PermissionsCreateDashboardFolders, PermissionsViewPublicDashboards, PermissionsManageDashbdsInPubFolders, PermissionsCreateCustomizeReports, PermissionsCreateReportFolders, PermissionsViewPublicReports, PermissionsManageReportsInPubFolders, PermissionsEditMyDashboards, PermissionsEditMyReports, PermissionsViewAllUsers, PermissionsBypassEmailApproval, PermissionsAllowUniversalSearch, PermissionsConnectOrgToEnvironmentHub, PermissionsWorkCalibrationUser, PermissionsCreateCustomizeFilters, PermissionsWorkDotComUserPerm, PermissionsModerateNetworkFeeds, PermissionsModerateNetworkFiles, PermissionsGovernNetworks, PermissionsSalesConsole, PermissionsTwoFactorApi, PermissionsDeleteTopics, PermissionsEditTopics, PermissionsCreateTopics, PermissionsAssignTopics, PermissionsIdentityEnabled, PermissionsIdentityConnect, PermissionsAllowViewKnowledge, PermissionsCreateWorkBadgeDefinition, PermissionsManageSearchPromotionRules, PermissionsCustomMobileAppsAccess, PermissionsViewHelpLink, PermissionsManageProfilesPermissionsets, PermissionsAssignPermissionSets, PermissionsManageRoles, PermissionsManageIpAddresses, PermissionsManageSharing, PermissionsManageInternalUsers, PermissionsManagePasswordPolicies, PermissionsManageLoginAccessPolicies, PermissionsManageCustomPermissions, PermissionsManageUnlistedGroups, PermissionsManageTwoFactor, PermissionsLightningExperienceUser, PermissionsConfigCustomRecs, PermissionsSubmitMacrosAllowed, PermissionsBulkMacrosAllowed, PermissionsShareInternalArticles, PermissionsModerateNetworkMessages, PermissionsSendAnnouncementEmails, PermissionsChatterEditOwnPost, PermissionsChatterEditOwnRecordPost, PermissionsCreateAuditFields, PermissionsUpdateWithInactiveOwner, PermissionsAssignUserToSkill, PermissionsImportCustomObjects, PermissionsSelectFilesFromSalesforce, PermissionsMergeTopics, PermissionsManagePvtRptsAndDashbds, UserLicenseId, UserType, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, IsSsoEnabled, Description FROM Profile WHERE Id=:profileId LIMIT 1]);
		}

		return profileMap.get(profileId);
	}


}