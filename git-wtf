#!/usr/bin/env ruby

## git-wtf: display the state of your repository in a readable and easy-to-scan
## format.
##
## git-wtf tries to ease the task of having many git branches. It's also useful
## for getting a summary of how tracking branches relate to a remote server.
##
## git-wtf shows you:
## - How your branch relates to the remote repo, if it's a tracking branch.
## - How your branch relates to non-feature ("version") branches, if it's a
##   feature branch.
## - How your branch relates to the feature branches, if it's a version branch.
##
## For each of these relationships, git-wtf displays the commits pending on
## either side, if any. It displays checkboxes along the side for easy scanning
## of merged/non-merged branches.
##
## If you're working against a remote repo, git-wtf is best used between a 'git
## fetch' and a 'git merge' (or 'git pull' if you don't mind the redundant
## network access).
##
## Usage: git wtf [branch+] [-l|--long] [-a|--all] [--dump-config]
##
## If [branch] is not specified, git-wtf will use the current branch.  With
## --long, you'll see author info and date for each commit. With --all, you'll
## see all commits, not just the first 5. With --dump-config, git-wtf will
## print out its current configuration in YAML format and exit.
##
## git-wtf uses some heuristics to determine which branches are version
## branches, and which are feature branches. (Specifically, it assumes the
## version branches are named "master", "next" and "edge".) If it guesses
## incorrectly, you will have to create a .git-wtfrc file.
##
## git-wtf looks for a .git-wtfrc file starting in the current directory, and
## recursively up to the root. The config file is a YAML file that specifies
## the version branches, any branches to ignore, and the max number of commits
## to display when --all isn't used. To start building a configuration file,
## run "git-wtf --dump-config > .git-wtfrc" and edit it.
##
## IMPORTANT NOTE: all local branches referenced in .git-wtfrc must be prefixed
## with heads/, e.g. "heads/master". Remote branches must be of the form
## remotes/<remote>/<branch>.
##
## git-wtf Copyright 2008 William Morgan <wmorgan-git-wt-add@masanjin.net>.
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by the Free
## Software Foundation, either version 3 of the License, or (at your option)
## any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
## more details.
##
## You can find the GNU General Public License at: http://www.gnu.org/licenses/


require 'yaml'
CONFIG_FN = ".git-wtfrc"

class Numeric; def pluralize s; "#{to_s} #{s}" + (self != 1 ? "s" : "") end end

$long = ARGV.delete("--long") || ARGV.delete("-l")
$all = ARGV.delete("--all") || ARGV.delete("-a")
$dump_config = ARGV.delete("--dump-config")

## find config file
$config = { "versions" => %w(heads/master heads/next heads/edge), "ignore" => [], "max_commits" => 5 }.merge begin
  p = File.expand_path "."
  fn = while true
    fn = File.join p, CONFIG_FN
    break fn if File.exist? fn
    pp = File.expand_path File.join(p, "..")
    break if p == pp
    p = pp
  end

  (fn && YAML::load_file(fn)) || {} # YAML turns empty files into false
end

if $dump_config
  puts $config.to_yaml
  exit(0)
end

## the set of commits in 'to' that aren't in 'from'.
## if empty, 'to' has been merged into 'from'.
def commits_between from, to
  if $long
    `git log --pretty=format:"- %s [%h] (%ae; %ar)" #{from}..#{to}`
  else
    `git log --pretty=format:"- %s [%h]" #{from}..#{to}`
  end.split(/[\r\n]+/)
end

def show_commits commits, prefix="    "
  if commits.empty?
    puts "#{prefix} none"
  else
    max = $all ? commits.size : $config["max_commits"]
    max -= 1 if max == commits.size - 1 # never show "and 1 more"
    commits[0 ... max].each { |c| puts "#{prefix}#{c}" }
    puts "#{prefix}... and #{commits.size - max} more." if commits.size > max
  end
end

def ahead_behind_string ahead, behind
  [ahead.empty? ? nil : "#{ahead.size.pluralize 'commit'} ahead",
   behind.empty? ? nil : "#{behind.size.pluralize 'commit'} behind"].
   compact.join("; ")
end

