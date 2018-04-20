@isTest
public class test_CtrlrAdvCampWiz {
    public static testMethod void testTheWiz () {
        //create GAU for test
        TestDataFactory.CreateGAU ('Activity Fees');
        String theName;
        //Instantiate the wizard VFPage
        PageReference wizard = page.AdvCampaignWizard;        
        test.setCurrentPage(wizard);
        CtrlrAdvCampWiz controller = new CtrlrAdvCampWiz();
        theName = 'the campaign';
        
        //call the get methods to initialize the controller variables 
        Campaign initial = controller.getCampaign();        
        GW_Volunteers__Volunteer_Job__c oneJob = controller.getTheJob();
        GW_Volunteers__Volunteer_Shift__c oneShift = controller.getTheShift(); 
        //test the cancel() action
        PageReference afterCancel = controller.cancel();
        system.assertEquals('/701/o', afterCancel.getUrl());
        //try saving with null values;
        PageReference aftersave1 = controller.save();
        List<Campaign> insCamp1 = [SELECT id, Related_Campaign__c FROM Campaign
                                   WHERE Name = :theName];
        system.assertEquals(0, insCamp1.size());
        
        
        controller.campaign.description = 'this is the description';
        controller.campaign.startdate = date.today();
        controller.campaign.endDate = date.today();
        controller.campaign.isActive = true;
        controller.campaign.type = 'Cycling';
        controller.campaign.status = 'Planned';  
        controller.theJob.name = 'cycling support '+ date.today();
        controller.theShift.GW_Volunteers__Start_Date_Time__c = 
            DateTime.newInstance(2017, 04, 04, 3, 3, 3);
        controller.theShift.GW_Volunteers__Duration__c = 3;
        controller.theShift.GW_Volunteers__Desired_Number_of_Volunteers__c = 4;
        controller.theJob.GW_Volunteers__Location_Street__c = 'the location';
        controller.theJob.GW_Volunteers__Location_City__c = 'Phoenix';
        controller.theJob.GW_Volunteers__Location__c = 'AZ';
        controller.theJob.GW_Volunteers__Location_Zip_Postal_Code__c = '85308';
        controller.theJob.GW_Volunteers__Description__c =
            'the description for volunteers';
        // the campaign name is empty
        aftersave1 = controller.save();
        insCamp1 = [SELECT id, Related_Campaign__c FROM Campaign
                    WHERE Name = :theName]; 
        system.assertEquals(0, insCamp1.size());
        
        controller.campaign.name = theName;
        
        //the start date is null
        controller.campaign.startdate = null;
        insCamp1 = [SELECT id, Related_Campaign__c FROM Campaign
                    WHERE Name = :theName]; 
        system.assertEquals(0, insCamp1.size());
        
        Fee__c fee = new Fee__c();
        fee.Amount__c = 15.00;
        fee.Effective_Date__c = date.today() - 10;
        fee.Activity_Type__c = 'Cycling';
        insert fee;
        controller.campaign.startdate = date.today();
        
        insCamp1 = [SELECT id, Related_Campaign__c FROM Campaign
                    WHERE Name = :theName]; 
        system.assertEquals(0, insCamp1.size());
        controller.campaign.Fee_for_Activity__c = fee.id;
        
        PageReference aftersave = controller.save();
        List<Campaign> insCamp = [SELECT id, Related_Campaign__c FROM Campaign
                                  WHERE Name = :theName];
        system.assertEquals(1, insCamp.size());
        Campaign volCamp = [SELECT id, name FROM Campaign
                            WHERE id = :insCamp[0].Related_Campaign__c limit 1];
        system.assertEquals(true, volCamp.name.contains('Volunteer'));
        List<GW_Volunteers__Volunteer_Job__c> aJob = 
            [SELECT id FROM GW_Volunteers__Volunteer_Job__c 
             WHERE GW_Volunteers__Campaign__c = :volCamp.id];
        system.assertEquals(1, aJob.size());
        List<GW_Volunteers__Volunteer_Shift__c> shift = 
            [SELECT id FROM GW_Volunteers__Volunteer_Shift__c
             WHERE GW_Volunteers__Volunteer_Job__c = :aJob[0].id];
        system.assertEquals(1, shift.size());
        
        //Add values to some fields, but leave some blank to test error msg
        //Add values to some fields, but leave some blank to test error msg
        //Add values to some fields, but leave some blank to test error msg
        //Add all necessary values to add a campaign
        //add another campaign
        //check that the campaign, vol campaign, job and shift are added        
    }    
    
}