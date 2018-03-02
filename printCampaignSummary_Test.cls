// Test class for printCampaignSummary class - this is the controller for the
// visualforce page printCampaignSummaryPDF which prints a summary of the adventure campaign
// 
// Martha Vance
// 2/19/2018

@isTest
public class printCampaignSummary_Test {

    @isTest(SeeAllData='true')
    public static void testReportWithData()
    {
        //set up variables to limit campaingns retrieved for test
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
        //run the PDF visualforce page with the 5 (or less) campaigns retrieved
        for (Campaign c : camps)
        {
            //load the visualforce page in the test environment
            PageReference campaignSummary = page.printCampaignSummaryPDF;
            test.setCurrentPage(campaignSummary);
            //add the parameter to the visualforce page (the campaign id)
            ApexPages.currentPage().getParameters().put('id', c.Id);
            printCampaignSummary controller = new printCampaignSummary();
            controller.autoRun();
        }
        
    }

}