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
        //contact0, Iam0, contact0@gmail.com
        //contact1, Iam1, contact1@gmail.com
        for (Integer x=0; x<2; x++){
            Contact cont1 = new Contact(FirstName = 'contact' + x,
                                        LastName = 'Iam'+ x,
                                        Email = 'contact' + x + '@gmail.com');
            conts.add(cont1);
        }
        insert conts;
        TestDataFactory.CreateCampaigns('Campaign', 'Benevon', 
                                        'POE', 3, 0, Date.TODAY()+7, 
                                        Date.TODAY()+7, fee);
        List<Campaign> myCampaigns = [Select id, Name, Type,
                                      RecordTypeId from Campaign
                                      where RecordType.DeveloperName = 'Benevon'
                                      and Type = 'POE'];
        Test.startTest();
        PageReference signUpForm = page.signUpBenevonMember;
        test.setCurrentPage(signUpForm);
        signUpBenevonMembers controller = new signUpBenevonMembers();

        //test without campaigns
        controller.invitee = controller.getInvitee();

        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = 'hola@gmail.com';
        controller.save();
        
        List<SelectOption> theOptions = controller.getBenevonEvents();
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
        controller.invitee.FirstName = 'contact0';
        controller.invitee.LastName = 'Iam0';
        controller.invitee.email = 'contactmailcom';
        controller.save();
        controller.save();
        
        //test a signup with a contact in SF this will be successful
        controller.invitee.FirstName = 'contact0';
        controller.invitee.LastName = 'Iam0';
        controller.invitee.email = 'contact0@gmail.com';
        controller.save();         

        //reset the page because the last SAVE was successful
        test.setCurrentPage(signUpForm);
        controller = new signUpBenevonMembers();
        controller.campaignID = theOptions[0].getValue();
        controller.invitee = controller.getInvitee();
        theOptions = controller.getBenevonEvents();
        controller.campaignID = theOptions[0].getValue();
        controller.invitee = controller.getInvitee();
        
        //test inserting a new contact
        controller.invitee.FirstName = 'Hola';
        controller.invitee.LastName = 'ComoEstas';
        controller.invitee.email = 'hola@gmail.com';
        controller.setInvitee(controller.invitee);
        controller.save();
        test.stopTest();
        integer totContacts = [SELECT count() FROM Contact];
        Integer totCM = [select count() from CampaignMember 
                         WHERE campaignId =: myCampaigns[0].id];
        system.assertEquals(2, totCM);
        system.assertEquals(3, totContacts);
        
    }
}