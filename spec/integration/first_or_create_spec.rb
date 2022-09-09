# frozen_string_literal: true

require 'spec_helper'

describe 'first_or_create' do
  before do
    load_simple_document

    SimpleDocument.field(:field1, unique: true)
  end

  context 'when the arguments are targeting an existing document' do
    let!(:existing_doc) { SimpleDocument.create(field1: 1) }

    it 'returns the document' do
      SimpleDocument.where(field1: 1).first_or_create.should eql existing_doc
      SimpleDocument.count.should eql 1
      SimpleDocument.where(field1: 2).first_or_create.should eql SimpleDocument.last
      SimpleDocument.count.should eql 2
      SimpleDocument.where(field1: 2).first_or_create.should eql SimpleDocument.last
      SimpleDocument.count.should eql 2
    end
  end

  shared_examples_for 'failed first_or_create' do
    it 'fails' do
      expect { query }.to raise_error(err_msg)
    end
  end

  context 'when the where() clause is invalid' do
    let(:err_msg) { /Please use a query of the form/ }

    context 'due to a missing where()' do
      let(:query) { SimpleDocument.first_or_create }

      it_behaves_like 'failed first_or_create'
    end

    context 'due to an empty where()' do
      let(:query) { SimpleDocument.where({}).first_or_create }
      let(:err_msg) { /Missing.*clauses/ }

      it_behaves_like 'failed first_or_create'
    end

    context 'due to a non :and clause' do
      let(:query) { SimpleDocument.where(or: [{ field1: 1 }, { field1: 2 }]).first_or_create }

      it_behaves_like 'failed first_or_create'
    end

    context 'due to a non scalar query' do
      let(:query) { SimpleDocument.where(:field1.any => 'xx').first_or_create }
      let(:err_msg) { /only use equal/ }

      it_behaves_like 'failed first_or_create'
    end

    context 'due to a non eq query' do
      let(:query) { SimpleDocument.where(:field1.lt => 'xx').first_or_create }
      let(:err_msg) { /only use equal/ }

      it_behaves_like 'failed first_or_create'
    end

    context 'due to a nested hash query' do
      let(:query) { SimpleDocument.where(field1: { xx: 'xx' }).first_or_create }
      let(:err_msg) { /You may not use nested hash/ }

      it_behaves_like 'failed first_or_create'
    end
  end

  context 'when matching params between the where clause and the create params' do
    context 'when some keys are equal' do
      it 'works' do
        SimpleDocument.where(field1: 123).first_or_create(field1: 123)
        SimpleDocument.count.should eql 1
      end
    end

    context 'when failing due to a conflict' do
      let(:query) { SimpleDocument.where(field1: 123).first_or_create(field1: 456) }
      let(:err_msg) { /conflicting values on the following keys: \[:field1\]/ }

      it_behaves_like 'failed first_or_create'
    end
  end

  context 'when passing arguments in the params block' do
    it 'raises' do
      expect do
        SimpleDocument.where(field1: 123).first_or_create { |doc| }
      end.to raise_error(/no argument/)
    end
  end

  context 'when matching a uniqueness validator' do
    before do
      SimpleDocument.field :field2, uniq: { scope: :field3 }
      SimpleDocument.field :field3, uniq: { scope: %i[field1 field2] }
      SimpleDocument.field :field4
    end

    context 'when failing to match a validator' do
      context 'due to a missing one-clause validator' do
        let(:query) { SimpleDocument.where(field2: 123).first_or_create }
        let(:err_msg) { /field :field2, :uniq => true/ }

        it_behaves_like 'failed first_or_create'
      end

      context 'due to a missing two-clause validator' do
        let(:query) { SimpleDocument.where(field1: 123, field2: 123).first_or_create }
        let(:err_msg) { /field :field1, :uniq => {:scope => :field2}/ }

        it_behaves_like 'failed first_or_create'
      end

      context 'due to a missing N-clause validator' do
        let(:query) { SimpleDocument.where(field1: 123, field2: 123, field4: 123).first_or_create }
        let(:err_msg) { /field :field1, :uniq => {:scope => \[:field2, :field4\]}/ }

        it_behaves_like 'failed first_or_create'
      end
    end

    context 'when getting matches' do
      it 'works' do
        SimpleDocument.where(field3: 123, field2: 123).first_or_create
        SimpleDocument.where(field3: 123, field2: 123, field1: 123).first_or_create
        SimpleDocument.where(SimpleDocument.pk_name => '123').first_or_create
        SimpleDocument.count.should eql 2
      end
    end
  end

  context 'when validations fail' do
    before { SimpleDocument.field :field2, required: true }

    context 'when using first_or_create' do
      it 'returns a failing document' do
        SimpleDocument.where(field1: 123).first_or_create.persisted?.should be_falsey
      end
    end

    context 'when using first_or_create!' do
      it 'raises' do
        expect { SimpleDocument.where(field1: 123).first_or_create! }
          .to raise_error(NoBrainer::Error::DocumentInvalid)
      end
    end
  end

  context 'when using polymorphism' do
    before do
      load_polymorphic_models
      Parent.field :parent_field, uniq: true
    end

    context 'when passing a _type in create_params' do
      it 'creates the child subtype' do
        doc = Parent.where(parent_field: 123).first_or_create(_type: :Child, child_field: 123)
        doc.should be_a(Child)
        doc.child_field.should eql 123
      end
    end

    context 'when passing a wrong _type in create_params' do
      it 'creates the child subtype' do
        expect { Parent.where(parent_field: 123).first_or_create(_type: :SimpleDocument) }
          .to raise_error(NoBrainer::Error::InvalidPolymorphicType)
      end
    end

    context 'when querying on a subclass with a field that belongs to the parent' do
      it 'raises' do
        expect { Child.where(parent_field: '123').first_or_create }
          .to raise_error(/defined on `Parent'.*Parent.where.*:_type => "Child"/m)
      end
    end

    context 'when querying on a subclass with a field that belongs to the subclass' do
      before { Child.field :child_field, uniq: true }

      it 'creates the child subtype' do
        doc = Child.where(child_field: 123).first_or_create
        doc.should be_a(Child)
        doc.child_field.should eql 123
      end
    end
  end

  context 'when using belongs_to polymorphic association' do
    before do
      load_belongs_to_polymorphic_models

      SimpleDocument.belongs_to(:picturable, polymorphic: true, uniq: true)

      NoBrainer.sync_indexes
    end

    let(:identified_person) { IdentifiedPerson.create! }
    let(:existing_doc) { SimpleDocument.create!(picturable: identified_person) }

    context 'when query do not match any existing documents' do
      it 'creates a new document' do
        expect do
          SimpleDocument.where(picturable: IdentifiedPerson.create!).first_or_create
        end.to change(SimpleDocument, :count).by 1
      end
    end

    context 'when querying existing documents' do
      it 'does not create a document' do
        SimpleDocument.create!(picturable: identified_person)

        expect { SimpleDocument.where(picturable: identified_person).first_or_create }
          .not_to(change(SimpleDocument, :count))
      end

      it 'returns existing documents' do
        expected = existing_doc
        expect(
          SimpleDocument.where(picturable: identified_person).first_or_create
        ).to eql(expected)
      end
    end
  end

  context 'when using upsert' do
    context 'when matching a uniqueness validator' do
      before do
        SimpleDocument.field :field2, uniq: { scope: :field3 }
        SimpleDocument.field :field3, uniq: { scope: %i[field1 field2] }
        SimpleDocument.field :field4
      end

      it 'creates documents' do
        SimpleDocument.upsert(field3: 123, field2: 123)
        SimpleDocument.upsert(field3: 123, field2: 123)
        SimpleDocument.count.should eql 1

        SimpleDocument.upsert(field3: 456, field2: 456, field1: 456)
        SimpleDocument.upsert(field3: 456, field2: 456, field1: 456)
        SimpleDocument.count.should eql 2

        SimpleDocument.upsert(SimpleDocument.pk_name => '123', field4: 123)
        SimpleDocument.upsert(SimpleDocument.pk_name => '123', field4: 123)
        SimpleDocument.count.should eql 3

        SimpleDocument.find('123').field4.should eql 123
      end

      it 'updates documents' do
        attrs = { field1: 123, field2: 123 }
        SimpleDocument.upsert(attrs)
        SimpleDocument.count.should eql 1
        SimpleDocument.first.attributes.symbolize_keys.slice(*attrs.keys).should eql attrs

        attrs = { field1: 123, field2: 456 }
        SimpleDocument.upsert(attrs)
        SimpleDocument.count.should eql 1
        SimpleDocument.first.attributes.symbolize_keys.slice(*attrs.keys).should eql attrs
      end
    end

    context 'when not matching a uniqueness validator' do
      it 'errors' do
        expect { SimpleDocument.upsert(field2: 123) }
          .to raise_error(/Could not find a uniqueness validator.*field2/)
        expect { SimpleDocument.upsert(field2: 123, field3: 123) }
          .to raise_error(/Could not find a uniqueness validator.*field2.*field3/)
      end

      context 'when validations fail' do
        before { SimpleDocument.field :field2, required: true }

        context 'when using upsert' do
          it 'returns a failing document' do
            SimpleDocument.upsert({}).persisted?.should be_falsey
          end
        end

        context 'when using upsert!' do
          it 'raises' do
            expect { SimpleDocument.upsert!({}) }
              .to raise_error(NoBrainer::Error::DocumentInvalid)
          end
        end
      end
    end

    context 'when matching a uniqueness validator with validations' do
      context 'when validations fail' do
        before { SimpleDocument.field :field2, required: true }

        context 'when using upsert' do
          it 'returns a failing document' do
            SimpleDocument.upsert(field1: 123).persisted?.should be_falsey
          end
        end

        context 'when using upsert!' do
          it 'raises' do
            expect { SimpleDocument.upsert!(field1: 123) }
              .to raise_error(NoBrainer::Error::DocumentInvalid)
          end
        end
      end
    end

    context 'when matching a uniqueness validator with a belongs_to' do
      before do
        load_blog_models
        Comment.belongs_to :post, uniq: true
      end

      let(:post) { Post.create }

      it 'upserts with model instances as foreign keys' do
        Comment.upsert(post: post)
        Comment.upsert(post: post)
        Comment.count.should eql 1
      end
    end
  end
end
