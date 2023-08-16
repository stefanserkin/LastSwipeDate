@IsTest
private class ContactLastSwipeScheduler_Test {
    private static String cronExp = '0 0 0 15 3 ? 2030';
    private static String scheduledJobName = ContactLastSwipeBatch.JOB_NAME;
    
    @isTest
    static void testScheduler() {
        // If scheduled job is in progress, abort it
        List<CronTrigger> lstJobs = new List<CronTrigger>();
		lstJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :scheduledJobName];
        if (!lstJobs.isEmpty()) {
            System.abortJob(lstJobs[0].Id);
        }
        
        Test.startTest();
        ContactLastSwipeScheduler.run();
        Test.stopTest();
    }

    @isTest
    static void testSpecifyJobSchedule() {
        // If scheduled job is in progress, abort it
        List<CronTrigger> lstJobs = new List<CronTrigger>();
		lstJobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :scheduledJobName];
        if (!lstJobs.isEmpty()) {
            System.abortJob(lstJobs[0].Id);
        }
        
        Test.startTest();
        ContactLastSwipeScheduler clss = new ContactLastSwipeScheduler();
        String jobId = System.schedule(
            scheduledJobName, 
            cronExp, 
            clss
        );
        clss.execute(null);
        Test.stopTest();
        
        CronTrigger cronTrigger = [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger ORDER BY CreatedDate DESC LIMIT 1
        ];
        
        System.assertEquals(
            scheduledJobName, 
            cronTrigger.CronJobDetail.Name, 
            'Should have received scheduled job name in most recent cron trigger'
        );
    }
}