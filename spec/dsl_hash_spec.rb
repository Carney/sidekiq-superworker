require 'spec_helper'

describe Sidekiq::Superworker::DSLHash do
  include Sidekiq::Superworker::WorkerHelpers

  before :all do
    create_dummy_workers
    @dsl_hash = Sidekiq::Superworker::DSLHash.new
  end

  describe '.parse' do
    context 'batch superworker' do
      it 'returns the correct records' do
        block = proc do
          batch first_arguments: :first_argument do
            Worker1 :first_argument
            Worker2 :first_argument
          end
        end
        
        nested_hash = Sidekiq::Superworker::DSLParser.parse(block)
        args = {
          first_arguments: [10, 11, 12]
        }
        records = @dsl_hash.nested_hash_to_records(nested_hash, args)
        records.should ==
          {1=>
            {:subjob_id=>1,
             :subworker_class=>"batch",
             :arg_keys=>[{:first_arguments=>:first_argument}],
             :arg_values=>[{:first_arguments=>:first_argument}],
             :parent_id=>nil,
             :children_ids=>[2, 5, 8]},
           2=>
            {:subjob_id=>2,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>1},
           3=>
            {:subworker_class=>:Worker1,
             :arg_keys=>[:first_argument],
             :subjob_id=>3,
             :parent_id=>2,
             :arg_values=>[10],
             :next_id=>4},
           4=>
            {:subworker_class=>:Worker2,
             :arg_keys=>[:first_argument],
             :subjob_id=>4,
             :parent_id=>2,
             :arg_values=>[10]},
           5=>
            {:subjob_id=>5,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>1},
           6=>
            {:subworker_class=>:Worker1,
             :arg_keys=>[:first_argument],
             :subjob_id=>6,
             :parent_id=>5,
             :arg_values=>[11],
             :next_id=>7},
           7=>
            {:subworker_class=>:Worker2,
             :arg_keys=>[:first_argument],
             :subjob_id=>7,
             :parent_id=>5,
             :arg_values=>[11]},
           8=>
            {:subjob_id=>8,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[12],
             :parent_id=>1},
           9=>
            {:subworker_class=>:Worker1,
             :arg_keys=>[:first_argument],
             :subjob_id=>9,
             :parent_id=>8,
             :arg_values=>[12],
             :next_id=>10},
           10=>
            {:subworker_class=>:Worker2,
             :arg_keys=>[:first_argument],
             :subjob_id=>10,
             :parent_id=>8,
             :arg_values=>[12]}}
      end
    end

    context 'batch superworker with nested superworker' do
      it 'returns the correct nested hash' do
        Sidekiq::Superworker::Worker.create(:BatchNestedChildSuperworker, :first_argument) do
          Worker2 :first_argument do
            Worker3 :first_argument
          end
        end

        block = proc do
          batch first_arguments: :first_argument do
            BatchNestedChildSuperworker :first_argument
          end
        end
        
        nested_hash = Sidekiq::Superworker::DSLParser.parse(block)

        args = {
          first_arguments: [10, 11]
        }
        records = @dsl_hash.nested_hash_to_records(nested_hash, args)
        records.should ==
          {1=>
            {:subjob_id=>1,
             :subworker_class=>"batch",
             :arg_keys=>[{:first_arguments=>:first_argument}],
             :arg_values=>[{:first_arguments=>:first_argument}],
             :parent_id=>nil,
             :children_ids=>[2, 6]},
           2=>
            {:subjob_id=>2,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>1},
           3=>
            {:subworker_class=>:BatchNestedChildSuperworker,
             :arg_keys=>[:first_argument],
             :subjob_id=>3,
             :parent_id=>2,
             :arg_values=>[10],
             :children_ids=>[4]},
           4=>
            {:subjob_id=>4,
             :subworker_class=>"Worker2",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>3,
             :children_ids=>[5]},
           5=>
            {:subjob_id=>5,
             :subworker_class=>"Worker3",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>4},
           6=>
            {:subjob_id=>6,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>1},
           7=>
            {:subworker_class=>:BatchNestedChildSuperworker,
             :arg_keys=>[:first_argument],
             :subjob_id=>7,
             :parent_id=>6,
             :arg_values=>[11],
             :children_ids=>[8]},
           8=>
            {:subjob_id=>8,
             :subworker_class=>"Worker2",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>7,
             :children_ids=>[9]},
           9=>
            {:subjob_id=>9,
             :subworker_class=>"Worker3",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>8}}
      end
    end

    context 'batch superworker with nested superworker and worker' do
      it 'returns the correct nested hash' do
        Sidekiq::Superworker::Worker.create(:BatchNestedChildSuperworker, :first_argument) do
          Worker2 :first_argument do
            Worker3 :first_argument
          end
        end

        block = proc do
          batch first_arguments: :first_argument do
            BatchNestedChildSuperworker :first_argument
            Worker1 :first_argument
          end
        end
        
        nested_hash = Sidekiq::Superworker::DSLParser.parse(block)

        args = {
          first_arguments: [10, 11]
        }
        records = @dsl_hash.nested_hash_to_records(nested_hash, args)
        records.should ==
          {1=>
            {:subjob_id=>1,
             :subworker_class=>"batch",
             :arg_keys=>[{:first_arguments=>:first_argument}],
             :arg_values=>[{:first_arguments=>:first_argument}],
             :parent_id=>nil,
             :children_ids=>[2, 7]},
           2=>
            {:subjob_id=>2,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>1},
           3=>
            {:subworker_class=>:BatchNestedChildSuperworker,
             :arg_keys=>[:first_argument],
             :subjob_id=>3,
             :parent_id=>2,
             :arg_values=>[10],
             :children_ids=>[4],
             :next_id=>6},
           4=>
            {:subjob_id=>4,
             :subworker_class=>"Worker2",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>3,
             :children_ids=>[5]},
           5=>
            {:subjob_id=>5,
             :subworker_class=>"Worker3",
             :arg_keys=>[:first_argument],
             :arg_values=>[10],
             :parent_id=>4},
           6=>
            {:subworker_class=>:Worker1,
             :arg_keys=>[:first_argument],
             :subjob_id=>6,
             :parent_id=>2,
             :arg_values=>[10]},
           7=>
            {:subjob_id=>7,
             :subworker_class=>"batch_child",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>1},
           8=>
            {:subworker_class=>:BatchNestedChildSuperworker,
             :arg_keys=>[:first_argument],
             :subjob_id=>8,
             :parent_id=>7,
             :arg_values=>[11],
             :children_ids=>[9],
             :next_id=>11},
           9=>
            {:subjob_id=>9,
             :subworker_class=>"Worker2",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>8,
             :children_ids=>[10]},
           10=>
            {:subjob_id=>10,
             :subworker_class=>"Worker3",
             :arg_keys=>[:first_argument],
             :arg_values=>[11],
             :parent_id=>9},
           11=>
            {:subworker_class=>:Worker1,
             :arg_keys=>[:first_argument],
             :subjob_id=>11,
             :parent_id=>7,
             :arg_values=>[11]}}
      end
    end
  end
end
