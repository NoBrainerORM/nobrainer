require 'spec_helper'

describe 'module lookup' do
  context 'when both models are in the same module' do
    before do
      define_class('ModuleA::User') do
        include NoBrainer::Document
        has_many :posts
        has_one :post
      end

      define_class('ModuleA::Post') do
        include NoBrainer::Document
        belongs_to :user
      end
    end

    it 'should lookup the target model in the module' do
      ModuleA::User.association_metadata[:posts].target_model.should == ModuleA::Post
      ModuleA::User.association_metadata[:post].target_model.should == ModuleA::Post
      ModuleA::Post.association_metadata[:user].target_model.should == ModuleA::User
    end
  end

  context 'when models are in different modules, with one in the top level' do
    before do
      define_class('User') do
        include NoBrainer::Document
        has_many :posts, :class_name => 'ModuleA::Post'
        has_one :post, :class_name => 'ModuleA::Post'
      end

      define_class('ModuleA::Post') do
        include NoBrainer::Document
        belongs_to :user
      end
    end

    it 'should lookup the target model in the module' do
      User.association_metadata[:posts].target_model.should == ModuleA::Post
      User.association_metadata[:post].target_model.should == ModuleA::Post
      ModuleA::Post.association_metadata[:user].target_model.should == User
    end
  end
end
