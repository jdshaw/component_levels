require 'db/migrations/utils'

Sequel.migration do

  # as a pre-0.1 version of component_levels included a
  # 001 migration, add some placeholder migrations to ensure
  # the later migrations are run.

end