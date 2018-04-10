//This class is the controller for the VF page AZGives_DonorVF

//This class processes the donations received from AZGives.org after the spreadsheet
//has been loaded into the AZGives_Donors__c object this class will parse out info
//into a campaign and set up the opportunity for each donor. 
//Serial donors will have all their donations added and only one opportunity created
//
//The process matches the email addresses first and then the first and last names.
//If the email is found but the firstname or lastname are not exact then an opportunity
//won't be created and the donor will not be added to the campaign. The field 
//AZGives_Donors__c.Email_Matched__c will be true and AZGives_Donors__c.Processed__c will
//be true when the process ends.
//
//Martha Vance


public class processOpportunitiesFromDonations {
    
    public list<AZGives_Donor__c> donors;
    public List<Contact> newContacts;
    public List<Opportunity> oppys;
    
    public List<Task> taskList;
    public Campaign campAZGD {get;set;}
    public id campaignId;
    public id accId;
    public Integer donorCount {get;set;}
    public Integer opportunitiesCount {get;set;}
    public Integer tasksCount {get;set;}
    public Integer newContactsCount {get;set;}
    public Integer dontHaveOppy {get;set;}
    List<CampaignMember> cms;
    RecordType donation;
    public Integer year {get;set;}
    
    public processOpportunitiesFromDonations(){
        //get the opportunity recordTypeId for donation
        donation = [Select id from RecordType 
                           where sObjectType = 'Opportunity' AND
                          DeveloperName = 'Donation' limit 1];
        year = date.today().year();
    }
    
