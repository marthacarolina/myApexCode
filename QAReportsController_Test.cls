@isTest
public class QAReportsController_Test {
    
    @isTest
    public static void ReportControllerTest () {
        //instantiate page
        PageReference reportsPage = page.QAreportsVF;
        test.setCurrentPage(reportsPage);        
        QAReportsController controller = new QAReportsController();        
        //Populate the years list and make sure it's the right size
        List<SelectOption> years = controller.getYearItems();
        Integer totYears = date.today().year() - 2017 + 1;
        system.assertEquals(totYears, years.size());
        controller.year = '2017';
        system.assertEquals('2017', controller.year);
        //pupulate the months options (c_items) and check the size
        List<SelectOption> c_items = controller.getItems();
        system.assertEquals(16, c_items.size());
        //check that the right month is selected when the user chooses "this month"
        controller.setMonthSel('c-0');
        system.assertEquals(date.today().month(), controller.nMonth);
        //check that when the uses chooses "October" the program changes it to number 10
        controller.setMonthSel('10');
        system.assertEquals('October', controller.getMonthSel());
        system.assertEquals(10, controller.nMonth);
        //
        Decimal d = date.today().month() / 3 ;
        d = d.round(System.RoundingMode.CEILING); 
        Integer nQ = integer.valueOf(d);     
        //populate the options for the Quarter picker and check the size  
        List<SelectOption> c_quarters = controller.getQuarterItems();
        system.assertEquals(6, c_quarters.size());
        //check that the program has the right quarter when the user chooses "this quarter"
        controller.setQuarter('c-0');
        system.assertEquals('c-0', controller.getQuarter());        
        system.assertEquals(nQ, controller.nQuarter);
        controller.setQuarter ('1');
        system.assertEquals(0, controller.nQuarter);
        controller.year = string.valueOf(date.today().year());
        //check that the url is constructed correctly when calling the monthly volunteer report
        string expYear = string.valueOf(date.today().year());
        PageReference pg = controller.pMonthlyVol();
        system.assertEquals('/apex/QAmonthlyVolVF?m=10&q=N&y='+expYear,pg.getUrl());
        //check the URL for calling the Monthly Participant report
        PageReference pgPart = controller.printMonthly();
        system.assertEquals('/apex/QAMonthlyPdfVF?m=10&y='+expYear,pgPart.getUrl());
        //call the other methods
        PageReference quarterlyVol = controller.pQuarterlyVol();
        PageReference annualPDF = controller.pAnnualDonor();
        PageReference annualCSV = controller.exelAnnualDonor();
        PageReference quarterlyD = controller.pQuarterlyDonor();
        PageReference mstaff = controller.printMonthlyStaff();
    }
}