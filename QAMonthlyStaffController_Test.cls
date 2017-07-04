@isTest
public class QAMonthlyStaffController_Test {

    public static void putInTheTestRecords()
    {
        Fee__c fee = new Fee__c(Activity_Type__c = 'Cycling',
                             Effective_Date__c = date.newInstance(2016,12,31),
                             Amount__c = 10);
        insert fee;
        //Make campaigns
        List<Campaign> campaigns = new List<Campaign>();
        List<RecordType> rt = [select id, Name from RecordType
                               WHERE Name = 'Adventure' OR
                               Name = 'Fundraising' OR
                               Name = 'Volunteer Campaign'
                               Order By Name];
        id cRecType = rt[0].id; //adventure
        String ctype = 'Camping';
        for (Integer x = 0 ; x < 7; x++)
        {
            if (x > 2) cRecType = rt[1].id;
            if (x > 6) cRecType = rt[2].id;
            if (x > 0) ctype = 'Hiking';
            if (x == 3) ctype = 'Outreach';
            if (x == 4) ctype = 'Fundraising';
            Campaign camp = new Campaign(Name = 'Camp ' + x,
                                         StartDate = date.newInstance(2017,1,1 + x),
                                         EndDate = date.newInstance(2017, 1, 1+x),
                                         RecordTypeId = cRecType,
                                         Fee_for_Activity__c = fee.id,
                                         Type = ctype);
            campaigns.add(camp);
        }

        insert campaigns;

        List<Campaign> insertedCamps = [select id, Name,
                                        Related_Campaign__c, RecordTypeId
                                        From Campaign];
        system.debug('insertedCamps.size()' + insertedCamps.size());
        List<id> volIds = new List<id>();
        for (Campaign c : insertedCamps)
        {
            if (c.Related_Campaign__c != null && ! c.Name.contains('Volunteer'))
            {
                volIds.add(c.Related_Campaign__c);
            }
        }

        //insert contacts

        List<Contact> contacts = new List<Contact>();
        Boolean part = True;
        Boolean fof = false;
        Boolean caregiver = false;
        for (Integer x=0; x<25; x++)
        {
            if (x > 15)
            {
                part = false; fof = true;
            }
            if (x > 20)
            {
                fof = false; caregiver = true;
            }
            Contact cont = new Contact(FirstName = 'Test' + x,
                                       LastName = 'Test ' + x,
                                       Participant__c = part,
                                       Relationship_w_Participant__c = fof,
                                       Caregiver__c = caregiver);
            contacts.add(cont);
        }
        insert contacts;
        // Insert Campaign Members
        Integer y = 0;
        List<CampaignMember> members = new List<CampaignMember>();
        for (Campaign c : insertedCamps)
        {
            if (y < 8)
            {
                String stat = 'Attended';
                If (c.RecordTypeId == rt[1].id)
                    stat = 'Staff';
                else if (c.RecordTypeId == rt[2].id)
                    stat = 'Completed';
                for (Integer x=0; x < 3; x++)
                {
                    CampaignMember cm = new CampaignMember(ContactId = contacts[x + (3*y)].id,
                                                           Status = stat,
                                                           CampaignId = c.id);
                    members.add(cm);
                }
                y++;
            }
        }
        insert members;
    }

    @isTest
    public static void QAmStaffTest(){
        //insert records for test
        putInTheTestRecords();
        //instantiate page
        PageReference QAStaffReport = page.QAMonthlyStaffVF;
        test.setCurrentPage(QAStaffReport);
        ApexPages.currentPage().getParameters().put('m', '1');
        ApexPages.currentPage().getParameters().put('y', '2017');
        QAMonthlyStaffController controller = new QAMonthlyStaffController();
        controller.printPDFReport();
        system.assertEquals('2017-01-01', controller.beginRange);
        system.assertEquals(4,controller.allCampaignsByType.size());
    }

}
