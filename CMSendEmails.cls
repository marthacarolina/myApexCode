//This class sends emails to members of a campaign, using a template in the
//object Email_Content. 
//It attaches Policies and procedures according to the Campaign type.
//It uses the Custom Type Settings: Attachment_Setting__mdt to check the campaign type
//Martha Vance May 2018


public class CMSendEmails {
    
    private ApexPages.StandardController std;
    @TestVisible private final Campaign camp;
    public Campaign volCamp {get;set;}
    public String emailType {get;set;}
    public List<WrapCM> cMs {get;set;}
    public String message {get;set;}
    public Boolean volAttachment {get;set;}
    public String emailSubject {get;set;}
    private List<String> attch = new List<String>();
    private List<CampaignMember> cMAdv;
    private List<CampaignMember> cMVol;
    private List<id> volIds;
    private List<GW_Volunteers__Volunteer_Hours__c> volInfo;
    private map<id,GW_Volunteers__Volunteer_Job__c> jobInfo;
    private String theSubject;
    private Boolean noTemplate;
    private Boolean attExist = True;
    @TestVisible private Boolean sansTemplate;
    private Boolean no_Vol = false;
    private Boolean no_participants = false;
    
    public CMSendEmails (ApexPages.StandardController stdCtrl)
    {
        volInfo = new List<GW_Volunteers__Volunteer_Hours__c>();
        jobInfo = new map<id,GW_Volunteers__Volunteer_Job__c>();
        volAttachment = true;
        noTemplate = False;
        sansTemplate = False;
        camp = (Campaign) stdCtrl.getRecord();
        Map<id, RecordType> cRecordType = Utilities.CampaignRecTypes();
        //if the campaign is a benevon campaign do not include the attachment for Volunteers
        if (cRecordType.get(camp.RecordTypeId).Name == 'Benevon')
        {
            volAttachment = false;
        }
        //check if it is an Adventure or a Volunteer campaign
        If (cRecordType.get(camp.RecordTypeId).Name == 'Adventure' ||
            cRecordType.get(camp.RecordTypeId).Name == 'Volunteer Campaign' ||
            cRecordType.get(camp.RecordTypeId).Name == 'Benevon' ||
            camp.Type == 'Orientation')
        {
            //Get Volunteer campaign
            //If the campaign that originated the process is a volunteer campaign with no related
            //campaign
            If (camp.Related_Campaign__c != null)
            {
                volCamp = [SELECT id, Name, RecordTypeId, Type, Description,
                           StartDate, Email_Message__c, Related_Campaign__c
                           FROM Campaign WHERE id =: camp.Related_Campaign__c];
                if (volCamp.Email_Message__c == null) volCamp.Email_Message__c = camp.Email_Message__c;
            }
            else
            {
                no_Vol = true;
                volCamp = new Campaign();
                volCamp.id = camp.id;               
            }
        }
        else
            no_Vol = true;
        
        cMs = new List<WrapCM>();
        //set the default for the type of emails to send
        if (cRecordType.get(camp.RecordTypeId).Name == 'Benevon')
        {
            volAttachment = false;
            emailType = 'No Template';
        }
        else if (camp.StartDate > date.today()) emailType = 'Reminder Emails';
             else emailType = 'After Campaign Emails';
        
        //Get campaign members from both campaigns and show them on the VF page
        //The campaign members without emails will not be visible in the page
        cMAdv = [SELECT id, Email, Name, FirstName, LastName, Status,
                 ContactId, Description, Activity_Days__c
                 FROM CampaignMember WHERE CampaignId = :camp.id And Email != null
                 ORDER BY Name LIMIT 30];
        If (cMAdv.size()>0)
            Make_Wrap(cMAdv, 'Participant');
        else no_participants = true;
        if (! no_Vol)
        {
            cMVol = [SELECT id, Email, Name, FirstName, LastName, Status,
                     Description, ContactId, Activity_Days__c
                     FROM CampaignMember WHERE CampaignId = :volCamp.id AND Email != null
                     ORDER BY Name LIMIT 30];
            //system.debug('Number of Volunteers in Campaign ' + cMVol.size());
            if (cMVol.size() > 0)
            {
                Make_Wrap(cMVol, 'Volunteer');
                VolunteerInformation(True);
            }
            else
            {
                no_Vol = true;
                VolunteerInformation(False);
            }            
        }
        if (no_Vol && no_participants)
            message = 'There are no participants or volunteers associated with this campaign';
        
    }
    
