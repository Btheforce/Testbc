/**
 * Updated all brEmailNotification method singantures  
 * @updatedBy Alakh Biniwale
 * @date   10/08/2018
 * @ticket https://jira.bigcommerce.com/browse/BAP-8237
 */
public class brIdeaTriggerHandler {

    public brIdeaTriggerHandler(){
        if (!Trigger.isExecuting) throw new brIdeaSecurityException('This code must run in trigger context only');
    }

    public void createSubscriptions(List<Idea> ideaList) {
        List<brIdeaSubscription__c> subscrList = new List<brIdeaSubscription__c>();

        for (Idea idea : ideaList) {
            subscrList.add(new brIdeaSubscription__c(
                    Idea__c = idea.Id,
                    User__c = idea.CreatedById,
                    Token__c = brUtils.generateToken(50)
                ));
        }

        insert subscrList;
    }

    public void sendNewIdeaNotifications(List<Idea> ideasList) {
        Map<String, List<String>> aMap = brIdeaDataSelector.getAssignedUserEmailsByCategory();
        brEmailNotification notificator = new brEmailNotification();
        List<String> categories;
        Set<String> emailsList;

        //Added BAP-8237 Alakh Biniwale
        EmailTemplate templateAssignee = new EmailTemplate();
        templateAssignee = notificator.getEmailTemplate('NewIdeaNotificationToCategoryAssignee');
        
        //Added BAP-8371 Alakh Biniwale
        String orgWideEmailAddressId = brLghtIdeasHelper.getConfigValue('orgwide_email_id');
        
        for (Idea idea : ideasList) {
            categories = idea.Categories.split(';');
            emailsList = new Set<String>();

            for (String category : categories) {
                if (aMap.get(category) == NULL) continue;

                emailsList.addAll(aMap.get(category));
            }

            for (String em : emailsList) {
                notificator.addIdeaCreatedNotification(em, idea, templateAssignee, orgWideEmailAddressId);
            }
        }

        notificator.sendEmails();
    }

    public void sendStatusChangeNotifications(List<Idea> ideasList, Map<Id, Idea> oldMap) {

        List<Idea> filteredList = new List<Idea>();

        for (Idea idea : ideasList) {
            if(idea.Status != oldMap.get(idea.Id).Status) {
                filteredList.add(idea);
            }
        }

        if (filteredList.isEmpty()) return;

        this.sendStatusChangeNotificationsToSubscribers(filteredList, oldMap);
        this.sendStatusChangeNotificationsToManagers(filteredList, oldMap);
    }

    private void sendStatusChangeNotificationsToSubscribers(List<Idea> ideasList, Map<Id, Idea> oldMap){
        brEmailNotification notificator = new brEmailNotification();
        String oldStatus;
        List<brIdeaSubscription__c> subscriptions = [
                SELECT Idea__c, Idea__r.Id, Idea__r.Title, Idea__r.Status,
                        Idea__r.CommunityId, Idea__r.Body, User__r.Email
                FROM brIdeaSubscription__c
                WHERE Idea__c IN :ideasList LIMIT 10000];

        //Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
        EmailTemplate templateSubscriber = new EmailTemplate();
        templateSubscriber = notificator.getEmailTemplate('ChangeStatusNotificationToSubscriber');
        
        //Added to fix soql 101 bad practice BAP-8371 Alakh Biniwale
        String orgWideEmailAddressId = brLghtIdeasHelper.getConfigValue('orgwide_email_id');
                                                               
        for (brIdeaSubscription__c subscr : subscriptions) {
            if (subscr.User__r.Email != null) {
                oldStatus = oldMap.get(subscr.Idea__c).Status != NULL ? oldMap.get(subscr.Idea__c).Status : '';
                notificator.addStatusChangeNotification1(subscr.User__r.Email, (Idea)subscr.Idea__r,
                        oldStatus, templateSubscriber, orgWideEmailAddressId);
            }
        }

        notificator.sendEmails();
    }

    private void sendStatusChangeNotificationsToManagers(List<Idea> ideasList, Map<Id, Idea> oldMap){
        Map<String, List<String>> aMap = brIdeaDataSelector.getAssignedUserEmailsByCategory();
        brEmailNotification notificator = new brEmailNotification();
        List<String> categories;
        Set<String> emailsList;
        String oldStatus;
		
        //Added to fix soql 101 bad practice BAP-8237 Alakh Biniwale
        EmailTemplate templateAssignee = new EmailTemplate();
        templateAssignee = notificator.getEmailTemplate('ChangeStatusNotificationToCategoryAssignee');
        
        //Added to fix soql 101 bad practice BAP-8371 Alakh Biniwale
        String orgWideEmailAddressId = brLghtIdeasHelper.getConfigValue('orgwide_email_id');
        
        for (Idea idea : ideasList) {
            categories = idea.Categories.split(';');
            emailsList = new Set<String>();

            for (String category : categories) {
                if (aMap.get(category) == NULL) continue;

                emailsList.addAll(aMap.get(category));
            }

            for (String em : emailsList) {
                oldStatus = oldMap.get(idea.Id).Status != NULL ? oldMap.get(idea.Id).Status : '';
                notificator.addStatusChangeNotification1(em, idea, oldStatus, templateAssignee, orgWideEmailAddressId);
            }
        }

        notificator.sendEmails();
    }

}