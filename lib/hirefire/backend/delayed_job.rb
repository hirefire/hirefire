module HireFire
  module Backend
    module DelayedJob
      autoload :ActiveRecord,  'hirefire/backend/delayed_job/active_record'
      autoload :ActiveRecord2, 'hirefire/backend/delayed_job/active_record_2'
      autoload :Mongoid,       'hirefire/backend/delayed_job/mongoid'
    end
  end
end
