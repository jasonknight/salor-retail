class Ability
  def initialize(user)
    can :manage, :all if user.is_owner?
    can :read, :all
  end
end
