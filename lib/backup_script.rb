# Backup Script 

  module BackupProject

  module BackupProjectPatch

  def self.included(base)
      base.class_eval do

  # Create SQL File with INSERT command to construct the project in redmine database
  # This method is called with the identifier of the project and the path of the backup folder
  def backup

    dir = Setting[:plugin_redmine_backup_project][:base_url]
    unless Dir.exist?(dir)
      Dir::mkdir(dir)
    end
    ident = @project.identifier.to_s

    # creating backup folder url
    projectBackupDir = File.join(dir,ident)
    projectFileDir = File.join(projectBackupDir, 'files')
    projectBackupFile = File.join(projectBackupDir, ident + '.sql')

    # creating sql backup
    unless Dir.exist?(projectBackupDir)
      Dir::mkdir(projectBackupDir)
    end
    unless Dir.exist?(projectFileDir)
      Dir::mkdir(projectFileDir)
    end
    file = File.open(projectBackupFile, "a")

    export(file, @project)

    # export project attachments
    Attachment.where(:container_id => @project.id, :container_type => 'Project').find_each do |o|
      export(file, o)

      export_file(o, attDir)
    end

    # export issues
    Issue.where(:project_id => @project.id).find_each do |issue|
      export(file, issue)

      # export issue journals
      Journal.where(:journalized_type => 'Issue', :journalized_id => issue.id).find_each do |j|
        export(file, j)
        # export issue journal details
        JournalDetail.where(:journal_id => j.id).find_each do |d|
          export(file, d)
        end
      end

      # export issue attachments
      Attachment.where(:container_id => issue.id, :container_type => 'Issue').find_each do |o|
        export(file, o)

        export_file(o, attDir)
      end

      # export issue relations
      IssueRelation.where(:issue_from_id => issue.id).find_each do |o|
        export(file, o)
      end

      # export issue watchers
      Watcher.where(:watchable_id => issue.id, :watchable_type => 'Issue').find_each do |o|
        export(file, o)
      end
    end

    # export documents
    Document.where(:project_id => @project.id).find_each do |document|
      export(file, document)

      # export document attachments
      Attachment.where(:container_id => document.id, :container_type => 'Document').find_each do |o|
        export(file, o)

        export_file(o, attDir)
      end
    end

    # export enabled_modules
    EnabledModule.where(:project_id => @project.id).find_each do |o|
      export(file, o)
    end

    # export issue_categories
    IssueCategory.where(:project_id => @project.id).find_each do |o|
      export(file, o)
    end

    # export members
    Member.where(:project_id => @project.id).find_each do |o|
      export(file, o)
    end

    # export queries
    Query.where(:project_id => @project.id).find_each do |o|
      export(file, o)
    end

    # export changesets
    repo = Repository.find(:first, :conditions => ["project_id = ?", @project.id])
    export(file,repo)
    Changeset.where(:repository_id => repo.id).find_each do |o|
      export(file,o)
      Change.where(:changeset_id => o.id).find_each do |oc|
          export(file,oc)
      end
    end

    # export versions
    Version.where(:project_id => @project.id).find_each do |version|
      export(file, version)

      # export version attachments
      Attachment.where(:container_id => version.id, :container_type => 'Version').find_each do |o|
        export(file, o)

        export_file(o, attDir)
      end
    end

    # export wikis
    Wiki.where(:project_id => @project.id).find_each do |wiki|
      export(file, wiki)

      # export wiki redirects
      WikiRedirect.where(:wiki_id => wiki.id).find_each do |r|
        export(file, r)
      end

      # export wiki pages
      WikiPage.where(:wiki_id => wiki.id).find_each do |page|
        export(file, page)

        # export wiki page contents
        WikiContent.where(:page_id => page.id).find_each do |content|
          export(file, content)
        end

        # export wiki page attachments
        Attachment.where(:container_id => page.id, :container_type => 'WikiPage').find_each do |o|
          export(file, o)

          export_file(o, attDir)
        end

        # export wiki page watchers
        Watcher.where(:watchable_id => page.id, :watchable_type => 'WikiPage').find_each do |o|
          export(file, o)
        end
      end
    end

    file.close
    return true
  end

  def export(file, data)
    c = data.class
    file.print("INSERT INTO " + c.table_name + "(" + c.column_names.join(',') + ") VALUES(")

    c.column_names.each_with_index {|key, i|
      file.print(c.connection.quote(data.attributes[key]))
      if i != c.columns.size - 1
        file.print(',')
      end
    }
    file.puts(');')
  end

  def export_file(attach, attDir)
    src = attach.diskfile
    if attach.attribute_present?('disk_directory')
      FileUtils.mkdir_p(File.join(attDir, attach.disk_directory))
      dest = File.join(attDir, attach.disk_directory, attach.disk_filename)
    else
      dest = File.join(attDir, attach.disk_filename)
    end
    FileUtils.copy(src, dest) if File.exists?(src)
  end

  def archive
    if request.post?
      unless backup
        flash[:error] = l(:error_can_not_archive_project)
      end
      unless @project.archive
        flash[:error] = l(:error_can_not_archive_project)
      end
    end
    redirect_to admin_projects_path(:status => params[:status])
  end

  end

  end

end

end
