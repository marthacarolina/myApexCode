//this test insert its own testing records. But for some reason the Sataus for the Participants
//is being saved as Sent, regardless of the value given in the code.
@isTest

public class CMSendEmailsTest {
    @isTest
    private static void SndEmail()
    {
        //insert Contacts
        List<contact> contacts = new List<Contact>();
        for (Integer x = 1; x < 9; x++)
        {
            Contact cont = new Contact(FirstName = 'test'+x,
                                       LastName = 'test ' + x,
                                       email = 'marthacv@gmail.com');
            if (x==8) cont.email = '';
            contacts.add(cont);
        }
        insert contacts;

        //insert Fee
        Fee__c fee = new Fee__c(Activity_Type__c = 'Cycling',
                               Amount__c = 5);
        insert fee;
        // prepare fields for campaigns
        List<String> campaignTypes = new List<String>{'Cycling','Hiking','Kayaking','Backpacking','Camping'};
        List<Date> campaignDates = new List<Date>();
        campaignDates.add(date.today()+5);
        campaignDates.add(date.today()+5);
        campaignDates.add(date.today()-5);
        campaignDates.add(date.today()-5);
        campaignDates.add(date.today()+5);

        List<Campaign> campaigns = new List<Campaign>();
        for (integer x = 0; x<5; x++)
        {
            Campaign camp = new Campaign(Name = 'Campaign ' + x,
                                         Type = campaignTypes[x],
                                         StartDate = campaignDates[x],
                                         EndDate = campaignDates[x],
                                         Description = 'testing emails',
                                         RecordTypeId = '012o0000000xwhO',
                                         Fee_for_Activity__c = fee.id);
            campaigns.add(camp);
        }
        insert campaigns;
        campaigns.clear();
        //Retrieve campaigns to obtain the complete record (with the volunteer campaign)
        campaigns = [SELECT id, Name, Type, StartDate, EndDate, Description,
                     RecordTypeId, Related_Campaign__c
                     FROM Campaign ORDER BY Name];
        system.debug('inserted Campaigns, and retrieved campaigns');
        //insesert job, shifts and hours for campaigns
        List<GW_Volunteers__Volunteer_Job__c> jobs = new List<GW_Volunteers__Volunteer_Job__c>();
        for (integer x = 0; x<5; x++)
        {
            GW_Volunteers__Volunteer_Job__c job = new GW_Volunteers__Volunteer_Job__c(
                GW_Volunteers__Campaign__c = campaigns[x].Related_Campaign__c,
                GW_Volunteers__Description__c = 'description for campaign',
                GW_Volunteers__Location_City__c = 'PHoenix',
                GW_Volunteers__Location_Information__c = 'info',
                GW_Volunteers__Location__c = 'location',
                GW_Volunteers__Location_Street__c = 'street');
            jobs.add(job);
        }
        insert jobs;
        //insert shifts
        List<GW_Volunteers__Volunteer_Shift__c> shifts = new List<GW_Volunteers__Volunteer_Shift__c>();
        for (integer x = 0; x<5; x++)
        {
            GW_Volunteers__Volunteer_Shift__c shift = new GW_Volunteers__Volunteer_Shift__c(
                GW_Volunteers__Desired_Number_of_Volunteers__c = 4,
                GW_Volunteers__Duration__c = 3,
                GW_Volunteers__Start_Date_Time__c = datetime.now(),
                GW_Volunteers__Volunteer_Job__c = jobs[x].id);
            shifts.add(shift);
        }
        insert shifts;
        //insert volunteers --trhough the Hours object
        List<GW_Volunteers__Volunteer_Hours__c> listHours = new List<GW_Volunteers__Volunteer_Hours__c>();

        GW_Volunteers__Volunteer_Hours__c hours = new GW_Volunteers__Volunteer_Hours__c(
            GW_Volunteers__Contact__c = contacts[2].id,
            GW_Volunteers__Start_Date__c = campaigns[0].StartDate,
            GW_Volunteers__Hours_Worked__c = 3,
            GW_Volunteers__Planned_Start_Date_Time__c = datetime.now(),
            GW_Volunteers__Status__c = 'Confirmed',
            GW_Volunteers__Volunteer_Job__c = jobs[0].id,
            GW_Volunteers__Volunteer_Shift__c = shifts[0].id);
        listHours.add(hours);
        hours = new GW_Volunteers__Volunteer_Hours__c(
            GW_Volunteers__Contact__c = contacts[7].id,
            GW_Volunteers__Hours_Worked__c = 3,
            GW_Volunteers__Start_Date__c = campaigns[0].StartDate,
            GW_Volunteers__Planned_Start_Date_Time__c = datetime.now(),
            GW_Volunteers__Status__c = 'Confirmed',
            GW_Volunteers__Volunteer_Job__c = jobs[0].id,
            GW_Volunteers__Volunteer_Shift__c = shifts[0].id);
        listHours.add(hours);
        hours = new GW_Volunteers__Volunteer_Hours__c(
            GW_Volunteers__Contact__c = contacts[4].id,
            GW_Volunteers__Hours_Worked__c = 3,
            GW_Volunteers__Start_Date__c = campaigns[2].StartDate,
            GW_Volunteers__Planned_Start_Date_Time__c = datetime.now(),
            GW_Volunteers__Status__c = 'Completed',
            GW_Volunteers__Volunteer_Job__c = jobs[2].id,
            GW_Volunteers__Volunteer_Shift__c = shifts[2].id);
        listHours.add(hours);
        hours = new GW_Volunteers__Volunteer_Hours__c(
            GW_Volunteers__Contact__c = contacts[5].id,
            GW_Volunteers__Hours_Worked__c = 3,
            GW_Volunteers__Start_Date__c = campaigns[2].StartDate,
            GW_Volunteers__Planned_Start_Date_Time__c = datetime.now(),
            GW_Volunteers__Status__c = 'Canceled',
            GW_Volunteers__Volunteer_Job__c = jobs[2].id,
            GW_Volunteers__Volunteer_Shift__c = shifts[2].id);
        listHours.add(hours);
        hours = new GW_Volunteers__Volunteer_Hours__c(
            GW_Volunteers__Contact__c = contacts[1].id,
            GW_Volunteers__Start_Date__c = campaigns[4].StartDate,
            GW_Volunteers__Hours_Worked__c = 3,
            GW_Volunteers__Planned_Start_Date_Time__c = datetime.now(),
            GW_Volunteers__Status__c = 'Confirmed',
            GW_Volunteers__Volunteer_Job__c = jobs[4].id,
            GW_Volunteers__Volunteer_Shift__c = shifts[4].id);
        listHours.add(hours);
        insert hours;
        system.debug('inserted all the volunteers (hours)');
        //insert participants
        List<CampaignMember> participants = new List<CampaignMember>();
        CampaignMember participant = new CampaignMember(ContactId = contacts[0].id,
                                                        Status = 'Signed Up',
                                                        CampaignId = campaigns[0].id);
        participants.add(participant);
        participant = new CampaignMember(ContactId = contacts[1].id,
                                         Status = 'Cancelled',
                                         CampaignId = campaigns[0].id);
        participants.add(participant);
        participant = new CampaignMember(ContactId = contacts[3].id,
                                         Status = 'Attended',
                                         CampaignId = campaigns[2].id);
        participants.add(participant);
        participant = new CampaignMember(ContactId = contacts[6].id,
                                         Status = 'No Show',
                                         CampaignId = campaigns[2].id);
        participants.add(participant);
        participant = new CampaignMember(ContactId = contacts[7].id,
                                         Status = 'Attended',
                                         CampaignId = campaigns[2].id);
        participants.add(participant);
        participant = new CampaignMember(ContactId = contacts[0].id,
                                         Status = 'Signed Up',
                                         CampaignId = campaigns[4].id);
        participants.add(participant);
        insert participants;
        system.debug('the participants have been inserted');
        //Insert documents for attachment
//Even though I am running this test without the See All Data setting, it seems to see
//the documents already in the system.


//        List<String> docs = new List<String>{'P209HIking','P202Backpacking','P200Cycling','P206Kayaking'};
//        List <Document> haveDoc = [SELECT id, Name from Document where
//                                       DeveloperName in :docs];
//        system.debug('haveDoc.size = ' + haveDoc.size());
//        if(haveDoc.size()<4)
//        {
//            List<Integer> notHave = new List<Integer>();
//            for(Integer x = 0; x<4 ; x++)
//            {
//                Boolean foundIt = false;
//                for (Document d : haveDoc)
//                {
//                    if (d.DeveloperName == docs[x])
//                        foundIt = true;
//                }
//                if (!foundIt)
//                    notHave.add(x);
//            }

//            List<Document> documents = new List<Document>();
//            for (integer x=0; x < notHave.size(); x++)
//            {
//                Document document = new Document();
//                document.Body = Blob.valueOf('Some Text');
//                document.ContentType = 'application/pdf';
//                document.DeveloperName = docs[x];
//                document.IsPublic = true;
//                document.Name = docs[notHave[x]] + ' Policies and Procedures';
//                document.FolderId = [select id from folder where name = 'DA Programs Policies and Procedures'].id;
//                documents.add(document);
//            }
//            insert documents;
//        }

        //begin test now
        //
        //CAMP[0] reminder emails - cycling  2 participants selected 1 volunteers
        //camp[1] Reminder Emails   1 Volunteer should be selected  0 Participants
        //camp[2] After Campaign Emails   1 PARTICIPANT should be selected
        //camp[3] no campaign members at all
        test.startTest();
        List<String> returnPages = new List<String>();
        List<PageReference> pgref = new List<PageReference>();

        ///------------------------
        system.debug('camp = '+campaigns[0].Name);

        ApexPages.StandardController std1 =
            new ApexPages.StandardController(campaigns[0]);
        system.debug('In first test');
        CMSendEmails firstTest = new CMSendEmails(std1);
        pgref.add(firstTest.SendTheEmails());
        returnPages.add(pgref[0].getUrl());
        system.debug('returnPages[0] = '+returnPages[0]);
        //--------------------
        system.debug('campaigns[1].Name: ' + campaigns[1].Name);
        std1 = new ApexPages.StandardController(campaigns[1]);
        system.debug('going to second test: 1 volunteer selected');
        CMSendEmails secondTest = new CMSendEmails(std1);
        system.assertEquals('There are no participants or volunteers associated with this campaign', secondTest.message);
        pgref.add(secondTest.SendTheEmails());
        returnPages.add(pgref[1].getUrl());
        system.debug('returnPages[1] = '+returnPages[1]);

        //-------------------
        system.debug('campaigns[2].Name: ' + campaigns[2].Name);
        std1 = new ApexPages.StandardController(campaigns[2]);
        CMSendEmails thirdTest = new CMSendEmails(std1);
        pgref.add(thirdTest.SendTheEmails());
        returnPages.add(pgref[2].getUrl());
        system.debug('returnPages[2] = '+returnPages[2]);

        //--------------------
        system.debug('campaigns[3].Name: ' + campaigns[3].Name);
        std1 = new ApexPages.StandardController(campaigns[3]);
        CMSendEmails fourthTest = new CMSendEmails(std1);
        pgref.add(fourthTest.SendTheEmails());
        returnPages.add(pgref[3].getUrl());
        system.debug('returnPages[3] = '+returnPages[3]);

        //---------
        system.debug('campList[4].Name: ' + campaigns[4].Name);
        std1 = new ApexPages.StandardController(campaigns[4]);
        CMSendEmails fifthTest = new CMSendEmails(std1);
        pgref.add(fifthTest.SendTheEmails());
        system.assertEquals('There is no Email_Content of type Reminder Emails for Camping Adventure', fifthTest.message);
        returnPages.add(pgref[4].getUrl());
        system.debug('returnPages[4] = '+returnPages[4]);

        test.stopTest();

        Integer tasksInserted = [select count() from Task];
        system.assertEquals(5, tasksInserted);
        for (integer x=0; x<returnPages.size(); x++)
        {
            if (x != 1 && x != 4)
                system.assertEquals(true, returnPages[x].contains(Campaigns[x].id));
        }

    }
}
