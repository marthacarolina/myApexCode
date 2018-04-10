public class Delete_opportunities {
//this class deletes all opportunities that match a criteria.

    
    public static void deleteOpportunities(){
        List<opportunity> oppys = [select id from Opportunity
                                  where name LIKE '%AZGivesDay 2018'];
        delete oppys;
    }
}