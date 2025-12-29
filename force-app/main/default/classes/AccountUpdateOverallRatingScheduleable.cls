/**
  * @description        : Scheduleable class to run Account Overall Rating batch job
  * @author             : Radhika Sherly
  * @group              : 
  * @last modified on   : 29-AUG-2025
  * @last modified by   : Radhika Sherly
  * Modifications Log
  * Ver     Date          Author              Modification
  * 1.0     29-AUG-2025   Radhika Sherly   Initial Version
  * 
  * Schedule to run daily at 1:00 AM:
  * String cronExp = '0 0 1 * * ?';
  * System.schedule('Account Overall Rating Update', cronExp, new AccountUpdateOverallRatingScheduleable());
  **/
global class AccountUpdateOverallRatingScheduleable implements Schedulable {

    private Date closedDate;

    global AccountUpdateOverallRatingScheduleable(Date closedDate) {
        this.closedDate = closedDate != null ? closedDate : Date.today().addDays(-1);
    }

    global void execute(SchedulableContext SC) {
        AccountUpdateOverallRatingBatch batch = new AccountUpdateOverallRatingBatch(this.closedDate);
        Database.executeBatch(batch, 10);
    }
}