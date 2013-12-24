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


# Configuring NoBrainer is typically done in an initializer.
# The defaults are shown when using a Rails app:
NoBrainer.configure do |config|
  config.rethinkdb_url           = "rethinkdb://localhost/#{Rails.app.name}_#{Rails.env}"
  config.logger                  = Rails.logger
  config.warn_on_active_record   = true
  config.auto_create_databases   = true
  config.auto_create_tables      = true
  config.cache_documents         = true
  config.auto_include_timestamps = true
  config.max_reconnection_tries  = 10
  config.include_root_in_json    = false
end

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

puts Comment.create(:post => post, :author => 'dude').
  errors.full_messages == ["Body can't be blank"]

Comment.create(:post => post, :author => 'dude', :body => 'burp')
Comment.create(:post => post, :author => 'dude', :body => 'wut')
Comment.create(:post => post, :author => 'joe',  :body => 'sir')
Comment.all.each { |comment| puts comment.body }

post.comments.where(:author => 'dude').destroy
puts post.comments.count == 1

# Handles Regex as a condition
Comment.create(:post => post, :author => 'dude', :body => 'hello')
Comment.create(:post => post, :author => 'dude', :body => 'ohai')

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
  index :full_name_lambda, ->(doc){ doc['first_name'] + "_" + doc['last_name'] }
end

# Index creation on the database.
# It will also drop indexes that are no longer declared.
NoBrainer.update_indexes # can also use rake db:update_indexes

Person.create(:first_name => 'John', :last_name => 'Doe', :job => 'none')

Person.where(:job => 'none') # Implicitely use the job index
Person.without_index.where(:job => 'none') # Not using the job index

Person.where(:full_name => ['John', 'Doe']) # Using the compound index
Person.where(:first_name => 'John', :last_name => 'Doe') # Implicitely using the compound index
Person.without_index.where(:first_name => 'John', :last_name => 'Doe') # Not using the comound index

Person.where(:full_name_lambda => 'John_Doe') # Using the compound index

# You can use .use_index(:index_name) to force NoBrainer to use a specific index
# in case multiple indexes could be used. An error will be raised if the index
# cannot be used.

# Indexes are also autmatically used in order_by() queries, but won't figure out
# what compound index to use, it's your job to pass the name of the index if desired.

# Multi tenancy support:
# 1) Globally switch database with:
NoBrainer.with_database('db_name') do
  ...
end
# 2) Per model database/table name usage:
Model.store_in :database => ->{ 'db_name' }, :table => ->{ 'table_name' }

# Eager Loading:
# Support nested relations. Example with an author that has many posts which
# have many comments and categories:
author.includes(:posts => [:comments, :categories])

# If you want to provide additional rules, you may use criteria.
# Note that the default scopes are used by default.
# You may use .unscoped to get rid of them.
author.includes(:posts => Post.order_by(:created_at).includes(
                  :comments, :categories => Category.where(:tags.in => ['fun', 'stuff'])))

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
* Multi tenancy (global, and per model)
* Eager loading with `includes`

Contributors
------------

- [Toby Marsden](https://github.com/tobymarsden)
- [Andy Selvig](https://github.com/ajselvig)

License
--------

See [`LICENSE.md`](https://github.com/nviennot/nobrainer/blob/master/LICENSE.md).
