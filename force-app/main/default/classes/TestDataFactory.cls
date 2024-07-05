@IsTest
public class TestDataFactory {
    public static final String DEFAULT_USERNAME = 'killempesttestusername@test.org';

    public static User createKillemPestUser() {
        User user = createStandardUser('America/Los_Angeles', DEFAULT_USERNAME, true);

        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name LIKE 'FSL%' OR Name = 'Custom_FSL_User'
            LIMIT 1
        ];

        List<PermissionSetAssignment> permAssignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            permAssignments.add(new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSet.Id));
        }
        insert permAssignments;

        return user;
    }

    public static User createStandardUser(
        final String timeZoneSidKey,
        final String userName,
        final Boolean insertThis
    ) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String uniqueName = orgId + dateString + randomInt;

        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE Name LIKE '%standard%' AND UserType = 'Standard' AND UserLicense.Name = 'Salesforce'
            ORDER BY CreatedDate NULLS LAST
            LIMIT 1
        ];

        User user = new User(
            Alias = uniqueName.substring(18, 23),
            Username = userName != null ? userName : uniqueName + '@test' + orgId + '.org',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = timeZoneSidKey,
            FederationIdentifier = 'testfederationid@killempest.com',
            FirstName = 'Standard',
            LastName = 'KillemPest',
            Email = 'testemail@killempest.com',
            Title = 'Title',
            Division = 'Division',
            Department = 'Department',
            CompanyName = 'KillemPest',
            Phone = '+123456789',
            MobilePhone = '+123456789'
        );

        if (insertThis) {
            insert user;
        }
        return user;
    }
}