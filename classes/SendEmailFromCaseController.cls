/******************************************************************************************************************************
Name:  SendEmailFromCaseController
==============================================================================================================================
Purpose: Controller for the SendEmailFromCase page, that allows the user to select and run different macros using command buttons
==============================================================================================================================

History:   

VERSION     AUTHOR              DATE        DETAIL     

1.0     Bala Rajagopal          		    BAP-5604
2.0		Sruthi Kattula			9/18/2018	BAP-7767
******************************************************************************************************************************/
public class SendEmailFromCaseController {
	public boolean ReadyforEmail {get; set;}
    public Id ProposeSolutionMacroId {get; set;}
    public Id AskforMoreInfoMacroId {get; set;}
    public Id ProvideInfoCloseMacroId {get; set;}
    public Id EscalateCaseMacroId {get; set;}
    public Id RespondtoClientMacroId {get;set;}
    
    public SendEmailFromCaseController(ApexPages.StandardController controller) {
        if(ReadyforEmail==null){
            ReadyforEmail = false;
        } 
        List<Macro> MacroList = new List<Macro>([Select id, Name from Macro where RecordType.Name = 'Client Success']);
        for(Macro mc:MacroList){
            if(mc.Name == 'Propose a Solution'){
                ProposeSolutionMacroId = mc.id;
            } else if(mc.Name == 'Ask for more info'){
                AskforMoreInfoMacroId = mc.id;
            } else if(mc.Name == 'Providing Info, Closing'){
                ProvideInfoCloseMacroId = mc.id;
            } else if(mc.Name == 'Escalate Case'){
                EscalateCaseMacroId = mc.id;
            } else if(mc.Name == 'Respond to Client'){ //Added By Sruthi K - CS refactor - EPIC 2189 || BAP  7767
                RespondtoClientMacroId = mc.id;
            }
        }

    }
    
}