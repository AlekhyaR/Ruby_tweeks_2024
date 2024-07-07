#nullify blanks 
# Do you remember Rails nilify_blanks gem? With Rails 7.1 `ActiveRecord::Base::normalizes` you can get similar results out of the box.

class ApplicationRecord > ActiveRecord::Base
  primary_abstract_class

  def self.nillify_blanks(*columns)
    normalizes *columns, with: -> (value) { value.strip.presence }
  end
end

class Inventory < ApplicationRecord
  nillify_blanks :barcode_data, :barcode_data_replacement
end

# here we used lambda function, -> (value) { value.strip.presence }
# The ApplicationRecord class provides a method nillify_blanks which can be used by any subclass to automatically convert blank values to nil for specified columns. The Inventory class uses this method to 
# ensure that any blank values in its barcode_data or barcode_data_replacement fields are normalized to nil. This helps maintain data consistency and integrity by avoiding storing blank strings in the database.

Similar example 

normalizes :first_name, with: ->(value) { value.capitalize }
normalizes :last_name, with: ->(value) { value.capitalize }

