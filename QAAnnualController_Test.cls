@isTest
public class QAAnnualController_Test {

    @isTest(SeeAllData='true')
    public static void QAannualTest(){
        //instantiate page
        PageReference QAAnnualReport = page.QAannualDonorVF;
        test.setCurrentPage(QAAnnualReport);
        ApexPages.currentPage().getParameters().put('f', 'false');
        ApexPages.currentPage().getParameters().put('y', '2017');
        QAAnnualController controller = new QAAnnualController();
        controller.AnnualQA();
        system.assertEquals('2017-01-01', controller.beginRange);
    }
}
