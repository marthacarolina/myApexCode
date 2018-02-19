@isTest
public class printCampaignSummary_Test {

    @isTest(SeeAllData='true')
    public static void testReportWithData()
    {
        date cSDate = date.newInstance(2018, 1, 1);
        date cEDate = date.newInstance(2018, 1, 31);
        RecordType recType = [select id from RecordType
                      where sObjectType = 'Campaign' AND DeveloperName = 'Adventure'
                      limit 1];
        List<Campaign> camps = [SELECT id, RecordTypeId FROM Campaign
                        WHERE RecordTypeId = :recType.id AND
                         (StartDate > :cSDate AND
                         EndDate < :cEDate) AND 
                         Related_Campaign__c != null
                         ORDER BY StartDate LIMIT 5];
        for (Campaign c : camps)
        {
            PageReference campaignSummary = page.printCampaignSummaryPDF;
            test.setCurrentPage(campaignSummary);
            ApexPages.currentPage().getParameters().put('id', c.Id);
            printCampaignSummary controller = new printCampaignSummary();
            controller.autoRun();
        }
        
    }

}