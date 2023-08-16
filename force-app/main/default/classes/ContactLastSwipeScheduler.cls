public with sharing class ContactLastSwipeScheduler implements Schedulable {
    public static String schedule = '0 29 16 ? * *'; // Every day at 4:29pm

    public static String run() {
        ContactLastSwipeScheduler sched = new ContactLastSwipeScheduler();
        return System.schedule(
            ContactLastSwipeBatch.JOB_NAME, 
            schedule, 
            sched
        );
    }

    public void execute(SchedulableContext context) {
        ContactLastSwipeBatch batch = new ContactLastSwipeBatch();
        Id batchId = Database.executeBatch(batch, 50);
    }
}