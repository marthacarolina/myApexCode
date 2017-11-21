public class CtrlrAdvCampWiz {
    
    public Boolean noVolCamp {get;set;}    
    public String message {get;set;}
    Campaign campaign;
    GW_Volunteers__Volunteer_Job__c theJob;
    GW_Volunteers__Volunteer_Shift__c theShift;
    Boolean itsBlankC;
    Boolean itsBlankJ;
    Boolean itsBlankS;
    String mistake;
    public Id advTypeId;
    
    public CtrlrAdvCampWiz()
    {
        advTypeId = 
            Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Adventure').getRecordTypeId();
    }
    
    public Campaign getCampaign()
    {
        if (campaign == null) campaign = new Campaign();
        campaign.IsActive = true;
        campaign.RecordTypeId = advTypeId;
            
        return campaign;
    }
    
    public GW_Volunteers__Volunteer_Job__c getTheJob ()
    {
        if (theJob == null) 
        {
            theJob = new GW_Volunteers__Volunteer_Job__c();
            theJob.GW_Volunteers__Location__c = 'AZ';
        }
        return theJob;
    }
    
    public GW_Volunteers__Volunteer_Shift__c getTheShift ()
    {
        if (theShift == null) theShift = new GW_Volunteers__Volunteer_Shift__c ();
        return theShift;
    }
    
    // This method cancels the wizard, and returns the user to the 
    // Campaign tab
    public PageReference cancel() {
        PageReference campaignPage = new PageReference('/701/o');
        campaignPage.setRedirect(true);
        return campaignPage; 
    }
        
    public PageReference save(){
        String stndcamp = '';
        PageReference campPage;
        //check if there are any required fields for the campaign
        //left blank
        itsBlankC = true;
        mistake = '';
        If (campaign.Name == null)
            mistake = 'Campaign Name';
        Else 
            if (campaign.StartDate == null)
            mistake = 'Start Date';
        Else 
            if (campaign.EndDate == null)
            mistake = 'End Date';
        else
            if (campaign.Fee_for_Activity__c == null)
            mistake = 'Fee for Activity';
        else itsBlankC = false;
        system.debug('itsBlankC = '+ itsBlankC);
        //check if there are any required fields for the Job 
        //left blank
        itsBlankJ = true;
        if (theJob.Name == null)
            mistake = 'Job Name';
        else
            itsBlankJ = false;
        //check that the shift has a start time and that
        //there is a number of desired volunteers
        itsBlankS = true;
        if (theShift.GW_Volunteers__Start_Date_Time__c == null)
            mistake = 'Shift start date & time';
        else
            if (theShift.GW_Volunteers__Duration__c == null)
            mistake = 'Shift duration';
        else
            if (theShift.GW_Volunteers__Desired_Number_of_Volunteers__c == null)
            mistake = 'desired number of volunteers';
        else
            itsBlankS = false;
        if (itsBlankC || itsBlankJ || itsBlankS)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'The '+ mistake + ' must not be blank.'));
            return null;
        }
        else
        {
            campaign.RecordTypeId = advTypeId;
            try {
                insert campaign;}
            catch (Exception e){
                system.debug('campaign insert error : '+ e);}
            Campaign nRec = [SELECT id, Related_Campaign__c FROM Campaign
                             WHERE id = :campaign.id];
            theJob.GW_Volunteers__Campaign__c = nRec.Related_Campaign__c;
            try {
                insert theJob;}
            catch (exception e){
                system.debug('job insert error : ' + e);
            }
            theShift.GW_Volunteers__Volunteer_Job__c = theJob.id;
            try {
                insert theShift;}
            catch (Exception e){
                system.debug('shift insert error : ' + e);
            }
            stndcamp = '/'+campaign.id;
        }
        if (stndcamp.length() > 3)
        {
            campPage = new PageReference(stndcamp);
            campPage.setRedirect(true);
        }
        else
        {       
            campPage = ApexPages.currentPage();
            campPage.setRedirect(false);
        }
        return campPage;                                           
    }        
}
