@isTest
public class QAReportsController_Test {
    
    @isTest
    public static void ReportControllerTest () {
        //instantiate page
        PageReference reportsPage = page.QAreportsVF;
        test.setCurrentPage(reportsPage);        
        QAReportsController controller = new QAReportsController();        
        //////////
        List<SelectOption> years = controller.getYearItems();
        Integer totYears = date.today().year() - 2017 + 1;
        system.assertEquals(totYears, years.size());
        controller.year = '2017';
        system.assertEquals('2017', controller.year);
        ///
        List<SelectOption> c_items = controller.getItems();
        system.assertEquals(16, c_items.size());
        controller.setMonthSel('c-0');
        system.assertEquals(date.today().month(), controller.nMonth);
        controller.setMonthSel('10');
        system.assertEquals('October', controller.getMonthSel());
        system.assertEquals(10, controller.nMonth);
        //
        Decimal d = date.today().month() / 3 ;
        d = d.round(System.RoundingMode.CEILING); 
        Integer nQ = integer.valueOf(d);       
        List<SelectOption> c_quarters = controller.getQuarterItems();
        system.assertEquals(6, c_quarters.size());
        controller.setQuarter('c-0');
        system.assertEquals('c-0', controller.getQuarter());        
        system.assertEquals(nQ, controller.nQuarter);
        controller.setQuarter ('1');
        system.assertEquals(0, controller.nQuarter);
        controller.year = string.valueOf(date.today().year());
        PageReference pg = controller.pMonthlyVol();
        string expYear = string.valueOf(date.today().year());
        system.assertEquals('/apex/QAmonthlyVolVF?m=10&y='+expYear,pg.getUrl());
        PageReference pgPart = controller.printMonthly();
        system.assertEquals('/apex/QAmonthlyVolVF?m=10&y='+expYear,pg.getUrl());
        PageReference annualPDF = controller.pAnnualDonor();
        PageReference annualCSV = controller.exelAnnualDonor();
        PageReference quarterlyD = controller.pQuarterlyDonor();
        PageReference mstaff = controller.printMonthlyStaff();
    }