public class CMSendEmails {

    private ApexPages.StandardController std;
    public Campaign camp {get;set;}
    public Campaign volCamp {get;set;}
    public Picklist_Values__c picklist {get;set;}
    private Boolean no_Vol = false;
    private Boolean no_participants = false;
    private List<CampaignMember> cMAdv;
    private List<CampaignMember> cMVol;
    public List<WrapCM> cMs {get;set;}
    public String message {get;set;}
	public Email_Content__c email_template;

    public CMSendEmails (ApexPages.StandardController stdCtrl)
    {
    	camp = [SELECT id, Name, RecordTypeId, Type, Description, StartDate,
                Email_Message__c, Related_Campaign__c
               FROM Campaign WHERE id = :stdCtrl.getId()];
        //check if it is an Adventure or a Volunteer campaign
        If (camp.RecordTypeId == '012o0000000xwhO' ||
            camp.RecordTypeId == '012o0000000xwhT')
        {
            //Get Volunteer campaign
            If (camp.RecordTypeId == '012o0000000xwhO' && camp.Related_Campaign__c != null)
            {
            	volCamp = [SELECT id, Name, RecordTypeId, Type, Description,
            				StartDate, Email_Message__c, Related_Campaign__c
                       		FROM Campaign WHERE id =: camp.Related_Campaign__c];
                if (volCamp.Email_Message__c == null) volCamp.Email_Message__c = camp.Email_Message__c;
            }
            else
            if (camp.Related_Campaign__c == null)
            {
                no_Vol = true;
                system.debug('no_Vol = ' + no_Vol);
            	volCamp = new Campaign();
            	volCamp.id = camp.id;
            }
        }
        cMs = new List<WrapCM>();
        picklist = new Picklist_Values__c();
        if (camp.StartDate > date.today()) picklist.etype__c = 'Reminder Emails';
        	else picklist.etype__c = 'After Campaign Emails';
        //Get campaign members from both campaigns
        cMAdv = [SELECT id, email, Name, FirstName, LastName, Status,
        				Email_Message__c, ContactId, Description, Activity_Days__c
                FROM CampaignMember WHERE CampaignId = :camp.id
                 ORDER BY Name LIMIT 30];
        system.debug('cMAdv.size() '+ cMAdv.size());
        If (cMAdv.size()>0)
        {
            for (CampaignMember cm1: cMAdv)
                system.debug('cm1.status = '+cm1.status);
            Make_Wrap(cMAdv, 'Participant');
        }
        else no_participants = true;
        if (! no_Vol)
        {
            cMVol = [SELECT id, email, Name, FirstName, LastName, Status,
            			Email_Message__c, Description, ContactId, Activity_Days__c
                FROM CampaignMember WHERE CampaignId = :volCamp.id
                ORDER BY Name LIMIT 30];
            if (cMVol.size() > 0) Make_Wrap(cMVol, 'Volunteer');
            else no_Vol = true;
        }
		if (no_Vol && no_participants)
            message = 'There are no participants or volunteers associated with this campaign';
    }

    public void Make_Wrap (List<CampaignMember> campMems, String type_Cm){
    	//this method makes the wrap to include the checkbox and distinguish
    	//participants from volunteers. It adds the object to a list which will
    	//be the list of recipients
        boolean selected = false;
        system.debug('in Make_Wrap type_Cm = '+ type_Cm);
        system.debug('campMems.size() = '+ campMems.size());
        For (CampaignMember c : campMems)
        {
            system.debug('Picklist.etype__c = '+ Picklist.etype__c);
            system.debug('c.FirstName = ' + c.FirstName);
            if (Picklist.etype__c == 'Reminder Emails')
        	{
                system.debug('c.Status = ' + c.Status);
            	if (c.Status == 'Signed Up' || c.Status == 'Confirmed') selected = true;
        	}
            else
                if (picklist.etype__c == 'After Campaign Emails')
            		if (c.Status == 'Attended' || c.Status == 'Completed')
                		selected = true;
            system.debug('selected = ' + selected);
            cMs.add(new WrapCM(c, selected, type_Cm));
            selected = false;
        }
        system.debug('out of Make_Wrap');
    }

