public with sharing class ContactLastSwipeScheduler implements Schedulable {
    public static String schedule = '0 44 3 ? * *'; // Every day at 3:44am

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