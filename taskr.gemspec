Gem::Specification.new do |s|
  s.name = %q{taskr}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Zukowski", "David Palm"]
  s.date = %q{2008-08-11}
  s.description = %q{cron-like scheduler service with a RESTful interface}
  s.email = ["matt at roughest dot net", "dvd plm on googles free email service"]
  s.executables = ["taskr", "taskr-ctl"]
  s.extra_rdoc_files = ["CHANGELOG.txt", "GPLv3-LICENSE.txt", "History.txt", "Manifest.txt", "README.txt", "taskr4rails/LICENSE.txt"]
  s.files = ["CHANGELOG.txt", "GPLv3-LICENSE.txt", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/taskr", "bin/taskr-ctl", "config.example.yml", "examples/active_resource_client_example.rb", "examples/php_client_example.php", "lib/public/prototype.js", "lib/public/taskr.css", "lib/taskr.rb", "lib/taskr/actions.rb", "lib/taskr/controllers.rb", "lib/taskr/environment.rb", "lib/taskr/helpers.rb", "lib/taskr/models.rb", "lib/taskr/version.rb", "lib/taskr/views.rb", "setup.rb", "taskr4rails/LICENSE.txt", "taskr4rails/README", "taskr4rails/Rakefile", "taskr4rails/init.rb", "taskr4rails/install.rb", "taskr4rails/lib/taskr4rails_controller.rb", "taskr4rails/tasks/taskr4rails_tasks.rake", "taskr4rails/test/taskr4rails_test.rb", "taskr4rails/uninstall.rb", "test.rb", "test/taskr_test.rb", "test/test_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://taskr.rubyforge.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{taskr}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{cron-like scheduler service with a RESTful interface}
  s.test_files = ["test/taskr_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<picnic>, ["~> 0.6.4"])
      s.add_runtime_dependency(%q<reststop>, ["~> 0.3.0"])
      s.add_runtime_dependency(%q<restr>, ["~> 0.4.0"])
      s.add_runtime_dependency(%q<rufus-scheduler>, ["~> 1.0.7"])
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<picnic>, ["~> 0.6.4"])
      s.add_dependency(%q<reststop>, ["~> 0.3.0"])
      s.add_dependency(%q<restr>, ["~> 0.4.0"])
      s.add_dependency(%q<rufus-scheduler>, ["~> 1.0.7"])
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<picnic>, ["~> 0.6.4"])
    s.add_dependency(%q<reststop>, ["~> 0.3.0"])
    s.add_dependency(%q<restr>, ["~> 0.4.0"])
    s.add_dependency(%q<rufus-scheduler>, ["~> 1.0.7"])
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
