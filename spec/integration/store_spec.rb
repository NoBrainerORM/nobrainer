# frozen_string_literal: true

require 'spec_helper'

describe 'store' do
  before { load_store_accessor_document }
  let(:john) do
    AdminUser.create!(
      name: 'John Doe', color: 'black', remember_login: true,
      height: 'tall', is_a_good_guy: true,
      parent_name: 'Quinn', partner_name: 'Dallas',
      partner_birthday: '1997-11-1'
    )
  end

  it 'reads the store attributes through accessors' do
    expect(john.color).to eql('black')
    expect(john.homepage).to be_nil
  end

  it 'writes the store attributes through accessors' do
    john.color = 'red'
    john.homepage = '37signals.com'

    expect(john.color).to eql('red')
    expect(john.homepage).to eql('37signals.com')
  end

  it 'reading store attributes through accessors with prefix' do
    expect(john.parent_name).to eql('Quinn')
    expect(john.parent_birthday).to be_nil
    expect(john.partner_name).to eql('Dallas')
    expect(john.partner_birthday).to eql('1997-11-1')
  end

  it 'writing store attributes through accessors with prefix' do
    john.partner_name = 'River'
    john.partner_birthday = '1999-2-11'

    expect(john.partner_name).to eql('River')
    expect(john.partner_birthday).to eql('1999-2-11')
  end

  it 'accessing attributes not exposed by accessors' do
    john.settings[:icecream] = 'graeters'
    john.save

    expect(john.reload.settings[:icecream]).to eql('graeters')
  end

  it 'overriding a read accessor' do
    john.settings[:phone_number] = '1234567890'

    expect(john.phone_number).to eql('(123) 456-7890')
  end

  it 'overriding a read accessor using super' do
    john.settings[:color] = nil

    expect(john.color).to eql('red')
  end

  it 'updating the store will mark it as changed' do
    john.color = 'red'

    expect(john.settings_changed?).to be_truthy
  end

  it 'updating the store populates the changed array correctly' do
    john.color = 'red'

    expect(john.settings_change[0]['color']).to eql('black')
    expect(john.settings_change[1]['color']).to eql('red')
  end

  it "updating the store won't mark it as changed if an attribute isn't changed" do
    john.color = john.color

    expect(john.settings_changed?).to be_falsy
  end

  it 'updating the store will mark accessor as changed' do
    john.color = 'red'

    expect(john.color_changed?).to be_truthy
  end

  it 'new record and no accessors changes' do
    user = AdminUser.new
    expect(user.color_changed?).to be_falsy
    expect(user.color_was).to be_nil
    expect(user.color_change).to eql([nil, nil])

    user.color = 'red'
    expect(user.color_changed?).to be_truthy
    expect(user.color_was).to be_nil
    expect(user.color_change[1]).to eql('red')
  end

  it "updating the store won't mark accessor as changed if the whole store was updated" do
    john.settings = { color: john.color, some: 'thing' }

    expect(john.settings_changed?).to be_truthy
    expect(john.color_changed?).to be_falsy
  end

  it 'updating the store populates the accessor changed array correctly' do
    john.color = 'red'

    expect(john.color_was).to eql('black')
    expect(john.color_change[0]).to eql('black')
    expect(john.color_change[1]).to eql('red')
  end

  it "updating the store won't mark accessor as changed if the value isn't changed" do
    john.color = john.color

    expect(john.color_changed?).to be_falsy
  end

  it 'nullifying the store mark accessor as changed' do
    color = john.color
    john.settings = nil

    expect(john.color_changed?).to be_truthy
    expect(john.color_was).to eql(color)
    expect(john.color_change).to eql([color, nil])
  end

  it 'dirty methods for suffixed accessors' do
    john.configs[:two_factor_auth] = true

    expect(john.two_factor_auth_configs_changed?).to be_truthy
    expect(john.two_factor_auth_configs_was).to be_nil
    expect(john.two_factor_auth_configs_change).to eql([nil, true])
  end

  it 'dirty methods for prefixed accessors' do
    john.spouse[:name] = 'Lena'

    expect(john.partner_name_changed?).to be_truthy
    expect(john.partner_name_was).to eql('Dallas')
    expect(john.partner_name_change).to eql(%w[Dallas Lena])
  end

  # NoBrainer doesn't have `attribute_will_change!` so those methods
  # can't be implemented yet.
  # See https://github.com/NoBrainerORM/nobrainer/pull/190
  #
  # it 'saved changes tracking for accessors' do
  #   john.spouse[:name] = 'Lena'
  #   expect(john.partner_name_changed?).to be_truthy
  #
  #   john.save!
  #
  #   expect(john.partner_name_change).to be_falsy
  #   expect(john.saved_change_to_partner_name?).to be_truthy
  #   expect(john.saved_change_to_partner_name).to eql(%w[Dallas Lena])
  #   expect(john.partner_name_before_last_save).to eql('Dallas')
  # end

  it 'object initialization with not nullable column' do
    expect(john.remember_login).to be_truthy
  end

  it 'writing with not nullable column' do
    john.remember_login = false

    expect(john.remember_login).to be_falsy
  end

  it 'overriding a write accessor' do
    john.phone_number = '(123) 456-7890'

    expect(john.settings[:phone_number]).to eql('1234567890')
  end

  it 'overriding a write accessor using super' do
    john.color = 'yellow'

    expect(john.color).to eql('blue')
  end

  it 'preserve store attributes data in HashWithIndifferentAccess format without any conversion' do
    john.json_data = ActiveSupport::HashWithIndifferentAccess.new(:height => 'tall', 'weight' => 'heavy')
    john.height = 'low'

    expect(john.json_data.instance_of?(ActiveSupport::HashWithIndifferentAccess)).to be_truthy
    expect(john.json_data[:height]).to eql('low')
    expect(john.json_data['height']).to eql('low')
    expect(john.json_data[:weight]).to eql('heavy')
    expect(john.json_data['weight']).to eql('heavy')
  end

  it 'convert store attributes from Hash to HashWithIndifferentAccess saving the data and access attributes indifferently' do
    AdminUser.create!(name: 'Jamis', settings: {
      :symbol => 'symbol',
      "string" => 'string'
    })

    user = AdminUser.where(name: 'Jamis').first
    expect(user.settings[:symbol]).to eql('symbol')
    expect(user.settings['symbol']).to eql('symbol')
    expect(user.settings[:string]).to eql('string')
    expect(user.settings['string']).to eql('string')
    expect(user.settings.instance_of?(ActiveSupport::HashWithIndifferentAccess)).to be_truthy

    user.height = 'low'
    expect(user.settings[:symbol]).to eql('symbol')
    expect(user.settings['symbol']).to eql('symbol')
    expect(user.settings[:string]).to eql('string')
    expect(user.settings['string']).to eql('string')
    expect(user.settings.instance_of?(ActiveSupport::HashWithIndifferentAccess)).to be_truthy
  end

  it 'convert store attributes from any format other than Hash or HashWithIndifferentAccess losing the data' do
    john.json_data = 'somedata'
    john.height = 'low'

    expect(john.json_data.instance_of?(ActiveSupport::HashWithIndifferentAccess)).to be_truthy
    expect(john.json_data[:height]).to eql('low')
    expect(john.json_data['height']).to eql('low')
    expect(john.json_data.delete_if { |k, v| k == "height" }.any?).to be_falsy
  end

  it 'reading store attributes through accessors encoded with JSON' do
    expect(john.height).to eql('tall')
    expect(john.weight).to be_nil
  end

  it 'writing store attributes through accessors encoded with JSON' do
    john.height = 'short'
    john.weight = 'heavy'

    expect(john.height).to eql('short')
    expect(john.weight).to eql('heavy')
  end

  it 'accessing attributes not exposed by accessors encoded with JSON' do
    john.json_data['somestuff'] = 'somecoolstuff'
    john.save

    expect(john.reload.json_data["somestuff"]).to eql('somecoolstuff')
  end

  it 'updating the store will mark it as changed encoded with JSON' do
    john.height = 'short'

    expect(john.json_data_changed?).to be_truthy
  end

  it 'object initialization with not nullable column encoded with JSON' do
    expect(john.is_a_good_guy).to be_truthy
  end

  it 'writing with not nullable column encoded with JSON' do
    john.is_a_good_guy = false

    expect(john.is_a_good_guy).to be_falsy
  end

  it 'all stored attributes are returned' do
    expect(AdminUser.stored_attributes[:settings]).to eql(%i[color homepage favorite_food])
  end

  it 'stored_attributes are tracked per class' do
    define_class :FirstModel do
      include NoBrainer::Document

      store_accessor :data, :color
    end
    define_class :SecondModel do
      include NoBrainer::Document

      store_accessor :data, :width, :height
    end

    expect(FirstModel.stored_attributes[:data]).to eql([:color])
    expect(SecondModel.stored_attributes[:data]).to eql(%i[width height])
  end

  it 'stored_attributes are tracked per subclass' do
    define_class :FirstModel do
      include NoBrainer::Document

      store_accessor :data, :color
    end

    define_class :SecondModel, FirstModel do
      include NoBrainer::Document

      store_accessor :data, :width, :height
    end

    define_class :ThirdModel, FirstModel do
      include NoBrainer::Document

      store_accessor :data, :area, :volume
    end

    expect(FirstModel.stored_attributes[:data]).to eql([:color])
    expect(SecondModel.stored_attributes[:data]).to eql(%i[color width height])
    expect(ThirdModel.stored_attributes[:data]).to eql(%i[color area volume])
  end

  it 'YAML coder initializes the store when a Nil value is given' do
    expect(john.params).to eql({})
  end

  it 'dump, load and dump again a model' do
    dumped = YAML.dump(john)
    loaded = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(dumped) : YAML.load(dumped)
    expect(john).to eql(loaded)

    second_dump = YAML.dump(loaded)
    second_loaded = YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(second_dump) : YAML.load(second_dump)
    expect(john).to eql(second_loaded)
  end

  it 'read store attributes through accessors with default suffix' do
    john.configs[:two_factor_auth] = true

    expect(john.two_factor_auth_configs).to be_truthy
  end

  it 'write store attributes through accessors with default suffix' do
    john.two_factor_auth_configs = false

    expect(john.configs[:two_factor_auth]).to be_falsy
  end

  it 'read store attributes through accessors with custom suffix' do
    john.configs[:login_retry] = 3

    expect(john.login_retry_config).to eql(3)
  end

  it 'write store attributes through accessors with custom suffix' do
    john.login_retry_config = 5

    expect(john.configs[:login_retry]).to eql(5)
  end

  it 'read accessor without pre/suffix in the same store as other pre/suffixed accessors still works' do
    john.configs[:secret_question] = 'What is your high school?'

    expect(john.secret_question).to eql('What is your high school?')
  end

  it 'write accessor without pre/suffix in the same store as other pre/suffixed accessors still works' do
    john.secret_question = 'What was the Rails version when you first worked on it?'

    expect(john.configs[:secret_question]).to eql('What was the Rails version when you first worked on it?')
  end

  it 'prefix/suffix do not affect stored attributes' do
    expect(AdminUser.stored_attributes[:configs]).to eql(%i[secret_question two_factor_auth login_retry])
  end
end
