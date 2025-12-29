/**
  * @description        : Batch class to calculate and update Account Overall Rating based on closed cases
  * @author             : Radhika Sherly
  * @group              : 
  * @last modified on   : 29-AUG-2025
  * @last modified by   : Radhika Sherly
  * Modifications Log
  * Ver     Date          Author              Modification
  * 1.0     29-AUG-2025   Radhika Sherly   Initial Version
  **/
global class AccountUpdateOverallRatingBatch implements Database.Batchable<sObject> {
    
    private Date closedDate;
    
    /**
     * @description Constructor to set the closed date filter
     * @param closedDate Date to filter closed cases (defaults to yesterday)
     */
    global AccountUpdateOverallRatingBatch(Date closedDate) {
        this.closedDate = closedDate != null ? closedDate : Date.today().addDays(-1);
    }
    
    /**
     * @description Default constructor - uses yesterday's date
     */
    global AccountUpdateOverallRatingBatch() {
        this(Date.today().addDays(-1));
    }
    
    /**
     * @description Start method to query accounts with closed cases
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        // Query accounts that have cases closed on the specified date
        String query = 'SELECT Id, ' +
                      'FROM Account ' +
                      'WHERE Id IN (SELECT AccountId FROM Case WHERE IsClosed = true AND ClosedDate = :closedDate AND AccountId != null)';
        
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method to calculate average rating and update accounts
     */
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        for (AggregateResult ar : [SELECT AccountId, AVG(Rating__c) avgRating
                                    FROM Case
                                    WHERE AccountId IN :scope AND Rating__c != NULL
                                    GROUP BY AccountId]) {
            Account acc = new Account();
            acc.Id = (Id)ar.get('AccountId');
            acc.OverallRating__c = (Decimal)ar.get('avgRating');
            accountsToUpdate.add(acc);
        }
        
        if (accountsToUpdate.size() > 0) {
            try {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            // Code to log the exception
                            System.debug('**Error**' + err.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                // Log the exception
                System.debug('**Stack Trace**' + e.getStackTraceString());
            }
        }
    }
    
    /**
     * @description Finish method to log completion
     */
    global void finish(Database.BatchableContext BC) {
        
        // Get the job info
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                           FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        // Log any errors
        System.debug('**AccountUpdateOverallRatingBatch: Job Status**' + job.Status + 
                    ' **Items Processed**' + job.JobItemsProcessed + '/' + job.TotalJobItems + 
                    ' **Errors**' + job.NumberOfErrors);
    }
}