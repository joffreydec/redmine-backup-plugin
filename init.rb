Redmine::Plugin.register :redmine_backup_project do
  name 'Redmine Backup Project Plugin'
  author 'Joffrey DECOURSELLE'
  description 'This plugin allows admin to create a sql backup file when a project is archived'
  version '0.0.1'
  settings(:partial => 'settings/redmine_backup_project', :default => {
    :base_url => "/tmp/backup",
  })
end

Rails.configuration.to_prepare do
  require_dependency 'backup_script'
  ProjectsController.send(:include, BackupProject::BackupProjectPatch) 
end

