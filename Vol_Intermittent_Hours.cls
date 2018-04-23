//this is the controller for the Visualforce page Volunteer_Intermittent_hours
//It saves a shift and the hours the volunteer worked depending on the information
//entered in the UI
//
//
//Martha Vance April 2018

public class Vol_Intermittent_Hours {
    public String vEmail{get; set;}
    public String vFirstName{get;set;}
    public String vLastName{get;set;}
    public Date dateVol{get;set;}
    public String startTime{get;set;}
    public decimal duration{get;set;}
    public String JobName {get;set;}
    Contact volunteer;
    GW_Volunteers__Volunteer_Job__c job;
    
    public void Vol_Intermittent_Hours(){
    }    
    
    public PageReference save(){
        Integer hour = 0;
        Integer minute = 0;
        if (startTime.length() == 8)
        {
            hour = integer.valueOf(startTime.substringBefore(':'));
            if ((startTime.right(2) == 'PM' || startTime.right(2) == 'pm') && hour < 12)
                hour = hour + 12;
            minute = integer.valueOf(startTime.substringBetween(':', ' '));
        }
        else
        {
            ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.error, 'The starting time must be in this format HH:MM followed by either AM or PM'));
            return null;
        }
        time sTime = time.newInstance(hour, minute, 0, 0);
        Contact volunteer;
        GW_Volunteers__Volunteer_Job__c job;
        //find the contact record       
        List<Contact> volunteers= [SELECT id, FirstName, LastName, Email 
                     FROM Contact
                     WHERE Email = :vEmail AND
                     FirstName = :vFirstName LIMIT 1];
        //check that there is a contact with that email and name
        if (volunteers.size()<1)
        {
            ApexPages.addmessage(new ApexPages.Message
                                 (ApexPages.severity.error, 
                                  'The name ' +  vFirstName + ' and email ' + vEmail + ' are not in our database. Please check the spelling or contact our office.'));
            return null;            
        }
        volunteer = volunteers[0];
        
        //find the on going job where the Volunteer hours will be inserted
        List<GW_Volunteers__Volunteer_Job__c> jobs = 
            [SELECT id FROM GW_Volunteers__Volunteer_Job__c
             WHERE Name = :jobName AND
             GW_Volunteers__Ongoing__c = true AND
             GW_Volunteers__Inactive__c = false    
             limit 1];
        if (jobs.size() < 1) 
        {
            ApexPages.addmessage(new ApexPages.Message
                                 (ApexPages.severity.error, 
                                  'The Volunteer Job has to be setup before you enter hours. Please contact our office.'));
            return null;
        }       
        job = jobs[0];
        //insert the shift with date, time and duration indicated by user        
        GW_Volunteers__Volunteer_Shift__c shift = 
            new GW_Volunteers__Volunteer_Shift__c
            (GW_Volunteers__Description__c = 'Intermittent volunteer work',
             GW_Volunteers__Duration__c = duration,
             GW_Volunteers__Start_Date_Time__c = DateTime.newInstance(dateVol, sTime),
             GW_Volunteers__Volunteer_Job__c = job.id);
        insert shift;        
        //insert the volunteer hours
        GW_Volunteers__Volunteer_Hours__c volHours =
            new GW_Volunteers__Volunteer_Hours__c(
                GW_Volunteers__Contact__c = volunteer.id,
                GW_Volunteers__Hours_Worked__c = duration,
                GW_Volunteers__Number_of_Volunteers__c = 1,
                GW_Volunteers__Status__c = 'Completed',
                GW_Volunteers__Start_Date__c = dateVol,
                GW_Volunteers__Volunteer_Shift__c = shift.id,
                GW_Volunteers__Volunteer_Job__c = job.id);
        insert volHours;
        ApexPages.addmessage(new ApexPages.Message(ApexPages.severity.info, duration + ' hours have been entered for '+ dateVol + ' ' + startTime));
        return null;
    }
    
    public List<SelectOption> getPossibleJobs(){
        List<SelectOption> jobOptions = new List<SelectOption>();
        jobOptions.add(new SelectOption('Administrative Support Ongoing','Administrative Support'));
        jobOptions.add(new SelectOption('Equipment Maintenance Ongoning', 'Equipment Maintenance'));
        return jobOptions;
    }    

}