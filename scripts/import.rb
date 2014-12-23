require 'open3'
require 'active_record'
require 'optparse'
require 'csv'

repo_dir = ARGV[0]
raise 'must specify git repository path' if repo_dir.nil?

unless File.exist?(File.join(repo_dir, '.git')) 
  raise 'not git repository'
end

GIT_LOG_DELIMITER = '---commit---:'
GIT_LOG_CMD = <<-CMD
  git log --numstat --pretty=format:"#{GIT_LOG_DELIMITER}%H%x09%an%x09%ad"
CMD
DB_PATH = File.expand_path('../../db/db.sqlite3', __FILE__)
TMP_CSV_PATH = File.expand_path('../../tmp/tmp.csv', __FILE__)

FileUtils.rm(DB_PATH, force: true)
FileUtils.rm(TMP_CSV_PATH, force: true)

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => DB_PATH
)

ActiveRecord::Migration.class_eval do
  create_table :git_logs, id: false do |t|
    t.string :commit_hash, null: false, unique: true
    t.string :author, null: false
    t.datetime :author_date, null: false
    t.string :file_name, null: false
    t.integer :change_count, null: false
    t.integer :insert_count, null: false
    t.integer :delete_count, null: false
  end

  add_index :git_logs, :author
  add_index :git_logs, :author_date
  add_index :git_logs, :file_name
end

module GitStat

  module Parser
    class Commit
      attr_reader :row, :head, :body, :author, :author_date, :hash, :files

      def initialize(row)
        @row = row.dup.freeze

        lines = row.split("\n")
        head = lines.shift.split("\t")
        @hash = head[0]
        @author = head[1]
        @author_date = head[2]

        @files = lines.map do |line| 
          File.new(self, line).to_h
        end
      end
    end

    class File
      attr_reader :commit, :row, :insert_count, :delete_count, :name
      def initialize(commit, row)
        @commit = commit
        @row = row.dup.freeze

        cols = row.split("\t")
        @insert_count = cols[0].to_i
        @delete_count = cols[1].to_i
        @name = cols[2]
      end

      def to_h
        {
          commit_hash: commit.hash,
          author: commit.author,
          author_date: commit.author_date,
          file_name: name,
          change_count: insert_count + delete_count,
          insert_count: insert_count,
          delete_count: delete_count,
        }
      end
    end
  end
end

puts 'get logs from repo...'
row_commits = nil
Dir.chdir(repo_dir) do
  out, err, status = Open3.capture3(GIT_LOG_CMD)
  raise err unless status.success?
  row_commits = out.split(GIT_LOG_DELIMITER)
  row_commits.shift
end

begin
  puts 'covert to tmp csv...'
  CSV.open(TMP_CSV_PATH, 'wb') do |csv|
    row_commits.each do |row_commit|
      files = GitStat::Parser::Commit.new(row_commit).files

      files.each do |file|
        csv << file.values
      end
    end
  end

  puts 'import to db...'
  cmd = "sqlite3 -separator , #{DB_PATH} '.import #{TMP_CSV_PATH} git_logs'"
  out, err, status = Open3.capture3(cmd)
  raise err unless status.success?

  puts 'done'
ensure
  FileUtils.rm(TMP_CSV_PATH, force: true)
end
