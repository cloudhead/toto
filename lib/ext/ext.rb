class Object
  def meta_def name, &blk
    (class << self; self; end).instance_eval do
      define_method(name, &blk)
    end
  end
end

class String
  def slugize
    self.downcase.gsub(/&/, 'and').gsub(/\s+/, '-').gsub(/[^a-z0-9-]/, '')
  end

  def humanize
    self.capitalize.gsub(/[-_]+/, ' ')
  end
end

class Fixnum
  def ordinal
    # 1 => 1st
    # 2 => 2nd
    # 3 => 3rd
    # ...
    case self % 100
      when 11..13; "#{self}th"
    else
      case self % 10
        when 1; "#{self}st"
        when 2; "#{self}nd"
        when 3; "#{self}rd"
        else    "#{self}th"
      end
    end
  end
end

class Date
  # This check is for people running Toto with ActiveSupport, avoid a collision
  unless respond_to? :iso8601
    # Return the date as a String formatted according to ISO 8601.
    def iso8601
      ::Time.utc(year, month, day, 0, 0, 0, 0).iso8601
    end
  end
end
