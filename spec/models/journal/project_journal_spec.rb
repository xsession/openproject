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

RSpec.describe Journal::ProjectJournal do
  describe '#render_detail' do
    let(:project) { build(:project) }
    let(:journal) { build(:project_journal, journable: project) }

    it 'renders identifier field correctly' do
      html = journal.render_detail(['identifier', [nil, 'my-project']], html: true)
      expect(html).to eq('<strong>Identifier</strong> set to ' \
                         '<i>my-project</i>')

      html = journal.render_detail(['identifier', [nil, 'my-project']], html: false)
      expect(html).to eq('Identifier set to my-project')

      html = journal.render_detail(['identifier', ['my-project', 'my-beautiful-project']], html: true)
      expect(html).to eq('<strong>Identifier</strong> changed from <i>my-project</i> ' \
                         '<strong>to</strong> <i>my-beautiful-project</i>')

      html = journal.render_detail(['identifier', ['my-project', 'my-beautiful-project']], html: false)
      expect(html).to eq('Identifier changed from my-project to my-beautiful-project')
    end

    it 'renders name field correctly' do
      html = journal.render_detail(['name', [nil, 'Test Project 123']], html: true)
      expect(html).to eq('<strong>Name</strong> set to ' \
                         '<i>Test Project 123</i>')

      html = journal.render_detail(['name', [nil, 'Test Project 123']], html: false)
      expect(html).to eq('Name set to Test Project 123')

      html = journal.render_detail(['name', ['Old Project Name', 'New Project Name']], html: true)
      expect(html).to eq('<strong>Name</strong> changed from <i>Old Project Name</i> ' \
                         '<strong>to</strong> <i>New Project Name</i>')

      html = journal.render_detail(['name', ['Old Project Name', 'New Project Name']], html: false)
      expect(html).to eq('Name changed from Old Project Name to New Project Name')
    end
  end
end
