// This is the test class for signUpBenevonMembers
// 
// Martha Vance -- April 2018

@isTest
public class signUpBenevonMembers_Test {
    public static testMethod void testSignUpBenevon () {
        TestDataFactory.CreateGAU('General Donation');
        id fee = TestDataFactory.CreateFee('Cycling', 10);
        List<Contact> conts = new List<Contact>();  
        //insert contacts that will become participants in the campaign
        //the contacts will be
        //Contactx, Testx, ContactTestx@testing.com
        TestDataFactory.CreateContacts(10, 0);
        TestDataFactory.CreateCampaigns('Volunteer Volunteer Orientation', 'Volunteers_Campaign',
                                       'Orientation', 4, 0, Date.TODAY()+7, Date.TODAY()+7, fee);
        TestDataFactory.CreateCampaigns('Campaign', 'Benevon', 
                                        'POE', 4, 0, Date.TODAY()+7, 
                                        Date.TODAY()+7, fee);
        List<Campaign> myCampaigns = [Select id, Name, Type, 
                                      Public_Event__c, RecordTypeId from Campaign];
        //set all campaigns except for one as public events
        for (Integer x = 0; x< myCampaigns.size(); x++){
            if (x != 3)
                myCampaigns[x].Public_Event__c = true;
            else
                myCampaigns[x].Public_Event__c = false;
        }         
        Campaign privateCamp = myCampaigns[3];
        update myCampaigns;        
        Test.startTest();
        //test with the private POE
        PageReference privateEvent = page.signUpPrivatePOEVF;
        privateEvent.getParameters().put('id',privateCamp.id);
        test.setCurrentPage(privateEvent);
        signUpBenevonMembers controller = new signUpBenevonMembers();
        boolean startIt = controller.getBegin();
        controller.invitee = controller.getInvitee();
        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = 'hola@gmail.com';
        controller.save();        
        //set the page to the signUpMember page
        PageReference signUpForm = page.signUpMember;
        test.setCurrentPage(signUpForm);
        controller = new signUpBenevonMembers();
        startIt = controller.getBegin();

        //test without campaigns
        controller.invitee = controller.getInvitee();

        controller.invitee.FirstName = 'Nombre';
        controller.invitee.LastName = 'Apellido';
        controller.invitee.email = 'soyYo@gmail.com';
        controller.save();
        
        List<SelectOption> theOptions = controller.getCampaignEvents();
        controller.campaignID = theOptions[0].getValue();
        controller.invitee = controller.getInvitee();
        //test a signup without a name
        controller.invitee.FirstName = '';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = 'hola@gmail.com';
        controller.save();
        
        //test a signup without a last name
        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = '';
        controller.invitee.email = 'hola@gmail.com';
        controller.save();

        //test a signup without an email
        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = '';
        controller.save(); 
        
        //test a signup with an invalid email address
        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = 'holaItisME';
        controller.save();
        
        //test a signup of a current contact with a different incorrect email address
        controller.invitee.FirstName = 'Contact0';
        controller.invitee.LastName = 'Test0';
        controller.invitee.email = 'contactmailcom';
        controller.save();
        controller.save();
        
        //test a signup with a contact in SF this will be successful
        controller.invitee.FirstName = 'Contact0';
        controller.invitee.LastName = 'Test0';
        controller.invitee.email = 'ContactTest0@testing.com';
        controller.save();         

        //reset the page because the last SAVE was successful
        test.setCurrentPage(signUpForm);
        
        controller = new signUpBenevonMembers();
        startIt = controller.getBegin();
        controller.campaignID = theOptions[0].getValue();
        controller.invitee = controller.getInvitee();
        theOptions = controller.getCampaignEvents();
        controller.campaignID = theOptions[0].getValue();
        controller.invitee = controller.getInvitee();
        
        //test inserting a new contact
        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = 'hola@gmail.com';
        controller.setInvitee(controller.invitee);
        controller.save();
        integer totContacts = [SELECT count() FROM Contact];
        Integer totCM = [select count() from CampaignMember 
                         WHERE campaignId =: myCampaigns[0].id];
        //system.assertEquals(2, totCM);
        //system.assertEquals(3, totContacts);
        test.stopTest();        
        
    }
}