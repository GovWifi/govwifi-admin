module UseCases
  class DeleteInactiveUnconfirmed
    def self.execute(inactive_period)
      User.unconfirmed.where("created_at < ?", Time.zone.now - inactive_period).delete_all
    end
  end
end
