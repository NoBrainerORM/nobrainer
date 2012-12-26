No Brainer
===========

No Brainer is a Ruby ORM for [RethinkDB](http://www.rethinkdb.com/).

Installation
-------------

```ruby
gem 'nobrainer'
```

Usage Example
--------------

Here is a quick example of what NoBrainer can do:

```ruby
#!/usr/bin/env ruby
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
```

Features
---------

* creation of database and tables on demand
* find/create/save/update_attributes/destroy. XXX find vs find!
* attributes accessors
* validation support, expected behavior with save!, save, etc (todo: uniqueness validation)
* validatation, create, update, save, destroy callbacks
* where, order_by, skip, limit, each
* update, inc, dec
* belongs_to, has_many
* to_json, to_xml
* attr_protected.
* rails3 compatible

License
--------

MIT License
