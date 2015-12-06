# Runs react_on_rails generators on #{BASE_BRANCH} with varying options and puts each result in its own branch.
# You must pass in a version number so that the branches will be unique. For example:
#   rake all[10] will generate all results with a "-10" suffix on the branches.
namespace :gen_res do
  RESULT_TYPES = %w(basic
                    basic-server-rendering
                    redux
                    redux-server-rendering
                    basic-heroku-deployment
                    basic-skip-bootstrap)
  GENERATOR_OPTIONS = %w(redux server-rendering heroku-deployment skip-bootstrap)
  COMPARISON_TYPES = [
    %w(basic basic-server-rendering),
    %w(redux redux-server-rendering),
    %w(basic-server-rendering redux-server-rendering),
    %w(basic redux),
    %w(basic basic-heroku-deployment),
    %w(basic basic-skip-bootstrap)
  ]
  REPO_NAME = "react_on_rails-generator-results-testing"
  GIT_REMOTE = "origin"
  START_BRANCH = "master"
  DIRECTORY = File.expand_path("../../../react_on_rails-generator-results-testing", __FILE__)
  DIRECTORY_NAME = File.basename(DIRECTORY)
  PARENT_DIRECTORY = File.expand_path("../.", DIRECTORY)

  # Define tasks to generate each result type app
  RESULT_TYPES.each do |result_type|
    desc "generate #{result_type} app"
    task "gen_#{result_type}", [:version] do |_task, args|
      sh %(cd #{DIRECTORY} && git checkout #{START_BRANCH})
      sh %(cd #{DIRECTORY} && git checkout -b #{result_type}-#{args[:version]})
      add_gems
      sh %(cd #{DIRECTORY} && bundle install)
      sh %(cd #{DIRECTORY} && spring stop)

      generator_options = ""
      result_type.split(/-/, 2).each do |name_part|
        generator_options += " --#{name_part}" if GENERATOR_OPTIONS.include?(name_part)
      end

      sh %(cd #{DIRECTORY} && rails generate react_on_rails:install#{generator_options})
      sh %(cd #{DIRECTORY} && bundle install)
      sh %(cd #{DIRECTORY} && spring stop)
      sh %(cd #{DIRECTORY} && git add .)
      sh %(cd #{DIRECTORY} && git commit -m "#{result_type} App Generated v#{args[:version]}")
    end
  end

  desc "generates all results and places them in their own branch"
  task :gen_all, [:version] do |_task, args|
    RESULT_TYPES.each do |result_type|
      Rake::Task["gen_res:gen_#{result_type}"].invoke(args[:version])
    end
  end

  desc "creates additional comparison branches"
  task "compare_all", [:version] do |_task, args|
    COMPARISON_TYPES.each do |comparison_type|
      base_branch = "#{comparison_type[0]}-#{args[:version]}"
      sh %(cd #{DIRECTORY} && git checkout #{base_branch})

      # Keep .git folder
      git_folder = File.join(DIRECTORY, ".git")
      tmp_git_folder = File.join(PARENT_DIRECTORY, ".git")
      mv(git_folder, PARENT_DIRECTORY)

      rm_rf(DIRECTORY)
      sh %(cd #{PARENT_DIRECTORY} && rails new #{DIRECTORY_NAME})
      sh %(cd #{DIRECTORY} && spring stop)

      # Put .git folder back
      mv(tmp_git_folder, DIRECTORY)

      add_gems

      sh %(cd #{DIRECTORY} && bundle install)
      sh %(cd #{DIRECTORY} && spring stop)

      generator_options = ""
      comparison_type[1].split(/-/, 2).each do |name_part|
        generator_options += " --#{name_part}" if GENERATOR_OPTIONS.include?(name_part)
      end

      sh %(cd #{DIRECTORY} && rails generate react_on_rails:install#{generator_options})
      sh %(cd #{DIRECTORY} && bundle install)
      sh %(cd #{DIRECTORY} && spring stop)
      sh %(cd #{DIRECTORY} && git checkout -b #{comparison_type[0]}-to-#{comparison_type[1]}-comparison-#{args[:version]})
      sh %(cd #{DIRECTORY} && git add .)
      sh %(cd #{DIRECTORY} && git commit -m "#{comparison_type[0]}-#{args[:version]} -> #{comparison_type[1]}-#{args[:version]} comparison")
    end
  end

  desc "push all branches"
  task "push_all", [:version] do |_task, args|
    RESULT_TYPES.each do |result_type|
      branch_name = "#{result_type}-#{args[:version]}"
      sh %(cd #{DIRECTORY} && git checkout #{branch_name})
      sh %(cd #{DIRECTORY} && git push #{GIT_REMOTE} #{branch_name} -u)
    end

    COMPARISON_TYPES.each do |comparison_type|
      branch_name = "#{comparison_type[0]}-to-#{comparison_type[1]}-comparison-#{args[:version]}"
      sh %(cd #{DIRECTORY} && git checkout #{branch_name})
      sh %(cd #{DIRECTORY} && git push #{GIT_REMOTE} #{branch_name} -u)
    end
  end

  # Requires `hub` command-line tool
  desc "creates pull requests"
  task "pull_all", [:version] do |_task, args|
    RESULT_TYPES.each do |result_type|
      branch_name = "#{result_type}-#{args[:version]}"
      sh %(cd #{DIRECTORY} && git checkout #{branch_name})
      message = result_type
      sh %(cd #{DIRECTORY} && hub pull-request -b shakacode/#{REPO_NAME}:#{START_BRANCH} -h shakacode/#{REPO_NAME}:#{branch_name} -m "#{message}")
    end

    COMPARISON_TYPES.each do |comparison_type|
      base_branch_name = "#{comparison_type[0]}-#{args[:version]}"
      head_branch_name = "#{comparison_type[0]}-to-#{comparison_type[1]}-comparison-#{args[:version]}"
      message = "#{comparison_type[0]} to #{comparison_type[1]}"
      sh %(cd #{DIRECTORY} && hub pull-request -m "#{message}" -b shakacode/#{REPO_NAME}:#{base_branch_name} -h shakacode/#{REPO_NAME}:#{head_branch_name})
    end
  end

  desc "runs everything"
  task :all, [:version] do |_task, args|
    Rake::Task["gen_res:gen_all"].invoke(args[:version])
    Rake::Task["gen_res:compare_all"].invoke(args[:version])
    Rake::Task["gen_res:push_all"].invoke(args[:version])
    Rake::Task["gen_res:pull_all"].invoke(args[:version])
  end

  desc "default: runs all (runs everything)"
  task default: ["all"]

  desc "Delete branches for given version number"
  task :delete_branches, [:version] do |_task, args|
    sh %(cd #{DIRECTORY} && git checkout #{START_BRANCH})
    sh %(cd #{DIRECTORY} && git remote prune origin)
    RESULT_TYPES.each do |result_type|
      branch_name = "#{result_type}-#{args[:version]}"
      sh %(cd #{DIRECTORY} && git branch -D #{branch_name})
    end
    COMPARISON_TYPES.each do |comparison_type|
      branch_name = "#{comparison_type[0]}-to-#{comparison_type[1]}-comparison-#{args[:version]}"
      sh %(cd #{DIRECTORY} && git branch -D #{branch_name})
    end
    puts "All Branches for version #{args[:version]} Deleted!"
  end
end

private

def add_gems
  gemfile = File.join(DIRECTORY, "Gemfile")
  gemfile_additions = "source 'https://rubygems.org'\n\n"
  gemfile_additions << "gem 'react_on_rails', path: '../react_on_rails'\n"

  old_gemfile_text = File.read(gemfile)
  new_gemfile_text = old_gemfile_text.gsub(/^source .*\n/, gemfile_additions)
  File.open(gemfile, "w") { |file| file.puts(new_gemfile_text) }
end
