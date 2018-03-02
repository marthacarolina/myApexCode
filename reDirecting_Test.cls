//This is the test class for reDirecting class
//
//Martha Vance February 2018

@isTest
public class reDirecting_Test {
    public static testMethod void testReDirecting()
    {
        //create the GAU used for the campaign
        TestDataFactory.CreateGAU('Activity Fees');
        //create the fee needed for the campaign to be inserted
        id idFee = TestDataFactory.CreateFee('Hiking', 5.00);
        date aDate = date.today();
        //create 2 Adventure campaigns
        //becuse of the campaign trigger the volunteer campaigns will be created as well
        TestDataFactory.CreateCampaigns('Hiking','Adventure','Hiking',2,0,aDate,aDate,idFee);

        //get the id for the RecordType 'Adventure'
        List<RecordType> recs = [SELECT id, Name, DeveloperName FROM RecordType
                                WHERE sObjectType = 'Campaign' AND
                                DeveloperName = 'Adventure' LIMIT 1];
        
        //retrieve the Adventure campaign id's from the campaigns just created     
        List<Campaign> allCampaigns = [SELECT id, Related_Campaign__c, StartDate
                                       FROM Campaign 
                                       WHERE RecordTypeId = :recs[0].id];
        
        //create a job and a shift for each Volunteer campaign
        TestDataFactory.CreateJobShift(allCampaigns);
        GW_Volunteers__Volunteer_Job__c job = [SELECT id FROM GW_Volunteers__Volunteer_Job__c
                                               WHERE 
                                               GW_Volunteers__Campaign__c = :allCampaigns[0].Related_Campaign__c
                                               LIMIT 1];
        time sTime = time.newInstance(10, 30, 0, 0);
        //create a second shift for one of the volunteer campaigns (the first campaign queried)
        GW_Volunteers__Volunteer_Shift__c shift = new GW_Volunteers__Volunteer_Shift__c(
            GW_Volunteers__Desired_Number_of_Volunteers__c = 2,
            GW_Volunteers__Duration__c = 2,
            GW_Volunteers__Start_Date_Time__c = DateTime.newInstance(aDate, sTime),
            GW_Volunteers__Volunteer_Job__c = job.id);
        insert shift;
        
        
        //get the shift form the job of the second campaign
        List<GW_Volunteers__Volunteer_Shift__c> shiftTwo = [SELECT id FROM GW_Volunteers__Volunteer_Shift__c
                                                      WHERE GW_Volunteers__Volunteer_Job__c != :job.id];
                
        //make a list of two srtrings that will hold the two possible URLs returned by the class
        List<string> expURLs = new List<string>();
        expURLs.add('/'+allCampaigns[0].Related_Campaign__c);
        expURLs.add('/'+shiftTwo[0].id);
        integer x = 0;
        
        //and now for the test
        for (campaign camp : allCampaigns)
        {
            //instantiate tha standard controller with the current campaign
            ApexPages.StandardController std = 
                new ApexPages.StandardController(camp);
            //instantiate the extention class with the standardcontroller
            reDirecting controllerExt = new reDirecting(std);
            //call the function SendMe and store the result in pref
            PageReference pref = controllerExt.SendMe();
            string stringURL = pref.getUrl();
            //check that the expected and actual URL are one and the same
            system.assertEquals(expURLs[x], stringURL);
            x++;
        }
    }
}