module UseCases
  class DeleteInactiveUnconfirmed
    def self.execute(inactive_period)
      User
        .unconfirmed
        .where("created_at < ?", Time.zone.now - inactive_period)
        .includes(:mous)
        .find_each(&:destroy)
    end
  end
end
