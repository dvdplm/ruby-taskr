require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'hoe'
include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'taskr', 'version')

AUTHOR = ["Matt Zukowski", "David Palm"]  # can also be an array of Authors
EMAIL = ["matt at roughest dot net", "dvd plm on googles free email service"]
DESCRIPTION = "cron-like scheduler service with a RESTful interface"
GEM_NAME = "taskr" # what ppl will type to install your gem
RUBYFORGE_PROJECT = "taskr" # The unix name for your project
HOMEPATH = "http://#{RUBYFORGE_PROJECT}.rubyforge.org"


NAME = "taskr"
REV = nil
VERS = ENV['VERSION'] || (Taskr::VERSION::STRING + (REV ? ".#{REV}" : ""))
                          CLEAN.include ['**/.*.sw?', '*.gem', '.config']
RDOC_OPTS = ['--quiet', '--title', "taskr documentation",
    "--opname", "index.html",
    "--line-numbers", 
    "--main", "README",
    "--inline-source"]

class Hoe
  def extra_deps 
    @extra_deps.reject { |x| Array(x).first == 'hoe' } 
  end 
end

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
hoe = Hoe.new(GEM_NAME, VERS) do |p|
  p.author = AUTHOR 
  p.description = DESCRIPTION
  p.email = EMAIL
  p.summary = DESCRIPTION
  p.url = HOMEPATH
  p.rubyforge_name = RUBYFORGE_PROJECT if RUBYFORGE_PROJECT
  p.test_globs = ["test/**/*_test.rb"]
  p.clean_globs = CLEAN  #An array of file patterns to delete on clean.
  
  # == Optional
  #p.changes        - A description of the release's latest changes.
  #p.extra_deps     - An array of rubygem dependencies.
  #p.spec_extras    - A hash of extra values to set in the gemspec.
  
  p.extra_deps = [
    ['picnic', '~> 0.6.4'], 
    ['reststop', '~> 0.3.0'], 
    ['restr', '~> 0.4.0'], 
    ['rufus-scheduler', '~> 1.0.7']
  ]
  p.spec_extras = {:executables => ['taskr', 'taskr-ctl']}
end

desc "Generate gemspec"
task :gemspec do |x|
  # Check the manifest before generating the gemspec
  manifest = %x[rake check_manifest]
  manifest.gsub!(/\(in .{1,}\)\n/, "")
 
  unless manifest.empty?
    print "\n", "#"*68, "\n"
    print <<-EOS
  Manifest.txt is not up-to-date. Please review the changes below.
  If the changes are correct, run 'rake check_manifest | patch'
  and then run this command again.
EOS
    print "#"*68, "\n\n"
    puts manifest
  else
    gemspec = %x[rake debug_gem]
    gemspec.gsub!(/\(in .{1,}\)\n/, "")
    File.open("#{GEM_NAME}.gemspec",'w'){|f| f<<gemspec}
    # %x[rake debug_gem > #{GEM_NAME}.gemspec]
  end
end