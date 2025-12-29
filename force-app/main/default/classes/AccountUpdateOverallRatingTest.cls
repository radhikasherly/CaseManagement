/**
  * @description        : Test class for Account Overall Rating batch and schedule classes
  * @author             : Radhika Sherly
  * @group              : 
  * @last modified on   : 29-AUG-2025
  * @last modified by   : Radhika Sherly
  * Modifications Log
  * Ver     Date          Author              Modification
  * 1.0     29-AUG-2025   Radhika Sherly   Initial Version
  **/
@isTest
public class AccountUpdateOverallRatingTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                OverallRating__c = null
            ));
        }
        insert testAccounts;
        
        // Create test cases with ratings
        List<Case> testCases = new List<Case>();
        Date yesterday = Date.today().addDays(-1);
        
        // Account 0: 3 cases with ratings 4, 5, 5 (average = 4.67)
        testCases.add(new Case(
            AccountId = testAccounts[0].Id,
            Subject = 'Test Case 1',
            Status = 'Closed',
            Rating__c = 4
        ));
        testCases.add(new Case(
            AccountId = testAccounts[0].Id,
            Subject = 'Test Case 2',
            Status = 'Closed',
            Rating__c = 5
        ));
        testCases.add(new Case(
            AccountId = testAccounts[0].Id,
            Subject = 'Test Case 3',
            Status = 'Closed',
            Rating__c = 5
        ));
        
        // Account 1: 2 cases with ratings 3, 4 (average = 3.5)
        testCases.add(new Case(
            AccountId = testAccounts[1].Id,
            Subject = 'Test Case 4',
            Status = 'Closed',
            Rating__c = 3
        ));
        testCases.add(new Case(
            AccountId = testAccounts[1].Id,
            Subject = 'Test Case 5',
            Status = 'Closed',
            Rating__c = 4
        ));
        
        // Account 2: 1 case with rating 2
        testCases.add(new Case(
            AccountId = testAccounts[2].Id,
            Subject = 'Test Case 6',
            Status = 'Closed',
            Rating__c = 2
        ));
        
        // Account 3: Case with no rating (should be excluded)
        testCases.add(new Case(
            AccountId = testAccounts[3].Id,
            Subject = 'Test Case 7',
            Status = 'Closed',
            Rating__c = null
        ));
        
        // Account 4: Open case (should not be processed)
        testCases.add(new Case(
            AccountId = testAccounts[4].Id,
            Subject = 'Test Case 8',
            Status = 'New',
            Rating__c = 5
        ));
        
        insert testCases;
    }
    
    @isTest
    static void testBatchUpdateOverallRating() {
        Date yesterday = Date.today().addDays(-1);
        
        Test.startTest();
        AccountUpdateOverallRatingBatch batch = new AccountUpdateOverallRatingBatch(yesterday);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify results
        List<Account> updatedAccounts = [SELECT Id, Name, OverallRating__c 
                                        FROM Account 
                                        WHERE Name LIKE 'Test Account%' 
                                        ORDER BY Name];
        
        // Account 0: Average of 4, 5, 5 = 4.67
        Assert.areEqual(4.67, updatedAccounts[0].OverallRating__c, 'Account 0 rating should be 4.67');
        
        // Account 1: Average of 3, 4 = 3.5
        Assert.areEqual(3.5, updatedAccounts[1].OverallRating__c, 'Account 1 rating should be 3.5');
        
        // Account 2: Single rating of 2
        Assert.areEqual(2.0, updatedAccounts[2].OverallRating__c, 'Account 2 rating should be 2.0');
        
        // Account 3: No valid ratings (should remain null)
        Assert.areEqual(null, updatedAccounts[3].OverallRating__c, 'Account 3 rating should be null');
        
        // Account 4: No closed cases (should remain null)
        Assert.areEqual(null, updatedAccounts[4].OverallRating__c, 'Account 4 rating should be null');
    }
    
    @isTest
    static void testBatchDefaultConstructor() {
        Test.startTest();
        AccountUpdateOverallRatingBatch batch = new AccountUpdateOverallRatingBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify batch executed without errors
        List<Account> updatedAccounts = [SELECT Id, OverallRating__c 
                                        FROM Account 
                                        WHERE Name LIKE 'Test Account%' AND OverallRating__c != null];
        
        Assert.isTrue(updatedAccounts.size() > 0, 'At least one account should have been updated');
    }
    
    @isTest
    static void testScheduleUpdateOverallRating() {
        Test.startTest();
        String cronExp = '0 0 1 * * ?';
        String jobId = System.schedule('Test Account Rating Update', cronExp, new AccountUpdateOverallRatingScheduleable(Date.today()));
        Test.stopTest();
        
        // Verify the scheduled job was created
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                         FROM CronTrigger 
                         WHERE Id = :jobId];
        
        Assert.areEqual(cronExp, ct.CronExpression, 'Cron expression should match');
        Assert.areEqual(0, ct.TimesTriggered, 'Job should not have been triggered yet');
    }
    
    @isTest
    static void testScheduleWithParameters() {
        Date testDate = Date.today().addDays(-2);
        
        Test.startTest();
        AccountUpdateOverallRatingScheduleable scheduler = new AccountUpdateOverallRatingScheduleable(Date.today());
        String cronExp = '0 0 2 * * ?';
        String jobId = System.schedule('Test Account Rating Update With Params', cronExp, scheduler);
        Test.stopTest();
        
        // Verify the scheduled job was created
        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(cronExp, ct.CronExpression, 'Cron expression should match');
    }
    
    @isTest
    static void testBatchWithMultipleAccounts() {
        // Create additional accounts with cases
        List<Account> additionalAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            additionalAccounts.add(new Account(
                Name = 'Bulk Test Account ' + i
            ));
        }
        insert additionalAccounts;
        
        Date yesterday = Date.today().addDays(-1);
        List<Case> bulkCases = new List<Case>();
        for (Account acc : additionalAccounts) {
            bulkCases.add(new Case(
                AccountId = acc.Id,
                Subject = 'Bulk Test Case',
                Status = 'Closed',
                Rating__c = 5
            ));
        }
        insert bulkCases;
        
        Test.startTest();
        AccountUpdateOverallRatingBatch batch = new AccountUpdateOverallRatingBatch(yesterday);
        Database.executeBatch(batch, 5); // Small batch size to test multiple batches
        Test.stopTest();
        
        // Verify all bulk accounts were updated
        List<Account> updatedBulkAccounts = [SELECT Id, OverallRating__c 
                                            FROM Account 
                                            WHERE Name LIKE 'Bulk Test Account%'];
        
        for (Account acc : updatedBulkAccounts) {
            Assert.areEqual(5.0, acc.OverallRating__c, 'All bulk accounts should have rating of 5.0');
        }
    }
    
    @isTest
    static void testBatchWithNoRatingChange() {
        // Set existing rating on account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account 0' LIMIT 1];
        testAccount.OverallRating__c = 4.67;
        update testAccount;
        
        Date yesterday = Date.today().addDays(-1);
        
        Test.startTest();
        AccountUpdateOverallRatingBatch batch = new AccountUpdateOverallRatingBatch(yesterday);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify rating remained the same
        Account updatedAccount = [SELECT OverallRating__c FROM Account WHERE Id = :testAccount.Id];
        Assert.areEqual(4.67, updatedAccount.OverallRating__c, 'Rating should remain unchanged');
    }
}