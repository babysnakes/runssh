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

  Scenario: Connect to bookmark with host and login
    Given Bookmark "one two three" exist with:
      | name      | value     |
      | host-name | some.host |
      | login     | someuser  |
    When I run the "shell" command with:
      | option | argument      |
      |        | one two three |
    Then It should execute "ssh -l someuser some.host"

  Scenario: Connect to bookmark with custom tunnel definition
    Given Bookmark "one two three" exist with:
      | name      | value     |
      | host-name | some.host |
    When I run the "shell" command with:
      | option | argument              |
      |        | one two three         |
      | -L     | 10000:localhost:10000 |
    Then It should execute "ssh some.host -L 10000:localhost:10000"

  Scenario: Expand abbreviated tunnel syntax when connecting
    Given Bookmark "one two three" exist with:
      | name      | value     |
      | host-name | some.host |
    When I run the "shell" command with:
      | option | argument      |
      |        | one two three |
      | -L     | 10000         |
    Then It should execute "ssh some.host -L 10000:localhost:10000"

  Scenario Outline: Various shell manipulations
    Given Bookmark "one two three" exist with:
      | name      | value     |
      | host-name | some.host |
      | login     | mylogin   |
    When I run the "shell" command with:
      | option   | argument      |
      |          | one two three |
      | <option> | <argument>    |
    Then It should execute "<command>"

    Scenarios: Overriding arguments
      | option | argument   | command                     |
      | -n     | other.host | ssh -l mylogin other.host   |
      | -l     | otherlogin | ssh -l otherlogin some.host |

    Scenarios: Remote commands
      | option | argument       | command                                        |
      | --     | ls             | ssh -l mylogin some.host -- \"ls\"             |
      | --     | ls && ls /tmp/ | ssh -l mylogin some.host -- \"ls && ls /tmp/\" |

  Scenario: Display error if no bookmark given
    When Running "shell" without path
    Then I should get a "not host definition!" error
