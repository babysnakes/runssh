Feature: Print bookmarks
  In order to see the content of a bookmark
  I want to be able to print it to the console.

  Scenario: Printing bookmark (only host and user)
    Given Bookmark "one two" exist with:
      | name      | value     |
      | host-name | some.host |
      | login     | myuser    |
    When I run the "print" command with "one two"
    Then It should run successfully
    And The output should include "host: some.host"
    And The output should include "login: myuser"
    And The output should not include "local tunnel:"

  Scenario: Printing bookmark (with local tunnel)
    Given Bookmark "one two" exist with:
      |name|value|
      |host-name|some.host|
      |local-tunnel|7070:localhost:7070|
    When I run the "print" command with "one two"
    Then It should run successfully
    And The output should include "host: some.host"
    And The output should include "local tunnel: 7070:localhost:7070"

  Scenario: Invalid bookmark
    Given Empty database
    When I run the "print" command with "one two"
    Then I should get a "Error: host definition (one => two) doesn't exist" error
