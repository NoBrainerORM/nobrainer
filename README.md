No Brainer
===========

No Brainer is a Ruby ORM for [RethinkDB](http://www.rethinkdb.com/).

Installation
-------------

```ruby
gem 'nobrainer'
```

Usage
------

Here is a quick example of what NoBrainer can do:

```ruby
require 'nobrainer'

NoBrainer.connect 'rethinkdb://localhost/blog'

class Post
  include NoBrainer::Document

  field :title
  field :body

  has_many :comments

  validates :title, :body, :presence => true
end

class Comment
  include NoBrainer::Document

  field :author
  field :body

  belongs_to :post

  validates :author, :body, :post, :presence => true

  after_create do
    puts "#{author} commented on #{post.title}"
  end
end

NoBrainer.purge!

post = Post.create!(:title => 'ohai', :body  => 'yummy')

puts post.comments.create(:author => 'dude').
  errors.full_messages == ["Body can't be blank"]

post.comments.create(:author => 'dude', :body => 'burp')
post.comments.create(:author => 'dude', :body => 'wut')
post.comments.create(:author => 'joe',  :body => 'sir')
Comment.all.each { |comment| puts comment.body }

post.comments.where(:author => 'dude').destroy
puts post.comments.count == 1

# Handles Regex as a condition
post.comments.create(:author => 'dude', :body => 'hello')
post.comments.create(:author => 'dude', :body => 'ohai')

post.comments.where(:body => /^h/).map{|comment| comment.body } # => ["hello"]
post.comments.where(:body => /h/).map{|comment| comment.body } # => ["ohai", "hello"]

# Supports dynamic attributes.
# Not explicitly defined field can be accessed with [] and []=
class Animal
  include NoBrainer::Document
  include NoBrainer::Document::DynamicAttributes

  field :name
end

fido = Animal.create!(name: 'Fido', kind: 'Dog')
fido.name
 => 'Fido'
fido['kind']
 => 'Dog'
fido['kind'] = 'Sheepdog'
 => 'Sheepdog'

# Supports complex where queries
# Ranges
Model.where(:field.lt => 5)
Model.where(:field.gt => 5)
Model.where(:field => (3..8))
Model.where(:field.not => (3..8))
# Inclusions
Model.where(:field.in => ['hello', /^ohai/])
# Booleans
Model.where(:or => [{:field1 => 'hello'}, {:field2 => 'ohai'}])
# Arbitrary RethinkDB lambdas
Model.where { |doc| (doc[:field1] + doc[:field2]).eq(3) }

# Indexes

class Person
  field :first_name
  field :last_name
  field :job, :index => true # Single field index

  # Single field index alternate syntax
  index :job

  # Compound Indexes
  index :full_name, [:first_name, :last_name]

  # Arbitrary Indexes
  index :full_name2, ->(doc){ doc['first_name'] + "_" + doc['last_name'] }
end

# Index creation on the database.
# It will also drop indexes that are no longer declared.
NoBrainer.update_indexes # can also use rake db:update_indexes

Person.create(:first_name => 'John', :last_name => 'Doe', :job => 'none')

Person.indexed_where(:job => 'none') # Explicitely use the job index
Person.where(:job => 'none') # Implicitely use the job index
Person.without_index.where(:job => 'none') # Not using the job index

Person.indexed_where(:full_name => ['John', 'Doe']) # Explicitely using the compound index
Person.where(:first_name => 'John', :last_name => 'Doe') # Implicitely using the compound index
Person.without_index.where(:first_name => 'John', :last_name => 'Doe') # Not using the comound index

Person.indexed_where(:full_name2 => 'John_Doe') # Using the custom index
```

Features
---------

* Compatible with Rails 3 and Rails 4
* Autogeneration of ID, MongoDB style
* Creation of database and tables on demand
* Validation support, expected behavior with `save!`, `save`, etc.
* validation, create, update, save, and destroy callbacks.
* `find`, `find!`, `create`, `save`, `update_attributes`, `destroy`
* `where`, `order_by`, `skip`, `limit`, `each`
* `update`, `inc`, `dec`
* `belongs_to`, `has_many`
* `to_json`, `to_xml`
* `attr_protected`
* Scopes
* Thread-safe
* Polymorphism
* Dirty tracking
* Secondary indexes + transparent usage of indexes when using where()

Contributors
------------

- [Toby Marsden](https://github.com/tobymarsden)
- [Andy Selvig](https://github.com/ajselvig)

License
--------

See [`LICENSE.md`](https://github.com/nviennot/nobrainer/blob/master/LICENSE.md).
