//this is the test class for SelectParticipants
//Martha 2017

@isTest
public class testSelectParticipants {

    public static testMethod void ContactSearchSelectSave () {
        List<Contact> conts = new List<Contact>();  
        //insert contacts that will become participants in the campaign
        for (Integer x=0; x<4; x++){
            Contact cont1 = new Contact(FirstName = 'contact ' + x,
                                        LastName = 'Iam '+ x);
            conts.add(cont1);
        }
        insert conts;
        //insert GAU's & Fee
        TestDataFactory.CreateGAU('Activity Fees');
        id fee = TestDataFactory.CreateFee('Cycling', 10); 
        TestDataFactory.CreateCampaigns('Campaign', 'Adventure', 
                                        'Cycling', 1, 0, Date.TODAY(), 
                                        Date.TODAY(), fee);
        List<Campaign> myCampaigns = [Select id, Name, Related_Campaign__c,
                                      RecordTypeId from Campaign
                                     where RecordType.DeveloperName = 'Adventure'];
        List<String> statai = new List<String> {'Signed Up','Attended','Attended'};
        //Create campaign members for the campaign
        TestDataFactory.CreateCampaignMembers(myCampaigns, conts, 3, statai);        
                
        //Now for the test
        Test.startTest();
        ApexPages.StandardController std = 
            new ApexPages.StandardController(myCampaigns[0]);
        selectParticipants sce = new selectParticipants(std);
        // get current campaign members 
        System.assertEquals(3, sce.participants.size()); 
        // get all possible statuses
        sce.getPossibleStatuses();
        
        //try searching with an empty string
        sce.nameQuery = '';
        sce.executeSearch();
        
        
        //search for a member that doesn't exist
        sce.nameQuery = 'Testing';
        sce.executeSearch();
        
        // Look for a contact
        sce.nameQuery = 'Iam';
        sce.executeSearch();
        
        
        Test.stopTest();
        
        // getContacts that match search returns the right amount of contacts
        System.assertEquals(4, sce.wrapContactList.size());
        // select one of the contast to add to the Campaign
        sce.wrapContactList[2].selected = true;
        sce.wrapContactList[3].selected = true;
        sce.processSelected();
        
        //check that the contact was added to the participant's list
        System.assertEquals(4, sce.participants.size()); 
        //Now check that the message is displayed when trying to record a repeated contact
        sce.wrapContactList[2].selected = true;
        sce.processSelected();
        System.assertEquals(true, sce.mess.contains('is already a member of the adventure.'));
        //now save the new participant and check that it was indeed saved in the database
        sce.saveNewParticipants();    
    }
}