    public void Make_Wrap (List<CampaignMember> campMems, String type_Cm){        
        //this method makes the wrap to include the checkbox and distinguish
        //participants from volunteers. It adds the object to a list which will
        //be the list of recipients
        boolean selected = false;      
        For (CampaignMember c : campMems)
        {
            if (emailType == 'Reminder Emails')
            {
                if (c.Status == 'Signed Up' || c.Status == 'Confirmed') selected = true;
            }
            else
            {
                if (emailType == 'After Campaign Emails')
                {
                    if (c.Status == 'Attended' || c.Status == 'Completed')
                        selected = true;
                }
            }
            cMs.add(new WrapCM(c, selected, type_Cm));
            selected = false;
        }
    }
    
    public List<SelectOption> getEmailTypes(){
        //this method creates the selection list (drop down) for the type of email to send
        List<SelectOption> emTypes = new List<SelectOption>();
        emTypes.add(new SelectOption('Reminder Emails','Reminder Emails'));
        emTypes.add(new SelectOption('After Campaign Emails','After Campaign Emails'));        
        emTypes.add(new SelectOption('No Template','No Template Emails (only the message here is included)'));                
        return emTypes;        
    }
    
    private void VolunteerInformation(Boolean isVol)
    {
        // this method retrieves the Volunteer's campaign records and attachments
        if (isVol)  // If there are volunteers in the campaign
        {
            if (volAttachment)
            {   // Get the id of the document to be attached
                Attachment_Setting__mdt attachments = [Select Document_Name__c
                                                       FROM Attachment_Setting__mdt
                                                       WHERE CampType__c = :camp.Type Limit 1];
                Try
                {
                    Document docs = [Select id from Document
                                     Where DeveloperName = :attachments.Document_Name__c];
                    attch.add(docs.id);
                }
                catch (Exception e)
                {
                    message = 'There are no documents for the Attachment';
                    attExist = False;
                }
            }
            // get the record from the Volunteer_Hours__c object for the vounteers in
            // the campaign
            volInfo = [SELECT GW_Volunteers__Shift_Start_Date_Time__c,
                       GW_Volunteers__Total_Hours_Worked__c,
                       GW_Volunteers__Status__c,
                       GW_Volunteers__Contact__c,
                       GW_Volunteers__Volunteer_Job__c
                       FROM GW_Volunteers__Volunteer_Hours__c
                       WHERE GW_Volunteers__Volunteer_Job__r.GW_Volunteers__Campaign__c =
                       :volCamp.id];
            // get the information from the Volunteer_Job__c object for the campaign
            jobInfo = new map<id, GW_Volunteers__Volunteer_Job__c>
                ([Select GW_Volunteers__Location__c,
                  GW_Volunteers__Location_Street__c,
                  GW_Volunteers__Location_City__c,
                  GW_Volunteers__Location_Zip_Postal_Code__c,
                  GW_Volunteers__Location_Information__c
                  FROM GW_Volunteers__Volunteer_Job__c
                  WHERE GW_Volunteers__Campaign__c = :volCamp.id]);
        }
        else
        {
            //if there are no volunteers get any record from the
            //Volunteer_Hours__c and Job it won't be used, but it needs can't be null.
            volInfo = [SELECT GW_Volunteers__Shift_Start_Date_Time__c,
                       GW_Volunteers__Total_Hours_Worked__c,
                       GW_Volunteers__Status__c,
                       GW_Volunteers__Contact__c,
                       GW_Volunteers__Volunteer_Job__c
                       FROM GW_Volunteers__Volunteer_Hours__c
                       LIMIT 1];
            jobInfo = new map<id, GW_Volunteers__Volunteer_Job__c>
                ([Select GW_Volunteers__Location__c,
                  GW_Volunteers__Location_Street__c,
                  GW_Volunteers__Location_City__c,
                  GW_Volunteers__Location_Zip_Postal_Code__c,
                  GW_Volunteers__Location_Information__c
                  FROM GW_Volunteers__Volunteer_Job__c
                  WHERE id = :volInfo[0].GW_Volunteers__Volunteer_Job__c
                  LIMIT 1]);
        }
    }
    
    private GW_Volunteers__Volunteer_Hours__c whatShift(id contId)
    {
        //this method retrieves the shift record for the volunteer campaign
        GW_Volunteers__Volunteer_Hours__c shft = new GW_Volunteers__Volunteer_Hours__c();
        for (GW_Volunteers__Volunteer_Hours__c vh : volInfo)
            if (vh.GW_Volunteers__Contact__c == contId)
            shft = vh;
        return shft;
    }
    
