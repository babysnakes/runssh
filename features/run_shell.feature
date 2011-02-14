Feature: Connect to other hosts by ssh
  In order to connect to a bookmarked host
  I want to run the shell subcommand on a bookmark.

  The `shell` subcommand invokes the 'ssh' shell command
  with the appropriate parameters. You can override every
  option in the bookmark using the same option.

  Scenario: Connect to bookmark with host_name only
    Given Bookmark "one two three" exist with:
      | name      | value     |
      | host-name | some.host |
    When I run the "shell" command with:
      | option | argument      |
      |        | one two three |
    Then It should execute "ssh some.host"
