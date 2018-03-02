public class printCampaignRosters {
  // this class is an extension of the Visualforce page VFprintRoster
  // it calls the report for campaing roster setting the filter to
  // the name of the campaign with -contains- so that it will catch
  // the volunteer campaign as well.
  // Martha Vance 4/24/2017
  // report: Campaigns_Roster
  
    private ApexPages.StandardController std;
    private Campaign campaign;
    private Campaign volCamp;
    
    public printCampaignRosters(ApexPages.StandardController stdCtrl) {
        std = stdCtrl;
        this.campaign = (Campaign)std.getRecord();
    }
    
    public PageReference autoRun() {
        String theId = std.getId();
        campaign = [SELECT id, Related_Campaign__c FROM Campaign WHERE id = :theId limit 1];
        if (campaign.Related_Campaign__c != null) {
            volCamp = [SELECT id FROM Campaign WHERE id = :campaign.Related_Campaign__c];            
        } 
        else
        {
            volCamp = new Campaign();
          volCamp.id = campaign.id;
        }
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report where
                                    DeveloperName = 'Adventure_and_Volunteer_Roster'];
        String reportId = (String)reportList.get(0).get('Id');
        String campId = campaign.id;
        String volCId = volCamp.id;
        
        String reportURL = '/' + reportId + '?pv0=' + campId.substring(0,15) + '&pv1=' + volCId.substring(0,15);
     
        return new PageReference(reportURL);
    }
}