    public PageReference SendTheEmails()        
    {
        //This method is triggered when the user clicks on the Send Emails button
        if(emailType == 'No Template') sansTemplate = true;
        
        if (!no_Vol || !no_participants)
        {
            //if there are participants and/or volunteers
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            //add a SingleEmailMessage to each campaignmember selected
            String cType = camp.Type;
            if (emailType == 'After Campaign Emails')
                cType = 'Cycling';
            List<Email_Content__c> emailBody = new List<Email_Content__c>();
            // initialize template variables
            String pBody = '';   
            String pSubject = '';
            String vBody = '';
            String vSubject = '';
            if (!sansTemplate)  //if using templates
            {
                //retrieve the templates from Email_Content__c (for participants & vols)
                try{
                    emailBody = [Select For_Participants__c, For_Volunteers__c,
                                 Type_of_Email__c, Campaign_Type__c, Body__c,
                                 Subject__c
                                 From Email_Content__c
                                 Where Type_of_Email__c = :emailType AND
                                 Campaign_Type__c = :cType];
                }
                catch (Exception e)
                {
                    message = 'There is no Email_Content of type '+ emailType + ' for '+ cType+' Adventure';
                    noTemplate = true;
                }
                if (emailBody.size() == 0) //if there were no records found for the campaign type
                {
                    message = 'There is no Email_Content of type '+ emailType + ' for '+ cType+' Adventure';
                    noTemplate = true;
                }
                if (! noTemplate)
                {
                    for (Email_Content__c bd : emailBody)
                    {
                        // set the subject and body of the email depending on whether the
                        // campaign member is a Participant or a Volunteer
                        if (bd.Body__c == null) bd.Body__c = '<span></span>';
                        if (bd.For_Participants__c)
                        {
                            pBody = bd.Body__c;
                            pSubject = bd.Subject__c;
                        }
                        if (bd.For_Volunteers__c)
                        {
                            vBody = bd.Body__c;
                            vSubject = bd.Subject__c;
                        }
                    }
                }
            }
            else  //if the user doesn't want to include a template asign values to template variables
            {
                pBody = '*additional.message*<br/><br/><br/>*user.name*<br/>*user.email*';
                if (emailSubject != null) 
                    pSubject = emailSubject;
                else
                    pSubject = 'A message from Daring Adventures';                  
                vBody = '*additional.message*<br/><br/><br/>*user.name*<br/>*user.email*';
                vSubject = pSubject;
            }
            if (! noTemplate)  // if there was a template found or the user elected No Template
            {
                //set the bcc address to the user sending the emails
                List<String> bccAddys = new List<String>();
                bccAddys.add(UserInfo.getUserId());
                //go trhough the list of select campaign members and add a message to the
                //list of single emails to send
                for (WrapCM wCM : cMs)
                {
                    // if the campaign member has been selected in the UI
                    if (wCM.selected)
                    {
                        Messaging.SingleEmailMessage mess = new Messaging.SingleEmailMessage();
                        mess.setBccAddresses(bccAddys);
                        List<String> addresses = new List<String>();
                        addresses.add(wCM.part.email);
                        mess.setTargetObjectId(wCM.part.ContactId);
                        mess.setToAddresses(addresses);
                        mess.setSenderDisplayName('Daring Adventures');
                        String theBody = '';
                        if (wCM.type_member == 'Participant')
                        {
                            // if the campaign member is a participant
                            theSubject = pSubject.replace('*adventure.type*', camp.type);
                            GW_Volunteers__Volunteer_Hours__c volShift = 
                                new GW_Volunteers__Volunteer_Hours__c();
                            GW_Volunteers__Volunteer_Job__c volJob = 
                                new GW_Volunteers__Volunteer_Job__c();
                            if (volInfo.size() > 0) {
                                volShift = volInfo[0];
                                volJob = jobInfo.get(volShift.GW_Volunteers__Volunteer_Job__c);
                            }
                            volJob = FillNull(volJob);
                            theBody = makeBody(wCM.part, camp, pBody, volShift, volJob);
                        }
                        else
                        {//if the campaign member is a volunteer
                            Integer index = 0;
                            for (Integer i = 0; i<volInfo.size(); i++)
                            {   //find the record from Volunteer_Hours__c that corresponds to this
                                //campaign member
                                if (volInfo[i].GW_Volunteers__Contact__c == wCM.part.ContactId)
                                {
                                    index = i;
                                    i = volInfo.size();
                                }
                            }
                            theSubject = vSubject.replace('*adventure.type*', camp.type);
                            GW_Volunteers__Volunteer_Hours__c volShift =
                                whatShift(wCM.part.ContactId);
                            GW_Volunteers__Volunteer_Job__c volJob =
                                jobInfo.get(volShift.GW_Volunteers__Volunteer_Job__c);
                            volJob = FillNull(volJob);
                            theBody = makeBody(wCM.part, volCamp, vBody, volShift, volJob);
                            //attach a file to the volunteers emails
                            if (volAttachment && attExist && (emailType == 'Reminder Emails'))
                                mess.setEntityAttachments(attch);
                        }
                        mess.setSubject(theSubject);
                        mess.setHtmlBody(theBody);
                        messages.add(mess);
                    }
                }
                //once all the emails have been added to the list send the emails using
                //the messaging class
                messaging.sendEmail(messages);
                List<Campaign> updatedCamps = new List<Campaign>();
                updatedCamps.add(camp);
                if (! no_Vol) updatedCamps.add(volCamp);
                update updatedCamps;
                return new PageReference('/'+camp.id);
            }
            else
            {
                return ApexPages.currentPage();
            }
        }
        else
            return ApexPages.currentPage();        
    }
    
