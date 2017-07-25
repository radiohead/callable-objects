class VirtusDataModel < SimpleDelegator
  include Virtus.model

  attribute :record

  def initialize(*args)
    super
    __setobj__(record)
  end

  def reload
    self.record = record.reload
    self
  end
end
