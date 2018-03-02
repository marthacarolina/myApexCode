//Extension to the Visualforce page: directMeToShift
//
//This class sends the user to the volunteer shift of the Adventure campaign they are viewing
//or to the Volunteer campaign if there is more than one shift
//
//Martha Vance February 2018

public class reDirecting {
    private id campId;

    public reDirecting(ApexPages.StandardController stdController){
        //get the campaign Id from the Standard Controller
        //because the method SendMe executes in the Page tag the record hasn't been retrieved yet
        //but we have the id.
        this.campId = stdController.getRecord().id;
    }

    public pageReference SendMe(){
        string theProblem = '';
        //Retrieve the id for the Volunteer campaign
        Campaign camp = [Select Related_Campaign__c from Campaign
                         WHERE id = :campId];
        //Retrieve the job
        List<GW_Volunteers__Volunteer_Job__c> jobs = [select id FROM GW_Volunteers__Volunteer_Job__c
                                                      WHERE GW_Volunteers__Campaign__c = :camp.Related_Campaign__c];
        id jobId = jobs[0].id;
        //Retrieve the shift id
        LIST<GW_Volunteers__Volunteer_Shift__c> shifts = [SELECT id from GW_Volunteers__Volunteer_Shift__c
                                        where GW_Volunteers__Volunteer_Job__c = :jobId];
        string stringURL = '';
        if (shifts.size() > 0 && shifts.size() == 1)
        {
            //use the shift id to call the Shift record detail page where the user can
            //access the Mass Edit Volunteer function throught the button.
            stringURL = '/'+shifts[0].id;
        }
        else 
        {
            //if there is no shifts or there is more than one shift go to the volunteer campaign
            if (shifts.size()== 0) theProblem = 'No shifts in Volunteer Campaign';
            else theProblem = 'there are more than one shift in the Volunteer Campaign';
            stringURL = '/' + camp.Related_Campaign__c;
        }        
        return new PageReference(stringURL);
    }

}