    private GW_Volunteers__Volunteer_Job__c FillNull (GW_Volunteers__Volunteer_Job__c vJ)
    {
        //This method fills in the null values 
        if (vJ.GW_Volunteers__Location__c == null)
            vJ.GW_Volunteers__Location__c = '<span></span>';
        if (vJ.GW_Volunteers__Location_Street__c == null)
            vJ.GW_Volunteers__Location_Street__c = '<span></span>';
        if (vJ.GW_Volunteers__Location_City__c == null)
            vJ.GW_Volunteers__Location_City__c = '<span></span>';
        if (vJ.GW_Volunteers__Location_Zip_Postal_Code__c == null)
            vJ.GW_Volunteers__Location_Zip_Postal_Code__c = '<span></span>';
        if (vJ.GW_Volunteers__Location_Information__c == null)
            vJ.GW_Volunteers__Location_Information__c = '<span></span>';
        return vJ;
    }
    
    private String makeBody(CampaignMember c, Campaign tcamp, String template,
                            GW_Volunteers__Volunteer_Hours__c vHours,
                            GW_Volunteers__Volunteer_Job__c vJob)
    {
        // This method calls the Reminder method or the ThankYou method. Both metohds
        // return the body of the email.
        If (emailType == 'Reminder Emails') return Reminder(c, tcamp, template, vHours, vJob);
        else return ThankYou(c, tcamp, template, vHours, vJob);
    }
    
    private String Reminder(CampaignMember c, Campaign tcamp, String template,
                            GW_Volunteers__Volunteer_Hours__c vHours,
                            GW_Volunteers__Volunteer_Job__c vJob)
    {
        String body = '';
        template = template.replace('*Name*',c.FirstName);
        template = template.replace('*adventure.type*', tcamp.Type);
        if (tcamp.Description != null)
            template = template.replace('*adventure.description*', tcamp.Description);
        else
            template = template.replace('*adventure.description*', ' ');
        
        template = template.replace('*adventure.startdate*', tcamp.StartDate.format());
        if (tcamp.Google_Calendar_Link__c != null)
        {
            String linkAndImage = '<a target="_blank" href="' + 
                                    tcamp.Google_Calendar_Link__c + 
                                    '"><img border="0" src="https://www.google.com/calendar/images/ext/gc_button1_en.gif"></a>';
            template = template.replace('*adventure.googlelink*', linkAndImage);
        }
        else
        {
            template = template.replace('*adventure.googlelink*', '');            
        }
        String rplcment= specMessage(tcamp);
        template = template.replace('*additional.message*', rplcment);
        template = template.replace('*user.name*', UserInfo.getName());
        template = template.replace('*user.email*', UserInfo.getUserEmail());
        if (tcamp.name.contains('Volunteer'))
        {
            String sTime = ''+ vHours.GW_Volunteers__Shift_Start_Date_Time__c.time();
            template = template.replace('*shift.starttime*',sTime);
            template = template.replace('*job.location*', vJob.GW_Volunteers__Location__c);
            template = template.replace('*job.street*', vJob.GW_Volunteers__Location_Street__c);
            String cityLine = vJob.GW_Volunteers__Location_City__c + ' ' +
                vJob.GW_Volunteers__Location_Zip_Postal_Code__c;
            template = template.replace('*job.city*', cityLine);
            template = template.replace('*location.information*',vJob.GW_Volunteers__Location_Information__c);
        }
        body = body + template;
        return body;
    }
    
    public String ThankYou(CampaignMember c, Campaign tcamp, String template,
                           GW_Volunteers__Volunteer_Hours__c vHours,
                           GW_Volunteers__Volunteer_Job__c vJob)
    {
        String body = '';
        String activity_days = '' + c.Activity_Days__c;
        String hours = '' + vHours.GW_Volunteers__Total_Hours_Worked__c;
        template = template.replace('*Name*',c.FirstName);
        template = template.replace('*XX*', activity_days);
        template = template.replace('*HH*', hours);
        template = template.replace('adventure.type', tcamp.type);
        String rplcment= specMessage(tcamp);
        template = template.replace('*additional.message*', rplcment);
        template = template.replace('*user.name*', UserInfo.getName());
        template = template.replace('*user.email*', UserInfo.getUserEmail());
        body = body + template;
        return body;
    }
    
    private String specMessage(Campaign tcamp)
    {
        string rplcment='';
        if (tcamp.Email_Message__c == null) {
            rplcment = '<span></span>';
        }
        else 
            rplcment = tcamp.Email_Message__c;
        return rplcment;        
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