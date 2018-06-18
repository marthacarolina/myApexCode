//test for class VolRegistrationController the controller works with the VF page
//VolApplication
//
//Martha Vance

@isTest
public class VolRegistrationController_Test {

    @isTest
    public static void VolRegTest() {
        //create a contact to test the registration with an existing contact
        List<Contact> contacts = TestDataFactory.CreateContacts(1, 1);
        
        //instantiate VF page
        PageReference volApp = page.VolApplication;
        Test.setCurrentPage(volApp);
        //add the paramater (contact id) to the page
        ApexPages.currentPage().getParameters().put('contID', contacts[0].id);
        //instantiate the controller
        VolRegistrationController controller = new VolRegistrationController();
        boolean initiate = controller.getIni();
        system.assertEquals(true, initiate);
        //give values to the variables
        Contact cont = controller.volunteer;
        cont.Phone = '4445556666';
        cont.Birthdate = date.newInstance(1980, 4, 2);
        cont.Allergies__c = 'dairy, penicillin';
        cont.CPR_Certificate_Expiration_Date__c = date.today() + 7;
        cont.First_Aid_Certification_Expiration_Date__c = date.today() + 7;
        cont.Fingerprint_Clearance_Expiration_Date__c = date.today() - 15;
        controller.volunteer = cont;
        //submit the form
        controller.save();
        system.assertEquals(true, controller.volunteer.CPR_Certificate__c);
        system.assertEquals(true, controller.volunteer.First_Aid_Certification__c);
        system.assertEquals(false, controller.volunteer.Fingerprint_Clearance__c);
        
        //now test with a new contact - no parameter in URL
        PageReference noID = page.VolApplication;
        Test.setCurrentPage(noID);
        initiate = controller.getIni();        
        cont = new Contact();
        cont.FirstName = 'Monica';
        cont.LastName = 'Lewinski';
        //try the insert with an invalid email address
        cont.Email = 'monLewgmail';
        cont.Phone = '4445556666';
        cont.Birthdate = date.newInstance(1980, 4, 2);
        cont.Allergies__c = 'Bees';
        cont.CPR_Certificate_Expiration_Date__c = date.today() - 7;
        cont.First_Aid_Certification_Expiration_Date__c = date.today() - 7;
        cont.Fingerprint_Clearance_Expiration_Date__c = date.today() +  715;
        controller.volunteer = cont;
        PageReference retPage = controller.save();
        system.assertEquals(null, retPage);
        controller.volunteer.email = 'monLew@gmail.com';
        retPage = controller.save();
        Integer totRecs = [Select count() from Contact];
        system.assertEquals(2, totRecs);
        //test without name, lastname nor email
        controller.volunteer = new Contact();
        controller.volunteer.FirstName = '';
        controller.volunteer.LastName = '';
        controller.volunteer.Email = '';
        controller.volunteer.Allergies__c = 'n/a';
        controller.volunteer.Phone = '8883332222';
        retPage = controller.save();
        system.assertEquals(null, retPage);

       
        //test with existing contact no id in URL parameter
        
        
        
        
    }
}