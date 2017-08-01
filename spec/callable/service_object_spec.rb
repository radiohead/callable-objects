require 'spec_helper'

RSpec.describe Callable::ServiceObject do
  context 'With simple math service' do
    let(:negative_error) { 'Can only multiply positive numbers!' }
    let(:odd_error)      { 'Can only square even numbers!' }

    before do
      module Test
        class SimpleMathService < Callable::ServiceObject
          attribute :left,  Types::Int
          attribute :right, Types::Int

          process(:multiply).
            process(:square)

          private

          def multiply(left, right)
            if left > 0 && right > 0
              Right(left * right)
            else
              Left(negative_error)
            end
          end

          def square(number)
            if number.even?
              Right(number ** 2)
            else
              Left(odd_error)
            end
          end
        end
      end
    end

    after { Test.send(:remove_const, :SimpleMathService) }

    subject { Test::SimpleMathService.call(left: left, right: right) }

    context 'With positive even numbers' do
      let(:left)  { 2 }
      let(:right) { 4 }

      it { is_expected.to be_a(Right) }
      it { is_expected.to eq((left * right) ** 2) }
    end

    context 'With positive odd numbers' do
      let(:left)  { 3 }
      let(:right) { 5 }

      it { is_expected.to be_a(Left) }
      it { is_expected.to eq(odd_error) }
    end

    context 'With negative numbers' do
      let(:left)  { -1 }
      let(:right) { -2 }

      it { is_expected.to be_a(Left) }
      it { is_expected.to eq(negative_error) }
    end
  end
end