    public PageReference SendTheEmails(){
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		//add a SingleEmailMessage to each campaignmember selected
		//+++ here get the records from the Email_Content__c one for participants
		List<Email_Content__c> emailBody = [Select For_Participants__c, For_Volunteers__c,
                        					Type_of_Email__c, Campaign_Type__c, Body__c
                                            From Email_Content__c
                                      		Where Type_of_Email__c = :picklist.etype__c AND
                                      		Campaign_Type__c = :camp.Type];
        String pBody = '';
        String vBody = '';
        for (Email_Content__c body : emailBody)
        {
            if(body.For_Participants__c) pBody = body.Body__c;
            if(body.For_Volunteers__c) vBody = body.Body__c;
        }
        List<String> bccAddys = new List<String>();
        bccAddys.add(UserInfo.getUserId());
        String subj = '';
        if (picklist.etype__c == 'Reminder')
            subj = 'Reminder of your upcoming '+camp.Type + ' adventure';
        else
            subj = 'We are so glad you were able to join us!';
        for (WrapCM wCM : cMs){
            Messaging.SingleEmailMessage mess = new Messaging.SingleEmailMessage();
            mess.setBccAddresses(bccAddys);
            List<String> addresses = new List<String>();
            addresses.add(wCM.part.email);
            mess.setToAddresses(addresses);
            mess.setSenderDisplayName('Daring Adventures');
            mess.setSubject(subj);
            String body = '';
            if (wCM.type_member == 'Participant')
                body = makeBody(wCM.part, camp, pbody);
            else
                body = makeBody(wCM.part, camp, vbody);
        	mess.setHtmlBody(body);
            messages.add(mess);
        }
        messaging.sendEmail(messages);
        return new PageReference('/'+camp.id);
    }

    private String makeBody(CampaignMember c, Campaign camp, String template)
    {
        If (picklist.etype__c == 'Reminder') return Reminder(c, camp, template);
        else return ThankYou(c, camp, template);
    }

	private String Reminder(CampaignMember c, Campaign camp, String template)
    {
        String body = '<h3 >Hi ' + c.FirstName + ',</h3><br />';
        body = body + camp.Email_Message__c + '<br />' + template;
		body = body + '<p>We are looking forward to our adventure with you!</p>';
		body = body + '<br />Your friends at Daring Adventures,<br/>';
        body = body + UserInfo.getName() + '<br />';
        body = body + UserInfo.getUserEmail()+'<br />';
        body = body + '555-555-5555';
        return body;
    }

    public String ThankYou(CampaignMember c, Campaign camp, String template)
    {
        String body = '<h3 >Hi '+ c.FirstName + ' ,</h3>';
		body = body + '<br /><p>Congratulations! You have completed XXXXXX ';
        body = body + 'Active Days with Daring Adventures during your recent adventure. ';
        body = body + 'We were thrilled that you were able to join us.</p><br />';
		body = body + campaign.email_message__c +'<br /><p>Do not forget to look for more adventures ';
        body = body + 'in our calendar <a href="http://www.daring-adventures.org/">';
		body = body + 'www.daring-adventures.org</a> and sign up for your next adventure.</p>';
		body = body + '<p>We are looking forward to our next adventure with you!</p>';
		body = body + '<br />Your friends at Daring Adventures,<br/>';
        body = body + UserInfo.getName() + '<br />';
        body = body + UserInfo.getUserEmail();
        String activity_days = ''+ c.Activity_Days__c;
        body = body.replace('XXXXXX', activity_days);
        return body;
    }

    public class WrapCM {
        public CampaignMember part {get;set;}
        public Boolean selected {get;set;}
    	public String type_member {get; set;}

        public WrapCM (CampaignMember p, Boolean sel, String tCM)
        {
            part = p;
            selected = sel;
            type_member = tCM;
        }
    }
}
