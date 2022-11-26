# frozen_string_literal: true

class Vacuum::UserProfileVacuum
  TTL = 1.day.freeze

  def initialize(retention_period)
    @retention_period = retention_period
  end

  def perform
    vacuum_cached_files! if retention_period?
  end

  private

  def vacuum_cached_files!
    userprofiles_past_retention_period.find_each do |account|
      account.avatar.destroy
      account.header.destroy
      account.save
    end
  end

  def userprofiles_past_retention_period
    orphaned_accounts = Account.unscoped.remote.where(Account.arel_table[:last_webfingered_at].lt(@retention_period.ago))
    .joins(:account_stat)
    .where("account_stats.followers_count": 0, "account_stats.following_count": 0)
    
    orphaned_accounts.where.not(avatar_file_name: nil).or(orphaned_accounts.where.not(header_file_name: nil))
  end

  def retention_period?
    @retention_period.present?
  end
end
