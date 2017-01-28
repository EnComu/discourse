
require 'upecimport'

desc "[upec] Imports Categories, Subcategories and Topics from CSV"
task "upec:import_csv", [:filename] => [:environment] do |_,args|
  # Imports from CSV, params is filename
  # $ rake upec:import_csv["/path/to/textos_eix5.csv"]    
  #
  filename = args[:filename]
  UPeCImport.new(filename)
end


desc "[upec] WARNING! Delete all DB"
task "upec:delete_db" => [:environment] do
  # Delete all database Topics, Posts and Categories, for testing purposes
  # $ rake upec:delete_db
  #
  UPeCImport.delete_db
end
