require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:accession].update(:system_mtime => Time.now)
    self[:resource].update(:system_mtime => Time.now)
    self[:archival_object].update(:system_mtime => Time.now)
  end

end