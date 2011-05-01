Feature: Adding bookmarks
  In order to make it easier to remember all the hosts I have to connect
  I want to be able to store them in a logical way so I can easily retrieve them.

  The bookmarks will be arranged in groups so it'll be easier to navigate
  logically to find a host bookmark. e.g., In order to connect to the mail
  server in the office of a certain customer, I might save this bookmark as:
  customer1 => office => mail_server.

  Scenario: Automatically creating database
    Given No database
    When I bookmark host: "some.host.com" as "group1 somehost"
    Then It should run successfully
    And A database should be created
    And Bookmark: "group1 somehost" should point to "some.host.com"

  Scenario: All available options
    Given Empty database
    When I run the "add" command with "one two three -n some.host -l mylogin -L 8080:localhost:8080 -o StrictHostKeyChecking=no"
    Then It should run successfully
    And Bookmark "one two three" should contain:
      | name         | value                    |
      | host_name    | some.host                |
      | login        | mylogin                  |
      | local_tunnel | 8080:localhost:8080      |
      | option       | StrictHostKeyChecking=no |

  Scenario: Shortcut for insecure connection (no known_hosts)
    Given Empty database
    When I run the "add" command with "one two three -n some.host --no-host-key-checking"
    Then It should run successfully
    And Bookmark "one two three" should contain:
      | name      | value                        |
      | host_name | some.host                    |
      | option    | StrictHostKeyChecking=no     |
      | option    | UserKnownHostsFile=/dev/null |

  Scenario: Automatic database backup
    Given Existing database
    When I bookmark host: "somehost" as "group somehost"
    Then It should run successfully
    And A backup database should be created with ".bak" suffix

  Scenario: Adding host
    Given Empty database
    When I bookmark host: "somehost" as "group somehost"
    Then It should run successfully
    And Bookmark: "group somehost" should point to "somehost"

  Scenario: Required hostname
    Given Empty database
    When I bookmark host: "" as "group somehost"
    Then I should get a "option '-n' needs a parameter" error

  Scenario: Overwriting bookmark is forbidden
    Given Bookmark "group subgroup" exists
    When I bookmark host: "host" as "group subgroup"
    Then I should get a "path already exist!" error
