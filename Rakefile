require 'rake'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new('specs') do |t|
  t.spec_files = FileList.new('test/**/*.rb')
  # t.warning = true
  t.rcov = true
end