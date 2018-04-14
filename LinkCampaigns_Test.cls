//This tests the class LinkCampaigns
//
//Martha Vance, April 2018

@isTest
public class LinkCampaigns_Test {
    public static testMethod void LCtest(){
        TestDataFactory.CreateGAU ('Activity Fees');
        id feeId = TestDataFactory.CreateFee('Hiking', 5);
        date sDate = date.today();
        TestDataFactory.CreateCampaigns('camp', 'Adventure', 'Hiking', 1, 1, sDate, sDate, feeId);
        TestDataFactory.CreateCampaigns('camp', 'Fundraising', 'Email', 1, 2, sDate, sDate, feeId);
        TestDataFactory.CreateCampaigns('camp', 'Volunteers_Campaign', 'Hiking', 1, 3, sDate, sDate, feeId);
        Map<string, Campaign> mapCamps = new Map<string, Campaign>();
        List<Campaign> campaigns = [Select id, Name, StartDate, EndDate, 
                                    RecordTypeId, Related_Campaign__c 
                                    FROM Campaign ORDER BY Name];
        for(Campaign c : campaigns)
        {
            mapCamps.put(c.Name, c);
        }
        // test with a campaign that has a volunteer campaign linked
        ApexPages.StandardController stdCtrl = 
            new ApexPages.StandardController(mapCamps.get('camp1'));
        LinkCampaigns controller = new LinkCampaigns(stdCtrl);
        PageReference pg = controller.goBack();
        system.assertEquals('/'+mapCamps.get('camp1').id, pg.getUrl());
        
        // test with a campaign that is a volunteer campaign
        stdCtrl = new ApexPages.StandardController(mapCamps.get('camp3'));
        controller = new LinkCampaigns(stdCtrl);
        pg = controller.LinkIt();
        system.assertEquals(null, pg);
        
        // test with a fundraising campaign without Related Cmpaign
        stdCtrl = new ApexPages.StandardController(mapCamps.get('camp2'));
        controller = new LinkCampaigns(stdCtrl);
        
        List<SelectOption> soList = controller.getVolCampaigns();
        controller.VolCampId = (mapCamps.get('camp3').id);
        pg = controller.LinkIt();
        system.assertEquals('/'+ mapCamps.get('camp2').id, pg.getUrl());                 
    }
}