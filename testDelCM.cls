@isTest
private class testDelCM {
    //test for CMemberTriggerHandler Trigger for deleted campaign
    //
    @isTest static void testingCMTriggerDel() {
        //add a contacts to test
        List<Contact> conts1 = TestDataFactory.CreateContacts(3, 0);
        List<Contact> conts2 = TestDataFactory.CreateContacts(6, 3);

        //add Fee
        id fee = TestDataFactory.CreateFee('Cycling', 10);
        //add GAU
        TestDataFactory.CreateGAU ('Activity Fees');
        //add Campaign Member status default
        TestDataFactory.CreateCMStatusDefault('Cycling');

        //add an Adventure Campaign
        TestDataFactory.CreateCampaigns('Test Campaign ' ,'Adventure', 'Cycling', 2, 0, Date.TODAY(), Date.TODAY(), fee);

        //add a fundraing Campaign
        TestDataFactory.CreateCampaigns('Fundraising Campaign ','Fundraising', 'Cycling', 1, 2, Date.TODAY(), Date.TODAY(), fee);

        //The following code makes and inserts Campaign Member records for the
        //campaigns that were just inserted.
        List<Campaign> advCampaign1 = [Select id, Name, StartDate, EndDate, RecordTypeId,
                                   Related_Campaign__c from Campaign
                                   where RecordType.Name = 'Adventure' and
                                   Name = 'Test Campaign 0'];
        List<String> statai = new List<String>{'Signed Up', 'Attended', 'Attended'};
        TestDataFactory.CreateCampaignMembers(advCampaign1, conts1,3, statai);
        List<Campaign> campaigns = [Select id, Name, StartDate, EndDate, RecordTypeId,
                                   Related_Campaign__c from Campaign
                                   where (RecordType.Name = 'Adventure' or
                                          RecordType.Name = 'Fundraiser') AND
                                   (Name = 'Test Campaign 0' or
                                    Name = 'Fundraising Campaign 2')];
        statai.remove(0);
        TestDataFactory.CreateCampaignMembers(campaigns, conts2, 3, statai);

        //Delete one campaign

        //Now for the test
        //Retrieve all the campaignmembers inserted
        List<CampaignMember> theCMs = [Select id, ContactId FROM
                                      CampaignMember];

        try
        {
            system.debug('theCMs[0].ContactId = '+ theCMs[0].ContactId);
            delete theCMs;

        }
        catch (DMLException e)
        {

            // Check that the trigger interrupts the deletion

            Boolean statusException =
                e.getMessage().contains('Cannot delete a member with status Attended. You must change the status first');
            system.debug('statusException = ' + statusException);
            System.AssertEquals(true, statusException);

        }
    }
}
