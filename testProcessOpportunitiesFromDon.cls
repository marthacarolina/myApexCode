//Test for processOpportunitiesFromDonations class
//
//Martha Vance    April 2018

@isTest
public class testProcessOpportunitiesFromDon {
    private static testMethod void testingImport(){
        List<Contact> conts = new List<Contact>();
        List<AZGives_Donor__c> donors = new List<AZGives_Donor__c>();
        //make contacts
        for (Integer i = 0; i < 30; i++){
            Contact c = new Contact(LastName = 'Ln'+i,
                                    FirstName = 'Fn'+i,
                                    Email = 'person'+i+'@gmail.com');
            conts.add(c);            
        }
        insert conts;
        //make donors
        for (Integer i = 0; i < 15; i++){
            Boolean inv = false;
            If (i>9) inv = true;
            AZGives_Donor__c d = 
                new AZGives_Donor__c(Amount__c = i * 10, 
                                     Transaction_Date_Time__c = datetime.newInstance(2018, 4, 3),
                                     Anonymous__c = 'No', 
                                     FirstName__c = 'Fn' + i, 
                                     LastName__c = 'Ln' + i, 
                                     Email__c = 'person'+i+'@gmail.com', 
                                     Phone_Number__c = i+'5'+i+'5',
                                     Address_1__c = i + ' street', 
                                     Address_2__c = '', 
                                     City__c = 'Phoenix', 
                                     State__c= 'AZ', 
                                     Country__c = '',
                                     Zip_Code__c = '85300', 
                                     Cover_Fees_Txt__c = 'Yes', 
                                     In_Memory__c = 'Jesus', 
                                     Comments__c = 'Have a nice Day', 
                                     Get_Involved__c = inv,
                                     Campaign_Name__c = '');
            donors.add(d);
        }
        // make one donor with a non-matching first name
        donors[10].FirstName__c = 'changed';
        // make one donor with a non-matcing last name
        donors[11].LastName__c = 'changed';
        // make 2 donors with non-matching email addresses
        donors[5].Email__c = 'changed1@gmail.com';
        donors[2].Email__c = 'changed2@gmail.com';
        donors[1].Anonymous__c = 'Yes - Partially';
        donors[8].Anonymous__c = 'Yes - Fully';
        //make the AZGives Campaign
        insert donors;
        system.debug('finished inserting donors for test ' + donors.size());
        //insert GAU
        TestDataFactory.CreateGAU('General Donations');
        TestDataFactory.CreateGAU('Activity Fees');
        TestDataFactory.CreateGAU('George Bohnert Scholarship Fund');
        id fundRecType =
            Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Fundraising').getRecordTypeId();

        Account acc = new Account(Name = 'Anonymous');
        insert acc;
        
        test.startTest();
        PageReference wizard = page.AZGives_DonorVF;
        test.setCurrentPage(wizard);
        
        processOpportunitiesFromDonations controller = new processOpportunitiesFromDonations();
        PageReference pg = controller.processDonors();
        
        //system.assertEquals(30, controller.conts.size());
        //get the records where the emails didn't match any contacts
        Integer notProcessed = [SELECT count() FROM AZGives_Donor__c 
                                WHERE Not_Found__c = True];
        system.assertEquals(0, notProcessed);
        //get the records where the emails were matched but the names didn't match
        Integer processed = [SELECT count() FROM AZGives_Donor__c
                             WHERE Processed__c = true];
        Date transDate = date.newInstance(2018, 4, 3);
        Integer oppys = [SELECT count() FROM Opportunity
                         WHERE CloseDate = :transDate];
        system.assertEquals(13, oppys);
        Campaign camp = [select id FROM Campaign
                         where name like 'AZGives%' limit 1];
        Integer newtasks = [SELECT count() FROM Task
                            WHERE WhatId = :camp.id];
        system.assertEquals(3, newtasks);
        test.stopTest();
    }
}