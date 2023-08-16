public with sharing class ContactLastSwipeBatch implements Database.Batchable<SObject> {

    public static final String JOB_NAME = 'Contact Last Swipe Batch';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Last_Swipe__c, (SELECT SwipeTime__c FROM AccessSwipes__r ORDER BY SwipeTime__c DESC LIMIT 1)' + 
            ' FROM Contact WHERE Id IN (SELECT Contact__c FROM AccessSwipes__c WHERE SwipeDate__c = YESTERDAY OR CreatedDate >= YESTERDAY OR LastModifiedDate >= YESTERDAY)';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Contact> scope) {
        List<Contact> lstContactsToUpdate = new List<Contact>();
        for (Contact ct : scope) {
            Datetime dtLastSwipe = ct.AccessSwipes__r[0].SwipeTime__c;
            if (ct.Last_Swipe__c == null || ct.Last_Swipe__c < dtLastSwipe) {
                lstContactsToUpdate.add(
                    new Contact(Id = ct.Id, Last_Swipe__c = dtLastSwipe)
                );
            }
        }
        if (!lstContactsToUpdate.isEmpty()) {
            // TODO - Handle failures
            List<Database.SaveResult> lstResults = Database.update(
                lstContactsToUpdate, 
                false, 
                AccessLevel.SYSTEM_MODE
            );
        }
    }

    public void finish(Database.BatchableContext bc){
        AsyncApexJob a = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
              FROM AsyncApexJob 
             WHERE Id = :bc.getJobId()
        ];
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Sharing Recalculation ' + a.Status);
        mail.setPlainTextBody(
            'The ' + JOB_NAME + ' processed ' + a.TotalJobItems + 
            ' batches with '+ a.NumberOfErrors + ' failures.'
        );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
     }

}