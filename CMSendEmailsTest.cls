//This is the test for CMSendEmails class
//
//Martha Vance 2017
@isTest    

public class CMSendEmailsTest {
    @isTest
    private static void SndEmail()
    {
        Map<String, id> recTypeIds = new Map<String, id>();
        List<RecordType> recs = [select id, Name, DeveloperName from RecordType
                                 where sObjectType = 'Campaign'];

        
        for (RecordType rt : recs)
            recTypeIds.put(rt.DeveloperName, rt.id); 
        id fee = TestDataFactory.CreateFee('Cycling', 15);
        TestDataFactory.CreateGAU('Activity Fees');
        TestDataFactory.CreateCMStatusDefault('Cycling');
        TestDataFactory.CreateCMStatusDefault('Kayaking');
        TestDataFactory.CreateCMStatusDefault('Backpacking');
        TestDataFactory.CreateCMStatusDefault('Hiking');
        //TestDataFactory.CreateCMStatusDefault('Camping');
        //
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Cycling', 1, 1, date.today() - 10, date.today() - 10, fee);
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Backpacking', 1, 2, date.today() + 10, date.today() + 10, fee);
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Hiking', 1, 3, date.today() - 5, date.today() - 5, fee);
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Kayaking', 1, 4, date.today() - 10, date.today() - 10, fee);
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Camping', 1, 5, date.today() + 20, date.today() + 20, fee);
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Camping', 1, 6, date.today() + 20, date.today() + 20, fee);
        TestDataFactory.CreateCampaigns('Testing ', 'Adventure', 'Backpacking', 1, 7, date.today() + 10, date.today() + 10, fee);
        TestDataFactory.CreateContacts(12, 1);
        
        List<Contact> contacts = [SELECT id, FirstName, LastName, email
                                 FROM Contact ORDER BY LastName];
        contacts[6].email = '';
        update contacts[6];
        CreateEmailContent('Cycling');
        CreateEmailContent('Backpacking');
        CreateEmailContent('Kayaking');
        CreateEmailContent('Hiking');

        
        //only insert campaign members for the first campaign created
        //camp[0] - Adventure, CM 0,1,2   Volunteer - CM 3,4
        //camp[1] - Adventure no CM  volunteer - CM 4,5
        //camp[2] - Adventure CM 0,1,2,3 Volunteer No CM
        //camp[3] - Adventure no CM  volunteer no CM

        //make a campaign without volunteer campaign        
        Campaign camp6 = [select id, Name, RecordTypeId, Type, Description,
                           StartDate, EndDate, Email_Message__c, Related_Campaign__c
                          from Campaign 
                          where Name = 'Testing 6' limit 1];
        Campaign volCamp6 = [select id, Name, RecordTypeId, Type, Description,
                             StartDate, EndDate, Email_Message__c, Related_Campaign__c
                             FROM Campaign
                             where id = :camp6.Related_Campaign__c];
        delete volCamp6;
        camp6.Related_Campaign__c = null;
        update camp6;
        //Retrieve the campaigns that were just created        
        List<Campaign> campList = new List<Campaign>
            ([Select id, Name, RecordTypeId, Type, Description,
                     StartDate, EndDate, Email_Message__c, Related_Campaign__c,
                     Google_Calendar_Link__c
              from Campaign              
              ORDER BY RecordType.Name, Name]);
        //add a google link to 3 of the campaigns
        for (Integer x=0; x < 3; x++)
            campList[x].Google_Calendar_Link__c = 'https://google.com';
        update campList;
        Map<id, Campaign> mapCamps = new Map<id, Campaign>(campList);
        //make a map of the campaign Id's where the Key is the campaign Name
        Map<String, id> campsByName = new Map<String, Id>();
        List<Campaign> camps = new List<Campaign>();
        for (Campaign c : campList)
        {
           campsByName.put(c.Name, c.id);
        }

        //Create campaign members
        //campaign members for the campaign with name Testing 1
        camps.add(mapCamps.get(campsByName.get('Testing 1')));
        List<String> statai = new List<String>{'Signed Up', 'Cancelled'};
        TestDataFactory.CreateCampaignMembers(camps, contacts, 2, statai);
        contacts.remove(1); // test 2  rec 1
        contacts.remove(0);  //test 1  rec 0
        camps.clear();
        statai.clear();
        Campaign tempCamp = mapCamps.get(campsByName.get('Testing 3')); 
        camps.add(tempCamp); //send the Adventure campaign to TestDataFactory it will insert job in related campaign
        TestDataFactory.CreateJobShift(camps);
        statai.add('Canceled');
        statai.add('Confirmed');
        tempCamp = mapCamps.get(tempCamp.Related_Campaign__c);
        CreateVolHours(tempCamp, contacts, 2, statai);
        contacts.remove(1);   // test 4   rec 3
        contacts.remove(0);   // test 3   rec 2
        camps.clear();
        statai.clear();
        camps.add(mapCamps.get(campsByName.get('Testing 4')));
        statai = new List<String>{'Attended','Attended','No-Show'};
        TestDataFactory.CreateCampaignMembers(camps, contacts, 3, statai);

        contacts.remove(2);   // test 7   rec 6
        contacts.remove(1);   // test 6   rec 5
        contacts.remove(0);   // test 5   rec 4
        camps.clear();
        statai.clear(); statai.add('Signed Up');
        camps.add(mapCamps.get(campsByName.get('Testing 5')));
        TestDataFactory.CreateCampaignMembers(camps, contacts, 1, statai);
        contacts.remove(0);  // test 8   rec 7
        camps.clear();
        tempCamp = mapCamps.get(campsByName.get('Testing 5')); 
        camps.add(tempCamp);
        TestDataFactory.CreateJobShift(camps);
        statai.clear();
        statai.add('Confirmed');
        tempCamp = mapCamps.get(tempCamp.Related_Campaign__c); //this is the volunteer campaign
        CreateVolHours(tempCamp, contacts, 1, statai);
        contacts.remove(0);
        camps.clear();
        tempCamp = mapCamps.get(campsByName.get('Testing 7'));
        camps.add(tempCamp);
        statai.clear();
        statai.add('Signed Up');
        TestDataFactory.CreateCampaignMembers(camps, contacts, 1, statai);
        contacts.remove(0);
        //create volunteers for Testing 7
        TestDataFactory.CreateJobShift(camps);
        statai.clear();        
        statai.add('Confirmed');
        tempCamp = mapCamps.get(tempCamp.Related_Campaign__c);
        CreateVolHours(tempCamp, contacts, 1, statai);
                                
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
        
        ApexPages.StandardController std1 =
            new ApexPages.StandardController(campList[0]);
        CMSendEmails firstTest = new CMSendEmails(std1); 
        List<SelectOption> typesOfEmail = firstTest.getEmailTypes();
        pgref.add(firstTest.SendTheEmails());
        returnPages.add(pgref[0].getUrl());
        
        //--------------------
        //Campaign 2 has no participants and no volunteers
        std1 = new ApexPages.StandardController(campList[1]);
        CMSendEmails secondTest = new CMSendEmails(std1);
        system.assertEquals('There are no participants or volunteers associated with this campaign', secondTest.message);
        pgref.add(secondTest.SendTheEmails());                
        returnPages.add(pgref[1].getUrl());
        
        //-------------------
        std1 = new ApexPages.StandardController(campList[2]);
        CMSendEmails thirdTest = new CMSendEmails(std1);
        pgref.add(thirdTest.SendTheEmails());
        returnPages.add(pgref[2].getUrl());
                
        //--------------------  Test with no template
        std1 = new ApexPages.StandardController(campList[3]);
        CMSendEmails fourthTest = new CMSendEmails(std1);
        fourthTest.sansTemplate = true;
        pgref.add(fourthTest.SendTheEmails());        
        returnPages.add(pgref[3].getUrl());
                
        //---------
        //There is no email templates for this campaign
        std1 = new ApexPages.StandardController(campList[4]);
        CMSendEmails fifthTest = new CMSendEmails(std1);
        system.assertEquals('There are no documents for the Attachment', fifthTest.message);
        pgref.add(fifthTest.SendTheEmails());
        returnPages.add(pgref[4].getUrl());

        std1 = new ApexPages.StandardController(campList[5]);        
        CMSendEmails sixthTest = new CMSendEmails(std1);
        pgref.add(sixthTest.SendTheEmails());       
        returnPages.add(pgref[5].getUrl());
        
        std1 = new ApexPages.StandardController(campList[6]);        
        CMSendEmails seventhTest = new CMSendEmails(std1);
        pgref.add(seventhTest.SendTheEmails());       
        returnPages.add(pgref[6].getUrl());
        
        test.stopTest();
        
        //Integer tasksInserted = [select count() from Task where ];
        //system.assertEquals(5, tasksInserted);
        system.debug('returnPages.size()' + returnPages.size());
//        for (integer x=0; x<returnPages.size(); x++)
//        {
//            if (CampList[x].Name != 'Testing 2' && CampList[x].Name != 'Testing 5')
//                system.assertEquals(true, returnPages[x].contains(CampList[x].id));
//        }                
    }
    
