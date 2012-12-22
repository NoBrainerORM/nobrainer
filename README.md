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

```ruby
NoBrainer.connect "rethinkdb://host:port/database"


class Model < NoBrainer::Base
  field :field1
  field :field2
  field :field3
end


doc = BasicModel.create(:field1 => 'hello')
doc = BasicModel.find(doc.id)
doc.field1.should == 'hello'

doc.field1 = 'ohai'
doc.field2 = ':)'
doc.save

doc = BasicModel.find(doc.id)
doc.field1.should == 'ohai'
doc.field2.should == ':)'
```

License
--------

MIT License
