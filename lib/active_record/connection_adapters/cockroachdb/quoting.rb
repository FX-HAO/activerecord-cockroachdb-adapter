module ActiveRecord
  module ConnectionAdapters
    module CockroachDB
      module Quoting
        private

        # CockroachDB does not allow inserting integer values into string
        # columns, but ActiveRecord expects this to work. CockroachDB will
        # however allow inserting string values into integer columns. It will
        # try to parse string values and convert them to integers so they can be
        # inserted in integer columns.
        #
        # We take advantage of this behavior here by forcing numeric values to
        # always be strings. Then, we won't have to make any additional changes
        # to ActiveRecord to support inserting integer values into string
        # columns.
        #
        # For spatial types, data is stored as Well-known Binary (WKB) strings
        # (https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry#Well-known_binary)
        # but when creating objects, using RGeo features is more convenient than
        # converting to WKB, so this does it automatically.
        def _quote(value)
          case value
          when Numeric
            "'#{quote_string(value.to_s)}'"
          when RGeo::Feature::Geometry
            "'#{RGeo::WKRep::WKBGenerator.new(hex_format: true, type_format: :ewkb, emit_ewkb_srid: true).generate(value)}'"
          when RGeo::Cartesian::BoundingBox
            "'#{value.min_x},#{value.min_y},#{value.max_x},#{value.max_y}'::box"
          else
            super
          end
        end
      end
    end
  end
end
