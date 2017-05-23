@isTest
public class CMSendEmailsTest {
    @isTest
    private static void SndEmail(){
        List<String> campType = new List<String> {'Cycling', 'Kayaking', 'Camping', 'Hiking'};
        List<Email_Content__c> emails = new List<Email_Content__c>();
        for (Integer x=0; x<4; x++)
        {
            String emailType = '';
            if (x>1) emailType = 'After Campaign Emails';
            	else emailType = 'Reminder Emails';
        	Email_Content__c email = new Email_Content__c(Name = 'testing only ' + x,
                                                     Body__c = 'Dont forget to bring all your stuff',
                                                     Campaign_Type__c = campType[x],
                                                     For_Participants__c = True,
                                                     For_Volunteers__c = True,
                                                     Type_of_Email__c = emailType,
                                                     Subject__c = 'your email *adventure.type*');
            emails.add(email);
        }
        insert emails;
        List<Contact> conts = new List<Contact>();
        //insert contacts that will become participants in the campaign
    	for (Integer x=0; x<10; x++){
        	Contact cont1 = new Contact(FirstName = 'contact ' + x,
                                    LastName = 'Iam '+ x,
                                    email = 'marthacv@gmail.com');
            conts.add(cont1);
        }
        insert conts;
        // add four new Adventure campaigns, one will have no CM
        List<Campaign> camp = new List<Campaign>();
        for (Integer x = 0; x<4 ; x++){
         	Campaign c = new Campaign(RecordTypeId = '012o0000000xwhO',
                                             Name = 'Campaign'+ x,
                                             IsActive = True,
                                             Type = campType[x],
                                             Status = 'Planned',
                                             Description = 'Text campaign cycling ' + x,
                                             Email_Message__c = 'rich text with a personalized message '+ x,
                                             Fee_for_Activity__c = 'a14o000000330iV',
                                             EndDate = Date.TODAY()+2,
                                             StartDate = Date.TODAY()+2);
            system.debug('Campaign ' + x + ' type '+campType[x]);
            if (x>1) {c.StartDate = date.today()-2; c.EndDate = date.today()-2;}
        	camp.add(c);
        }

        Database.SaveResult[] srList = Database.insert(camp, false);

        //The following code makes and inserts Campaign Member records for the
        //campaign that was just inserted.
		LIst<id> theIds = new List<id>();

	    for (Database.SaveResult sr : srList)
	    {
	        if (sr.isSuccess()) {
		        // Operation was successful, so get the ID of the record that was inserted
		        ID CampId = sr.getId();
                theIds.add(CampId);
            }
    		else
    		{
        		// Operation failed, so get all errors
        		for(Database.Error err : sr.getErrors())
        		{
        		    System.debug('The following error has occurred.');
	        	    System.debug(err.getStatusCode() + ': ' + err.getMessage());
    	    	    System.debug('Campaign fields that affected this error: '
                                 + err.getFields());
        		}
            }
        }
        List<Campaign> allCampaigns = [select Name, Type, StartDate from Campaign];
        system.debug('******* A list of campaigns inserted ');
        for (Campaign onecmp: allCampaigns)
        {
            system.debug('Campaign Name '+ onecmp.Name + ' type ' + onecmp.Type +
                         ', StartDate '+ onecmp.StartDate.format());
        }
        //only insert campaign members for the first campaign created
        //camp[0] - Adventure, CM 0,1,2   Volunteer - CM 3,4
        //camp[1] - Adventure no CM  volunteer - CM 4,5
        //camp[2] - Adventure CM 0,1,2,3 Volunteer No CM
        //camp[3] - Adventure no CM  volunteer no CM
        List<Campaign> campList = new List<Campaign>
            			([Select id, Name, Related_Campaign__c, StartDate from Campaign
                          where id In :theIds]);
		List<Campaign> volCampList = new List<Campaign>
						([Select id, Name, Related_Campaign__c, StartDate from Campaign
                          where Related_Campaign__c In :theIds]);
        List<GW_Volunteers__Volunteer_Job__c> jobs = new List<GW_Volunteers__Volunteer_Job__c>();
        for (Integer x=0; x<4; x++)
        {
            GW_Volunteers__Volunteer_Job__c job = new GW_Volunteers__Volunteer_Job__c(
            									GW_Volunteers__Campaign__c = volCampList[x].id,
            									GW_Volunteers__Location__c = 'park ' + x,
                								GW_Volunteers__Location_Street__c = 'street ' + x,
                								GW_Volunteers__Location_City__c = 'Phoenix',
                								GW_Volunteers__Location_Zip_Postal_Code__c = '8530' + x);
            system.debug('Job for Volunteer Campaign: camp id = '+volCampList[x].id);
            jobs.add(job);
        }
        Insert jobs;
        List<GW_Volunteers__Volunteer_Shift__c> shifts =
            						new List<GW_Volunteers__Volunteer_Shift__c>();
        Time shtime = time.newInstance(8, 00, 0, 0);
        for (Integer x=0;x<4;x++)
        {
            Datetime shdateTime = DateTime.newInstance(camp[x].StartDate,shtime);
        	GW_Volunteers__Volunteer_Shift__c shift =
                  new GW_Volunteers__Volunteer_Shift__c
                		(GW_Volunteers__Duration__c = 3,
                         GW_Volunteers__Volunteer_Job__c = jobs[x].id,
                         GW_Volunteers__Start_Date_Time__c=shdateTime);
            system.debug('shift linked to job id '+ jobs[x].id);
            shifts.add(shift);
        }
        insert shifts;

        List<GW_Volunteers__Volunteer_Hours__c> vHours =
            new List<GW_Volunteers__Volunteer_Hours__c>();
        List<CampaignMember> theCMs = new List<CampaignMember>();
        // CAMP[0] reminder emails - cycling  2 participants selected 1 volunteers
        //camp[0] insert 3 CM for Adventure campaign #0,1 Signed Up #2 Attended
        for (Integer x = 0; x <  3; x++){
            CampaignMember aCamMember = new CampaignMember(CampaignId = campList[0].id,
                                             ContactId = conts[x].id,
                                             Status = 'Signed Up');
            if (x==2) aCamMember.Status = 'Attended';
            system.debug('campaign = ' + campList[0].Name + ' campaign member id is ' + aCamMember.ContactId +
                                 ' with status '+ aCamMember.Status);
            theCMs.add(aCamMember);
        }
        //camp[0] insert 2 CM to volunteer campaign #3 confirmed #4 completed
        String theStatus = 'Confirmed';
        for (Integer x = 3; x <  5; x++){
            CampaignMember bCamMember = new CampaignMember(CampaignId = campList[0].Related_Campaign__c,
                                             ContactId = conts[x].id,
                                             Status = theStatus);
            GW_Volunteers__Volunteer_Hours__c bHour = new GW_Volunteers__Volunteer_Hours__c(
                        								  GW_Volunteers__Hours_Worked__c = 3,
                										  GW_Volunteers__Start_Date__c = campList[0].StartDate,
                    									  GW_Volunteers__Status__c = theStatus,
                    									  GW_Volunteers__Contact__c = conts[x].id,
                        								  GW_Volunteers__Volunteer_Job__c = jobs[0].id,
                        								  GW_Volunteers__Volunteer_Shift__c = shifts[0].id);
            if (x==4) theStatus = 'Completed';
            system.debug('vol campaign[0] = ' + campList[0].Name + ' the campaign member id is ' + bCamMember.ContactId +
                                 ' with status '+ bCamMember.Status);
            theCMs.add(bCamMember);
            vHours.add(bHour);
        }
        //camp[1] Insert 2 CM in the Volunteer campaign #4 confirmed #5 Completed
        //camp[1] Reminder Emails   1 Volunteer should be selected  0 Participants
        theStatus = 'Confirmed';
        for (Integer x = 4; x <  6; x++){
            CampaignMember cCamMember = new CampaignMember(CampaignId = campList[1].Related_Campaign__c,
                                             ContactId = conts[x].id,
                                             Status = theStatus);
            GW_Volunteers__Volunteer_Hours__c cHour = new GW_Volunteers__Volunteer_Hours__c(
                        								  GW_Volunteers__Hours_Worked__c = 3,
                										  GW_Volunteers__Start_Date__c = campList[1].StartDate,
														  GW_Volunteers__Status__c = theStatus,
                    									  GW_Volunteers__Contact__c = conts[x].id,
                        								  GW_Volunteers__Volunteer_Job__c = jobs[1].id,
                        								  GW_Volunteers__Volunteer_Shift__c = shifts[1].id);
            if (x==5) theStatus = 'Completed';
            system.debug('campaign vol camp[1]= ' + campList[1].Name + 'the campaign member id is '
                         						+ cCamMember.ContactId +
                                 				' with status '+ cCamMember.Status);
            theCMs.add(cCamMember);
            vHours.add(cHour);
        }
        //camp[2] insert 4 CMs in Adventure Campaign #1,3 signed up #0 attended #2 cancelled
        //camp [2]After Campaign Emails   1 PARTICIPANT should be selected
        for (Integer x = 0; x <  4; x++){
            CampaignMember dCamMember = new CampaignMember(CampaignId = campList[2].id,
                                             ContactId = conts[x].id,
                                             Status = 'Signed Up');
            if (x==0) dCamMember.Status='Attended';
             else if (x==2) dCamMember.Status = 'Cancelled';
            system.debug('campaign [2]= ' + campList[2].Name + 'the campaign member id is '
                         				+ dCamMember.ContactId +
                                 		' with status '+ dCamMember.Status);
            theCMs.add(dCamMember);
        }
        system.debug('the size for theCMs = '+ theCMs.size());
    	insert theCMs;
        system.debug('*******here are the campaignmembers insterted ');
        list<CampaignMember> allCMs = [SELECT NAME, STATUS FROM CampaignMember];
        for (CampaignMember one : allCMs)
        {
            system.debug('Campaign member: '+one.Name + ', Status: '+ one.Status);
        }
        insert vHours;

    	//begin test now
    	//
        //CAMP[0] reminder emails - cycling  2 participants selected 1 volunteers
        //camp[1] Reminder Emails   1 Volunteer should be selected  0 Participants
        //camp[2] After Campaign Emails   1 PARTICIPANT should be selected
		//camp[3] no campaign members at all
        test.startTest();
        List<String> returnPages = new List<String>();
        List<PageReference> pgref = new List<PageReference>();
        ApexPages.StandardController std1 =
            					new ApexPages.StandardController(campList[0]);
        system.debug('In first test: Cycling 2 participants selected 1 volunteer');
        CMSendEmails firstTest = new CMSendEmails(std1);
        firstTest.volAttachment = false;
        pgref.add(firstTest.SendTheEmails());
        returnPages.add(pgref[0].getUrl());
        std1 = new ApexPages.StandardController(campList[1]);
        system.debug('going to second test: 1 volunteer selected');
        CMSendEmails secondTest = new CMSendEmails(std1);
        secondTest.picklist.etype__c = 'After Campaign Emails';
        secondTest.volAttachment = false;
        pgref.add(secondTest.SendTheEmails());
        returnPages.add(pgref[1].getUrl());
        std1 = new ApexPages.StandardController(campList[2]);
        CMSendEmails thirdTest = new CMSendEmails(std1);
        // set the add attachemnts to volunteers to FALSE for camp[2] before calling
        // the SendTheEmails method
        thirdTest.volAttachment = false;
        pgref.add(thirdTest.SendTheEmails());
        returnPages.add(pgref[2].getUrl());
        std1 = new ApexPages.StandardController(campList[3]);
        CMSendEmails fourthTest = new CMSendEmails(std1);
        fourthTest.volAttachment = false;
        pgref.add(fourthTest.SendTheEmails());
        system.assertEquals('There are no participants or volunteers associated with this campaign', fourthTest.message);
        returnPages.add(pgref[3].getUrl());
    	test.stopTest();
        Integer tasksInserted = [select count() from Task];
        system.assertEquals(5, tasksInserted);
        system.assertEquals(true, returnPages[0].contains(CampList[0].id));
        system.assertEquals(true, returnPages[1].contains(CampList[1].id));
        system.assertEquals(true, returnPages[2].contains(CampList[2].id));
        system.assertEquals(true, returnPages[3].contains(CampList[3].id));
    }
}