    public PageReference processDonors(){
        donorCount = 0;
        opportunitiesCount = 0;
        tasksCount = 0;
        newContactsCount = 0;
        dontHaveOppy = 0;
        date tuesday;
        cms = new List<CampaignMember>();
        newContacts = new List<Contact>();
        taskList = new List<Task>();
        List<Campaign> campAZGDs = [SELECT id, Name FROM Campaign WHERE
                                Name LIKE 'AZGives%' 
                               ORDER BY StartDate DESC limit 1];
        tuesday = findFirstTuesday();
        if (campAZGDs.size() > 0)
        {
            If (!campAZGDs[0].Name.contains(string.valueOf(year))) 
            {
                //If there is no campaign for this year creat the AZGivesDay YEAR campaign
                insertCampaign(tuesday);
            }
            else
            {   campaignID = campAZGDs[0].id;}            
        }
        else
        {   insertCampaign(tuesday);}
        //campaignId = campAZGD.id;
        //retrieve the account used for anonymous donations
        List<Account> accs = [SELECT id, Name FROM Account
                              WHERE Name LIKE 'Anonymous'];
        if (accs.size() > 0) accId = accs[0].id;
        oppys = new List<Opportunity>();
        
        donors = [SELECT id, Amount__c, Transaction_Date_Time__c, Anonymous__c,
                  FirstName__c, LastName__c, Email__c, Phone_Number__c,
                  Address_1__c, Address_2__c, City__c, State__c, Country__c,
                  Zip_Code__c, Cover_Fees_Txt__c, In_Memory__c, Comments__c, Get_Involved__c,
                  Campaign_Name__c, Program_Designation__c, Processed__c, Matched_Email__c, 
                  Not_Found__c 
                  FROM AZGives_Donor__c WHERE 
                  (Not_Found__c = false AND Processed__c = false AND 
                   Matched_Email__c = false)];
        Map<string, AZGives_Donor__c> mapEmail = new Map<string, AZGives_Donor__c>();
        for (AZGives_Donor__c d : donors)
            mapEmail.put(d.Email__c, d);
        List <Contact> conts = [SELECT id, FirstName, LastName, Email,
                                npe01__HomeEmail__c,
                                npe01__WorkEmail__c
                                FROM Contact
                                WHERE Email IN :mapEmail.keySet()
                                OR npe01__HomeEmail__c IN :mapEmail.keySet()
                                OR npe01__WorkEmail__c IN :mapEmail.keySet()];        
        donorCount = donors.size();
        for (AZGives_Donor__c d : donors)
        {
            boolean notInSF = false;
            if ( ! d.Anonymous__c.contains('Fully'))
            {   
                for (integer x = 0; x < conts.size(); x++)
                {
                    if (d.email__c == conts[x].email || 
                        d.email__c == conts[x].npe01__HomeEmail__c ||
                        d.email__c == conts[x].npe01__WorkEmail__c )
                    { 
                        d.Matched_Email__c = true;
                        If (d.FirstName__c.equalsIgnoreCase(conts[x].FirstName) && 
                            d.LastName__c.equalsIgnoreCase(conts[x].LastName))
                        {
                            //generate opportunity add it to the list of oppys and 
                            //generate the task add it to the list of tasks mark the donor
                            //as processed
                            newOppy(conts[x], d, tuesday);
                            d.Processed__c = true;  
                            x = conts.size(); //exit the for if the contact has been found
                        }
                    }
                }
                //if the FirstName and LastName couldn't be found
                //mark this donor as not matched                                                                              
                if (! d.Processed__c) //if the email was found, but the contact name didn't match
                {
                    if (d.Matched_Email__c)
                    {
                        d.Processed__c = true;
                        dontHaveOppy++;
                    }
                    else //if the contact was not in SF
                    {
                        //create a contact record and add it to the contact list
                        addNewContacts(d);
                        d.Processed__c = false;
                    }
                }
            }
            else
            {
                //generate opportunity with account id mark the donor as processed
                newAnonOppy(d, tuesday);
                d.Processed__c = true;
            }
        }
        //now insert the new contacts
        newContactsCount = newContacts.size();
        insert newContacts;
        //generate the oppys for the new contacts (find the donor that matches the contact
        //and call the opportunity method) mark the donor as processed 
        for (AZGives_Donor__c d : donors)
            for (Contact c : newContacts)
            {
                if (c.Email == d.Email__c && (! d.Processed__c))
                {
                   newOppy(c, d, tuesday);
                   d.Processed__c = true;                    
                }            
            }
        //insert the opportunities
        opportunitiesCount = oppys.size();
        insert oppys;
        //change the GAU allocation of the opportunities with type not ''
        //put all the opportunities going to a NON General Donations GAU in a map
        Map<id, opportunity> difFund = new Map<id, opportunity>();
        for (opportunity opp : oppys)
        {
            if (opp.Type != null)
                difFund.put(opp.id, opp);
        }
        //retrieve the GAU's and make a map where the id can be retreived by the name
        List<npsp__General_Accounting_Unit__c> GAU = [Select id, Name 
                                                      FROM npsp__General_Accounting_Unit__c];
        Map<String, id> mapGAU = new Map<String, id>();
        for (npsp__General_Accounting_Unit__c g : GAU)
            mapGAU.put(g.Name, g.id);
        
        //retrieve the GAU Allocation records related to the opportunities not going to General Fund
        map<id, npsp__Allocation__c> Alls = 
            new map<id, npsp__Allocation__c>([SELECT id, npsp__General_Accounting_Unit__c,
                                              npsp__Opportunity__c 
                                              FROM npsp__Allocation__c
                                              WHERE npsp__Opportunity__c IN :difFund.keySet()]);
        //change the GAU allocation for the opportunities not going to the General Fund
        for (npsp__Allocation__c alloc : Alls.values())
        {
            String fund = difFund.get(alloc.npsp__Opportunity__c).Type;
            if (mapGAU.get(fund) != null)
                alloc.npsp__General_Accounting_Unit__c = mapGAU.get(fund);
            else
                system.debug('this GAU '+ fund + ' does not exist');
        }
        //update the allocations
        update Alls.values();    
        //insert the tasks
        tasksCount = tasklist.size();
        insert taskList;
        //update AZGives_Donor 
        update donors;  
        //insert campaignmembers
        insert cms;
        return null;
    }
    
