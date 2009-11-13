class Object
  def meta_def name, &blk
    (class << self; self; end).instance_eval do
      define_method(name, &blk)
    end
  end
end

class Fixnum
  def ordinal number
    # 1 => 1st
    # 2 => 2nd
    # 3 => 3rd
    # ...
    number = number.to_i
    case number % 100
      when 11..13; "#{number}th"
    else
      case number % 10
        when 1; "#{number}st"
        when 2; "#{number}nd"
        when 3; "#{number}rd"
        else    "#{number}th"
      end
    end
  end
end
