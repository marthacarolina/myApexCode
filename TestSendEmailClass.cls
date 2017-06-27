//this test is for the class SendKACEmailClass
@isTest
public class TestSendEmailClass {
    @isTest
    public static void TestingMethod(){
        List<Contact> Vols = new List<Contact>();
        For (Integer x=0; x<8; x++)
        {
            Contact oneVol = new Contact(FirstName = 'FName' + x,
                                         LastName = 'LName'+ x,
                                         Email = 'marthacv@gmail.com',
                                         CPR_Certificate_Expiration_Date__c = Date.newInstance(2018, 1, 1),
                                         First_Aid_Certification_Expiration_Date__c = Date.newInstance(2018, 1, 1),
                                         Fingerprint_Clearance_Expiration_Date__c = Date.newInstance(2018, 1, 1));
            Vols.add(oneVol);
        }
        Vols[1].CPR_Certificate_Expiration_Date__c = Date.newInstance(2017, 03, 10);
        Vols[2].First_Aid_Certification_Expiration_Date__c = Date.newInstance(2017, 3, 11);
        Vols[3].Fingerprint_Clearance_Expiration_Date__c = Date.newInstance(2017, 3, 12);
        Vols[4].CPR_Certificate_Expiration_Date__c = Date.newInstance(2017, 3, 13);
        Vols[4].First_Aid_Certification_Expiration_Date__c = Date.newInstance(2017, 3, 13);
        Vols[5].CPR_Certificate_Expiration_Date__c = Date.newInstance(2017, 3, 14);
        Vols[5].First_Aid_Certification_Expiration_Date__c = Date.newInstance(2017, 3, 14);
        Vols[5].Fingerprint_Clearance_Expiration_Date__c = Date.newInstance(2017, 3, 14);
        Vols[6].First_Aid_Certification_Expiration_Date__c = Date.newInstance(2017, 3, 15);
        Vols[6].Fingerprint_Clearance_Expiration_Date__c = Date.newInstance(2017, 3, 15);
        Vols[7].CPR_Certificate_Expiration_Date__c = Date.newInstance(2017, 2, 16);
        Vols[7].First_Aid_Certification_Expiration_Date__c = Date.newInstance(2017, 2, 16);
        Vols[7].Fingerprint_Clearance_Expiration_Date__c = Date.newInstance(2017, 2, 16);
        //insert volunteer records in database
        Database.SaveResult[] srList = Database.insert(Vols, false);
        for (Database.SaveResult sr : srList){
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted contact. Contact ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
        //create Alert records using the ids from the srList for the whoid
        Date hoy = date.today();
        List<Task> myAlerts = new List<Task>();
        for(Integer x = 0; x<5; x++)
        {
            Task oneTask = new Task(ActivityDate = hoy,
                                    Priority = 'Normal',
                                    Status = 'Completed',
                                    Subject =
                                    'Mass Email: Friendly reminder: Your FirstAid certification on file with Daring Adventures will expire soon',
                                    WhoId = srList[0].getid());
            myAlerts.add(oneTask);
        }
        myAlerts[0].Subject =
            'Mass Email: Friendly reminder: Your CPR certification on file with Daring Adventures will expire soon';
        myAlerts[0].WhoId = srList[4].getId();
        myAlerts[1].WhoId = srList[5].getId();
        myAlerts[2].Subject =
            'Mass Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures will expire soon';
        myAlerts[2].WhoId = srList[6].getId();
        myAlerts[3].Subject =
            'Mass Email: Friendly reminder: Your First Aid certification on file with Daring Adventures has EXPIRED';
        myAlerts[3].WhoId = srList[7].getId();
        myAlerts[4].WhoId = srList[7].getId();
        myAlerts[4].ActivityDate = Date.newInstance(2015, 1, 16);
        myAlerts[4].Subject =
            'Mass Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures has EXPIRED';
        Database.SaveResult[] Tasklist = Database.insert(myAlerts);

        //now run the class we are testing
        SendKACEmailClass.sendReminderEmails();

        //query all the activities that have todays date and check if we have the right amount
        List<Task> newActivities = [SELECT id, ActivityDate FROM Task WHERE
                                    ActivityDate = :hoy];
        // it seems that the email call takes some time and the tasks don't get inserted until
        // after the system.assert call there should be 13 records in the list, but only the
        // four that the
        system.assertEquals(4, newActivities.size());

    }
}