    public static void CreateVolHours (Campaign camp, List<Contact> conts, Integer numVol, List<String> stats)
    {
        GW_Volunteers__Volunteer_Job__c job = [SELECT id, Name, GW_Volunteers__Campaign__c
                                              FROM GW_Volunteers__Volunteer_Job__c
                                              WHERE GW_Volunteers__Campaign__c = :camp.id Limit 1];
        GW_Volunteers__Volunteer_Shift__c shift = [Select id, GW_Volunteers__Volunteer_Job__c,
                                                   GW_Volunteers__Start_Date_Time__c
                                                  from GW_Volunteers__Volunteer_Shift__c
                                                  where GW_Volunteers__Volunteer_Job__c = :job.id Limit 1];
        List<GW_Volunteers__Volunteer_Hours__c> hours = 
            new List<GW_Volunteers__Volunteer_Hours__c>();
        if (conts.size() < stats.size())
            system.debug('Not enough contacts, or too many statuses');
        else
        {
            Integer statusIndex = 0;
            for (Integer x=0; x < numVol; x++)
            {
                Integer y = statusIndex < stats.size() ? statusIndex : stats.size() - 1;
                GW_Volunteers__Volunteer_Hours__c volHour = 
                    new GW_Volunteers__Volunteer_Hours__c(GW_Volunteers__Contact__c = conts[x].id,
                                                      GW_Volunteers__End_Date__c = camp.EndDate,
                                                      GW_Volunteers__Hours_Worked__c = 3,
                                                      GW_Volunteers__Number_of_Volunteers__c = 1,
                                                      GW_Volunteers__Planned_Start_Date_Time__c =
                                                        shift.GW_Volunteers__Start_Date_Time__c,
                                                      GW_Volunteers__Start_Date__c = camp.StartDate,
                                                      GW_Volunteers__Status__c = stats[y],
                                                      GW_Volunteers__Volunteer_Job__c = job.id,
                                                      GW_Volunteers__Volunteer_Shift__c = shift.id);
                hours.add(volHour);
            }
            insert hours;
        }        
    }
    
    private static void CreateEmailContent (String cType)
    {
        List<String> typeEmail = new List<String>{'Reminder Emails', 'After Campaign Emails'};
        List<Email_Content__c> eContents = new List<Email_Content__c>();
        for (Integer x = 0; x < 2; x++)
        {
            Email_Content__c eContent = 
                new Email_Content__c (Name = cType + ' content email',
                                      Body__c = 'this is the body',
                                      Campaign_Type__c = cType,
                                      For_Participants__c = true,
                                      For_Volunteers__c = true,
                                      Subject__c = 'This is your email',
                                      Type_of_Email__c = typeEmail[x]);
            eContents.add(eContent);
        }
        insert eContents;
    }
}