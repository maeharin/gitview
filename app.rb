require 'sinatra'
require 'active_record'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

class GitLog < ActiveRecord::Base
end

class App < Sinatra::Base
  get '/' do
    haml :index
  end

  get '/commit_counts.json' do
    commit_counts = GitLog.find_by_sql <<-SQL
      select
        file_name, 
        count(*) as count
      from
        git_logs
      group by
        file_name
      order by
        count desc
SQL

    commit_counts.to_json
  end
end
