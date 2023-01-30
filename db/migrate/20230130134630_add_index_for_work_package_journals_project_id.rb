class AddIndexForWorkPackageJournalsProjectId < ActiveRecord::Migration[7.0]
  def change
    add_index :work_package_journals, :project_id
  end
end
