@isTest
public class QAAnnualController_Test {

    @isTest(SeeAllData='true')
    public static void QAannualTest(){
        //instantiate Annual Donor report page
        PageReference QAAnnualReport = page.QAannualDonorVF;
        test.setCurrentPage(QAAnnualReport);
        ApexPages.currentPage().getParameters().put('f', 'false');
        ApexPages.currentPage().getParameters().put('y', '2017');
        QAAnnualController controller = new QAAnnualController();
        controller.AnnualQA();
        system.assertEquals('2017-01-01', controller.beginRange);
        
        //instantiate Quarterly Donor report page
        PageReference QAQuarterlyDonorReport = page.QAquarterlyDonorVF;
        test.setCurrentPage(QAQuarterlyDonorReport);
        ApexPages.currentPage().getParameters().put('q', '0');
        ApexPages.currentPage().getParameters().put('y', '2017');
        controller = new QAAnnualController();
        controller.QuarterlyDonors();
        system.assertEquals('2017-01-01', controller.beginRange);
        
    }
}