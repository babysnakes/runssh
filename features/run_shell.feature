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

  Scenario: Connect to bookmark with abbreviated tunneling
    Given Bookmark "one two three" exist with:
      | name         | value     |
      | host-name    | some.host |
      | local-tunnel | 8080      |
    When I run the "shell" command with:
      | option | argument      |
      |        | one two three |
    Then It should execute "ssh some.host -L 8080:localhost:8080"

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
      | option  | argument        |
      |         | one two three   |
      | <empty> | <all_arguments> |
    Then It should execute "<command>"

    Scenarios: Overriding arguments
      | empty | all_arguments | command                     |
      |       | -n other.host | ssh -l mylogin other.host   |
      |       | -l otherlogin | ssh -l otherlogin some.host |

    Scenarios: Remote command pseudo terminal and quoting (e.g., to avoid wrong parsing of '&')
      | empty | all_arguments     | command                                           |
      |       | -- ls             | ssh -t -l mylogin some.host -- \"ls\"             |
      |       | -- ls && ls /tmp/ | ssh -t -l mylogin some.host -- \"ls && ls /tmp/\" |

    Scenarios: Disable pseudo terminal on remote command
      | empty | all_arguments | command                               |
      |       | -T -- ls      | ssh -l mylogin some.host -- \"ls\" |

  Scenario: Display error if no bookmark given
    When Running "shell" without path
    Then I should get a "not host definition!" error
