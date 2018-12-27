/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// An apex page controller that supports self registration of users in communities that allow self registration
// 
// Edited by: Evan W.
// 
// Addition(s): 
// 				List of accounts to check against.  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class CommunitiesSelfRegController 
{
    public String firstName {get; set;}
    public String lastName {get; set;}
    public String email {get; set;}
    public String accountName {get; set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    public String communityNickname {get; set { communityNickname = value == null ? value : value.trim(); } }
    public String socialSecurityNumber {get;set;}
    
    public CommunitiesSelfRegController() {
        String expid = ApexPages.currentPage().getParameters().get('expid');            
        if (expId != null) {
            Site.setExperienceId(expId); 
        }    
    }
    
    private boolean isValidPassword() {
        return password == confirmPassword;
    }

    public PageReference registerUser() {
    
           // it's okay if password is null - we'll send the user a random password in that case
        if (!isValidPassword()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.site.passwords_dont_match);
            ApexPages.addMessage(msg);
            return null;
        }    

        String profileId = null; // To be filled in by customer.
        String roleEnum = null; // To be filled in by customer.
        String accountId = ''; // To be filled in by customer.
        
        String userName = firstName.charAt(0) + lastName + '@brave-panda-w0etr2.com';

        User u = new User();
        u.Username = userName;
        u.Email = email;
        u.FirstName = firstName;
        u.LastName = lastName;
        u.CommunityNickname = communityNickname;
		u.ProfileId = profileId;
		//u.Social_Security_Number__c = socialSecurityNumber;
        
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
       	// Edited by: 	Evan W.
       	// Addition:	Check to insure the account entered is
       	// 				in our org, then attach the user
       	// 			 	to that exsiting account.
       	List<Account> accountList = new List<Account>();
       	accountList = [SELECT ID
                   	   FROM Account
                   	   WHERE Name = :accountName];
		if (accountList.isEmpty())
        {
        	ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,
                                 'Could not find ' + accountName + ' in our system.' +
                                 '  Please enter a valid account.'));
            system.debug('account query exception');
            return null;
        }
        accountID = accountList[0].ID;
        
        // Addition:	Check to see if the Contact is in the org
        // 				by email.  If not, add them to the Contact
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT ID, FirstName, LastName, Email, AccountID, Social_Security_Number__c
                       FROM Contact
                       WHERE Social_Security_Number__c = :socialSecurityNumber];
        if (!contactList.isEmpty())
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,
                                 'Social Security Number is already in use.  ' +
                                 'Please enter another Social Security Number'));
            system.debug('account query exception');
            return null;
        }

        //////////////////////////////////////////////////////END ADDITIONS//////////////////////////////////////////////////////
        
        String userId;

        try {
            userId = Site.createExternalUser(u, accountId, password);
        } catch(Site.ExternalUserCreateException ex) {
            List<String> errors = ex.getDisplayMessages();
            for (String error : errors)  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
            }
            
            // This message is used for debugging. Do not display this in the UI to the end user.
            // It has the information around why the user creation failed.
            System.debug(ex.getMessage());
        }
        
        if (userId != null) { 
            if (password != null && password.length() > 1) {
                return Site.login(userName, password, ApexPages.currentPage().getParameters().get('startURL'));
            }
            else {
					
				/*contactList = new List<Contact>();
				contactList = [SELECT email, Social_Security_Number__c
                               FROM Contact
                               WHERE Email = :u.Email
                               LIMIT 1];
				for (Contact c : contactList)
                {
                    c.Social_Security_Number__c = u.Social_Security_Number__c;
                }*/
                PageReference page = System.Page.CommunitiesSelfRegConfirm;
                page.setRedirect(true);
                return page;
            }
        }
        return null;
    }
}