//this class is the controller for the VF page signUpBenevonMember

public class signUpBenevonMembers {
    public BenInvitee invitee;
    id benevonTypeID;
    public Id campaignID{get;set;}
    map<id, Campaign> BenCamp;
    Boolean changeEmailAddress;
    Boolean triedUpdate;

    public signUpBenevonMembers(){
        //retrieve the id number for the Campaign records of record type Benevon
        benevonTypeID = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Benevon').getRecordTypeId();
        changeEmailAddress=false;
        triedUpdate = false;
    }
    
    public List<SelectOption> getBenevonEvents(){
        //retrieve the next 5 Benevon POE events
        BenCamp = new Map<id, Campaign>([SELECT ID, Name, StartDate
                                         FROM Campaign
                                         WHERE RecordTypeId = :benevonTypeId
                                         AND StartDate > Today
                                         ORDER by StartDate
                                         Limit 5]);
        List<SelectOption> POEevents = new List<SelectOption>();
        List<Campaign> campaigns = BenCamp.values();
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
        String stndcamp = '';
        PageReference campPage;
        //check if there are any required fields
        //left blank
        string mistake = '';
        If (invitee.FirstName.length() == 0)
            mistake = 'Please type in the First Name';
        Else 
            if (invitee.LastName.length() == 0)
               mistake = 'Please type in the Last Name';
            else
                if (invitee.Email.length() == 0)
                    mistake = 'You must enter an Email address';
        if (mistake.length() > 0)
        {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, mistake));
            return null;
        }
        //look for the contact record
        Contact contact = new Contact();
        List<Contact> contacts = [select id FROM Contact 
                           WHERE FirstName = :invitee.FirstName
                           AND LastName = :invitee.LastName];
        if (contacts.size() == 0)
        {
            //if the contact is not in the database create a new one and
            //insert it
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
                                                                   'We were unable to update you email address at this time, please contact us. Go ahead and click on SIGN UP agan'));
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
        // direct the user to the confirmation page
        String campName = BenCamp.get(campaignID).Name;           
        PageReference confirmation = new PageReference('/apex/signUpConfirmationVF?poe=' + campName);
        return confirmation;
    }
    
    public class BenInvitee{
        public String FirstName {get;set;}
        public String LastName {get;set;}
        public String Email {get;set;}
        public String Phone {get;set;}
        
        public benInvitee(){}
    }
    
}