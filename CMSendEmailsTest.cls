@isTest(SeeAllData=true)

public class CMSendEmailsTest {
    @isTest
    private static void SndEmail()
    {
        //only insert campaign members for the first campaign created
        //camp[0] - Adventure, CM 0,1,2   Volunteer - CM 3,4
        //camp[1] - Adventure no CM  volunteer - CM 4,5
        //camp[2] - Adventure CM 0,1,2,3 Volunteer No CM
        //camp[3] - Adventure no CM  volunteer no CM
        List<Campaign> campList = new List<Campaign>
            			([Select id, Name, Related_Campaign__c, StartDate from Campaign
                          where Name LIKE 'testing%']);

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
        system.debug('campList[0].Name: '+campList[0].Name);
        ApexPages.StandardController std1 =
            					new ApexPages.StandardController(campList[0]);
        system.debug('In first test: Cycling 2 participants selected 1 volunteer');
        CMSendEmails firstTest = new CMSendEmails(std1);
		if (CampList[0].Name == 'Testing 2')
        	system.assertEquals('There are no participants or volunteers associated with this campaign', firstTest.message);
        pgref.add(firstTest.SendTheEmails());
        if (CampList[0].Name == 'Testing 5')
            system.assertEquals('There is no Email_Content of type Reminder Emails for Camping Adventure', firstTest.message);
        returnPages.add(pgref[0].getUrl());
        system.debug('returnPages[0] = '+returnPages[0]);
//--------------------
        system.debug('campList[1].Name: ' + campList[1].Name);
        std1 = new ApexPages.StandardController(campList[1]);
        system.debug('going to second test: 1 volunteer selected');
        CMSendEmails secondTest = new CMSendEmails(std1);
        if (CampList[1].Name == 'Testing 2')
            system.assertEquals('There are no participants or volunteers associated with this campaign', secondTest.message);
        pgref.add(secondTest.SendTheEmails());
        if (CampList[1].Name == 'Testing 5')
            system.assertEquals('There is no Email_Content of type Reminder Emails for Camping Adventure', secondTest.message);
        returnPages.add(pgref[1].getUrl());
        system.debug('returnPages[1] = '+returnPages[1]);

//-------------------
        system.debug('campList[2].Name: ' + campList[2].Name);
        std1 = new ApexPages.StandardController(campList[2]);
        CMSendEmails thirdTest = new CMSendEmails(std1);
		if (CampList[2].Name == 'Testing 2')
            system.assertEquals('There are no participants or volunteers associated with this campaign', thirdTest.message);
        pgref.add(thirdTest.SendTheEmails());
        if (CampList[2].Name == 'Testing 5')
            system.assertEquals('There is no Email_Content of type Reminder Emails for Camping Adventure', thirdTest.message);
        returnPages.add(pgref[2].getUrl());

        system.debug('returnPages[2] = '+returnPages[2]);

//--------------------
        std1 = new ApexPages.StandardController(campList[3]);
        CMSendEmails fourthTest = new CMSendEmails(std1);
		if (CampList[3].Name == 'Testing 2')
            system.assertEquals('There are no participants or volunteers associated with this campaign', fourthTest.message);
        pgref.add(fourthTest.SendTheEmails());
        if (CampList[3].Name == 'Testing 5')
            system.assertEquals('There is no Email_Content of type Reminder Emails for Camping Adventure', fourthTest.message);
        returnPages.add(pgref[3].getUrl());

        system.debug('returnPages[3] = '+returnPages[3]);

//---------
        system.debug('campList[4].Name: ' + campList[4].Name);
        std1 = new ApexPages.StandardController(campList[4]);
        CMSendEmails fifthTest = new CMSendEmails(std1);
		if (CampList[4].Name == 'Testing 2')
            system.assertEquals('There are no participants or volunteers associated with this campaign', fifthTest.message);
        pgref.add(fifthTest.SendTheEmails());
        if (CampList[4].Name == 'Testing 5')
            system.assertEquals('There is no Email_Content of type Reminder Emails for Camping Adventure', fifthTest.message);
        returnPages.add(pgref[4].getUrl());
        system.debug('returnPages[4] = '+returnPages[4]);

    	test.stopTest();

        //Integer tasksInserted = [select count() from Task where ];
        //system.assertEquals(5, tasksInserted);
        for (integer x=0; x<returnPages.size(); x++)
        {
            if (CampList[x].Name != 'Testing 2' && CampList[x].Name != 'Testing 5')
        		system.assertEquals(true, returnPages[x].contains(CampList[x].id));
        }

    }
}
