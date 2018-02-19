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
        Campaign camp = [SELECT id, RecordTypeId FROM Campaign
                        WHERE RecordTypeId = :recType.id AND
                         StartDate > :cSDate AND
                         EndDate < :cEDate limit 1];
        PageReference campaignSummary = page.printCampaignSummaryPDF;
        test.setCurrentPage(campaignSummary);
        ApexPages.currentPage().getParameters().put('id', camp.Id);
        printCampaignSummary controller = new printCampaignSummary();
        controller.autoRun();
        
    }

}