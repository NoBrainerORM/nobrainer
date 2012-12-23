No Brainer
===========

No Brainer is a Ruby ORM for [RethinkDB](http://www.rethinkdb.com/).

Installation
-------------

```ruby
gem 'nobrainer'
```

Features
---------

* creation of database and tables on demand
* find/create/save/update_attributes/destroy
* attributes accessors
* validatation, create, update, save, destroy callbacks
* validation support, expected behavior with save!, save, etc.
* where, order_by, skip, limit, first/last, each

Usage
------

```ruby
NoBrainer.connect "rethinkdb://host:port/database"

class Model < NoBrainer::Base
  field :field1
  field :field2
end

Model.create(:field1 => 'hello')
Model.create(:field1 => 'ohai')

Model.where(:field1 => 'ohai').count == 1
Model.all.map(&:field1) == ['hello', 'ohai']
Model.where(:field1 => 'hello').first.update_attributes(:field1 => 'ohai')
Model.where(:field1 => 'ohai').count == 2
```

License
--------

MIT License
