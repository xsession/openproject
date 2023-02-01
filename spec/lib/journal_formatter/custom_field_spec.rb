#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe OpenProject::JournalFormatter::CustomField do
  include CustomFieldsHelper
  include ActionView::Helpers::TagHelper

  let(:klass) { described_class }
  let(:instance) { klass.new(journal) }
  let(:id) { 1 }
  let(:journal) do
    OpenStruct.new(id:)
  end
  let(:custom_field) do
    build_stubbed(:work_package_custom_field).tap do |cf|
      allow(CustomField)
        .to receive(:find_by)
              .with(id: cf.id)
              .and_return(cf)
    end
  end

  let(:key) do
    "custom_fields_#{custom_field.id}"
  end

  describe 'a multi-select user field' do
    let(:user1) { build_stubbed :user, firstname: 'Foo', lastname: 'Bar' }
    let(:user2) { build_stubbed :user, firstname: 'Bla', lastname: 'Blub' }

    let(:custom_field) do
      build_stubbed(:user_wp_custom_field).tap do |cf|
        allow(CustomField)
          .to receive(:find_by)
                .with(id: cf.id)
                .and_return(cf)
      end
    end

    let(:wherestub) { class_double(Principal) }
    let(:values) { [nil, "#{user1.id},#{user2.id}"] }

    subject(:rendered) { instance.render(key, values) }

    before do
      allow(Principal)
        .to receive(:in_visible_project_or_me).and_return(wherestub)

      allow(wherestub)
        .to receive(:where)
              .with(id: [user1.id, user2.id])
              .and_return(visible_users)
    end

    context 'with two visible users' do
      let(:visible_users) { [user1, user2] }

      let(:formatted_value) do
        "Foo Bar, Bla Blub"
      end
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{custom_field.name}</strong>",
               value: "<i>#{formatted_value}</i>")
      end

      it 'outputs both formatted names' do
        expect(rendered).to eq expected
      end

      context 'with only one visible user' do
        let(:visible_users) { [user1] }

        let(:formatted_value) do
          "Foo Bar, (missing value or lacking permissions to access)"
        end
        let(:expected) do
          I18n.t(:text_journal_set_to,
                 label: "<strong>#{custom_field.name}</strong>",
                 value: "<i>#{formatted_value}</i>")
        end

        it 'outputs the one visible formatted name' do
          expect(rendered).to eq expected
        end
      end
    end
  end

  describe 'WITH the first value being nil, and the second a valid value as string' do
    let(:values) { [nil, '1'] }
    let(:formatted_value) { format_value(values.last, custom_field) }

    let(:expected) do
      I18n.t(:text_journal_set_to,
             label: "<strong>#{custom_field.name}</strong>",
             value: "<i>#{formatted_value}</i>")
    end

    it { expect(instance.render(key, values)).to eq(expected) }
  end

  describe 'WITH the first value being a valid value as a string, and the second being a valid value as a string' do
    let(:values) { %w[0 1] }
    let(:old_formatted_value) { format_value(values.first, custom_field) }
    let(:new_formatted_value) { format_value(values.last, custom_field) }

    let(:expected) do
      I18n.t(:text_journal_changed_html,
             label: "<strong>#{custom_field.name}</strong>",
             linebreak: '',
             old: "<i>#{old_formatted_value}</i>",
             new: "<i>#{new_formatted_value}</i>")
    end

    it { expect(instance.render(key, values)).to eq(expected) }
  end

  describe 'WITH the first value being a valid value as a string, and the second being nil' do
    let(:values) { ['0', nil] }
    let(:formatted_value) { format_value(values.first, custom_field) }

    let(:expected) do
      I18n.t(:text_journal_deleted,
             label: "<strong>#{custom_field.name}</strong>",
             old: "<strike><i>#{formatted_value}</i></strike>")
    end

    it { expect(instance.render(key, values)).to eq(expected) }
  end

  describe "WITH the first value being nil, and the second a valid value as string
              WITH no html requested" do
    let(:values) { [nil, '1'] }

    let(:expected) do
      I18n.t(:text_journal_set_to,
             label: custom_field.name,
             value: format_value(values.last, custom_field))
    end

    it { expect(instance.render(key, values, html: false)).to eq(expected) }
  end

  describe "WITH the first value being a valid value as a string, and the second being a valid value as a string
              WITH no html requested" do
    let(:values) { %w[0 1] }

    let(:expected) do
      I18n.t(:text_journal_changed_plain,
             label: custom_field.name,
             old: format_value(values.first, custom_field),
             linebreak: '',
             new: format_value(values.last, custom_field))
    end

    it { expect(instance.render(key, values, html: false)).to eq(expected) }
  end

  describe "WITH the first value being a valid value as a string, and the second being nil
              WITH no html requested" do
    let(:values) { ['0', nil] }

    let(:expected) do
      I18n.t(:text_journal_deleted,
             label: custom_field.name,
             old: format_value(values.first, custom_field))
    end

    it { expect(instance.render(key, values, html: false)).to eq(expected) }
  end

  describe "WITH the first value being nil, and the second a valid value as string
              WITH the custom field being deleted" do
    let(:values) { [nil, '1'] }
    let(:key) { 'custom_values0' }

    let(:expected) do
      I18n.t(:text_journal_set_to,
             label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
             value: "<i>#{values.last}</i>")
    end

    it { expect(instance.render(key, values)).to eq(expected) }
  end

  describe "WITH the first value being a valid value as a string, and the second being a valid value as a string
              WITH the custom field being deleted" do
    let(:values) { %w[0 1] }
    let(:key) { 'custom_values0' }

    let(:expected) do
      I18n.t(:text_journal_changed_html,
             label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
             linebreak: '',
             old: "<i>#{values.first}</i>",
             new: "<i>#{values.last}</i>")
    end

    it { expect(instance.render(key, values)).to eq(expected) }
  end

  describe "WITH the first value being a valid value as a string, and the second being nil
              WITH the custom field being deleted" do
    let(:values) { ['0', nil] }
    let(:key) { 'custom_values0' }

    let(:expected) do
      I18n.t(:text_journal_deleted,
             label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
             old: "<strike><i>#{values.first}</i></strike>")
    end

    it { expect(instance.render(key, values)).to eq(expected) }
  end

  context 'for a multi list cf' do
    let(:custom_field) do
      build_stubbed(:list_wp_custom_field, multi_value: true).tap do |cf|
        allow(CustomField)
          .to receive(:find_by)
                .with(id: cf.id)
                .and_return(cf)

        cf_options = double('custom_options')
        old_options = double('selected options')
        new_options = double('selected options')

        allow(cf)
          .to receive(:custom_options)
                .and_return cf_options

        allow(cf_options)
          .to receive(:where)
                .with(id: [1, 2])
                .and_return old_options

        allow(cf_options)
          .to receive(:where)
                .with(id: [3, 4])
                .and_return new_options

        allow(old_options)
          .to receive(:order)
                .with(:position)
                .and_return(old_options)

        allow(new_options)
          .to receive(:order)
                .with(:position)
                .and_return(new_options)

        allow(old_options)
          .to receive(:pluck)
                .with(:id, :value)
                .and_return(old_custom_option_names)

        allow(new_options)
          .to receive(:pluck)
                .with(:id, :value)
                .and_return(new_custom_option_names)
      end
    end
    let(:old_custom_option_names) { [[1, 'cf 1'], [2, 'cf 2']] }
    let(:new_custom_option_names) { [[3, 'cf 3'], [4, 'cf 4']] }

    describe "WITH the first value being a comma separated list of ids, and the second being a comma separated list of ids" do
      let(:values) { %w[1,2 3,4] }

      let(:expected) do
        I18n.t(:text_journal_changed_html,
               label: "<strong>#{custom_field.name}</strong>",
               linebreak: '',
               old: "<i>cf 1, cf 2</i>",
               new: "<i>cf 3, cf 4</i>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    describe "WITH the first value being a comma separated list of ids, and the second being a comma separated list of ids that no longer exist" do
      let(:values) { %w[1,2 3,4] }
      let(:new_custom_option_names) { [[4, 'cf 4']] }

      let(:expected) do
        I18n.t(:text_journal_changed_html,
               label: "<strong>#{custom_field.name}</strong>",
               linebreak: '',
               old: "<i>cf 1, cf 2</i>",
               new: "<i>(deleted option), cf 4</i>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end
  end
end
