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
	public list<WrapTemp> pEmails;
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
    	//this method adds the email perosnalized message as well as adding the temporary
    	//records to the ParticipantEmail__c object to use with the templates
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
        addCampaignMessage(); //Add the campaign message to the selected CMs and add the records
        						//to the custom object (temporarily)
        String participant_template_name = 'Reminder'+camp.type;
        if (picklist.etype__c == 'After Campaign Emails')
			participant_template_name = 'Email_After'+camp.type;
        String volunteer_template_name = 'Vol'+participant_template_name;
		EmailTemplate temp = [select id from EmailTemplate where Name = :participant_template_name limit 1];
		system.debug('template temp = ' + temp.id);
        EmailTemplate volTemp = [select id from EmailTemplate where Name = :volunteer_template_name limit 1];
		system.debug('template voltemp = ' + volTemp.id);
        //instantiate the singleEmailMessage object
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
		//add a SingleEmailMessage to each campaignmember selected
        for (WrapTemp wCM : pEmails){
            Messaging.SingleEmailMessage mess = new Messaging.SingleEmailMessage();
            List<String> bccAddys = new List<String>();
            bccAddys.add(UserInfo.getUserId());
            mess.setBccAddresses(bccAddys);
            system.debug('wCM.tempRec.ContactId = ' + wCM.tempRec.ContactId__c);
            system.debug('wCM.tempRec.Id = '+wCM.tempRec.Id);
            //set the contact to be emailed
			mess.setTargetObjectId(wCM.tempRec.ContactId__c);
            system.debug('wCM.tempRec.Id = '+wCM.tempRec.Id);
            id theRecId = wCM.tempRec.Id;
            system.debug('theRecId = '+ theRecId);
            mess.setWhatId(theRecId);
            if (wCM.type_member == 'Participant')
                mess.setTemplateId(temp.Id);
            else
                mess.setTemplateId(volTemp.Id);
        	messages.add(mess);
        }
        messaging.sendEmail(messages);
        return new PageReference('/'+camp.id);
    }

    public void addCampaignMessage ()
    {
    	String personalizedMessage;
    	pEmails = new List<WrapTemp>();
    	List<ParticipantEmail__c> emailInfo = new List<ParticipantEmail__c>();
    	List<String> tempList = new List<String>();
    	//if the campaign member is selected, add the record to the temporary object where the
    	//template will take the information from.
        for (WrapCM wCM : cMs)
        {
        	if (wCM.selected == True)
        	{
            	if (wCM.type_member == 'Participant' && wCM.selected)
            	{
            	    personalizedMessage = camp.Email_Message__c;
            	}
            	else
            	{
            	    personalizedMessage = volCamp.Email_Message__c;
            	}
            	ParticipantEmail__c pe = new ParticipantEmail__c(CampaignStartDate__c = camp.StartDate,
            													ContactId__c = wCM.part.ContactId,
            													ContactNm__c = wCM.part.Name,
            													FirstName__c = wCM.part.FirstName,
            													LastName__c = wCM.part.LastName,
            													Description__c = camp.Description,
            													Email__c = wCM.part.Email,
            													Email_Message__c = personalizedMessage,
            													ActivityDays__c = wCM.part.Activity_Days__c);
            	emailInfo.add(pe);
            	tempList.add(wCM.Type_member);
        	}
        }
        if (emailInfo.size() > 0 )
    	{
        	insert emailInfo;
        	for (Integer x = 0; x < emailInfo.size(); x++)
            {
                system.debug('emailInfo[' + x + '].id = ' + emailInfo[x].id);
        		pEmails.add(new WrapTemp(emailInfo[x], tempList[x]));
            }
    	}
    }

    public class WrapTemp{
    	public ParticipantEmail__c tempRec;
    	public String type_member;
    	public WrapTemp (ParticipantEmail__c pe, String tCM)
    	{
    		tempRec = pe;
    		type_member = tCM;
    	}
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
