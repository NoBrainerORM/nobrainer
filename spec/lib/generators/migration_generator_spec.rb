# frozen_string_literal: true

require 'spec_helper'

require 'generator_spec'
require 'rails/generators/nobrainer/migration_generator'

describe NoBrainer::Generators::MigrationGenerator do
  SCRIPT_NAME = 'MigrateMyBeautifulDataNow'

  destination File.expand_path('../tmp', __dir__)
  arguments [SCRIPT_NAME]

  let(:formatted_time) { time_current.strftime('%Y%m%d%H%M%S') }
  let(:snake_case_script_name) { SCRIPT_NAME.underscore }
  let(:time_current) { Time.current }

  before do
    allow(Time).to receive(:current).and_return(time_current)

    prepare_destination
    run_generator
  end

  it 'creates a new file in the db/migrate' do
    assert_file "db/migrate/#{formatted_time}_#{snake_case_script_name}.rb",
                <<-SCRIPT
class #{SCRIPT_NAME} < NoBrainer::Migration
  def up
  end

  def down
  end
end
SCRIPT
  end
end
