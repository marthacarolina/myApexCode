@isTest
private class TestCampaignTrigger {
    //This test is for the CampaignTriggerHandler trigger
    @isTest static void TestInsertVolCampaignAlloc() {        
        //find the id for the RecordType 'Volunteers_Campaign' in object Campaign
        TestDataFactory.CreateGAU ('Activity Fees');
        id feeId = TestDataFactory.CreateFee('Cycling', 10);
        TestDataFactory.CreateCampaigns('Test ' ,'Adventure', 'Cycling', 5, 0, Date.TODAY(), Date.TODAY(), feeId);
        TestDataFactory.CreateCampaigns('Test ','Fundraising', 'Cycling', 3, 5, Date.TODAY(), Date.TODAY(), feeId);
        //test trigger with a fundraising campaign that have CMstatus of Sent Responded
        TestDataFactory.CreateCampaigns('Test fundraising','Fundraising', 'Orientation', 3, 5, Date.TODAY(), Date.TODAY(), feeId);

        //make a Mailchimp campaign (the trigger will change the RecordType to Fundraising)
        TestDataFactory.CreateCampaigns('MailChimp ','Adventure', 'Cycling', 1, 8, Date.TODAY(), Date.TODAY(), feeId);
        //make a volunteer campaign with a diferent endDate to diferentiate it from the ones created by the trigger
        TestDataFactory.CreateCampaigns('Test ','Volunteers_Campaign', 'Cycling', 1, 9, Date.TODAY()+2, Date.TODAY()+2, feeId);
        List<Campaign> myCampaigns = [SELECT id, Name, Type, RecordTypeId,
                                     StartDate, EndDate, Related_Campaign__c
                                     from Campaign
                                     Where RecordType.Name = 'Adventure'];
        List<Contact> conts1 = TestDataFactory.CreateContacts(3,0);
        List<Contact> conts = TestDataFactory.CreateContacts(9,3);

        List<Campaign> campSignedUp = new List<Campaign>();
        campSignedUp.add(myCampaigns[0]);
        myCampaigns.remove(0);
        List<Campaign> campsWCM = new List<Campaign>{myCampaigns[1],myCampaigns[2], myCampaigns[3]};
        List<String> statai1 = new List<String>{'Signed Up'};
        List<String> statai2 = new List<String>{'Attended'};
        TestDataFactory.CreateCampaignMembers(campSignedUp, conts1,3, statai1);
        TestDataFactory.CreateCampaignMembers(campsWCM, conts,3, statai2);
        //retrieve tha volunteer records inserted by the trigger
        // when the Adventure campaigns were inserted
        List<Campaign> volrecsinserted = [SELECT id FROM Campaign WHERE Type = 'Cycling' and
                          EndDate = Today and 
                           RecordType.DeveloperName ='Volunteers_Campaign'];
        System.assertEquals(5, volrecsinserted.size());

        List<Campaign> updateCamps = new List<Campaign>();
        myCampaigns[4].Related_Campaign__c = null;
        myCampaigns[4].StartDate = date.today() + 20;
        myCampaigns[4].EndDate = date.today() + 20;
        updateCamps.add(myCampaigns[4]);
        //this part tests the after update trigger
        Campaign originCamp = campSignedUp[0];
        TestDataFactory.CreateJobShift(campSignedUp);       
        originCamp.StartDate = date.today() + 30;
        originCamp.EndDate = date.today() + 31;        
        updateCamps.add(originCamp);        
        update updateCamps;
        Campaign volCamp = [select id, StartDate, EndDate from Campaign
                           where id = :originCamp.Related_Campaign__c limit 1];
        system.assertEquals(originCamp.StartDate, volCamp.StartDate);
        // this part tests the before delete trigger.
        myCampaigns.clear();
        myCampaigns = [select id, StartDate, EndDate from Campaign];
        try
        {
            delete myCampaigns;
            System.assert(false);
        }
        catch (DMLException e)
        {
            // Check that the trigger interrupts the deletion
            Boolean statusException = e.getMessage().contains('You must change the Member status to anything but Attended before deleting a Campaign.') ? true : false;
            Boolean volunteerException =  e.getMessage().contains('Before deleting the campaign you must delete the volunteer campaign associated with it.') ? true : false;
            Boolean expectedExceptionThrown = statusException || volunteerException;
            System.AssertEquals(expectedExceptionThrown, true);
            //system.assertEquals('Before deleting the campaign you must delete the volunteer campaign associated with it.', e.getMessage());
        }        
    }
}