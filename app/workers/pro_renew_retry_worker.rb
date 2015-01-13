class ProRenewRetryWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily }

  def perform
    recurring_plans = ProMembershipPlan.recurring_plans.map(&:id)
    tries = Array.new(3)
    tries[1] = User.where(pro_membership_id: recurring_plans,
                          pro_expires_at: (2.days.ago)..(1.day.ago))
    tries[2] = User.where(pro_membership_id: recurring_plans,
                          pro_expires_at: (4.days.ago)..(3.day.ago))
    tries[3] = User.where(pro_membership_id: recurring_plans,
                          pro_expires_at: (6.days.ago)..(5.day.ago))

    tries.with_index.each do |users, index|
      users.all.each do |user|
        manager = ProMembershipManager.new(user)
        manager.renew! attempt: index
      end
    end
  end
end
