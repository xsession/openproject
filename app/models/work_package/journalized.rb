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

module WorkPackage::Journalized
  extend ActiveSupport::Concern

  included do
    acts_as_journalized

    # This one is here only to ease reading
    module JournalizedProcs
      def self.event_title
        Proc.new do |o|
          title = o.to_s
          title << " (#{o.status.name})" if o.status.present?

          title
        end
      end

      def self.event_name
        Proc.new do |o|
          I18n.t(o.event_type.underscore, scope: 'events')
        end
      end

      def self.event_type
        Proc.new do |o|
          journal = o.last_journal
          t = 'work_package'

          t << if journal && journal.details.empty? && !journal.initial?
                 '-note'
               else
                 status = Status.find_by(id: o.status_id)

                 status.try(:is_closed?) ? '-closed' : '-edit'
               end
          t
        end
      end

      def self.event_url
        Proc.new do |o|
          { controller: :work_packages, action: :show, id: o.id }
        end
      end
    end

    acts_as_event title: JournalizedProcs.event_title,
                  type: JournalizedProcs.event_type,
                  name: JournalizedProcs.event_name,
                  url: JournalizedProcs.event_url

    register_journal_formatter(:cost_association) do |value, journable, field|
      association = journable.class.reflect_on_association(field.to_sym)
      if association
        record = association.class_name.constantize.find_by(id: value.to_i)
        record&.subject
      end
    end

    register_journal_formatted_fields(:id, 'parent_id')
    register_journal_formatted_fields(:fraction, 'estimated_hours', 'derived_estimated_hours')
    register_journal_formatted_fields(:decimal, 'done_ratio')
    register_journal_formatted_fields(:diff, 'description')
    register_journal_formatted_fields(:schedule_manually, 'schedule_manually')
    register_journal_formatted_fields(:attachment, /attachments_?\d+/)
    register_journal_formatted_fields(:custom_field, /custom_fields_\d+/)
    register_journal_formatted_fields(:cost_association, 'budget_id')
    register_journal_formatted_fields(:ignore_non_working_days, 'ignore_non_working_days')

    # Joined
    register_journal_formatted_fields :named_association, :parent_id, :project_id,
                                  :status_id, :type_id,
                                  :assigned_to_id, :priority_id,
                                  :category_id, :version_id,
                                  :author_id, :responsible_id
    register_journal_formatted_fields :datetime, :start_date, :due_date
    register_journal_formatted_fields :plaintext, :subject
    register_journal_formatted_fields :day_count, :duration
  end
end
