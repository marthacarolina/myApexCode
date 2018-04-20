//this test is for the class SendKACEmailClass
@isTest
public class TestSendEmailClass {
    @isTest
    public static void TestingMethod(){
        List<Contact> Vols = new List<Contact>();
        //all volunteers have gone through Orientation
        //volunteer 7 has expired certifications. Volunteer 8 has fcc expired
        For (Integer x=0; x<15; x++)
        {
            Contact oneVol = new Contact(FirstName = 'FName' + x,
                                         LastName = 'LName'+ x,
                                         Email = 'marthacv@gmail.com',
                                         CPR_Certificate_Expiration_Date__c = Date.today() + 365,
                                         First_Aid_Certification_Expiration_Date__c = Date.today() + 365,
                                         Fingerprint_Clearance_Expiration_Date__c = Date.today() + 365,
                                         Volunteer_Orientation__c = Date.today() - 100,
                                         GW_Volunteers__Volunteer_Status__c = 'Active');
            Vols.add(oneVol);
        }
        Vols[1].CPR_Certificate_Expiration_Date__c = Date.today() + 30;
        Vols[2].First_Aid_Certification_Expiration_Date__c = Date.today() + 60;
        Vols[3].Fingerprint_Clearance_Expiration_Date__c = Date.today() + 37;
        Vols[4].CPR_Certificate_Expiration_Date__c = Date.today() + 1;
        Vols[4].First_Aid_Certification_Expiration_Date__c = Date.today() + 70;
        Vols[5].CPR_Certificate_Expiration_Date__c = Date.today() + 5;
        Vols[5].First_Aid_Certification_Expiration_Date__c = Date.today() + 10;
        Vols[5].Fingerprint_Clearance_Expiration_Date__c = Date.today() + 10;
        Vols[6].First_Aid_Certification_Expiration_Date__c = Date.today() + 10;
        Vols[6].Fingerprint_Clearance_Expiration_Date__c = Date.today() + 10;
        Vols[7].CPR_Certificate_Expiration_Date__c = Date.today() - 10;
        Vols[7].First_Aid_Certification_Expiration_Date__c = Date.today() - 20;            
        Vols[7].Fingerprint_Clearance_Expiration_Date__c = Date.today() - 1;
        Vols[8].Fingerprint_Clearance_Expiration_Date__c = Date.today() - 20;
        Vols[9].CPR_Certificate_Expiration_Date__c = Date.today() - 10;
        Vols[9].First_Aid_Certification_Expiration_Date__c = Date.today() - 20;         
        Vols[10].First_Aid_Certification_Expiration_Date__c = Date.today() + 60;
        Vols[11].First_Aid_Certification_Expiration_Date__c = Date.today() - 20;
        Vols[12].Fingerprint_Clearance_Expiration_Date__c = Date.today() - 1;
        vols[13].First_Aid_Certification_Expiration_Date__c = Date.today() + 2;
        Vols[13].Email = '';
        
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
        for(Integer x = 0; x<8; x++)
        {
            Task oneTask = new Task(ActivityDate = hoy - 2,
                                    Priority = 'Normal',
                                    Status = 'Completed',
                                    Subject = 
                                    'Email: Friendly reminder: Your FirstAid certification on file with Daring Adventures will expire soon',
                                    WhoId = srList[0].getid());
            myAlerts.add(oneTask);
        }
        myAlerts[0].Subject = 
            'Email: Friendly reminder: Your CPR certification on file with Daring Adventures will expire soon';
        myAlerts[0].WhoId = srList[4].getId();
        myAlerts[1].WhoId = srList[5].getId();
        myAlerts[2].Subject = 
            'Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures will expire soon';
        myAlerts[2].WhoId = srList[6].getId();
        myAlerts[3].Subject =
            'Email: Friendly reminder: Your First Aid certification on file with Daring Adventures has EXPIRED';
        myAlerts[3].WhoId = srList[7].getId();
        myAlerts[4].Subject =
            'Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures has EXPIRED';
        myAlerts[4].WhoId = srList[7].getId();
        myAlerts[4].ActivityDate = Date.newInstance(2015, 1, 16);
        myAlerts[5].Subject =
            'Email: Friendly reminder: Your Fingerprint Clearance Card on file with Daring Adventures has EXPIRED';
        myAlerts[5].WhoId = srList[8].getId();       
        myAlerts[6].Subject =
            'Email: Friendly reminder: Your CPR certification on file with Daring Adventures has EXPIRED';
        myAlerts[6].WhoId = srList[9].getId();
        myAlerts[6].ActivityDate = Date.newInstance(2015, 1, 16);
        myAlerts[7].Subject =
            'Email: Friendly reminder: Your First Aid certification on file with Daring Adventures has EXPIRED';
        myAlerts[7].WhoId = srList[9].getId();
        myAlerts[7].ActivityDate = Date.today()-35;         
                
        Database.SaveResult[] Tasklist = Database.insert(myAlerts);
        
        //now run the class we are testing
        test.startTest();
        SendKACEmailClass.sendReminderEmails();
        
        //query all the activities that have todays date and check if we have the right amount
        List<Task> newActivities = [SELECT id, ActivityDate FROM Task];
        test.stopTest();
        // it seems that the email class is not actually adding any records to the
        // task object there should be 13 records in the list, but only the 
        // four that the test method inserts are inserted.
        
        system.assertEquals(23, newActivities.size());
        
    }
}