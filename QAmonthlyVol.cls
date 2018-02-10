public class QAMonthlyVol extends QAReports {
    public List<volPage> volPages{get;set;} //this var holds the pages that have volunteer records
    public List<volPage> qualvPages{get;set;} //pages - qualified volunteer pages
    public List<contPage> expCertPages{get;set;} //pages for volunteers with expired certs
    public List<volPage> inactVolPages{get;set;} //pages for inactive volunteers
    List<volunteer> volunteers; //the list of volunteers who worked this period
    List<volunteer> qpVolunteers; //a list of qualified program vol
    List<volunteer> inactiveVolunteers; //the list of inactive volunteers
    public integer totNewVolunteers{get;set;}
    public integer tot_Volunteers{get;set;}
    public integer tot_qpvol{get;set;}
    public integer tot_inactiveVols{get;set;}
    public Decimal mTot_Vol_Hours{get;set;}
    public List<Contact> v_expiring_certs{get;set;} //the list of volunteers with expiring certs
    public boolean samePage1{get;set;}
    public boolean samePage2{get;set;}
    public boolean samePage3{get;set;}
    public boolean samePage4{get;set;}
    public boolean monthly {get;set;}
    
    integer breakPoint = 40; //this value only works for the first page
    integer subseqPageBrakes = 59; //this is the number of lines for the rest of the pages
    integer linesInPage = 0;
    
    public void QAMonthlyVol(){}
    
    public void printMonthlyVol(){
        //this is the method that the visualforce page calls
        String q = ApexPages.currentPage().getParameters().get('q');
        String m = ApexPages.currentPage().getParameters().get('m');
        String y = ApexPages.currentPage().getParameters().get('y');
        if (q == 'N')
        {
            getMonthYear(m, y);
            monthly = true;
        }
        else
        {
            getQuarterYear(q, y);
            monthly = false;
        }
        printHours();
        tot_qpvol = 0;
        if (monthly)
        {
            qpVolunteers = VolunteersList(true);
            tot_qpvol = qpVolunteers.size();
            tot_inactiveVols = 0;
            inactiveVolunteers = VolunteersList(false);
            tot_inactiveVols = inactiveVolunteers.size();
            v_expiring_certs = Vol_expiring(Integer.valueOf(m));
        }
        prepareLinesForPrinting();        
    }
    
    private void printHours(){
        //this method runs the report VOLUNTER_HOURS_QA and parses the information
        //saving the list of volunteers who worked during this period in - volunteers -
        List<Report> reportList = [SELECT Id, DeveloperName FROM Report where
                                   DeveloperName = 'Volunteer_Hours_QA'];
        String reportId = (String)reportList.get(0).get('Id');
        // Get the report metadata
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        
        //Set the filters (bypass 0, set 1 and 2 with month's first date and last date)
        Reports.ReportFilter filter1 = rm.getReportFilters()[0];
        Reports.ReportFilter filter2 = rm.getReportFilters()[1];
        filter1.setValue(beginRange);
        filter2.setValue(endRange);
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        //System.debug('Synchronous results: ' + results);
        
        // Get detail columns
        List<String> columnFields = rm.getDetailColumns();
        Integer numOfColumns = columnFields.size();
        
        // Get report format
        // Get the down-groupings in the report in this report, the records are grouped by volunteers
        Reports.Dimension dim = results.getGroupingsDown();
        List<Reports.GroupingValue> groupingVal = dim.getGroupings();
        List<String> factMapKeys = new List<String>();
        volunteers = new List<volunteer>();
        mTot_Vol_Hours = 0;
        totNewVolunteers = 0;
        tot_Volunteers = 0;
        //iterate over the groups in the report (each grouping is a volunteer)
        for (Reports.GroupingValue gV : groupingVal)
        {
            tot_Volunteers++;
            volunteer vol = new volunteer();
            vol.fullName = gv.getLabel();
            // Construct a fact map key, using the grouping key value
            String factMapKey = gV.getKey() + '!T';
            factMapKeys.add(factMapKey);
            
            // Get the fact map for this grouping from the report results
            Reports.ReportFactWithDetails factDetails =
                (Reports.ReportFactWithDetails)results.getFactMap().get(factMapKey);
            
            // Get the summary amounts from the fact map it should be
            // Total Hours, Total Volunteers, Total records
            List<Reports.SummaryValue> sumVal = factDetails.getAggregates();
            vol.totHours = (decimal) sumVal[0].getValue();
            mTot_Vol_Hours = mTot_Vol_Hours + vol.totHours;
            vol.totCamp = integer.valueOf(sumVal[2].getValue());
            // Get the fields value for the grouping
            List<Reports.ReportDetailRow> detailRows = factDetails.getRows();
            List<volCamp> advs = new List<volCamp>();
            vol.firstTime = false;
            //iterate through the rows (campaigns)
            for (Reports.ReportDetailRow row : detailRows)
            {   //get the information from each of the columns in the report
                List<Reports.ReportDataCell> dataCells = row.getDataCells();
                volCamp adv = new volCamp();
                adv.cName = dataCells[1].getLabel();
                adv.jName = dataCells[2].getLabel();
                adv.status = dataCells[3].getLabel();
                adv.startDate = dataCells[4].getLabel();
                String hrs = dataCells[5].getLabel();
                adv.hours = Decimal.valueOf(hrs);
                if (vol.firstVolunteer == null) vol.firstVolunteer = date.valueOf(dataCells[8].getValue());
                advs.add(adv);
            }
            if (vol.firstVolunteer >= beginRangeDate)
            {
                vol.firstTime = true;
                totNewVolunteers++;
            }
            vol.Adventures = advs;
            volunteers.add(vol);
        }
    }
    
    private List<volunteer> VolunteersList(Boolean active)
    {
        //this method runs the report QA_VOLUNTEERS_CERTS and parses the information
        //returning the list of volunteers in the report (this can be qualified program volunteers or
        //inactive volunteers).
        List<volunteer> volList = new List<volunteer>();
        List<Report> reportList = [SELECT Id, DeveloperName FROM Report where
                                   DeveloperName = 'QA_Volunteers_Certs'];
        String reportId = (String)reportList.get(0).get('Id');
        // Get the report metadata
        Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata rm = describe.getReportMetadata();
        
        //Set the filters 0-3 (certs exp dates & orientation) with endRange for the 
        //part of the report that lists the QUALIFIED PROGRAM VOLUNTEERS
        //For the list of Inactive volunteers get rid of the first 4 filters,
        //keep the fifth and add a filter for the Volunteer Status field
        List<Reports.ReportFilter> filters = rm.getReportFilters();
        List<Reports.ReportFilter> newFilters = new List<Reports.ReportFilter>();
        if (active)
        {
            for (Integer x=0; x<4; x++)
            {
                filters[x].setValue(endRange);
            }
            if (filters.size()>5) filters[5].setValue('Active');
        }
        else
        {
            //get rid of the first 4 filters 0-3. Keep the last filter and add one 
            //to filter volunteer status == false 
            newFilters.add(filters[4]);
            Reports.ReportFilter addFilter = 
                new Reports.ReportFilter('Contact.GW_Volunteers__Volunteer_Status__c', 'equals', 'Inactive');
            newFilters.add(addFilter);
            rm.setReportFilters(newFilters);
        }
        // Run the report - syncronously
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId, rm, true);
        //get the report key, get the rows. Iterate through the volunteers, get the grand total of
        //records.
        List<String> factMapKeys = new List<String>();
        Reports.ReportFactWithDetails fullReport =
            (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');
        List<Reports.ReportDetailRow> detailRows = fullReport.getRows();
        for (Reports.ReportDetailRow row : detailRows)
        {
            List<Reports.ReportDataCell> dataCells = row.getDataCells();
            volunteer vol = new volunteer();
            vol.status = dataCells[0].getLabel();
            vol.fullName = dataCells[1].getLabel() + ' ' + dataCells[2].getLabel();
            vol.email = dataCells[4].getLabel();
            vol.orientationDate = (date) dataCells[4].getValue();
            vol.cprExpDate = (date) dataCells[5].getValue();
            vol.faidExpDate = (date) dataCells[6].getValue();
            vol.fccExpDate = (date) dataCells[7].getValue(); 
            vol.lifetimeHours = (decimal) dataCells[8].getValue();
            volList.add(vol);
        }       
        return volList;
    }
    
    public List<Contact> Vol_expiring(Integer nMonth)
    {
        //this method queries the CONTACT object for volunteers whose certifications are
        //about to expired.
        integer nyear = integer.valueOf(year);
        Date start_three_month_range = Date.newInstance(nyear,nMonth+1,1);
        Date end_three_month_range = 
            Date.newInstance(nyear, nMonth+4,date.daysInMonth(nyear,nMonth));
        Date soon = date.today() + 92;
        List<Contact> volExp = [SELECT Name, CPR_Certificate_Expiration_Date__c,
                                Fingerprint_Clearance_Expiration_Date__c,
                                First_Aid_Certification_Expiration_Date__c
                                FROM Contact
                                WHERE 
                                ((CPR_Certificate_Expiration_Date__c >= :start_three_month_range AND
                                  CPR_Certificate_Expiration_Date__c <= :end_three_month_range) OR
                                 (Fingerprint_Clearance_Expiration_Date__c >= :start_three_month_range AND
                                  Fingerprint_Clearance_Expiration_Date__c <= :end_three_month_range) OR
                                 (First_Aid_Certification_Expiration_Date__c >= :start_three_month_range AND
                                  First_Aid_Certification_Expiration_Date__c <= :end_three_month_range)) AND
                                Volunteer_Orientation__c != null
                                ORDER BY LastName, FirstName];
        
        return volExp;        
    }
    
    public void prepareLinesForPrinting(){
        volPages = new List<volPage>();
        decimal lineCount = 0;
        volPage onePage = new volPage();
        for (volunteer vol : volunteers)
        {
            lineCount = lineCount + 2; // two lines for the volunteer header
            lineCount = lineCount + (vol.Adventures.size() * 1.5); //all the detail lines for the volunteer
            if (lineCount > breakPoint)
            {
                breakPoint = subseqPageBrakes;
                volPages.add(onePage);
                onePage = new volPage();
                onePage.theVolunteers.add(vol);
                lineCount = 2 + vol.Adventures.size(); //two lines for the header + campaigns
            }
            else
            {
                onePage.theVolunteers.add(vol);
            }
        }
        if (onePage.theVolunteers.size() > 0) volPages.add(onePage);
        if (monthly)
        {
            samePage1 = true;
            integer x = 0;
            qualvPages = new List<volPage>();
            onePage = new volPage();
            lineCount = lineCount + 7; //header for qualified volunteers segment
            if (lineCount + qpVolunteers.size() > breakPoint)
            {
                for (volunteer vol : qpVolunteers)
                {
                    lineCount ++;
                    if (lineCount > breakPoint)
                    {
                        if (x==0) samePage1 = false;
                        breakPoint = subseqPageBrakes;
                        if(onePage.theVolunteers.size()>0)qualvPages.add(onePage);
                        onePage = new volPage();
                        onePage.theVolunteers.add(vol);
                        lineCount = 1;
                    }
                    else
                    {
                        onePage.theVolunteers.add(vol);
                    }
                    x++;
                }
            }
            else
            {
                onePage.theVolunteers.addAll(qpVolunteers);
                lineCount=lineCount+ qpVolunteers.size();
            }
            if (onePage.theVolunteers.size() > 0) qualvPages.add(onePage);
            samePage2 = true;
            x = 0;
            expCertPages = new List<contPage>();
            contPage aPage = new contPage();
            lineCount = lineCount + 5; //header for volunteer with expiring certs segment
            if (lineCount + v_expiring_certs.size() > breakpoint)
            {   //if all the lines in this section don't fit on the current page
                for (contact volEC : v_expiring_certs)
                { //cycle over every volunteer in this section
                    lineCount++;
                    if (lineCount > breakPoint)
                    {// if there are too many lines for this page start another page
                        if (x==0) samePage2 = false; // this variable tells us if this section is printed in the same page
                        breakPoint = subseqPageBrakes;
                        if (aPage.theContacts.size() > 0) expCertPages.add(aPage);
                        aPage = new contPage();
                        aPage.theContacts.add(volEC);
                        lineCount = 1;
                    }
                    else
                    {// otherwise just add the line to the page
                        aPage.theContacts.add(volEC);
                    }
                    x++;
                }
            }
            else
            {
                aPage.theContacts.addAll(v_expiring_certs);
                lineCount = lineCount + v_expiring_certs.size();
            }  
            if (aPage.theContacts.size() > 0) expCertPages.add(aPage); 
            samePage3 = true;
            x = 0;
            inactVolPages = new List<volPage>();
            onePage = new volPage();
            lineCount = lineCount + 7; //header for inactive volunteers segment
            if (lineCount + inactiveVolunteers.size() > breakPoint)
            {
                for (volunteer vol : inactiveVolunteers)
                {
                    lineCount ++;
                    if (lineCount > breakPoint)
                    {
                        if (x==0) samePage1 = false;
                        breakPoint = subseqPageBrakes;
                        if (onePage.theVolunteers.size() > 0) inactVolPages.add(onePage);
                        onePage = new volPage();
                        onePage.theVolunteers.add(vol);
                        lineCount = 1;
                    }
                    else
                    {
                        onePage.theVolunteers.add(vol);
                    }
                    x++;
                }
            }
            else
            {
                onePage.theVolunteers.addAll(inactiveVolunteers);
            }
            if (onePage.theVolunteers.size() > 0) inactVolPages.add(onePage); 
        }
    }
    
    public class volPage {
        public List<volunteer> theVolunteers {get;set;}
        public volPage(){
            this.theVolunteers = new List<volunteer>();
        }
    }
    
    public class contPage {
        public List<Contact> theContacts {get;set;}
        public contPage(){
            this.theContacts = new List<Contact>();
        }
    }
    
}