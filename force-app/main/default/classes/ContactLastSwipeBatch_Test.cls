@IsTest
private class ContactLastSwipeBatch_Test {

    @TestSetup
    static void makeData() {
        // 1 location
        TREX1__Location__c loc = TestDataFactory.createLocations(1).get(0);
        insert loc;

        // 4 access devices
        List<AccessDevice__c> lstDevices = TestDataFactory.createAccessDevices(loc, 4);
        insert lstDevices;

        // 10 contacts in separate households
        List<Contact> lstContacts = TestDataFactory.createContacts(10);
        insert lstContacts;

        // 5 swipes per contact
        insert TestDataFactory.createAccessSwipes(
            lstDevices,
            lstContacts,
            5
        );
    }


    @IsTest
    static void testBatch() {
        Test.startTest();
        ContactLastSwipeBatch batch = new ContactLastSwipeBatch();
        Id batchId = Database.executeBatch(batch, 50);
        Test.stopTest();
        
        List<Contact> lstContacts = [
            SELECT Id, 
                   Last_Swipe__c, 
                   (SELECT SwipeTime__c 
                      FROM AccessSwipes__r 
                     ORDER BY SwipeTime__c DESC 
                     LIMIT 1)
              FROM Contact
        ];

        for (Contact ct : lstContacts) {
            Assert.areEqual(
                ct.AccessSwipes__r[0].SwipeTime__c, 
                ct.Last_Swipe__c, 
                'Contact last swipe should equal the most recent access swipe time'
            );
        }
    }

}