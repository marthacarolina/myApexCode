//this is the extension for the visualforce page printMemberInfoPDF this class
//retrieves the medications for the contact
//
//Martha Vance 2/24/18


public class printMemberInfoMeds {
    private final id memberID;
    public boolean noMeds {get;set;}
    public String forDate {get;set;}
    public String forTime {get;set;}
    
    public printMemberInfoMeds(ApexPages.StandardController stdController){
        //get the contact Id from the Standard Controller
        this.memberID = (ID)stdController.getRecord().id;
    }
    
    public List<Medication__c> getMeds(){
        //prepare the strings for current Date and Time printed at the bottom of the page
        datetime theDate = system.now();
        forDate = string.valueOf(theDate.date().format());
        integer minutes = theDate.time().minute();
        string stMinutes = minutes > 9 ? string.valueOf(minutes) : '0' + string.valueOf(minutes);
        forTime = string.valueOf(theDate.time().hour()) + ':'+ stMinutes;
        //Query the Medication__c object to find all the medications for this contact(member)
        List<Medication__c> medicines= [SELECT Name, Dose__c, Frequency__c, Notes__c
                                        FROM Medication__c
                                        WHERE Contact_meds__c = :memberId];
        //if there are no medications set a variable to tell the Vf page not to print that part
        if (medicines.size()==0) noMeds = true;
        //Return the list of medications
        return medicines;
    }
}