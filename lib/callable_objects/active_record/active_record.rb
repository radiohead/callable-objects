class ActiveRecord::Base
  # Coercion for virtus:
  # https://github.com/solnic/virtus#custom-coercions
  def self.coercer
    @coercer ||= Virtus::ActiveRecordAttribute.generate_for(self)
  end
end
