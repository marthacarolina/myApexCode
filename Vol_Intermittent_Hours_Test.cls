//Test for class Vol_Intermittent_Hours - conroller for Volunteer_Intermittent_hours VF page
//
//Martha Vance  April 2018

@isTest
public class Vol_Intermittent_Hours_Test {
    
    public static testMethod void Entered_Hours_Test(){
        //Insert contacts
        TestDataFactory.CreateContacts(3, 1);
        //Insert Fee -- this is only because of TestDataFactory requirements
        id fee = TestDataFactory.CreateFee('Office Work', 0);
        TestDataFactory.CreateGAU('Activity Fees');
        //insert volunteer campaign
        TestDataFactory.CreateCampaigns('Intermittent Work', 'Adventure', 'Office Work', 2, 0, date.newInstance(2018, 1, 1), date.newInstance(2018, 12, 31), fee);
        //retrieve the id of the campaign created
        List<campaign> Campaigns = [select id, Related_Campaign__c,
                                    StartDate from Campaign
                                    where 
                                    RecordType.DeveloperName = 'Adventure'];
        //insert job
        TestDataFactory.CreateJobShift(Campaigns);
        //
        //set the controller variables comming from the vf page
        Vol_Intermittent_Hours controller = new Vol_Intermittent_Hours();
        controller.vFirstName = 'Contact1';
        controller.vLastName = 'Test1';
        controller.vEmail = 'contactTest1@testing.com';
        controller.dateVol = date.newInstance(2018, 4, 22);
        controller.duration = 1.5;
        List<SelectOption> theOptions = controller.getPossibleJobs();
        controller.JobName = theOptions[0].getValue();

        // test with the wrong time
        controller.startTime = '08 AM';
        controller.save();
        List<ApexPages.Message> messages = ApexPages.getMessages();
        system.assertEquals('The starting time must be in this format HH:MM followed by either AM or PM', messages[0].getSummary());        

        //test with right time, but no contact
        controller.startTime = '01:00 PM';
        controller.vEmail = 'contact1@testing.com';
        controller.save();
        messages = ApexPages.getMessages();
        system.assertEquals('The name Contact1 and email contact1@testing.com are not in our database. Please check the spelling or contact our office.', messages[1].getSummary());        
        
        // test with right time, but no volunteer job
        controller.vEmail = 'contactTest1@testing.com';
        controller.save();
        messages = ApexPages.getMessages();
        system.assertEquals('The Volunteer Job has to be setup before you enter hours. Please contact our office.', messages[2].getSummary());
            
        //retrieve the job and change the name then run the controller again with
        //the same values
        List<GW_Volunteers__Volunteer_Job__c> jobs = 
            [SELECT id, Name, GW_Volunteers__Ongoing__c,
             GW_Volunteers__Inactive__c
             from GW_Volunteers__Volunteer_Job__c];
        jobs[0].name = controller.JobName;
        jobs[0].GW_Volunteers__Ongoing__c = true;
        jobs[0].GW_Volunteers__Inactive__c = false;
        update jobs[0];
        controller.save();        
    }

}