def show b, all_branches
  puts "Local branch: #{b[:local_branch]}"
  both = false

  if b[:remote_branch]
    pushc = commits_between b[:remote_branch], b[:local_branch]
    pullc = commits_between b[:local_branch], b[:remote_branch]

    both = !pushc.empty? && !pullc.empty?
    if pushc.empty?
      puts "[x] in sync with remote"
    else
      action = both ? "push after rebase / merge" : "push"
      puts "[ ] NOT in sync with remote (needs #{action})"
      show_commits pushc
    end

    puts "\nRemote branch: #{b[:remote_branch]} (#{b[:remote_url]})"

    if pullc.empty?
      puts "[x] in sync with local"
    else
      action = pushc.empty? ? "merge" : "rebase / merge"
      puts "[ ] NOT in sync with local (needs #{action})"
      show_commits pullc

      both = !pushc.empty? && !pullc.empty?
    end
  end

  vbs, fbs = all_branches.partition { |name, br| $config["versions"].include? br[:local_branch] }
  if $config["versions"].include? b[:local_branch]
    puts "\nFeature branches:" unless fbs.empty?
    fbs.each do |name, br|
      remote_ahead = b[:remote_branch] ? commits_between(b[:remote_branch], br[:local_branch]) : []
      local_ahead = commits_between b[:local_branch], br[:local_branch]
      if local_ahead.empty? && remote_ahead.empty?
        puts "[x] #{br[:name]} is merged in"
      elsif local_ahead.empty? && b[:remote_branch]
        puts "(x) #{br[:name]} merged in (only locally)"
      else
        behind = commits_between br[:local_branch], b[:local_branch]
        puts "[ ] #{br[:name]} is NOT merged in (#{ahead_behind_string local_ahead, behind})"
        show_commits local_ahead
      end
    end
  else
    puts "\nVersion branches:" unless vbs.empty? # unlikely
    vbs.each do |v, br|
      ahead = commits_between v, b[:local_branch]
      if ahead.empty?
        puts "[x] merged into #{v}"
      else
        #behind = commits_between b[:local_branch], v
        puts "[ ] NOT merged into #{v} (#{ahead.size.pluralize 'commit'} ahead)"
        show_commits ahead
      end
    end
  end

  puts "\nWARNING: local and remote branches have diverged. A merge will occur unless you rebase." if both
end

#Required for Ruby 1.9+ as string arrays are handled differently
unless String.method_defined?(:lines) then
  class String
    def lines
      to_a
    end
  end
end

branches = `git show-ref`.lines.to_a.inject({}) do |hash, l|
  sha1, ref = l.chomp.split " refs/"
  next hash if $config["ignore"].member? ref
  next hash unless ref =~ /^heads\/(.+)/
  name = $1
  hash[name] = { :name => name, :local_branch => ref }
  hash
end

remotes = `git config --get-regexp ^remote\.\*\.url`.lines.to_a.inject({}) do |hash, l|
  l =~ /^remote\.(.+?)\.url (.+)$/ or next hash
  hash[$1] ||= $2
  hash
end

`git config --get-regexp ^branch\.`.lines.to_a.each do |l|
  case l
  when /branch\.(.*?)\.remote (.+)/
    next if $2 == '.'

    branches[$1] ||= {}
    branches[$1][:remote] = $2
    branches[$1][:remote_url] = remotes[$2]
  when /branch\.(.*?)\.merge ((refs\/)?heads\/)?(.+)/
    branches[$1] ||= {}
    branches[$1][:remote_mergepoint] = $4
  end
end

branches.each { |k, v| v[:remote_branch] = "#{v[:remote]}/#{v[:remote_mergepoint]}" if v[:remote] && v[:remote_mergepoint] }

show_dirty = ARGV.empty?
targets = if ARGV.empty?
  [`git symbolic-ref HEAD`.chomp.sub(/^refs\/heads\//, "")]
else
  ARGV
end.map { |t| branches[t] or abort "Error: can't find branch #{t.inspect}." }

targets.each { |t| show t, branches }

modified = show_dirty && `git ls-files -m` != ""
uncommitted = show_dirty &&  `git diff-index --cached HEAD` != ""

puts if modified || uncommitted
puts "NOTE: working directory contains modified files" if modified
puts "NOTE: staging area contains staged but uncommitted files" if uncommitted

# the end!

