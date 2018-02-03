@isTest
public class QAReports_Test {
    @isTest
    private static void qaTest(){
        QAReports rep = new QAReports();
        rep.getMonthYear('5', '2017');       
        system.assertEquals('May', rep.month);
        system.assertEquals('2017-05-01', rep.beginRange);
        system.assertEquals('2017-05-31', rep.endRange);
        rep.getQuarterYear('0','2017');
        system.assertEquals('1st Quarter', rep.quarter);
        system.assertEquals('2017-01-01', rep.beginRange);
        rep.emptyVars();
    }
}