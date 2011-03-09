Feature: Importing Bookmarks
  In order to reuse exported bookmarks (maybe after some editing)
  I want to be able to import them back to the database.

  This is currently a lacking feature as the import mechanism
  OVERWRITES the existing database!.

  Scenario: Warning before overwriting database
    Given Existing database
    When I import yml file
    Then I should be prompted with "Importing a file OVERWRITES existing configuration"

  Scenario: Importing databas and approving import
    When I import yml file
    And I answer "yes" at the prompt
    Then It should run successfully
    And Bookmark "cust1 dc1 host1" should contain:
      | name      | value      |
      | host_name | a.host.com |
      | login     | user1      |
    And Bookmark "cust1 dc1 host2" should contain:
      | name      | value      |
      | host_name | b.host.com |
      | login     | user1      |
    And Bookmark "cust1 dc2 host1" should contain:
      | name      | value      |
      | host_name | c.host.com |
      | login     | user3      |

  Scenario: Cancel import on prompt
    Given Existing database
    When I import yml file
    And I answer "no" at the prompt
    Then It should run successfully
    And Bookmark "cust1 dc1 host1" should not exist
