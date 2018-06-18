//Controller for visualforce page volApplication
//
//Martha Vance


public class VolRegistrationController {

    public Contact volunteer {get;set;}
    public boolean wildernesCert {get;set;}
    public date wildernesCertDate {get;set;}
    public moreCerts moreCerts {get;set;}
    public Application__c vApplication {get;set;}
    public List<Medication__c> meds {get;set;}
    public Medication__c med {get;set;}
    
    @testVisible private Boolean changeEmailAddress;
    @TestVisible private Boolean newContact;
    @TestVisible private Boolean triedUpdate;
    @TestVisible private Boolean existingContact;
    @TestVisible private id recTypeId;
    @TestVisible private id contID;
    
    public void VolRegistrationController() {        
    }
    
    public Boolean getIni(){
        contID = ApexPages.currentPage().getParameters().get('contID');
        if (contID != null) {
            existingContact = true;
            volunteer = [select FirstName, LastName, Email, 
                         MailingStreet, 
                         MailingCity, MailingState,
                         MailingPostalCode, BirthDate 
                         FROM Contact WHERE id = :contID LIMIT 1];
        }
        else 
        {
            existingContact = false;
            volunteer = new Contact();
            volunteer.FirstName = '';
            volunteer.LastName = '';
            volunteer.Email = '';
        }  
        moreCerts = new moreCerts();        
        vApplication = new Application__c();
        meds = new List<Medication__c>();
        changeEmailAddress = false;
        newContact = false;
        triedUpdate = false;
        recTypeId = 
            Schema.SObjectType.Application__c.getRecordTypeInfosByName().get('Volunteer Application').getRecordTypeId();
        system.debug('record type id = ' + recTypeId);
        return true;
    }

    public PageReference save() {
        system.debug('moreCerts.emt = ' + moreCerts.emt);
        volunteer.Area_of_Expertise__c = moreCerts.putTogether();
        //check if there are any required fields left blank
        string mistake = '';
        If (volunteer.FirstName.length() == 0)
            mistake = 'Please type in the First Name';
        Else 
            if (volunteer.LastName.length() == 0)
            mistake = 'Please type in the Last Name';
        else
            if (volunteer.Email.length() == 0)
            mistake = 'You must enter an Email address';
        if (mistake.length() > 0) //if there is an error 
        {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, mistake));
            return null;
        }
        volunteer.Volunteer__c = true;
        if (volunteer.CPR_Certificate_Expiration_Date__c > date.today())
            volunteer.CPR_Certificate__c = true;
        if (volunteer.First_Aid_Certification_Expiration_Date__c > date.today())
            volunteer.First_Aid_Certification__c = true;
        if (volunteer.Fingerprint_Clearance_Expiration_Date__c > date.today())
            volunteer.Fingerprint_Clearance__c = true;
        
        //look for the contact record
        if (! existingContact) {
            Contact contact = new Contact();
            List<Contact> contacts = [select id, email FROM Contact 
                                      WHERE email = :volunteer.email];
            if (contacts.size() == 0)
            {
                //if the contact is not in the database create a new one and
                //insert it
                newContact = true;               
                try{
                    insert volunteer;
                } catch(DmlException e){
                    if (e.getMessage().contains('INVALID_EMAIL_ADDRESS')) {
                        ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'You need to enter a valid email address'));
                        return null;                    
                    }
                }
            }
            else
            {
                //if the contact is in the database get the id for the new volunteer record
                volunteer.id = contacts[0].id;
            }
            //update the information in the Contact record (volunteer) if it has been 
            //inserted in the previous IF -> insert volunteer; this update shouldn't bother
            //anything. If it was an existing contact record it will update the infor with the
            //new information entered.
            try {
                update volunteer;
            }
            catch (DmlException e) {
                if (e.getMessage().contains('INVALID_EMAIL_ADDRESS')) {
                    ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, 'The email address entered is not valid'));
                    return null;                    
                }
                else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 
                                                               'There was an error while trying to save the information. Please contact our office. Error: ' + e));
                    return null;
                }
            }
        }
       
        // add the Application record for the volunteer
        vApplication.Contact__c = volunteer.id;
        vApplication.RecordTypeId = recTypeId;
        try {
            insert vApplication;
        } 
        catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 
                                 'There was an error while trying to save the information. Please contact our office. Error: ' + e));
            system.debug('there was an error while trying to insert: ' + e);
            return null;
        }
        PageReference done = new PageReference('/apex/confApplicationVol');
        return done;
    }
           
    public class moreCerts {
        public boolean emt {get;set;}
        public boolean rn {get;set;}
        public boolean pa {get;set;}
        public boolean md {get;set;}
        public boolean pt {get;set;}
        public String otherCerts {get;set;}
        public moreCerts(){
            this.emt = false;
            this.rn = false;
            this.pa = false;
            this.md = false;
            this.pt = false;
            this.otherCerts = '';
        }
        public String putTogether() {
            String allCerts = '';
            if (this.emt) allCerts = allCerts + 'EMT,';
            if (this.rn) allCerts = allCerts + 'RN,';
            if (this.pa) allCerts = allCerts + 'PA,';
            if (this.md) allCerts = allCerts + 'MD,';
            if (this.pt) allCerts = allCerts + 'Therapist,';
            if (this.otherCerts != null)
                allCerts = allCerts + this.otherCerts;
            allCerts = allCerts.trim();
            allCerts = allCerts.removeEnd(',');
            return allCerts;
        }
    }
}