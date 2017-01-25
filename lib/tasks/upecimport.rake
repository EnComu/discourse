
require 'upecimport'

desc "[upec] Imports Categories, Subcategories and Topics from CSV"
task "upec:import_csv", [:filename] => [:environment] do |_,args|
  # Imports from CSV, params is filename
  # $ rake upec:import_csv["/path/to/textos_eix5.csv"]    
  #
  filename = args[:filename]
  UPeCImport.new(filename)
end
