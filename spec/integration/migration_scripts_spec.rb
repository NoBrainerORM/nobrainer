# frozen_string_literal: true

require 'spec_helper'

describe NoBrainer::Migrator do
  let(:a_script_path) do
    File.join(File.expand_path('../tmp', __dir__), 'db', 'migrate',
              "#{Time.current.strftime('%Y%m%d%H%M%S')}_my_migration.rb")
  end
  let(:migrations_table_name) { NoBrainer::Migrator.migrations_table_name }
  let(:table_list) { NoBrainer.run(&:table_list) }
  let(:script_content) do
    <<-SCRIPT
    class MyMigration < NoBrainer::Migration
      def up
      end

      def down
      end
    end
    SCRIPT
  end

  before do
    FileUtils.mkdir_p(File.dirname(a_script_path))
    File.open(a_script_path, 'w') { |file| file.write(script_content) }

    # Prevents outputs
    allow_any_instance_of(described_class)
      .to receive(:announce).and_return(true)
  end

  context 'on first run' do
    context 'when running migrate' do
      before { described_class.new(a_script_path).migrate }

      it 'create the migrations table' do
        expect(table_list).to include migrations_table_name
      end
    end

    context 'when running rollback' do
      before { described_class.new(a_script_path).migrate }

      it 'create the migrations table' do
        expect(table_list).to include migrations_table_name
      end
    end
  end

  describe 'migrate' do
    let(:migrator) { described_class.new(a_script_path) }

    it 'checks the version from the migrations table' do
      expect(migrator).to receive(:check_if_version_exists?)

      migrator.migrate
    end

    it 'runs the script migrate! method' do
      require a_script_path
      expect_any_instance_of(MyMigration).to receive(:migrate!)

      migrator.migrate
    end

    context 'when the script has failed and have a down method' do
      before do
        require a_script_path
        expect_any_instance_of(MyMigration)
          .to receive(:up).and_raise('ERROR')
      end

      it "doesn't create the version" do
        expect(migrator).not_to receive(:create_version!)

        expect { migrator.migrate }.to raise_error('ERROR')
      end

      it 'runs the down method then raise the error' do
        expect_any_instance_of(MyMigration).to receive(:down)

        expect { migrator.migrate }.to raise_error('ERROR')
      end
    end

    context 'when the script has failed but do not have a down method' do
      before do
        require a_script_path
        allow_any_instance_of(MyMigration)
          .to receive(:respond_to?).with(:down).and_return(false)
        expect_any_instance_of(MyMigration)
          .to receive(:up).and_raise('ERROR')
      end

      it "doesn't create the version" do
        expect(migrator).not_to receive(:create_version!)

        expect { migrator.migrate }.to raise_error('ERROR')
      end

      it "doesn't run the down method but raises the error" do
        expect_any_instance_of(MyMigration).not_to receive(:down)

        expect { migrator.migrate }.to raise_error('ERROR')
      end
    end

    context 'when the script has succeeded' do
      before { require a_script_path }
      it 'runs the up method' do
        expect_any_instance_of(MyMigration).to receive(:up)

        migrator.migrate
      end

      it "doesn't run the down method" do
        expect_any_instance_of(MyMigration).not_to receive(:down)

        migrator.migrate
      end

      it 'creates the version' do
        expect(migrator).to receive(:create_version!)

        migrator.migrate
      end
    end

    context 'when executed twice' do
      before do
        allow(migrator).to receive(:check_if_version_exists?).and_return(true)
      end

      it "doesn't run the up method" do
        expect_any_instance_of(MyMigration).not_to receive(:up)

        migrator.migrate
      end
    end
  end

  describe 'rollback' do
    let(:migrator) { described_class.new(a_script_path) }

    context 'when the migration script has not being migrated yet' do
      it "doesn't run the script rollback! method" do
        require a_script_path
        expect_any_instance_of(MyMigration).not_to receive(:rollback!)

        migrator.rollback
      end
    end

    context 'when the migration script has not being migrated yet' do
      before { migrator.migrate }

      it 'checks the version from the migrations table' do
        expect(migrator).to receive(:check_if_version_exists?)

        migrator.rollback
      end

      it 'runs the script rollback! method' do
        require a_script_path
        expect_any_instance_of(MyMigration).to receive(:rollback!)

        migrator.rollback
      end

      context 'when the script do not have a down method' do
        before do
          require a_script_path
          allow_any_instance_of(MyMigration)
            .to receive(:respond_to?).with(:down).and_return(false)
        end

        it 'removes the version' do
          expect(migrator).to receive(:remove_version!)

          migrator.rollback
        end
      end

      context 'when the script has a down method which fails' do
        before do
          require a_script_path
          allow_any_instance_of(MyMigration)
            .to receive(:down).and_raise('ERROR')
        end

        it 'runs the down method' do
          expect_any_instance_of(MyMigration).to receive(:down)

          expect { migrator.rollback }.to raise_error('ERROR')
        end

        it "doesn't remove the version but raise the error" do
          expect(migrator).not_to receive(:remove_version!)

          expect { migrator.rollback }.to raise_error('ERROR')
        end
      end

      context 'when the script has a down method which succeeded' do
        before do
          require a_script_path
        end

        it 'runs the down method' do
          expect_any_instance_of(MyMigration).to receive(:down)

          migrator.rollback
        end

        it 'removes the version but raise the error' do
          expect(migrator).to receive(:remove_version!)

          migrator.rollback
        end
      end
    end
  end
end