    public void newOppy(Contact c, AZGives_Donor__c donor, date tuesday){
        Boolean newOppyB = true;
        for (Integer x = 0; x < oppys.size(); x++)
        {
            if (oppys[x].npsp__Primary_Contact__c == c.id)
            {
                oppys[x].Amount = oppys[x].Amount + donor.Amount__c;
                newOppyB = false;
            }
        }
        if (newOppyB)
        {
            String stName = 'Donation '+ c.FirstName + ' ' +
                c.LastName + ' AZGivesDay '+year;
            String annon1 = ' ';
            If (donor.Anonymous__c.contains('Partially')) 
                annon1 = 'Partially annonymous. ';
            String cover = '';
            if (donor.Cover_Fees_Txt__c.contains('Yes'))
                cover = 'Donor covered transaction fees. ';
            annon1 = annon1 + ' ' + donor.Comments__c + ' ';
            string tString = '';
            if (donor.Program_Designation__c != 'General Fund' )
                tString = donor.Program_Designation__c;
            system.debug('donor name = '+ donor.FirstName__c);
            system.debug('anonymous = ' + annon1);
            system.debug('contact = ' + c.FirstName + ' ' + c.LastName);
            system.debug('contact id = '+ c.id);
            system.debug('campaign id = ' + campaignId);
            Opportunity oppy = new Opportunity (Name = stName,
                                                RecordTypeId = donation.Id,
                                                npsp__Primary_Contact__c = c.id,
                                                Amount = donor.Amount__c,
                                                CloseDate = tuesday,
                                                StageName = 'Closed Won',
                                                Description = annon1,
                                                CampaignId = campaignId,
                                                LeadSource = 'Special Event',
                                                Type = tString,
                                                npe01__Do_Not_Automatically_Create_Payment__c = true,
                                                npsp__Honoree_Name__c = donor.In_Memory__c );        
            if (donor.Get_Involved__c){
                system.debug('in the if for get_involved');
                makeTask(c);
                system.debug('out of make task');}
            oppys.add(oppy);
            //add the contact to the Campaign Members list
            CampaignMember cm = new CampaignMember(CampaignId = campaignId,
                                                  ContactId = c.id,
                                                  Status = 'Responded');
            cms.add(cm);
        }
    }
    
    public void makeTask (Contact c)
    {
        system.debug('in makeTask');
        Task contTask = new Task(ActivityDate = Date.Today() + 3,
                                 Description = c.FirstName + ' ' + c.LastName + ' wants to be involved with DA.',
                                 Priority = 'High', Status = 'Not Started', 
                                 Subject = 'Need to contact this person.',
                                 WhatId = campaignId, 
                                 WhoId = c.id);
        taskList.add(contTask);
    }
    
    public void newAnonOppy(AZGives_Donor__c donor, date tuesday){
        Opportunity oppy = new Opportunity (Name = 'Anonymous donation AZGivesDay '+year,
                                            RecordTypeId = donation.Id,
                                            AccountId = accId,
                                            Amount = donor.Amount__c,
                                            CloseDate = tuesday,
                                            StageName = 'Closed Won',
                                            CampaignId = campaignId,
                                            npe01__Do_Not_Automatically_Create_Payment__c = true,
                                            npsp__Honoree_Name__c = donor.In_Memory__c );        
        oppys.add(oppy);
    }    
    
    private void insertCampaign(date tuesday)
    {
        id fundRecType =
            Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Fundraising').getRecordTypeId();
        campAZGD = new Campaign(Name = 'AZGivesDay '+ year,
                                StartDate = tuesday,
                                EndDate = tuesday,
                                RecordTypeId = fundRecType,
                                Description = 'Donations from AZGives.org',
                                IsActive = true,
                                Status = 'Planned ',
                                Type = 'Fundraising');
        insert campAZGD; 
        campaignID = campAZGD.Id;
    }
    
    public void addNewContacts(AZGives_Donor__c d)
    {
        // this method creates a contact record and adds it to the list
        // of new contacts.
        // if the donor record hasn't been processed and it hasnt been
        // matched then add a contact record with donor's info
        // after adding the new contact record update Processed__c to true
        Contact c = new Contact(FirstName = d.FirstName__c,
                                LastName = d.LastName__c,
                                Email = d.Email__c,
                                MailingStreet = d.Address_1__c,
                                MailingCity = d.City__c,
                                MailingState = d.State__c,
                                MailingPostalCode = d.Zip_Code__c,
                                Phone = d.Phone_Number__c);
        newContacts.add(c);
    }
    
    private Date findFirstTuesday (){
        //find the date for the first Tuesday of April
        date firstOfApril = date.newInstance(year, 4, 1);
        date tuesday = firstOfApril.toStartOfWeek().addDays(2);        
        if (tuesday.month() < 4)
            tuesday = tuesday.addDays(7);       
        return tuesday;
    }    
}