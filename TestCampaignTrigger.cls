@isTest
private class TestCampaignTrigger {
    //This test is for the NewVolCampaign trigger
    @isTest static void TestInsertVolCampaignAlloc() {
        //find the id for the id for the RecordType 'Volunteers_Campaign' in object Campaign
        // create records to test
        // bulk validation
        Map<String, id> recTypeIds = new Map<String, id>();
        List<RecordType> recs = [select id, Name, DeveloperName from RecordType
                                where sObjectType = 'Campaign'];
        for (RecordType rt : recs)
            recTypeIds.put(rt.DeveloperName, rt.id);
        Fee__c fee = new Fee__c (Activity_Type__c = 'Cycling',
                                Amount__c = 10);
        insert fee;

        npsp__General_Accounting_Unit__c genAcUnit =
            new npsp__General_Accounting_Unit__c (Name = 'Activity Fees',
                                                 npsp__Active__c = true);
        insert genAcUnit;
                AAKCS__Campaign_Status_Default__c statDef =
            new AAKCS__Campaign_Status_Default__c (Name = 'Cycling',
                                                  AAKCS__Action__c = 'Replace All',
                                                  AAKCS__Active__c = true);
        insert statDef;

        List<String> defNames = new List<String>{'Attended', 'Signed Up'};
        List<AAKCS__Campaign_Status_Default_Value__c> sdValues =
            new List<AAKCS__Campaign_Status_Default_Value__c> ();
        for (integer x = 0; x < 2; x++)
        {
            AAKCS__Campaign_Status_Default_Value__c sdValue =
            new AAKCS__Campaign_Status_Default_Value__c(Name = defNames[x],
                                                        AAKCS__Default__c = false,
                                                        AAKCS__Responded__c = false,
                                                        AAKCS__Campaign_Status_Default__c = statDef.id);
            sdValues.add(sdValue);
        }
        insert sdValues;

        List<Campaign> myCampaigns = new List<Campaign>();
        for (Integer i=0; i<10; i++){
            Campaign aCampaign = new Campaign(RecordTypeId = recTypeIds.get('Adventure'),
                                             Name = 'Campaign'+ i,
                                             IsActive = True,
                                             Type = 'Cycling',
                                             Fee_for_Activity__c = fee.id,
                                             Status = 'Planned',
                                             EndDate = Date.TODAY(),
                                             StartDate = Date.TODAY());
            myCampaigns.add(aCampaign);
        }
        myCampaigns[2].Name = 'MailChimp';
        //change some of the record types to be fundraising record types
        myCampaigns[3].RecordTypeId = recTypeIds.get('Fundraising');
        myCampaigns[5].RecordTypeId = recTypeIds.get('Fundraising');
        myCampaigns[8].RecordTypeId = recTypeIds.get('Fundraising');
        //this next record type is volunteer record type
        myCampaigns[1].RecordTypeId = recTypeIds.get('Volunteers_Campaign');
        myCampaigns[1].EndDate = myCampaigns[1].EndDate.addDays(2);

        //Now begin the test inserting the list of campaign records
        Database.SaveResult[] srList = Database.insert(myCampaigns, false);

        List<Campaign> volrecsinserted = [SELECT id FROM Campaign WHERE Type = 'Cycling' and
                          EndDate = Today and
                           RecordTypeId = :recTypeIds.get('Volunteers_Campaign')];
        System.assertEquals(5, volrecsinserted.size());

        List<Contact> conts = new List<Contact>();
        for (Integer x=0; x<5; x++){
            Contact cont1 = new Contact(FirstName = 'contact ' + x,
                                        LastName = 'Iam '+ x);
            conts.add(cont1);
        }
        insert conts;
        List<CampaignMember> theCMs = new List<CampaignMember>();
        List<id> campIds = new List<id>{myCampaigns[0].id, myCampaigns[4].id, myCampaigns[6].id};
        for(integer y=0; y < 3; y++)
        {
            for (Integer x=0; x<3; x++)
            {
                String stat = 'Signed Up';
                if (y > 0 && x > 0) stat = 'Attended';
                CampaignMember aCamMember = new CampaignMember(CampaignId = campIds[y],
                                                               ContactId = conts[x].id,
                                                               Status = stat);
                theCMs.add(aCamMember);
            }
        }
        insert theCMs;
        myCampaigns[9].Related_Campaign__c = null;
        update myCampaigns[9];

        try
        {
            delete myCampaigns;
            System.assert(false);
        }
        catch (DMLException e)
        {
            // Check that the trigger interrupts the deletion
            Boolean statusException = e.getMessage().contains('You must change the Member status to anything but Attended before deleting a Campaign.') ? true : false;
            Boolean volunteerException =  e.getMessage().contains('Before deleting the campaign you must delete the volunteer campaign associated with it.') ? true : false;
            Boolean expectedExceptionThrown = statusException || volunteerException;
            System.AssertEquals(expectedExceptionThrown, true);
            //system.assertEquals('Before deleting the campaign you must delete the volunteer campaign associated with it.', e.getMessage());
        }
    }
}
