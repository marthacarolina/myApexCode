public class CMemberTriggerHandler extends TriggerHandler{

    public CMemberTriggerHandler(){}

    protected override void beforeDelete() {
        PrepareForDeletion();
    }

    private void PrepareForDeletion()
    {
        // This trigger deletes the opportunity record (fee) of a CampaignMember
        // when a campaign member is deleted.
        // If the campaignMember status is marked as ATTENDED, or the
        // opportunity for the FEE is marked as CLOSED WON or PLEDGE
        // then the CampaignMember can't bee deleted

        //assign the records chosen to be deleted to delCampMem
        List<CampaignMember> delCampMem = (List<CampaignMember>) trigger.old;
        for (CampaignMember cm : delCampMem)
        {
            Contact participant = [SELECT Name, FirstName, LastName FROM Contact
                                   WHERE id = :cm.ContactId];
            //if the participant has a status of Attended, then the record can't be deleted
            if (cm.status == 'Attended')
            {
                system.debug('the staus is attended.');
                cm.adderror('Cannot delete a member with status Attended. You must change the status first.');
            }
            else
            {
                //Find the opportunity record that goes with the Participant and delet it
                String qryName = '%'+ participant.Name + '%';
                List<Opportunity> oppys = [SELECT id, Name, StageName from Opportunity WHERE CampaignId = :cm.CampaignId AND
                                           Name Like :qryName];
                For (Opportunity oppy : oppys) {
                    if (oppy.Name.contains('Fee')){
                        if (oppy.StageName != 'Close Won' && oppy.Stagename != 'Posted')
                        {  delete oppy;}
                        else
                        {cm.adderror('Cannot delete a member that has a Fee marked as PAID. Change the Opportunity record first');}
                    }
                }
            }
        }
    }

}
