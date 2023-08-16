public without sharing class FlowLastSwipeHandler {

    private static Set<Id> setUpdatedContactsIds;
    private static Set<Id> setErrorContactIds;


    @InvocableMethod(label='Set Last Swipe Data')
    public static List<Result> setLastSwipes(list<Request> lstRequests) {
        List<Result> lstResults = new List<Result>();
        for (Request req : lstRequests) {
            // Create list of contacts to update
            List<Contact> lstContactsToUpdate = new List<Contact>();
            // Get contacts with swipes in list
            List<Contact> lstContacts = getContacts(req.lstSwipes);
            // Filter to contacts needing an update
            for (Contact ct : lstContacts) {
                Datetime dtLastSwipe = ct.AccessSwipes__r[0]?.SwipeTime__c;
                if (ct.Last_Swipe__c != dtLastSwipe) {
                    ct.Last_Swipe__c = dtLastSwipe;
                    lstContactsToUpdate.add(ct);
                }
            }
            // Update contacts
            if (!lstContactsToUpdate.isEmpty()) {
                updateContacts(lstContactsToUpdate, req.allOrNothingMode);

                Result result = new Result();
                result.updatedContactIds = new List<Id>( setUpdatedContactsIds );
                result.errorContactIds = new List<Id>( setErrorContactIds );
                lstResults.add(result);
            }
        }
        return lstResults;
    }

    private static List<Contact> getContacts(
        List<AccessSwipes__c> lstSwipes
    ) {
        Set<Id> setContactIds = new Set<Id>();
        for (AccessSwipes__c swipe : lstSwipes) {
            setContactIds.add(swipe.Contact__c);
        }
        return [
            SELECT Id, 
                   Last_Swipe__c, 
                   (SELECT SwipeTime__c 
                      FROM AccessSwipes__r 
                     ORDER BY SwipeTime__c DESC 
                     LIMIT 1)
              FROM Contact
             WHERE Id IN :setContactIds
              WITH USER_MODE
             LIMIT 10000
        ];
    }

    private static void updateContacts(
        List<Contact> lstContacts,
        Boolean allOrNothing
    ) {
        List<Database.SaveResult> lstSRs = Database.insert(
            lstContacts, 
            allOrNothing, 
            AccessLevel.SYSTEM_MODE
        );
        setUpdatedContactsIds = new Set<Id>();
        setErrorContactIds = new Set<Id>();
        for (Database.SaveResult sr : lstSRs) {
            if (sr.isSuccess()) {
                setUpdatedContactsIds.add(sr.id);
            } else {
                setErrorContactIds.add(sr.id);
            }
        }
    }

    public class Request {
        @InvocableVariable(required=true label='AccessSwipes')
        public List<AccessSwipes__c> lstSwipes;
        @InvocableVariable(required=true label='Save All or Nothing')
        public Boolean allOrNothingMode;
    }

    public class Result {
        @InvocableVariable(label='Updated Contacts')
        public List<Id> updatedContactIds;
        @InvocableVariable(label='Contacts with Errors')
        public List<Id> errorContactIds;
    }

}