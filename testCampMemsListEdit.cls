@isTest
public class testCampMemsListEdit {
    public static testMethod void testSearchSelectSave () {
        
        List<Contact> conts = new List<Contact>();  
        //insert contacts that will become participants in the campaign
        for (Integer x=0; x<5; x++){
            Contact cont1 = new Contact(FirstName = 'contact ' + x,
                                        LastName = 'Iam '+ x);
            conts.add(cont1);
        }
        insert conts;
        TestDataFactory.CreateGAU ('Activity Fees');
        id fee = TestDataFactory.CreateFee('Cycling', 10);
        TestDataFactory.CreateCMStatusDefault('Cycling');
        id advRecType = 
               Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Adventure').getRecordTypeId();

        // add two new Adventure campaigns, one will have no CM
        List<Campaign> camp = new List<Campaign>();
        for (Integer x = 0; x<2 ; x++){
            Campaign c = new Campaign(RecordTypeId = advRecType,
                                      Name = 'Campaign'+ x,
                                      IsActive = True,
                                      Type = 'Cycling',
                                      Status = 'Planned',
                                      Fee_for_Activity__c = fee,
                                      EndDate = Date.TODAY(),
                                      StartDate = Date.TODAY());
            camp.add(c);
        }
        
        Database.SaveResult[] srList = Database.insert(camp, false);
        
        //The following code makes and inserts Campaign Member records for the
        //campaign that was just inserted.
        LIst<id> theId = new List<id>();
        List<CampaignMember> theCMs = new List<CampaignMember>();
        for (Database.SaveResult sr : srList)
        {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was inserted
                ID CampId = sr.getId();
                theId.add(CampId);
            }  
            else 
            {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors())
                {
                    System.debug('The following error has occurred.');                   
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Campaign fields that affected this error: ' 
                                 + err.getFields());
                }
            }
        }
        //only insert campaign members for the first campaign created
        for (Integer x = 0; x < 5; x++){
            CampaignMember aCamMember = new CampaignMember(CampaignId = theId[0],
                                                           ContactId = conts[x].id,
                                                           Status = 'Signed Up');
            theCMs.add(aCamMember);
            system.debug('the campaign member is: '+ 
                         aCamMember.Name + ' id is ' + aCamMember.ContactId + 
                         ' with status '+ aCamMember.Status);
        }
        system.debug('the size for theCMs = '+ theCMs.size());
        
        insert theCMs;
        
        //Now for the test
        //first test with no campaign members
        ApexPages.StandardController noCM_std = 
            new ApexPages.StandardController(camp[1]);
        CampMemsListEdit noCM_sce = new CampMemsListEdit(noCM_std); 
        System.assertEquals(true, noCM_sce.message.contains('There are no participants in this campaign.'));
        
        ApexPages.StandardController std = new ApexPages.StandardController(camp[0]);
        CampMemsListEdit sce = new CampMemsListEdit(std);
        // get current campaign members 
        System.assertEquals(5, sce.wrapParticipantList.size());  
        
        // Change status, then save
        sce.selectedStatus = 'Attended';
        
        // select two of the participants to change their status
        sce.wrapParticipantList[0].selected = true;
        sce.wrapParticipantList[2].selected = true;
        
        PageReference saving = sce.saveChanges();
        Integer y = 0;
        for (Integer x = 0; x<5; x++){
            system.debug('participant '+x+' status = '+ sce.participants[x].status);
            if (sce.participants[x].Status == 'Attended'){y++;}
        }
        List<CampaignMember> AttendedList = [Select id from CampaignMember
                                             where CampaignId = :theId and Status = 'Attended'];
        system.debug('attendedlist.size = ' + AttendedList.size());	        
        //check that there are two participants with status Attended
        System.assertEquals(2, y); 
        PageReference chkDone = sce.done();
        System.assertEquals('/'+sce.camp.Id, chkDone.getUrl());                
    }
}