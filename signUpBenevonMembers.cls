//this class is the controller for the VF pages 
//    signUpBenevonMember (a form for anyone to sign up for public POE's)
//    singUpPrivatePOE (a form for people invited to sign up for private POE's)
//    signUpOrientation (a form for anyone to sign up for Volunteer Orientation)

public class signUpBenevonMembers {
    public BenInvitee invitee;
    @TestVisible private id campTypeID;
    public Id campaignID{get;set;}
    @TestVisible private boolean isPublic; //if the campaign is public this var is true
    map<id, Campaign> CampaignsMap;
    Boolean changeEmailAddress;
    Boolean triedUpdate;
    public Campaign privateCampaign {get;set;}
    private String campType;
    public Boolean newContact {get;set;} //if the contact is not already in the database


    public void signUpBenevonMembers(){}
    
    public boolean getBegin() {
        //retrieve the id number for the Campaign records of record type Benevon
        changeEmailAddress=false;
        triedUpdate = false;
        isPublic = true;
        //Get the name (address) of the page usign the controller
        String PageURL = ApexPages.currentPage().getUrl();
        PageUrl = PageURL.toLowerCase();
        if (PageURL.containsIgnoreCase('signupprivate'))
        {
            //if the POE is private retrieve the campaign with the id in the URL
            isPublic = false;
            campaignID = (id) apexpages.currentpage().getparameters().get('id'); 
            privateCampaign = [Select id, Name from Campaign
                               WHERE id = :campaignID
                               LIMIT 1];
        }
        else
        {
        if (PageURL.containsIgnoreCase('signupmember')) {
            campType = 'Benevon';
        }
        else {
            campType = 'Volunteer Campaign';
        }
        campTypeID = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get(campType).getRecordTypeId();
        }
        return true;
    }
    
    public List<SelectOption> getCampaignEvents(){
        //retrieve the next 5 Benevon POE events
        String extFilter;
        if (campType == 'Benevon') {
            extFilter = 'Type = \'POE\'';
        }
        else {
            extFilter = 'Name Like \'Volunteer Volunteer Orientation%\'';
        }
        String queryString = 'SELECT ID, Name, StartDate FROM Campaign WHERE RecordTypeId = :campTypeId';
        queryString = queryString + ' AND StartDate >= Today AND Public_Event__c = true AND ' + extFilter; 
        queryString = queryString + ' ORDER by StartDate Limit 5';
        List<Campaign> campaigns = Database.query(queryString);
        CampaignsMap = new Map<id, Campaign>(campaigns);
        List<SelectOption> POEevents = new List<SelectOption>();
        for (Campaign c : campaigns)
            POEevents.add(new SelectOption(c.id,c.Name));        
        return POEevents;
    }      
    
    public BenInvitee getInvitee(){
        if (invitee == null) invitee = new BenInvitee();
        return invitee;
    }
    
    public void setInvitee(BenInvitee inv){
        invitee.FirstName = inv.FirstName;
        invitee.LastName = inv.LastName;
        invitee.Phone = inv.Phone;
        invitee.Email = inv.Email;
    }
        
    public PageReference save(){
        if (campaignID != null)
        {
            String stndcamp = '';
            //check if there are any required fields left blank
            string mistake = '';
            If (invitee.FirstName.length() == 0)
                mistake = 'Please type in the First Name';
            Else 
                if (invitee.LastName.length() == 0)
                mistake = 'Please type in the Last Name';
            else
                if (invitee.Email.length() == 0)
                mistake = 'You must enter an Email address';
            if (mistake.length() > 0) //if there is an error 
            {
                ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, mistake));
                return null;
            }
            //look for the contact record
            Contact contact = new Contact();
            List<Contact> contacts = [select id, email FROM Contact 
                                      WHERE FirstName = :invitee.FirstName
                                      AND LastName = :invitee.LastName];
            if (contacts.size() == 0)
            {
                //if the contact is not in the database create a new one and
                //insert it
                newContact = true;
                contact = new Contact(FirstName = invitee.FirstName,
                                      LastName = invitee.LastName,
                                      Phone = invitee.Phone,
                                      Email = invitee.email);
                try{
                    insert contact;
                } catch(DmlException e){
                    if (e.getMessage().contains('INVALID_EMAIL_ADDRESS')) {
                        ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'You need to enter a valid email address'));
                        return null;                    
                    }
                }
            }
            else
            {
                //if the contact is in the database check that the email is the same
                //if it is not the same update the old email with the new one
                contact = contacts[0];
                if (contact.email != invitee.email && ! changeEmailAddress)
                {
                    ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'Verify that your email address is correct. If it is, push SIGN UP'));
                    changeEmailAddress=true;
                    return null;
                }
                else
                {
                    contact.email = invitee.email;
                    if (! triedUpdate )
                    {
                        Try{
                            update contact;
                        }
                        catch (exception e){
                            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 
                                                                       'We were unable to update your email address at this time, please contact us. Go ahead and click on SIGN UP agan'));
                            triedUpdate = true;
                        }
                    }
                }
            }
            //create the campaign member record and sign up the contact for the camapign.
            CampaignMember benevonCM = new CampaignMember(CampaignId = campaignID,
                                                          ContactId = contact.id,
                                                          Status = 'Signed Up');
            try{
                insert benevonCM;
            } catch(DmlException e) {
                if (e.getMessage().contains('DUPLICATE_VALUE')){
                    ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'You were previously signed up for this event. '));
                    return null;
                }
                else
                {
                    ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'Sorry, something went wrong... We are unable to sign you up at this time.'));
                    return null; 
                }
            }
            // once the user has been signed on as a campaign member
            // direct the user to the confirmation page
            String campName; 
            if (isPublic) 
                campName = CampaignsMap.get(campaignID).Name;  
            else
                campName = privateCampaign.Name;
            PageReference confirmation;    
            if (campType == 'Volunteer Campaign') {
                confirmation = new PageReference('/apex/signUpConfirmationVolOrVF?contID='+contact.id+'&camp='+campName);
            }
            else {
                confirmation = new PageReference('/apex/signUpConfirmationVF?poe=' + campName);
            }
            return confirmation;
        }
        else // there is no campaign ID
        {
            //if there is no campaign to sign on to send the user a message.
            String errString;
            if (campType == 'Volunteer Campaign') {
                errString = ' Volunteer Orientations ';
            }
            else {
                errString = ' Discover Daring Adventures events ';
            }
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'There are no' + errString + 'scheduled at this time please check back later.'));
            return null; 
        }
    }
    
    public class BenInvitee{
        public String FirstName {get;set;}
        public String LastName {get;set;}
        public String Email {get;set;}
        public String Phone {get;set;}
        
        public benInvitee(){}
    }
    
}